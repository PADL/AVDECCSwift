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

    init(_ value: avdecc_local_entity_error_t) {
        self = Self(rawValue: value) ?? .internalError
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
}


public final class LocalEntity {
    static var DelegateThunk: avdecc_local_entity_controller_delegate_t = {
        var thunk = avdecc_local_entity_controller_delegate_t()
        thunk.onTransportError = LocalEntity_onTransportError
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

    init(_ protocolInterfaceHandle: UnsafeMutableRawPointer, entity: avdecc_entity_t) throws {
        var entity = entity
        var thunk = LocalEntity.DelegateThunk

        try withLocalEntityError {
            LA_AVDECC_LocalEntity_create(protocolInterfaceHandle, &entity, &thunk, &self.handle)
        }

        LA_AVDECC_LocalEntity_setApplicationData(
            self.handle,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    public convenience init(protocolInterface: ProtocolInterface, entity: avdecc_entity_t) throws {
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

    public func discoverRemoteEntity(id: avdecc_unique_identifier_t) throws {
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
        id entityID: avdecc_unique_identifier_t,
        isPersistent: Bool,
        descriptorType: avdecc_entity_model_descriptor_type_t,
        descriptorIndex: avdecc_entity_model_descriptor_index_t
    ) async throws -> (avdecc_local_entity_aem_command_status_t, avdecc_unique_identifier_t) {
        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            (avdecc_local_entity_aem_command_status_t, avdecc_unique_identifier_t),
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
                continuation.resume(returning: (status, owningEntity))
            }
            guard err != 0 else {
                continuation.resume(throwing: LocalEntityError(err))
                return
            }
        }
    }

    // LA_AVDECC_LocalEntity_releaseEntity
    // LA_AVDECC_LocalEntity_lockEntity
    // LA_AVDECC_LocalEntity_unlockEntity
    // LA_AVDECC_LocalEntity_queryEntityAvailable
    // LA_AVDECC_LocalEntity_queryControllerAvailable
    // LA_AVDECC_LocalEntity_registerUnsolicitedNotifications
    // LA_AVDECC_LocalEntity_unregisterUnsolicitedNotifications
    // LA_AVDECC_LocalEntity_readEntityDescriptor
    // LA_AVDECC_LocalEntity_readConfigurationDescriptor
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
    // LA_AVDECC_LocalEntity_getAsPath
    // LA_AVDECC_LocalEntity_getEntityCounters
    // LA_AVDECC_LocalEntity_getAvbInterfaceCounters
    // LA_AVDECC_LocalEntity_getClockDomainCounters
    // LA_AVDECC_LocalEntity_getStreamInputCounters
    // LA_AVDECC_LocalEntity_getStreamOutputCounters
    // LA_AVDECC_LocalEntity_getMilanInfo
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
