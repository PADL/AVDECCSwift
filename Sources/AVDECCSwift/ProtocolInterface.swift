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

import CxxAVDECC

public enum ProtocolInterfaceError: UInt8, Error {
    case transportError = 1
    case timeout = 2
    case unknownRemoteEntity = 3
    case unknownLocalEntity = 4
    case invalidEntityType = 5
    case duplicateLocalEntityID = 6
    case interfaceNotFound = 7
    case invalidParameters = 8
    case interfaceNotSupported = 9
    case messageNotSupported = 10
    case executorNotInitialized = 11
    case invalidProtocolInterfaceHandle = 98
    case internalError = 99

    init(_ value: avdecc_protocol_interface_error_t) {
        self = Self(rawValue: value) ?? .internalError
    }
}

func withProtocolInterfaceError(_ block: () -> avdecc_protocol_interface_error_t) throws {
    let err = block()
    if err != 0 {
        throw ProtocolInterfaceError(err)
    }
}

extension CheckedContinuation where T == avdecc_protocol_acmpdu_t, E == any Error {
    func resume(throwing err: avdecc_protocol_interface_error_t) {
        resume(throwing: ProtocolInterfaceError(err))
    }
}

extension CheckedContinuation where T == avdecc_protocol_aem_aecpdu_t, E == any Error {
    func resume(throwing err: avdecc_protocol_interface_error_t) {
        resume(throwing: ProtocolInterfaceError(err))
    }
}

extension CheckedContinuation where T == avdecc_protocol_mvu_aecpdu_t, E == any Error {
    func resume(throwing err: avdecc_protocol_interface_error_t) {
        resume(throwing: ProtocolInterfaceError(err))
    }
}

public protocol ProtocolInterfaceObserver {
    func onTransportError(_: ProtocolInterface)
    func onLocalEntityOnline(_: ProtocolInterface, _: Entity)
    func onLocalEntityOffline(_: ProtocolInterface, id: UniqueIdentifier)
    func onLocalEntityUpdated(_: ProtocolInterface, _: Entity)
    func onRemoteEntityOnline(_: ProtocolInterface, _: Entity)
    func onRemoteEntityOffline(_: ProtocolInterface, id: UniqueIdentifier)
    func onRemoteEntityUpdated(_: ProtocolInterface, _: Entity)

    func onAecpAemCommand(_: ProtocolInterface, pdu: avdecc_protocol_aem_aecpdu_t)
    func onAecpAemUnsolicitedResponse(_: ProtocolInterface, pdu: avdecc_protocol_aem_aecpdu_t)
    func onAecpAemIdentifyNotification(_: ProtocolInterface, pdu: avdecc_protocol_aem_aecpdu_t)

    func onAcmpCommand(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t)
    func onAcmpResponse(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t)

    func onAdpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_adpdu_t)
    func onAemAecpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_aem_aecpdu_t)
    func onMvuAecpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_mvu_aecpdu_t)
    func onAcmpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t)
}

public final class ProtocolInterface {
    static var ObserverThunk: avdecc_protocol_interface_observer_t = {
        var thunk = avdecc_protocol_interface_observer_t()
        thunk.onTransportError = ProtocolInterface_onTransportError
        thunk.onLocalEntityOnline = ProtocolInterface_onLocalEntityOnline
        thunk.onLocalEntityOffline = ProtocolInterface_onLocalEntityOffline
        thunk.onLocalEntityUpdated = ProtocolInterface_onLocalEntityUpdated
        thunk.onRemoteEntityOnline = ProtocolInterface_onRemoteEntityOnline
        thunk.onRemoteEntityOffline = ProtocolInterface_onRemoteEntityOffline
        thunk.onRemoteEntityUpdated = ProtocolInterface_onRemoteEntityUpdated

        thunk.onAecpAemCommand = ProtocolInterface_onAecpAemCommand
        thunk.onAecpAemUnsolicitedResponse = ProtocolInterface_onAecpAemUnsolicitedResponse
        thunk.onAecpAemIdentifyNotification = ProtocolInterface_onAecpAemIdentifyNotification
    
        thunk.onAcmpCommand = ProtocolInterface_onAcmpCommand
        thunk.onAcmpResponse = ProtocolInterface_onAcmpResponse

        thunk.onAdpduReceived = ProtocolInterface_onAdpduReceived
        thunk.onAemAecpduReceived = ProtocolInterface_onAemAecpduReceived
        thunk.onMvuAecpduReceived = ProtocolInterface_onMvuAecpduReceived
        thunk.onAcmpduReceived = ProtocolInterface_onAcmpduReceived

        return thunk
    }()

    private var executor = Executor.shared // ensure library initialized
    let handle: UnsafeMutableRawPointer!

    public var observer: ProtocolInterfaceObserver? {
        didSet {
            if observer != nil {
                LA_AVDECC_ProtocolInterface_registerObserver(handle, &ProtocolInterface.ObserverThunk)
            } else {
                LA_AVDECC_ProtocolInterface_unregisterObserver(handle, &ProtocolInterface.ObserverThunk)
            }
        }
    }

    static func withObserver(
        _ handle: UnsafeMutableRawPointer?,
        _ body: @escaping (ProtocolInterface) -> ()
    ) {
        if let handle, let this = LA_AVDECC_ProtocolInterface_getApplicationData(handle) {
            body(Unmanaged<ProtocolInterface>.fromOpaque(this).takeUnretainedValue())
        }
    }

    public init(
        type: avdecc_protocol_interface_type_e = avdecc_protocol_interface_type_pcap,
        interfaceID: String,
        executorName: String = DefaultExecutorName
    ) throws {
        var handle: UnsafeMutableRawPointer!

        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_create(
                UInt8(type.rawValue),
                interfaceID,
                executorName,
                &handle
            )
        }

        self.handle = handle

        LA_AVDECC_ProtocolInterface_setApplicationData(
            self.handle,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    deinit {
        if handle != nil {
            LA_AVDECC_ProtocolInterface_setApplicationData(handle, nil)
            LA_AVDECC_ProtocolInterface_destroy(handle)
        }
    }

    public var macAddress: avdecc_mac_address_t {
        get throws {
            var mac = avdecc_mac_address_t(0, 0, 0, 0, 0, 0)
            try withProtocolInterfaceError {
                LA_AVDECC_ProtocolInterface_getMacAddress(handle, &mac)
            }
            return mac
        }
    }

    public func shutdown() throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_shutdown(handle)
        }
    }

    public func getDynamicEID() throws -> UniqueIdentifier {
        var id = UniqueIdentifier()
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_getDynamicEID(handle, &id)
        }
        return id
    }

    public func releaseDynamicEID(_ id: UniqueIdentifier) throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_releaseDynamicEID(handle, id)
        }
    }

    public func register(localEntity: LocalEntity) throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_registerLocalEntity(handle, localEntity.handle)
        }
    }

    public func unregister(localEntity: LocalEntity) throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_unregisterLocalEntity(handle, localEntity.handle)
        }
    }

    public func enableEntityAdvertising(localEntity: LocalEntity) throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_enableEntityAdvertising(handle, localEntity.handle)
        }
    }

    public func disableEntityAdvertising(localEntity: LocalEntity) throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_disableEntityAdvertising(handle, localEntity.handle)
        }
    }

    public func setEntityNeedsAdvertise(
        localEntity: LocalEntity,
        flags: avdecc_local_entity_advertise_flags_t
    ) throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_setEntityNeedsAdvertise(handle, localEntity.handle, flags)
        }
    }

    public func discoverRemoteEntities() throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_discoverRemoteEntities(handle)
        }
    }

    public func discoverRemoteEntity(id: UniqueIdentifier) throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_discoverRemoteEntity(handle, id)
        }
    }

    public var isDirectMessageSupported: Bool {
        LA_AVDECC_ProtocolInterface_isDirectMessageSupported(handle) != 0
    }

    public func sendAdpMessage(_ pdu: avdecc_protocol_adpdu_t) throws {
        try withProtocolInterfaceError {
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAdpMessage(handle, &pdu)
        }
    }

    public func sendAemAecpMessage(_ pdu: avdecc_protocol_aem_aecpdu_t) throws {
        try withProtocolInterfaceError {
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAemAecpMessage(handle, &pdu)
        }
    }

    public func sendAcmpMessage(_ pdu: avdecc_protocol_acmpdu_t) throws {
        try withProtocolInterfaceError {
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAcmpMessage(handle, &pdu)
        }
    }

    private func invokeHandler<T>(
        _ handler: (
            _ handle: UnsafeMutableRawPointer,
            _ continuation: @escaping (T?) -> ()
        ) -> avdecc_protocol_interface_error_t
    ) async throws -> T {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<
            T,
            Error
        >) in
            guard let self else {
                continuation.resume(throwing: ProtocolInterfaceError.internalError)
                return
            }

            let err = handler(self.handle) { value in
                guard let value else {
                    continuation.resume(throwing: ProtocolInterfaceError.internalError)
                    return
                }
                continuation.resume(returning: value)
            }
            guard err != 0 else {
                continuation.resume(throwing: ProtocolInterfaceError(err))
                return
            }
        }
    }

    public func sendAemAecpCommand(_ pdu: avdecc_protocol_aem_aecpdu_t) async throws
        -> avdecc_protocol_aem_aecpdu_t
    {
        try await invokeHandler { handle, continuation in
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAemAecpCommand_block(
                handle,
                &pdu
            ) { response, _ in
                continuation(response?.pointee)
            }
        }
    }

    public func sendAemAecpResponse(_ pdu: avdecc_protocol_aem_aecpdu_t) throws {
        try withProtocolInterfaceError {
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAemAecpResponse(handle, &pdu)
        }
    }

    public func sendMvuAecpCommand(_ pdu: avdecc_protocol_mvu_aecpdu_t) async throws
        -> avdecc_protocol_mvu_aecpdu_t
    {
        try await invokeHandler { handle, continuation in
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendMvuAecpCommand_block(
                handle,
                &pdu
            ) { response, _ in
                continuation(response?.pointee)
            }
        }
    }

    public func sendMvuAecpResponse(_ pdu: avdecc_protocol_mvu_aecpdu_t) throws {
        try withProtocolInterfaceError {
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendMvuAecpResponse(handle, &pdu)
        }
    }

    public func sendAcmpCommand(_ pdu: avdecc_protocol_acmpdu_t) async throws
        -> avdecc_protocol_acmpdu_t
    {
        try await invokeHandler { handle, continuation in
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAcmpCommand_block(handle, &pdu) { response, _ in
                continuation(response?.pointee)
            }
        }
    }

    public func sendAvmpResponse(_ pdu: avdecc_protocol_acmpdu_t) throws {
        try withProtocolInterfaceError {
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAcmpResponse(handle, &pdu)
        }
    }

    public func lock() throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_lock(handle)
        }
    }

    public func unlock() throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_unlock(handle)
        }
    }

    public var isSelfLocked: Bool {
        LA_AVDECC_ProtocolInterface_isSelfLocked(handle) != 0
    }
}

private func ProtocolInterface_onTransportError(handle: UnsafeMutableRawPointer?) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onTransportError($0)
    }
}

private func ProtocolInterface_onLocalEntityOnline(
    _ handle: UnsafeMutableRawPointer?,
    _ entity: avdecc_entity_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onLocalEntityOnline($0, Entity(entity!))
    }
}

private func ProtocolInterface_onLocalEntityOffline(
    _ handle: UnsafeMutableRawPointer?,
    _ entityID: UniqueIdentifier
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onLocalEntityOffline($0, id: entityID)
    }
}

private func ProtocolInterface_onLocalEntityUpdated(
    _ handle: UnsafeMutableRawPointer?,
    _ entity: avdecc_entity_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onLocalEntityUpdated($0, Entity(entity!))
    }
}

private func ProtocolInterface_onRemoteEntityOnline(
    _ handle: UnsafeMutableRawPointer?,
    _ entity: avdecc_entity_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onRemoteEntityOnline($0, Entity(entity!))
    }
}

private func ProtocolInterface_onRemoteEntityOffline(
    _ handle: UnsafeMutableRawPointer?,
    _ entityID: UniqueIdentifier
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onRemoteEntityOffline($0, id: entityID)
    }
}

private func ProtocolInterface_onRemoteEntityUpdated(
    _ handle: UnsafeMutableRawPointer?,
    _ entity: avdecc_entity_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onRemoteEntityUpdated($0, Entity(entity!))
    }
}

private func ProtocolInterface_onAecpAemCommand(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_aem_aecpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onAecpAemCommand($0, pdu: pdu!.pointee)
    }
}

private func ProtocolInterface_onAecpAemUnsolicitedResponse(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_aem_aecpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onAecpAemUnsolicitedResponse($0, pdu: pdu!.pointee)
    }
}

private func ProtocolInterface_onAecpAemIdentifyNotification(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_aem_aecpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onAecpAemIdentifyNotification($0, pdu: pdu!.pointee)
    }
}

private func ProtocolInterface_onAcmpCommand(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_acmpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onAcmpCommand($0, pdu: pdu!.pointee)
    }
}

private func ProtocolInterface_onAcmpResponse(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_acmpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onAcmpResponse($0, pdu: pdu!.pointee)
    }
}

private func ProtocolInterface_onAdpduReceived(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_adpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onAdpduReceived($0, pdu: pdu!.pointee)
    }
}

private func ProtocolInterface_onAemAecpduReceived(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_aem_aecpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onAemAecpduReceived($0, pdu: pdu!.pointee)
    }
}

private func ProtocolInterface_onMvuAecpduReceived(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_mvu_aecpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onMvuAecpduReceived($0, pdu: pdu!.pointee)
    }
}

private func ProtocolInterface_onAcmpduReceived(
    _ handle: UnsafeMutableRawPointer?,
    pdu: avdecc_protocol_acmpdu_cp?
) {
    ProtocolInterface.withObserver(handle) {
        $0.observer?.onAcmpduReceived($0, pdu: pdu!.pointee)
    }
}
