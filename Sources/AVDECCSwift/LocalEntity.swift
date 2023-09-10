/*
 * Copyright (C) 2023, PADL Software Pty Ltd
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
        var entity = entity.bridgeToAvdeccType()

        try withLocalEntityError {
            LA_AVDECC_LocalEntity_create(protocolInterfaceHandle, &entity, &LocalEntity.DelegateThunk, &self.handle)
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
            LA_AVDECC_LocalEntity_discoverRemoteEntity(handle, id)
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
                guard status != 0 else {
                    continuation.resume(throwing: LocalEntityAemCommandStatus(status))
                    return
                }
                guard let value else {
                    continuation.resume(throwing: LocalEntityError.internalError)
                    return
                }
                continuation.resume(returning: value)
            }
            guard err != 0 else {
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
                entityID,
                isPersistent ? 1 : 0,
                descriptorType,
                descriptorIndex
            ) { _, _, status, owningEntity, _, _ in
                continuation(status, owningEntity)
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
                entityID,
                descriptorType,
                descriptorIndex
            ) { _, _, status, owningEntity, _, _ in
                continuation(status, owningEntity)
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
                entityID,
                descriptorType,
                descriptorIndex
            ) { _, _, status, lockingEntity, _, _ in
                continuation(status, lockingEntity)
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
                entityID,
                descriptorType,
                descriptorIndex
            ) { _, _, status, lockingEntity, _, _ in
                continuation(status, lockingEntity)
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
                entityID
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
                entityID
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
                entityID
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
        configurationIndex: EntityModelDescriptorType
    ) async throws -> EntityModelConfigurationDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readConfigurationDescriptor_block(
                handle,
                entityID,
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
        configurationIndex: EntityModelDescriptorType,
        audioUnitIndex: EntityModelDescriptorType
    ) async throws -> EntityModelAudioUnitDescriptor {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_readAudioUnitDescriptor_block(
                handle,
                entityID,
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

    // LA_AVDECC_LocalEntity_readStreamInputDescriptor
    // LA_AVDECC_LocalEntity_readStreamOutputDescriptor
    // LA_AVDECC_LocalEntity_readJackInputDescriptor
    // LA_AVDECC_LocalEntity_readJackOutputDescriptor
    // LA_AVDECC_LocalEntity_readAvbInterfaceDescriptor
    // LA_AVDECC_LocalEntity_readClockSourceDescriptor
    // LA_AVDECC_LocalEntity_readMemoryObjectDescriptor
    // LA_AVDECC_LocalEntity_readLocaleDescriptor
    // LA_AVDECC_LocalEntity_readStringsDescriptor
    // LA_AVDECC_LocalEntity_readStreamPortInputDescriptor
    // LA_AVDECC_LocalEntity_readStreamPortOutputDescriptor
    // LA_AVDECC_LocalEntity_readExternalPortInputDescriptor
    // LA_AVDECC_LocalEntity_readExternalPortOutputDescriptor
    // LA_AVDECC_LocalEntity_readInternalPortInputDescriptor
    // LA_AVDECC_LocalEntity_readInternalPortOutputDescriptor
    // LA_AVDECC_LocalEntity_readAudioClusterDescriptor
    // LA_AVDECC_LocalEntity_readAudioMapDescriptor
    // LA_AVDECC_LocalEntity_readClockDomainDescriptor

    public func setConfiguration(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorIndex
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setConfiguration_block(
                handle,
                entityID,
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
                entityID
            ) { _, _, status, index in
                continuation(
                    status,
                    index
                )
            }
        }
    }

    // LA_AVDECC_LocalEntity_setStreamInputFormat
    // LA_AVDECC_LocalEntity_getStreamInputFormat
    // LA_AVDECC_LocalEntity_setStreamOutputFormat
    // LA_AVDECC_LocalEntity_getStreamOutputFormat
    // LA_AVDECC_LocalEntity_getStreamPortInputAudioMap
    // LA_AVDECC_LocalEntity_getStreamPortOutputAudioMap
    // LA_AVDECC_LocalEntity_addStreamPortInputAudioMappings
    // LA_AVDECC_LocalEntity_addStreamPortOutputAudioMappings
    // LA_AVDECC_LocalEntity_removeStreamPortInputAudioMappings
    // LA_AVDECC_LocalEntity_removeStreamPortOutputAudioMappings
    // LA_AVDECC_LocalEntity_setStreamInputInfo
    // LA_AVDECC_LocalEntity_setStreamOutputInfo
    // LA_AVDECC_LocalEntity_getStreamInputInfo
    // LA_AVDECC_LocalEntity_getStreamOutputInfo

    public func setEntityName(
        id entityID: UniqueIdentifier,
        to entityName: String
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setEntityName_block(
                handle,
                entityID,
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
                entityID
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
                entityID,
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
                entityID
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
                entityID,
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
        audioUnitIndex: EntityModelDescriptorType,
        samplingRate: avdecc_entity_model_sampling_rate_t
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setAudioUnitSamplingRate_block(
                handle,
                entityID,
                audioUnitIndex,
                samplingRate
            ) { _, _, status, _, _ in
                continuation(status, ())
            }
        }
    }

    public func getAudioUnitSamplingRate(
        id entityID: UniqueIdentifier,
        audioUnitIndex: EntityModelDescriptorType
    ) async throws -> avdecc_entity_model_sampling_rate_t {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAudioUnitSamplingRate_block(
                handle,
                entityID,
                audioUnitIndex
            ) { _, _, status, _, samplingRate in
                continuation(status, samplingRate)
            }
        }
    }

    public func setVideoClusterSamplingRate(
        id entityID: UniqueIdentifier,
        videoClusterIndex: EntityModelDescriptorType,
        samplingRate: avdecc_entity_model_sampling_rate_t
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setVideoClusterSamplingRate_block(
                handle,
                entityID,
                videoClusterIndex,
                samplingRate
            ) { _, _, status, _, _ in
                continuation(status, ())
            }
        }
    }

    public func getVideoClusterSamplingRate(
        id entityID: UniqueIdentifier,
        videoClusterIndex: EntityModelDescriptorType
    ) async throws -> avdecc_entity_model_sampling_rate_t {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getVideoClusterSamplingRate_block(
                handle,
                entityID,
                videoClusterIndex
            ) { _, _, status, _, samplingRate in
                continuation(status, samplingRate)
            }
        }
    }

    public func setSensorClusterSamplingRate(
        id entityID: UniqueIdentifier,
        sensorClusterIndex: EntityModelDescriptorType,
        samplingRate: avdecc_entity_model_sampling_rate_t
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setSensorClusterSamplingRate_block(
                handle,
                entityID,
                sensorClusterIndex,
                samplingRate
            ) { _, _, status, _, _ in
                continuation(status, ())
            }
        }
    }

    public func getSensorClusterSamplingRate(
        id entityID: UniqueIdentifier,
        sensorClusterIndex: EntityModelDescriptorType
    ) async throws -> avdecc_entity_model_sampling_rate_t {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getSensorClusterSamplingRate_block(
                handle,
                entityID,
                sensorClusterIndex
            ) { _, _, status, _, samplingRate in
                continuation(status, samplingRate)
            }
        }
    }

    public func setClockSource(
        id entityID: UniqueIdentifier,
        clockDomainIndex: EntityModelDescriptorType,
        clockSourceIndex: EntityModelDescriptorType
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_setClockSource_block(
                handle,
                entityID,
                clockDomainIndex,
                clockSourceIndex
            ) { _, _, status, _, _ in
                continuation(status, ())
            }
        }
    }

    public func getClockSource(
        id entityID: UniqueIdentifier,
        clockDomainIndex: EntityModelDescriptorType
    ) async throws -> EntityModelDescriptorType {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getClockSource_block(
                handle,
                entityID,
                clockDomainIndex
            ) { _, _, status, _, clockSourceIndex in
                continuation(status, clockSourceIndex)
            }
        }
    }

    public func startStreamInput(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorType
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_startStreamInput_block(
                handle,
                entityID,
                streamIndex
            ) { _, _, status, _ in
                continuation(status, ())
            }
        }
    }

    public func startStreamOutput(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorType
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_startStreamOutput_block(
                handle,
                entityID,
                streamIndex
            ) { _, _, status, _ in
                continuation(status, ())
            }
        }
    }

    public func stopStreamInput(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorType
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_stopStreamInput_block(
                handle,
                entityID,
                streamIndex
            ) { _, _, status, _ in
                continuation(status, ())
            }
        }
    }

    public func stopStreamOutput(
        id entityID: UniqueIdentifier,
        streamIndex: EntityModelDescriptorType
    ) async throws {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_stopStreamOutput_block(
                handle,
                entityID,
                streamIndex
            ) { _, _, status, _ in
                continuation(status, ())
            }
        }
    }

    public func getAvbInfo(
        id entityID: UniqueIdentifier,
        avbInterfaceIndex: EntityModelDescriptorType
    ) async throws -> EntityModelAvbInfo {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getAvbInfo_block(
                handle,
                entityID,
                avbInterfaceIndex
            ) { _, _, status, _, info in
                continuation(status, info != nil ? EntityModelAvbInfo(info!.pointee) : nil)
            }
        }
    }

    // LA_AVDECC_LocalEntity_getAsPath
    // LA_AVDECC_LocalEntity_getEntityCounters
    // LA_AVDECC_LocalEntity_getAvbInterfaceCounters
    // LA_AVDECC_LocalEntity_getClockDomainCounters
    // LA_AVDECC_LocalEntity_getStreamInputCounters
    // LA_AVDECC_LocalEntity_getStreamOutputCounters

    public func getMilanInfo(
        id entityID: UniqueIdentifier
    ) async throws -> EntityModelMilanInfo {
        try await invokeHandler { handle, continuation in
            LA_AVDECC_LocalEntity_getMilanInfo_block(
                handle,
                entityID
            ) { _, _, status, info in
                continuation(status, info?.pointee)
            }
        }
    }

    // LA_AVDECC_LocalEntity_connectStream
    // LA_AVDECC_LocalEntity_disconnectStream
    // LA_AVDECC_LocalEntity_disconnectTalkerStream
    // LA_AVDECC_LocalEntity_getTalkerStreamState
    // LA_AVDECC_LocalEntity_getListenerStreamState
    // LA_AVDECC_LocalEntity_getTalkerStreamConnection
}

private func LocalEntity_onTransportError(handle: UnsafeMutableRawPointer?) {
    LocalEntity.withDelegate(handle) {
        $0.delegate?.onTransportError($0)
    }
}

private func LocalEntity_onEntityOnline(
    _ handle: UnsafeMutableRawPointer?,
    _ entityID: UniqueIdentifier,
    _ entity: avdecc_entity_cp?
) {
    LocalEntity.withDelegate(handle) {
        $0.delegate?.onEntityOnline($0, id: entityID, entity: Entity(entity!))
    }
}

private func LocalEntity_onEntityUpdate(
    _ handle: UnsafeMutableRawPointer?,
    _ entityID: UniqueIdentifier,
    _ entity: avdecc_entity_cp?
) {
    LocalEntity.withDelegate(handle) {
        $0.delegate?.onEntityUpdate($0, id: entityID, entity: Entity(entity!))
    }
}

private func LocalEntity_onEntityOffline(
    _ handle: UnsafeMutableRawPointer?,
    _ entityID: UniqueIdentifier
) {
    LocalEntity.withDelegate(handle) {
        $0.delegate?.onEntityOffline($0, id: entityID)
    }
}
