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

public enum LocalEntityCommandStatus: UInt16, Error {
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
    static var DelegateThunk: avdecc_local_entity_controller_delegate_t = {
        var thunk = avdecc_local_entity_controller_delegate_t()

        thunk.onTransportError = LocalEntity_onTransportError
        thunk.onEntityOnline = LocalEntity_onEntityOnline
        thunk.onEntityUpdate = LocalEntity_onEntityUpdate
        thunk.onEntityOffline = LocalEntity_onEntityOffline

        return thunk
    }()

    var handle: UnsafeMutableRawPointer!
    public var delegate: LocalEntityDelegate?

    static func withDelegate(
        _ handle: UnsafeMutableRawPointer?,
        _ body: @escaping (LocalEntity) -> ()
    ) {
        if let handle, let this = LA_AVDECC_LocalEntity_getApplicationData(handle) {
            body(Unmanaged<LocalEntity>.fromOpaque(this).takeUnretainedValue())
        }
    }

    init(_ protocolInterfaceHandle: UnsafeMutableRawPointer, entity: Entity) throws {
        var entity = entity.bridgeToAvdeccType()
        var thunk = LocalEntity.DelegateThunk

        try withLocalEntityError {
            LA_AVDECC_LocalEntity_create(protocolInterfaceHandle, &entity, &thunk, &self.handle)
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

    public func acquireEntity(
        id entityID: UniqueIdentifier,
        isPersistent: Bool,
        descriptorType: EntityModelDescriptorType,
        descriptorIndex: EntityModelDescriptorIndex
    ) async throws -> UniqueIdentifier {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            UniqueIdentifier,
            Error
        >) in
            guard let self else {
                continuation.resume(throwing: LocalEntityError.internalError)
                return
            }

            let err = LA_AVDECC_LocalEntity_acquireEntity_block(
                self.handle,
                entityID,
                isPersistent ? 1 : 0,
                descriptorType,
                descriptorIndex
            ) { _, _, status, owningEntity, _, _ in
                guard status != 0 else {
                    continuation.resume(throwing: LocalEntityCommandStatus(status))
                    return
                }
                continuation.resume(returning: owningEntity)
            }
            guard err != 0 else {
                continuation.resume(throwing: LocalEntityError(err))
                return
            }
        }
    }

    public func releaseEntity(
        id entityID: UniqueIdentifier,
        descriptorType: EntityModelDescriptorType,
        descriptorIndex: EntityModelDescriptorIndex
    ) async throws -> UniqueIdentifier {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            UniqueIdentifier,
            Error
        >) in
            guard let self else {
                continuation.resume(throwing: LocalEntityError.internalError)
                return
            }

            let err = LA_AVDECC_LocalEntity_releaseEntity_block(
                self.handle,
                entityID,
                descriptorType,
                descriptorIndex
            ) { _, _, status, owningEntity, _, _ in
                guard status != 0 else {
                    continuation.resume(throwing: LocalEntityCommandStatus(status))
                    return
                }
                continuation.resume(returning: owningEntity)
            }
            guard err != 0 else {
                continuation.resume(throwing: LocalEntityError(err))
                return
            }
        }
    }

    // LA_AVDECC_LocalEntity_lockEntity
    // LA_AVDECC_LocalEntity_unlockEntity
    // LA_AVDECC_LocalEntity_queryEntityAvailable
    // LA_AVDECC_LocalEntity_queryControllerAvailable
    // LA_AVDECC_LocalEntity_registerUnsolicitedNotifications
    // LA_AVDECC_LocalEntity_unregisterUnsolicitedNotifications

    public func readEntityDescriptor(
        id entityID: UniqueIdentifier
    ) async throws -> EntityModelEntityDescriptor {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            EntityModelEntityDescriptor,
            Error
        >) in
            guard let self else {
                continuation.resume(throwing: LocalEntityError.internalError)
                return
            }

            let err = LA_AVDECC_LocalEntity_readEntityDescriptor_block(
                self.handle,
                entityID
            ) { _, _, status, descriptor in
                guard status != 0 else {
                    continuation.resume(throwing: LocalEntityCommandStatus(status))
                    return
                }
                continuation.resume(returning: EntityModelEntityDescriptor(descriptor!.pointee))
            }
            guard err != 0 else {
                continuation.resume(throwing: LocalEntityError(err))
                return
            }
        }
    }

    public func readConfigurationDescriptor(
        id entityID: UniqueIdentifier,
        configurationIndex: EntityModelDescriptorType
    ) async throws -> EntityModelConfigurationDescriptor {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            EntityModelConfigurationDescriptor,
            Error
        >) in
            guard let self else {
                continuation.resume(throwing: LocalEntityError.internalError)
                return
            }

            let err = LA_AVDECC_LocalEntity_readConfigurationDescriptor_block(
                self.handle,
                entityID,
                configurationIndex
            ) { _, _, status, _, descriptor in
                guard status != 0 else {
                    continuation.resume(throwing: LocalEntityCommandStatus(status))
                    return
                }
                continuation
                    .resume(returning: EntityModelConfigurationDescriptor(descriptor!.pointee))
            }
            guard err != 0 else {
                continuation.resume(throwing: LocalEntityError(err))
                return
            }
        }
    }

    // LA_AVDECC_LocalEntity_readAudioUnitDescriptor
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
    // LA_AVDECC_LocalEntity_setConfiguration
    // LA_AVDECC_LocalEntity_getConfiguration
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
    // LA_AVDECC_LocalEntity_setEntityName
    // LA_AVDECC_LocalEntity_getEntityName
    // LA_AVDECC_LocalEntity_setEntityGroupName
    // LA_AVDECC_LocalEntity_getEntityGroupName
    // LA_AVDECC_LocalEntity_setConfigurationName
    // LA_AVDECC_LocalEntity_getConfigurationName
    // LA_AVDECC_LocalEntity_setAudioUnitName
    // LA_AVDECC_LocalEntity_getAudioUnitName
    // LA_AVDECC_LocalEntity_setStreamInputName
    // LA_AVDECC_LocalEntity_setStreamOutputName
    // LA_AVDECC_LocalEntity_getStreamOutputName
    // LA_AVDECC_LocalEntity_setAvbInterfaceName
    // LA_AVDECC_LocalEntity_getAvbInterfaceName
    // LA_AVDECC_LocalEntity_setClockSourceName
    // LA_AVDECC_LocalEntity_getClockSourceName
    // LA_AVDECC_LocalEntity_setMemoryObjectName
    // LA_AVDECC_LocalEntity_getMemoryObjectName
    // LA_AVDECC_LocalEntity_setAudioClusterName
    // LA_AVDECC_LocalEntity_getAudioClusterName
    // LA_AVDECC_LocalEntity_setClockDomainName
    // LA_AVDECC_LocalEntity_getClockDomainName
    // LA_AVDECC_LocalEntity_setAudioUnitSamplingRate
    // LA_AVDECC_LocalEntity_getAudioUnitSamplingRate
    // LA_AVDECC_LocalEntity_setVideoClusterSamplingRate
    // LA_AVDECC_LocalEntity_getVideoClusterSamplingRate
    // LA_AVDECC_LocalEntity_setSensorClusterSamplingRate
    // LA_AVDECC_LocalEntity_getSensorClusterSamplingRate
    // LA_AVDECC_LocalEntity_setClockSource
    // LA_AVDECC_LocalEntity_getClockSource
    // LA_AVDECC_LocalEntity_startStreamInput
    // LA_AVDECC_LocalEntity_startStreamOutput
    // LA_AVDECC_LocalEntity_stopStreamInput
    // LA_AVDECC_LocalEntity_stopStreamOutput
    // LA_AVDECC_LocalEntity_getAvbInfo

    public func getAvbInfo(
        id entityID: UniqueIdentifier,
        avbInterfaceIndex: EntityModelDescriptorType
    ) async throws -> EntityModelAvbInfo {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            EntityModelAvbInfo,
            Error
        >) in
            guard let self else {
                continuation.resume(throwing: LocalEntityError.internalError)
                return
            }

            let err = LA_AVDECC_LocalEntity_getAvbInfo_block(
                self.handle,
                entityID,
                avbInterfaceIndex
            ) { _, _, status, _, info in
                guard status != 0 else {
                    continuation.resume(throwing: LocalEntityCommandStatus(status))
                    return
                }
                continuation
                    .resume(returning: EntityModelAvbInfo(info!.pointee))
            }
            guard err != 0 else {
                continuation.resume(throwing: LocalEntityError(err))
                return
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
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            EntityModelMilanInfo,
            Error
        >) in
            guard let self else {
                continuation.resume(throwing: LocalEntityError.internalError)
                return
            }

            let err = LA_AVDECC_LocalEntity_getMilanInfo_block(
                self.handle,
                entityID
            ) { _, _, status, info in
                guard status != 0 else {
                    continuation.resume(throwing: LocalEntityCommandStatus(status))
                    return
                }
                continuation
                    .resume(returning: info!.pointee)
            }
            guard err != 0 else {
                continuation.resume(throwing: LocalEntityError(err))
                return
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
