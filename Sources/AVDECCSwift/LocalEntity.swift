/*
 * Copyright (C) 2023-2024, PADL Software Pty Ltd
 *
 * This file is part of AVDECCSwift.
 *
 * AVDECCSwift is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * AVDECCSwift is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with AVDECCSwift.  If not, see <http://www.gnu.org/licenses/>.
 */

import CAVDECC

public enum LocalEntityError: UInt8, Error {
    case invalidParameters = 1
    case duplicateLocalIdentityID = 2
    case invalidEntityHandle = 98
    case internalError = 99

    init(_ error: avdecc_local_entity_error_t) {
        self = Self(rawValue: error) ?? .internalError
    }
}

public enum LocalEntityAemCommandStatus: UInt16, Error {
    case notImplemented = 1
    case noSuchDescriptor = 2
    case lockedByOther = 3
    case acquiredByOther = 4
    case notAuthenticated = 5
    case authenticationDisabled = 6
    case badArguments = 7
    case onResources = 8
    case inProgress = 9
    case entityMisbehaving = 10
    case notSupported = 11
    case streamIsRunning = 12
    case networkError = 995
    case protocolError = 996
    case timedOut = 997
    case unknownEntity = 998
    case internalError = 999

    init(_ status: avdecc_local_entity_aem_command_status_t) {
        self = Self(rawValue: status) ?? .internalError
    }
}

func withLocalEntityError(_ block: () -> avdecc_local_entity_error_t) throws {
    let err = block()
    if err != 0 {
        throw LocalEntityError(err)
    }
}

public protocol LocalEntityDelegate {
    func onTransportError(_: LocalEntity)
    func onEntityOnline(_: LocalEntity, id: UniqueIdentifier, entity: Entity)
    func onEntityUpdate(_: LocalEntity, id: UniqueIdentifier, entity: Entity)
    func onEntityOffline(_: LocalEntity, id: UniqueIdentifier)
}

public final class LocalEntity {
    private static var DelegateThunk: avdecc_local_entity_controller_delegate_t = {
        var thunk = avdecc_local_entity_controller_delegate_t()

        thunk.onTransportError = LocalEntity_onTransportError
        thunk.onEntityOnline = LocalEntity_onEntityOnline
        thunk.onEntityUpdate = LocalEntity_onEntityUpdate
        thunk.onEntityOffline = LocalEntity_onEntityOffline

        return thunk
    }()

    var handle: UnsafeMutableRawPointer!
    public let entity: Entity
    public var delegate: LocalEntityDelegate?

    static func withDelegate(
        _ handle: UnsafeMutableRawPointer?,
        _ body: @escaping (LocalEntity) -> ()
    ) {
        if let handle, let this = LA_AVDECC_LocalEntity_getApplicationData(handle) {
            body(Unmanaged<LocalEntity>.fromOpaque(this).takeUnretainedValue())
        }
    }

    private init(_ protocolInterfaceHandle: UnsafeMutableRawPointer, entity: Entity) throws {
        self.entity = entity
        var entity = entity.bridgeToAvdeccCType()

        try withLocalEntityError {
            LA_AVDECC_LocalEntity_create(
                protocolInterfaceHandle,
                &entity,
                &LocalEntity.DelegateThunk,
                &self.handle
            )
        }

        LA_AVDECC_LocalEntity_setApplicationData(
            handle,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    public convenience init(protocolInterface: ProtocolInterface, entity: Entity) throws {
        try self.init(protocolInterface.handle, entity: entity)
    }

    deinit {
        if handle != nil {
            LA_AVDECC_LocalEntity_setApplicationData(handle, nil)
            LA_AVDECC_LocalEntity_destroy(handle)
        }
    }

    public func enableEntityAdvertising(availableDuration: CUnsignedInt) throws {
        try withLocalEntityError {
            LA_AVDECC_LocalEntity_enableEntityAdvertising(handle, availableDuration)
        }
    }

    public func disableEntityAdvertising() throws {
        try withLocalEntityError {
            LA_AVDECC_LocalEntity_disableEntityAdvertising(handle)
        }
    }

    public func discoverRemoteEntities() throws {
        try withLocalEntityError {
            LA_AVDECC_LocalEntity_discoverRemoteEntities(handle)
        }
    }

    public func discoverRemoteEntity(id: UniqueIdentifier) throws {
        try withLocalEntityError {
            LA_AVDECC_LocalEntity_discoverRemoteEntity(handle, id.id)
        }
    }

    public func setAutomaticDiscoveryDelay(_ millisecondsDelay: CUnsignedInt) throws {
        try withLocalEntityError {
            LA_AVDECC_LocalEntity_setAutomaticDiscoveryDelay(handle, millisecondsDelay)
        }
    }

    private func invokeHandler<T>(
        _ handler: (
            _ handle: UnsafeMutableRawPointer,
            _ continuation: @escaping (avdecc_local_entity_aem_command_status_t, T?) -> ()
        ) -> avdecc_local_entity_error_t
    ) async throws -> T {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            T,
            Error
        >) in
            guard let self else {
                continuation.resume(throwing: LocalEntityError.internalError)
                return
            }

            let err = handler(self.handle) { status, value in
                guard status == 0 else {
                    continuation.resume(throwing: LocalEntityAemCommandStatus(status))
                    return
                }
                guard let value else {
                    continuation.resume(throwing: LocalEntityError.internalError)
                    return
                }
                continuation.resume(returning: value)
            }
            guard err == 0 else {
                continuation.resume(throwing: LocalEntityError(err))
                return
            }
        }
    }

    public func acquireEntity(
        id entityID: UniqueIdentifier,
        isPersistent: Bool,
        descriptorType: EntityModelDescriptorType,
        descriptorIndex: EntityModelDescriptorIndex
    ) async throws -> UniqueIdentifier {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_acquireEntity_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                isPersistent ? 1 : 0,
                descriptorType.rawValue,
                descriptorIndex
            ) { _, _, status, owningEntity, _, _ in
                continuation(status, UniqueIdentifier(owningEntity))
            }
        }
    }

    public func releaseEntity(
        id entityID: UniqueIdentifier,
        descriptorType: EntityModelDescriptorType,
        descriptorIndex: EntityModelDescriptorIndex
    ) async throws -> UniqueIdentifier {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_releaseEntity_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                descriptorType.rawValue,
                descriptorIndex
            ) { _, _, status, owningEntity, _, _ in
                continuation(status, UniqueIdentifier(owningEntity))
            }
        }
    }

    public func lockEntity(
        id entityID: UniqueIdentifier,
        descriptorType: EntityModelDescriptorType,
        descriptorIndex: EntityModelDescriptorIndex
    ) async throws -> UniqueIdentifier {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_lockEntity_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                descriptorType.rawValue,
                descriptorIndex
            ) { _, _, status, lockingEntity, _, _ in
                continuation(status, UniqueIdentifier(lockingEntity))
            }
        }
    }

    public func unlockEntity(
        id entityID: UniqueIdentifier,
        descriptorType: EntityModelDescriptorType,
        descriptorIndex: EntityModelDescriptorIndex
    ) async throws -> UniqueIdentifier {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_unlockEntity_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                descriptorType.rawValue,
                descriptorIndex
            ) { _, _, status, lockingEntity, _, _ in
                continuation(status, UniqueIdentifier(lockingEntity))
            }
        }
    }

    // LA_AVDECC_LocalEntity_queryEntityAvailable
    // LA_AVDECC_LocalEntity_queryControllerAvailable

    public func registerUnsolicitedNotifications(
        id entityID: UniqueIdentifier
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_registerUnsolicitedNotifications_block(
                handle,
                entityID.bridgeToAvdeccCType()
            ) { _, _, status in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func unregisterUnsolicitedNotifications(
        id entityID: UniqueIdentifier
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_unregisterUnsolicitedNotifications_block(
                handle,
                entityID.bridgeToAvdeccCType()
            ) { _, _, status in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func readEntityDescriptor(
        id entityID: UniqueIdentifier
    ) async throws -> EntityModelEntityDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readEntityDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType()
            ) { _, _, status, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelEntityDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readConfigurationDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelConfigurationDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readConfigurationDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex
            ) { _, _, status, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelConfigurationDescriptor(descriptor!.pointee) :
                        nil
                )
            }
        }
    }

    public func readAudioUnitDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        audioUnitIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelAudioUnitDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readAudioUnitDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                audioUnitIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelAudioUnitDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readStreamInputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStreamDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readStreamInputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                streamIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelStreamDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readStreamOutputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStreamDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readStreamOutputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                streamIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelStreamDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readJackInputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        jackIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelJackDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readJackInputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                jackIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelJackDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readJackOutputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        jackIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelJackDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readJackOutputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                jackIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelJackDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readAvbInterfaceDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        avbInterfaceIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelAvbInterfaceDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readAvbInterfaceDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                avbInterfaceIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelAvbInterfaceDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readClockSourceDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        clockSourceIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelClockSourceDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readClockSourceDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                clockSourceIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelClockSourceDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readMemoryObjectDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        memoryObjectIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelMemoryObjectDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readMemoryObjectDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                memoryObjectIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelMemoryObjectDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readLocaleDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        localeIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelLocaleDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readLocaleDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                localeIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelLocaleDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readStringsDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        stringsIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStringsDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readStringsDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                stringsIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelStringsDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readStreamPortInputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        streamPortIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStreamPortDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readStreamPortInputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                streamPortIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelStreamPortDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readStreamPortOutputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        streamPortIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStreamPortDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readStreamPortOutputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                streamPortIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelStreamPortDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readExternalPortInputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        externalPortIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelExternalPortDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readExternalPortInputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                externalPortIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelExternalPortDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readExternalPortOutputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        externalPortIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelExternalPortDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readExternalPortOutputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                externalPortIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelExternalPortDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readInternalPortInputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        externalPortIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelInternalPortDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readInternalPortInputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                externalPortIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelInternalPortDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readInternalPortOutputDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        externalPortIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelInternalPortDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readInternalPortOutputDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                externalPortIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelInternalPortDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readAudioClusterDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        audioClusterIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelAudioClusterDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readAudioClusterDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                audioClusterIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelAudioClusterDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readAudioMapDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        audioMapIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelAudioMapDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readAudioMapDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                audioMapIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelAudioMapDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func readClockDomainDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        clockDomainIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelClockDomainDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readClockDomainDescriptor_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                clockDomainIndex
            ) { _, _, status, _, _, descriptor in
                continuation(
                    status,
                    descriptor != nil ? EntityModelClockDomainDescriptor(descriptor!.pointee) : nil
                )
            }
        }
    }

    public func setConfiguration(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setConfiguration_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex
            ) { _, _, status, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getConfiguration(
        id entityID: UniqueIdentifier
    ) async throws -> EntityModelDescriptorIndex {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getConfiguration_block(
                handle,
                entityID.bridgeToAvdeccCType()
            ) { _, _, status, index in
                continuation(
                    status,
                    index
                )
            }
        }
    }

    public func setStreamInputFormat(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex,
        streamFormat: EntityModelStreamFormat
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setStreamInputFormat_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex,
                streamFormat._format
            ) { _, _, status, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getStreamInputFormat(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStreamFormat {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamInputFormat_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _, format in
                continuation(
                    status,
                    EntityModelStreamFormat(format)
                )
            }
        }
    }

    public func setStreamOutputFormat(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex,
        streamFormat: EntityModelStreamFormat
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setStreamOutputFormat_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex,
                streamFormat._format
            ) { _, _, status, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getStreamOutputFormat(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStreamFormat {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamOutputFormat_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _, format in
                continuation(
                    status,
                    EntityModelStreamFormat(format)
                )
            }
        }
    }

    public func getStreamPortInputAudioMap(
        id entityID: UniqueIdentifier,
        streamPortIndex: EntityModelDescriptorIndex,
        mapIndex: EntityModelDescriptorIndex
    ) async throws -> [EntityModelAudioMapping] {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamPortInputAudioMap_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamPortIndex,
                mapIndex
            ) { _, _, status, _, numberOfMaps, _, mappings in
                continuation(
                    status,
                    EntityModelAudioMapDescriptor(numberOfMaps: numberOfMaps, mappings).mappings
                )
            }
        }
    }

    public func getStreamPortOutputAudioMap(
        id entityID: UniqueIdentifier,
        streamPortIndex: EntityModelDescriptorIndex,
        mapIndex: EntityModelDescriptorIndex
    ) async throws -> [EntityModelAudioMapping] {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamPortOutputAudioMap_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamPortIndex,
                mapIndex
            ) { _, _, status, _, numberOfMaps, _, mappings in
                continuation(
                    status,
                    EntityModelAudioMapDescriptor(numberOfMaps: numberOfMaps, mappings).mappings
                )
            }
        }
    }

    private func withStreamPortAudioMappings(
        id entityID: UniqueIdentifier,
        streamPortIndex: EntityModelDescriptorIndex,
        mappings: [EntityModelAudioMapping],
        _ block: (
            _ handle: UnsafeMutableRawPointer,
            _ entityID: avdecc_unique_identifier_t,
            _ streamPortIndex: EntityModelDescriptorIndex,
            _ mappings: UnsafePointer<avdecc_entity_model_audio_mapping_cp?>,
            _ block: @escaping avdecc_local_entity_add_stream_port_input_audio_mappings_block
        ) -> avdecc_local_entity_error_t
    ) async throws {
        var _mappings = mappings.map { $0.bridgeToAvdeccCType() }
        var pointers = [avdecc_entity_model_audio_mapping_cp?]()

        for i in 0..<_mappings.count {
            withUnsafePointer(to: &_mappings[i]) {
                pointers.append($0) // FIXME: escaping pointer
            }
        }

        pointers.append(nil)

        try await invokeHandler { handle, continuation in
            block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamPortIndex,
                pointers
            ) { _, _, status, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func addStreamPortInputAudioMappings(
        id entityID: UniqueIdentifier,
        streamPortIndex: EntityModelDescriptorIndex,
        mappings: [EntityModelAudioMapping]
    ) async throws {
        try await withStreamPortAudioMappings(
            id: entityID,
            streamPortIndex: streamPortIndex,
            mappings: mappings
        ) { handle, entityID, streamPortIndex, mappings, block in
            LA_AVDECC_LocalEntity_addStreamPortInputAudioMappings_block(
                handle,
                entityID,
                streamPortIndex,
                mappings,
                block
            )
        }
    }

    public func addStreamPortOutputAudioMappings(
        id entityID: UniqueIdentifier,
        streamPortIndex: EntityModelDescriptorIndex,
        mappings: [EntityModelAudioMapping]
    ) async throws {
        try await withStreamPortAudioMappings(
            id: entityID,
            streamPortIndex: streamPortIndex,
            mappings: mappings
        ) { handle, entityID, streamPortIndex, mappings, block in
            LA_AVDECC_LocalEntity_addStreamPortOutputAudioMappings_block(
                handle,
                entityID,
                streamPortIndex,
                mappings,
                block
            )
        }
    }

    public func removeStreamPortInputAudioMappings(
        id entityID: UniqueIdentifier,
        streamPortIndex: EntityModelDescriptorIndex,
        mappings: [EntityModelAudioMapping]
    ) async throws {
        try await withStreamPortAudioMappings(
            id: entityID,
            streamPortIndex: streamPortIndex,
            mappings: mappings
        ) { handle, entityID, streamPortIndex, mappings, block in
            LA_AVDECC_LocalEntity_removeStreamPortInputAudioMappings_block(
                handle,
                entityID,
                streamPortIndex,
                mappings,
                block
            )
        }
    }

    public func removeStreamPortOutputAudioMappings(
        id entityID: UniqueIdentifier,
        streamPortIndex: EntityModelDescriptorIndex,
        mappings: [EntityModelAudioMapping]
    ) async throws {
        try await withStreamPortAudioMappings(
            id: entityID,
            streamPortIndex: streamPortIndex,
            mappings: mappings
        ) { handle, entityID, streamPortIndex, mappings, block in
            LA_AVDECC_LocalEntity_removeStreamPortOutputAudioMappings_block(
                handle,
                entityID,
                streamPortIndex,
                mappings,
                block
            )
        }
    }

    public func setStreamInputInfo(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex,
        streamInputInfo: EntityModelStreamInfo
    ) async throws {
        var streamInputInfo = streamInputInfo.bridgeToAvdeccCType()
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setStreamInputInfo_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex,
                &streamInputInfo
            ) { _, _, status, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func setStreamOutputInfo(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex,
        streamOutputInfo: EntityModelStreamInfo
    ) async throws {
        var streamOutputInfo = streamOutputInfo.bridgeToAvdeccCType()
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setStreamOutputInfo_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex,
                &streamOutputInfo
            ) { _, _, status, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getStreamInputInfo(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStreamInfo {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamInputInfo_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _, streamInputInfo in
                continuation(
                    status,
                    streamInputInfo != nil ? EntityModelStreamInfo(streamInputInfo!) : nil
                )
            }
        }
    }

    public func getStreamOutputInfo(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelStreamInfo {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamOutputInfo_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _, streamOutputInfo in
                continuation(
                    status,
                    streamOutputInfo != nil ? EntityModelStreamInfo(streamOutputInfo!) : nil
                )
            }
        }
    }

    public func setEntityName(
        id entityID: UniqueIdentifier,
        to entityName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setEntityName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                entityName
            ) { _, _, status, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getEntityName(
        id entityID: UniqueIdentifier
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getEntityName_block(
                handle,
                entityID.bridgeToAvdeccCType()
            ) { _, _, status, entityName in
                continuation(
                    status,
                    entityName != nil ? String(cString: entityName!) : nil
                )
            }
        }
    }

    public func setEntityGroupName(
        id entityID: UniqueIdentifier,
        to entityGroupName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setEntityGroupName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                entityGroupName
            ) { _, _, status, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getEntityGroupName(
        id entityID: UniqueIdentifier
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getEntityGroupName_block(
                handle,
                entityID.bridgeToAvdeccCType()
            ) { _, _, status, entityGroupName in
                continuation(
                    status,
                    entityGroupName != nil ? String(cString: entityGroupName!) : nil
                )
            }
        }
    }

    public func setConfigurationName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        to configurationName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setConfigurationName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                configurationName
            ) { _, _, status, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getConfigurationName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getConfigurationName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex
            ) { _, _, status, _, configurationName in
                continuation(
                    status,
                    configurationName != nil ? String(cString: configurationName!) : nil
                )
            }
        }
    }

    public func setAudioUnitName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        audioUnitIndex: EntityModelDescriptorIndex,
        to audioUnitName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setAudioUnitName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                audioUnitIndex,
                audioUnitName
            ) { _, _, status, _, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getAudioUnitName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        audioUnitIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAudioUnitName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                audioUnitIndex
            ) { _, _, status, _, _, audioUnitName in
                continuation(
                    status,
                    audioUnitName != nil ? String(cString: audioUnitName!) : nil
                )
            }
        }
    }

    public func setStreamInputName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        streamIndex: EntityModelDescriptorIndex,
        to streamInputName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setStreamInputName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                streamIndex,
                streamInputName
            ) { _, _, status, _, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getStreamInputName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamInputName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                streamIndex
            ) { _, _, status, _, _, streamInputName in
                continuation(
                    status,
                    streamInputName != nil ? String(cString: streamInputName!) : nil
                )
            }
        }
    }

    public func setStreamOutputName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        streamIndex: EntityModelDescriptorIndex,
        to streamOutputName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setStreamOutputName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                streamIndex,
                streamOutputName
            ) { _, _, status, _, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getStreamOutputName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamOutputName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                streamIndex
            ) { _, _, status, _, _, streamOutputName in
                continuation(
                    status,
                    streamOutputName != nil ? String(cString: streamOutputName!) : nil
                )
            }
        }
    }

    public func setAvbInterfaceName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        avbInterfaceIndex: EntityModelDescriptorIndex,
        to avbInterfaceName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setAvbInterfaceName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                avbInterfaceIndex,
                avbInterfaceName
            ) { _, _, status, _, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getAvbInterfaceName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        avbInterfaceIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAvbInterfaceName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                avbInterfaceIndex
            ) { _, _, status, _, _, avbInterfaceName in
                continuation(
                    status,
                    avbInterfaceName != nil ? String(cString: avbInterfaceName!) : nil
                )
            }
        }
    }

    public func setClockSourceName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        clockSourceIndex: EntityModelDescriptorIndex,
        to clockSourceName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setClockSourceName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                clockSourceIndex,
                clockSourceName
            ) { _, _, status, _, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getClockSourceName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        clockSourceIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getClockSourceName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                clockSourceIndex
            ) { _, _, status, _, _, clockSourceName in
                continuation(
                    status,
                    clockSourceName != nil ? String(cString: clockSourceName!) : nil
                )
            }
        }
    }

    public func setMemoryObjectName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        memoryObjectIndex: EntityModelDescriptorIndex,
        to memoryObjectName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setMemoryObjectName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                memoryObjectIndex,
                memoryObjectName
            ) { _, _, status, _, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getMemoryObjectName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        memoryObjectIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getMemoryObjectName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                memoryObjectIndex
            ) { _, _, status, _, _, memoryObjectName in
                continuation(
                    status,
                    memoryObjectName != nil ? String(cString: memoryObjectName!) : nil
                )
            }
        }
    }

    public func setAudioClusterName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        audioClusterIndex: EntityModelDescriptorIndex,
        to audioClusterName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setAudioClusterName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                audioClusterIndex,
                audioClusterName
            ) { _, _, status, _, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getAudioClusterName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        audioClusterIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAudioClusterName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                audioClusterIndex
            ) { _, _, status, _, _, audioClusterName in
                continuation(
                    status,
                    audioClusterName != nil ? String(cString: audioClusterName!) : nil
                )
            }
        }
    }

    public func setClockDomainName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        clockDomainIndex: EntityModelDescriptorIndex,
        to clockDomainName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setClockDomainName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                clockDomainIndex,
                clockDomainName
            ) { _, _, status, _, _, _ in
                continuation(
                    status,
                    ()
                )
            }
        }
    }

    public func getClockDomainName(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex,
        clockDomainIndex: EntityModelDescriptorIndex
    ) async throws -> String {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getClockDomainName_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                configurationIndex,
                clockDomainIndex
            ) { _, _, status, _, _, clockDomainName in
                continuation(
                    status,
                    clockDomainName != nil ? String(cString: clockDomainName!) : nil
                )
            }
        }
    }

    public func setAudioUnitSamplingRate(
        id entityID: UniqueIdentifier,
        audioUnitIndex: EntityModelDescriptorIndex,
        samplingRate: EntityModelSamplingRate
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setAudioUnitSamplingRate_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                audioUnitIndex,
                samplingRate
            ) { _, _, status, _, _ in
                continuation(status, ())
            }
        }
    }

    public func getAudioUnitSamplingRate(
        id entityID: UniqueIdentifier,
        audioUnitIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelSamplingRate {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAudioUnitSamplingRate_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                audioUnitIndex
            ) { _, _, status, _, samplingRate in
                continuation(status, samplingRate)
            }
        }
    }

    public func setVideoClusterSamplingRate(
        id entityID: UniqueIdentifier,
        videoClusterIndex: EntityModelDescriptorIndex,
        samplingRate: EntityModelSamplingRate
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setVideoClusterSamplingRate_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                videoClusterIndex,
                samplingRate
            ) { _, _, status, _, _ in
                continuation(status, ())
            }
        }
    }

    public func getVideoClusterSamplingRate(
        id entityID: UniqueIdentifier,
        videoClusterIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelSamplingRate {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getVideoClusterSamplingRate_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                videoClusterIndex
            ) { _, _, status, _, samplingRate in
                continuation(status, samplingRate)
            }
        }
    }

    public func setSensorClusterSamplingRate(
        id entityID: UniqueIdentifier,
        sensorClusterIndex: EntityModelDescriptorIndex,
        samplingRate: EntityModelSamplingRate
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setSensorClusterSamplingRate_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                sensorClusterIndex,
                samplingRate
            ) { _, _, status, _, _ in
                continuation(status, ())
            }
        }
    }

    public func getSensorClusterSamplingRate(
        id entityID: UniqueIdentifier,
        sensorClusterIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelSamplingRate {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getSensorClusterSamplingRate_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                sensorClusterIndex
            ) { _, _, status, _, samplingRate in
                continuation(status, samplingRate)
            }
        }
    }

    public func setClockSource(
        id entityID: UniqueIdentifier,
        clockDomainIndex: EntityModelDescriptorIndex,
        clockSourceIndex: EntityModelDescriptorIndex
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setClockSource_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                clockDomainIndex,
                clockSourceIndex
            ) { _, _, status, _, _ in
                continuation(status, ())
            }
        }
    }

    public func getClockSource(
        id entityID: UniqueIdentifier,
        clockDomainIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelDescriptorIndex {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getClockSource_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                clockDomainIndex
            ) { _, _, status, _, clockSourceIndex in
                continuation(status, clockSourceIndex)
            }
        }
    }

    public func startStreamInput(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_startStreamInput_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _ in
                continuation(status, ())
            }
        }
    }

    public func startStreamOutput(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_startStreamOutput_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _ in
                continuation(status, ())
            }
        }
    }

    public func stopStreamInput(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_stopStreamInput_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _ in
                continuation(status, ())
            }
        }
    }

    public func stopStreamOutput(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_stopStreamOutput_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _ in
                continuation(status, ())
            }
        }
    }

    public func getAvbInfo(
        id entityID: UniqueIdentifier,
        avbInterfaceIndex: EntityModelDescriptorIndex
    ) async throws -> EntityModelAvbInfo {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAvbInfo_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                avbInterfaceIndex
            ) { _, _, status, _, info in
                continuation(status, info != nil ? EntityModelAvbInfo(info!.pointee) : nil)
            }
        }
    }

    public func getAsPath(
        id entityID: UniqueIdentifier,
        avbInterfaceIndex: EntityModelDescriptorIndex
    ) async throws -> [UniqueIdentifier] {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAsPath_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                avbInterfaceIndex
            ) { _, _, status, _, info in
                let path: [UniqueIdentifier]?

                if let sequence = info?.pointee.sequence {
                    path = nullTerminatedArrayToSwiftArray(sequence).map { UniqueIdentifier($0) }
                } else {
                    path = nil
                }
                continuation(status, path)
            }
        }
    }

    private static func makeCounters(
        _ validCounters: UInt32,
        _ counters: UnsafePointer<avdecc_entity_model_descriptor_counter_t>?
    ) -> [UInt32?]? {
        guard let counters else { return nil }

        let bufferPointer = UnsafeBufferPointer(start: counters, count: 32)

        var array = [UInt32?]()

        for i in 0..<bufferPointer.count {
            let valid = validCounters & (1 << i) != 0
            array.append(valid ? bufferPointer[i] : nil)
        }

        return array
    }

    public func getEntityCounters(
        id entityID: UniqueIdentifier
    ) async throws -> [UInt32?] {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getEntityCounters_block(
                handle,
                entityID.bridgeToAvdeccCType()
            ) { _, _, status, validCounters, counters in
                continuation(status, Self.makeCounters(validCounters, counters))
            }
        }
    }

    public func getAvbInterfaceCounters(
        id entityID: UniqueIdentifier,
        avbInterfaceIndex: EntityModelDescriptorIndex
    ) async throws -> [UInt32?] {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAvbInterfaceCounters_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                avbInterfaceIndex
            ) { _, _, status, _, validCounters, counters in
                continuation(status, Self.makeCounters(validCounters, counters))
            }
        }
    }

    public func getClockDomainCounters(
        id entityID: UniqueIdentifier,
        clockDomainIndex: EntityModelDescriptorIndex
    ) async throws -> [UInt32?] {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getClockDomainCounters_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                clockDomainIndex
            ) { _, _, status, _, validCounters, counters in
                continuation(status, Self.makeCounters(validCounters, counters))
            }
        }
    }

    public func getStreamInputCounters(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> [UInt32?] {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamInputCounters_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _, validCounters, counters in
                continuation(status, Self.makeCounters(validCounters, counters))
            }
        }
    }

    public func getStreamOutputCounters(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorIndex
    ) async throws -> [UInt32?] {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getStreamOutputCounters_block(
                handle,
                entityID.bridgeToAvdeccCType(),
                streamIndex
            ) { _, _, status, _, validCounters, counters in
                continuation(status, Self.makeCounters(validCounters, counters))
            }
        }
    }

    public func getMilanInfo(
        id entityID: UniqueIdentifier
    ) async throws -> EntityModelMilanInfo {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getMilanInfo_block(
                handle,
                entityID.bridgeToAvdeccCType()
            ) { _, _, status, info in
                continuation(status, info != nil ? EntityModelMilanInfo(info!.pointee) : nil)
            }
        }
    }

    public func connect(
        talkerStream: EntityModelStreamIdentification,
        to listenerStream: EntityModelStreamIdentification
    ) async throws -> (UInt16, UInt16) {
        var talkerStream = talkerStream.bridgeToAvdeccCType()
        var listenerStream = listenerStream.bridgeToAvdeccCType()
        return try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_connectStream_block(
                handle,
                &talkerStream,
                &listenerStream
            ) { _, _, _, connectionCount, flags, status in
                continuation(status, (connectionCount, flags))
            }
        }
    }

    public func disconnect(
        talkerStream: EntityModelStreamIdentification,
        from listenerStream: EntityModelStreamIdentification,
        force: Bool = false
    ) async throws -> (UInt16, UInt16) {
        var talkerStream = talkerStream.bridgeToAvdeccCType()
        var listenerStream = listenerStream.bridgeToAvdeccCType()
        return try await invokeHandler { handle, continuation in
            if force {
                LA_AVDECC_LocalEntity_disconnectTalkerStream_block(
                    handle,
                    &talkerStream,
                    &listenerStream
                ) { _, _, _, connectionCount, flags, status in
                    continuation(status, (connectionCount, flags))
                }
            } else {
                LA_AVDECC_LocalEntity_disconnectStream_block(
                    handle,
                    &talkerStream,
                    &listenerStream
                ) { _, _, _, connectionCount, flags, status in
                    continuation(status, (connectionCount, flags))
                }
            }
        }
    }

    public struct StreamState: Sendable {
        public let talkerStream: EntityModelStreamIdentification?
        public let listenerStream: EntityModelStreamIdentification?
        public let connectionCount: UInt16
        public let flags: UInt16
    }

    public func getTalkerStreamState(_ talkerStream: EntityModelStreamIdentification) async throws
        -> StreamState
    {
        var talkerStream = talkerStream.bridgeToAvdeccCType()
        return try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getTalkerStreamState_block(
                handle,
                &talkerStream
            ) { _, talkerStream, listenerStream, connectionCount, flags, status in
                let streamState = StreamState(
                    talkerStream: talkerStream != nil ?
                        EntityModelStreamIdentification(talkerStream!) : nil,
                    listenerStream: listenerStream != nil ?
                        EntityModelStreamIdentification(listenerStream!) : nil,
                    connectionCount: connectionCount,
                    flags: flags
                )
                continuation(status, streamState)
            }
        }
    }

    public func getListenerStreamState(
        _ talkerStream: EntityModelStreamIdentification
    ) async throws
        -> StreamState
    {
        var talkerStream = talkerStream.bridgeToAvdeccCType()
        return try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getListenerStreamState_block(
                handle,
                &talkerStream
            ) { _, talkerStream, listenerStream, connectionCount, flags, status in
                let streamState = StreamState(
                    talkerStream: talkerStream != nil ?
                        EntityModelStreamIdentification(talkerStream!) : nil,
                    listenerStream: listenerStream != nil ?
                        EntityModelStreamIdentification(listenerStream!) : nil,
                    connectionCount: connectionCount,
                    flags: flags
                )
                continuation(status, streamState)
            }
        }
    }

    public func getTalkerStreamConnection(
        _ talkerStream: EntityModelStreamIdentification,
        connectionIndex: UInt16
    ) async throws -> StreamState {
        var talkerStream = talkerStream.bridgeToAvdeccCType()
        return try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getTalkerStreamConnection_block(
                handle,
                &talkerStream,
                connectionIndex
            ) { _, talkerStream, listenerStream, connectionCount, flags, status in
                let streamState = StreamState(
                    talkerStream: talkerStream != nil ?
                        EntityModelStreamIdentification(talkerStream!) : nil,
                    listenerStream: listenerStream != nil ?
                        EntityModelStreamIdentification(listenerStream!) : nil,
                    connectionCount: connectionCount,
                    flags: flags
                )
                continuation(status, streamState)
            }
        }
    }
}

private func LocalEntity_onTransportError(handle: UnsafeMutableRawPointer?) {
    LocalEntity.withDelegate(handle) {
        $0.delegate?.onTransportError($0)
    }
}

private func LocalEntity_onEntityOnline(
    _ handle: UnsafeMutableRawPointer?,
    _ entityID: avdecc_unique_identifier_t,
    _ entity: avdecc_entity_cp?
) {
    LocalEntity.withDelegate(handle) {
        $0.delegate?.onEntityOnline($0, id: UniqueIdentifier(entityID), entity: Entity(entity!))
    }
}

private func LocalEntity_onEntityUpdate(
    _ handle: UnsafeMutableRawPointer?,
    _ entityID: avdecc_unique_identifier_t,
    _ entity: avdecc_entity_cp?
) {
    LocalEntity.withDelegate(handle) {
        $0.delegate?.onEntityUpdate($0, id: UniqueIdentifier(entityID), entity: Entity(entity!))
    }
}

private func LocalEntity_onEntityOffline(
    _ handle: UnsafeMutableRawPointer?,
    _ entityID: avdecc_unique_identifier_t
) {
    LocalEntity.withDelegate(handle) {
        $0.delegate?.onEntityOffline($0, id: UniqueIdentifier(entityID))
    }
}
