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

extension UnsafePointer {
    func propertyBasePointer<Property>(to property: KeyPath<Pointee, Property>)
        -> UnsafePointer<Property>?
    {
        guard let offset = MemoryLayout<Pointee>.offset(of: property) else { return nil }
        return (UnsafeRawPointer(self) + offset).assumingMemoryBound(to: Property.self)
    }
}

public extension avdecc_entity_t {
    func forEachInterface(_ block: (avdecc_entity_interface_information_cp) throws -> ()) rethrows {
        var interfaces_information = self.interfaces_information
        try withUnsafePointer(to: &interfaces_information) { first in
            var next = first.pointee.next

            try block(first)

            while next != nil {
                try block(next!)
                next = next?.pointee.next
            }
        }
    } 
}

public extension avdecc_entity_model_entity_descriptor_s {
    var entityName: String {
        String(avdeccFixedString: entity_name)
    }
    
    var firmwareVersion: String {
        String(avdeccFixedString: firmware_version)
    }
    
    var groupName: String {
        String(avdeccFixedString: group_name)
    }
    
    var serialNumber: String {
        String(avdeccFixedString: serial_number)
    }
}

protocol ObjectNameable {
    var object_name: avdecc_fixed_string_t { get }
}

extension ObjectNameable {
    public var objectName: String {
        String(avdeccFixedString: object_name)
    }
}

extension avdecc_entity_model_configuration_descriptor_s: ObjectNameable {}
extension avdecc_entity_model_audio_unit_descriptor_s: ObjectNameable {}
extension avdecc_entity_model_stream_descriptor_s: ObjectNameable {}
extension avdecc_entity_model_jack_descriptor_s: ObjectNameable {}
extension avdecc_entity_model_avb_interface_descriptor_s: ObjectNameable {}
extension avdecc_entity_model_clock_source_descriptor_s: ObjectNameable {}
extension avdecc_entity_model_memory_object_descriptor_s: ObjectNameable {}
extension avdecc_entity_model_audio_cluster_descriptor_s: ObjectNameable {}
extension avdecc_entity_model_clock_domain_descriptor_s: ObjectNameable {}

extension avdecc_entity_model_locale_descriptor_s {
    public var localeID: String {
        String(avdeccFixedString: locale_id)
    }
}

public final class Library {
    public static var shared = Library()

    private static func isCompatibleWithInterfaceVersion(_ version: Int32) -> Bool {
        LA_AVDECC_isCompatibleWithInterfaceVersion(avdecc_interface_version_t(version)) != 0
    }

    public static var interfaceVersion: avdecc_interface_version_t {
        LA_AVDECC_getInterfaceVersion()
    }

    public static var version: String {
        String(cString: LA_AVDECC_getVersion())
    }

    init() {
        precondition(Self.isCompatibleWithInterfaceVersion(LA_AVDECC_InterfaceVersion))
        LA_AVDECC_initialize()
    }

    deinit {
        LA_AVDECC_uninitialize()
    }
}

public extension avdecc_unique_identifier_t {
    static var null: Self {
        LA_AVDECC_getNullUniqueIdentifier()
    }
}

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
}

func withProtocolInterfaceError(_ block: () -> avdecc_protocol_interface_error_t) throws {
    let err = block()
    if err != 0 {
        throw ProtocolInterfaceError(rawValue: err) ?? .internalError
    }
}

extension CheckedContinuation where T == avdecc_protocol_acmpdu_t, E == any Error {
    func resume(throwing err: avdecc_protocol_interface_error_t) {
        let pie = ProtocolInterfaceError(rawValue: err) ?? .internalError
        self.resume(throwing: pie)
    }
}

public final class ProtocolInterface {
    var handle: UnsafeMutableRawPointer!

    public init(type: avdecc_protocol_interface_type_e, interfaceID: String) throws {
        try withProtocolInterfaceError {
            LA_AVDECC_ProtocolInterface_create(UInt8(type.rawValue), interfaceID, &handle)
        }
    }

    deinit {
        if handle != nil {
            LA_AVDECC_ProtocolInterface_destroy(handle)
        }
    }

    public func sendAdpMessage(_ pdu: avdecc_protocol_adpdu_t) throws {
        try withProtocolInterfaceError {
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAdpMessage(handle, &pdu)
        }
    }

    public func sendAcmpMessage(_ pdu: avdecc_protocol_acmpdu_t) throws {
        try withProtocolInterfaceError {
            var pdu = pdu
            return LA_AVDECC_ProtocolInterface_sendAcmpMessage(handle, &pdu)
        }
    }

    public func sendAcmpCommand(_ pdu: avdecc_protocol_acmpdu_t) async throws -> avdecc_protocol_acmpdu_t {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<avdecc_protocol_acmpdu_t, Error>) in
            var pdu = pdu
            let err = LA_AVDECC_ProtocolInterface_sendAcmpCommand_Block(self?.handle, &pdu) { response, err in
                guard err != 0 else {
                    continuation.resume(throwing: err)
                    return
                }
                continuation.resume(returning: response!.pointee)
            }
            guard err != 0 else {
                continuation.resume(throwing: err)
                return
            }
        }
    }
}

public enum LocalEntityError: UInt8, Error {
    case invalidParameters = 1
    case duplicateLocalIdentityID = 2
    case invalidEntityHandle = 98
    case internalError = 99
}

func withLocalEntityError(_ block: () -> avdecc_local_entity_error_t) throws {
    let err = block()
    if err != 0 {
        throw LocalEntityError(rawValue: err) ?? .internalError
    }
}

public final class LocalEntity {
    var delegate: avdecc_local_entity_controller_delegate_p? = nil
    var handle: UnsafeMutableRawPointer!

    public init(protocolInterface: ProtocolInterface, entity: avdecc_entity_t) throws {
        var entity = entity
        try withLocalEntityError {
            LA_AVDECC_LocalEntity_create(protocolInterface.handle, &entity, delegate, &handle)
        }
    }

    deinit {
        if handle != nil {
            LA_AVDECC_LocalEntity_destroy(handle)
        }
    }
}

public extension String {
    init(avdeccFixedString: avdecc_fixed_string_t) {
        self.init(withUnsafePointer(to: avdeccFixedString) { pointer in
            let start = pointer.propertyBasePointer(to: \.0)!
            return start.withMemoryRebound(
                to: UInt8.self,
                capacity: MemoryLayout.size(ofValue: pointer)
            ) {
                String(cString: $0)
            }
        })
    }
}
