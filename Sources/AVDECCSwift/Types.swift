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

public typealias EntityModelDescriptorType = avdecc_entity_model_descriptor_type_t
public typealias EntityModelDescriptorIndex = avdecc_entity_model_descriptor_index_t
public typealias UniqueIdentifier = avdecc_unique_identifier_t

func nullTerminatedArrayToSwiftArray<T>(
    _ args: UnsafeMutablePointer<UnsafeMutablePointer<T>?>?
) -> [T] {
    var array = [T]()

    if var ptr = args {
        while let p = ptr.pointee {
            array.append(p.pointee)
            ptr += 1
        }
    }

    return array
}

protocol AVDECCBridgeable: Sendable {
    associatedtype AVDECCType

    init(_: AVDECCType)

    func bridgeToAvdeccType() -> AVDECCType
}

extension AVDECCBridgeable {
    init(_ entity: UnsafePointer<AVDECCType>) {
        self.init(entity.pointee)
    }
}

public struct EntityModelEntityDescriptor: AVDECCBridgeable {
    typealias AVDECCType = avdecc_entity_model_entity_descriptor_t

    private let descriptor: AVDECCType

    init(_ descriptor: AVDECCType) {
        self.descriptor = descriptor
    }

    func bridgeToAvdeccType() -> AVDECCType {
        descriptor
    }

    public var entityID: UniqueIdentifier { descriptor.entity_id }
    public var entityModelID: UniqueIdentifier { descriptor.entity_model_id }
    public var entityCapabilities: avdecc_entity_entity_capabilities_t {
        descriptor.entity_capabilities
    }

    public var talkerStreamSources: UInt16 { descriptor.talker_stream_sources }
    public var talkerCapabilities: avdecc_entity_talker_capabilities_t {
        descriptor.talker_capabilities
    }

    public var listenerStreamSinks: UInt16 { descriptor.listener_stream_sinks }
    public var listenerCpabailities: avdecc_entity_listener_capabilities_t {
        descriptor.listener_capabilities
    }

    public var controllerCapabilities: avdecc_entity_controller_capabilities_t {
        descriptor.controller_capabilities
    }

    public var availableIndex: UInt { UInt(descriptor.available_index) }
    public var associationID: UniqueIdentifier { descriptor.association_id }
    public var entityName: String { String(avdeccFixedString: descriptor.entity_name) }
    public var vendorNameString: avdecc_entity_model_localized_string_reference_t {
        descriptor.vendor_name_string
    }

    public var modelNameString: avdecc_entity_model_localized_string_reference_t {
        descriptor.model_name_string
    }

    public var firmwareVersion: String { String(avdeccFixedString: descriptor.firmware_version) }
    public var groupName: String { String(avdeccFixedString: descriptor.group_name) }
    public var serialNumber: String { String(avdeccFixedString: descriptor.serial_number) }
    public var configurationsCount: UInt16 { descriptor.configurations_count }
    public var currentConfiguration: UInt16 { descriptor.current_configuration }
}

public struct EntityModelConfigurationDescriptor: Sendable {
    public struct Count: AVDECCBridgeable {
        typealias AVDECCType = avdecc_entity_model_descriptors_count_t

        public let descriptorType: avdecc_entity_model_descriptor_type_t
        public let count: UInt16

        init(_ count: AVDECCType) {
            descriptorType = count.descriptor_type
            self.count = count.count
        }

        func bridgeToAvdeccType() -> AVDECCType {
            var count = avdecc_entity_model_descriptors_count_t()
            count.descriptor_type = descriptorType
            count.count = self.count
            return count
        }
    }

    public let objectName: String
    public let localizedDescription: avdecc_entity_model_localized_string_reference_t
    public let counts: [Count]

    init(_ descriptor: avdecc_entity_model_configuration_descriptor_t) {
        objectName = String(avdeccFixedString: descriptor.object_name)
        localizedDescription = descriptor.localized_description
        counts = nullTerminatedArrayToSwiftArray(descriptor.counts).map { Count($0) }
    }
}

public typealias EntityModelSamplingRate = avdecc_entity_model_sampling_rate_t

public struct EntityModelAudioUnitDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_audio_unit_descriptor_t

    public let samplingRates: [EntityModelSamplingRate]

    init(_ descriptor: avdecc_entity_model_audio_unit_descriptor_t) {
        samplingRates = nullTerminatedArrayToSwiftArray(descriptor.sampling_rates)

        var descriptor = descriptor
        descriptor.sampling_rates = nil
        self.descriptor = descriptor
    }

    public var objectName: String { descriptor.objectName }
    public var localizedDescription: avdecc_entity_model_localized_string_reference_t {
        descriptor.localized_description
    }

    public var clockDomainIndex: EntityModelDescriptorIndex { descriptor.clock_domain_index }

    public var numberOfStreamInputPorts: UInt16 { descriptor.number_of_stream_input_ports }
    public var baseStreamInputPort: EntityModelDescriptorIndex { descriptor.base_stream_input_port }

    public var numberOfStreamOutputPorts: UInt16 { descriptor.number_of_stream_output_ports }
    public var baseStreamOutputPort: EntityModelDescriptorIndex {
        descriptor.base_stream_output_port
    }

    public var numberOfExternalInputPorts: UInt16 { descriptor.number_of_external_input_ports }
    public var baseExternalInputPort: EntityModelDescriptorIndex {
        descriptor.base_external_input_port
    }

    public var numberOfExternalOutputPorts: UInt16 { descriptor.number_of_external_output_ports }
    public var baseExternalOutputPort: EntityModelDescriptorIndex {
        descriptor.base_external_output_port
    }

    public var numberOfInternalInputPorts: UInt16 { descriptor.number_of_internal_input_ports }
    public var baseInternalInputPort: EntityModelDescriptorIndex {
        descriptor.base_internal_input_port
    }

    public var numberOfInternalOutputPorts: UInt16 { descriptor.number_of_external_output_ports }
    public var baseInternalOutputPort: EntityModelDescriptorIndex {
        descriptor.base_internal_output_port
    }

    public var numberOfControls: UInt16 { descriptor.number_of_controls }
    public var baseControl: EntityModelDescriptorIndex { descriptor.base_control }

    public var numberOfSignalSelectors: UInt16 { descriptor.number_of_signal_selectors }
    public var baseSignalSelector: EntityModelDescriptorIndex { descriptor.base_signal_selector }

    public var numberOfMixers: UInt16 { descriptor.number_of_mixers }
    public var baseMixer: EntityModelDescriptorIndex { descriptor.base_mixer }

    public var currentSamplingRate: EntityModelSamplingRate { descriptor.current_sampling_rate }
}

public typealias EntityModelClockSourceDescriptor = avdecc_entity_model_clock_source_descriptor_t

public struct EntityModelClockDomainDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_clock_domain_descriptor_t

    public let clockSources: [EntityModelDescriptorIndex]

    init(_ descriptor: avdecc_entity_model_clock_domain_descriptor_t) {
        clockSources = nullTerminatedArrayToSwiftArray(descriptor.clock_sources)

        var descriptor = descriptor
        descriptor.clock_sources = nil
        self.descriptor = descriptor
    }

    public var objectName: String {
        descriptor.objectName
    }

    public var localizedDescription: avdecc_entity_model_localized_string_reference_t {
        descriptor.localized_description
    }

    public var clockSourceIndex: EntityModelDescriptorIndex {
        descriptor.clock_source_index
    }
}

public typealias EntityModelMsrpMapping = avdecc_entity_model_msrp_mapping_t

public struct EntityModelAvbInfo: Sendable {
    private let info: avdecc_entity_model_avb_info_t

    public let mappings: [EntityModelMsrpMapping]

    init(_ info: avdecc_entity_model_avb_info_t) {
        mappings = nullTerminatedArrayToSwiftArray(info.mappings)

        var info = info
        info.mappings = nil
        self.info = info
    }

    public var gptpGrandmasterID: UniqueIdentifier {
        info.gptp_grandmaster_id
    }

    public var propagationDelay: UInt {
        UInt(info.propagation_delay)
    }

    public var gptpDomainNumber: UInt8 {
        info.gptp_domain_number
    }

    public var flags: avdecc_entity_avb_info_flags_t {
        info.flags
    }
}

public typealias EntityModelMilanInfo = avdecc_entity_model_milan_info_t

public struct Entity: AVDECCBridgeable {
    typealias AVDECCType = avdecc_entity_t

    public let commonInformation: avdecc_entity_common_information_t
    public let interfacesInformation: [avdecc_entity_interface_information_t]

    init(_ entity: AVDECCType) {
        commonInformation = entity.common_information
        var interfacesInformation = [avdecc_entity_interface_information_t]()
        entity.forEachInterface {
            interfacesInformation.append($0.pointee)
        }
        self.interfacesInformation = interfacesInformation
    }

    func bridgeToAvdeccType() -> AVDECCType {
        var entity = avdecc_entity_t()
        entity.common_information = commonInformation
        // FIXME: interfaces
        return entity
    }
}

private extension avdecc_entity_t {
    func forEachInterface(_ block: (avdecc_entity_interface_information_cp) throws -> ()) rethrows {
        var interfaces_information = interfaces_information
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

extension UnsafePointer {
    func propertyBasePointer<Property>(to property: KeyPath<Pointee, Property>)
        -> UnsafePointer<Property>?
    {
        guard let offset = MemoryLayout<Pointee>.offset(of: property) else { return nil }
        return (UnsafeRawPointer(self) + offset).assumingMemoryBound(to: Property.self)
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
