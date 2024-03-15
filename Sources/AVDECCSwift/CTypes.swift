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

@preconcurrency
import CAVDECC // because we can't make these types Sendable
import Foundation // FIXME: (

public typealias EntityModelLocalizedStringReference =
    avdecc_entity_model_localized_string_reference_t
public typealias EntityModelDescriptorType = avdecc_entity_model_descriptor_type_t
public typealias EntityModelDescriptorIndex = avdecc_entity_model_descriptor_index_t

public struct UniqueIdentifier: CustomStringConvertible, Equatable, Hashable, Sendable {
    var eui: avdecc_unique_identifier_t

    public var id: UInt64 {
        eui
    }

    public init() {
        eui = 0xFFFF_FFFF_FFFF_FFFF
    }

    public init(_ id: avdecc_unique_identifier_t) {
        eui = id
    }

    public var description: String {
        String(format: "0x%llx", id)
    }
}

public struct EntityModelStreamFormat: CustomStringConvertible, Equatable, Hashable, Sendable {
    var _format: avdecc_entity_model_stream_format_t

    public var format: UInt64 {
        _format
    }

    public init() {
        _format = 0
    }

    public init(_ format: avdecc_entity_model_stream_format_t) {
        _format = format
    }

    public var description: String {
        String(format: "0x%llx", _format)
    }
}

extension UniqueIdentifier: AvdeccCBridgeable {
    typealias AvdeccCType = avdecc_unique_identifier_t

    func bridgeToAvdeccCType() -> AvdeccCType {
        id
    }
}

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

protocol AvdeccCBridgeable: Sendable {
    associatedtype AvdeccCType

    init(_: AvdeccCType)

    func bridgeToAvdeccCType() -> AvdeccCType
}

extension AvdeccCBridgeable {
    init(_ entity: UnsafePointer<AvdeccCType>) {
        self.init(entity.pointee)
    }
}

public struct EntityModelEntityDescriptor: AvdeccCBridgeable, CustomStringConvertible {
    typealias AvdeccCType = avdecc_entity_model_entity_descriptor_t

    private let descriptor: AvdeccCType

    init(_ descriptor: AvdeccCType) {
        self.descriptor = descriptor
    }

    func bridgeToAvdeccCType() -> AvdeccCType {
        descriptor
    }

    public var description: String {
        "\(type(of: self))(entityID: \(entityID), entityName: \(entityName))"
    }

    public var entityID: UniqueIdentifier { UniqueIdentifier(descriptor.entity_id) }
    public var entityModelID: UniqueIdentifier { UniqueIdentifier(descriptor.entity_model_id) }
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
    public var associationID: UniqueIdentifier { UniqueIdentifier(descriptor.association_id) }
    public var entityName: String { String(avdeccFixedString: descriptor.entity_name) }
    public var vendorNameString: EntityModelLocalizedStringReference {
        descriptor.vendor_name_string
    }

    public var modelNameString: EntityModelLocalizedStringReference {
        descriptor.model_name_string
    }

    public var firmwareVersion: String { String(avdeccFixedString: descriptor.firmware_version) }
    public var groupName: String { String(avdeccFixedString: descriptor.group_name) }
    public var serialNumber: String { String(avdeccFixedString: descriptor.serial_number) }
    public var configurationsCount: UInt16 { descriptor.configurations_count }
    public var currentConfiguration: UInt16 { descriptor.current_configuration }
}

public struct EntityModelConfigurationDescriptor: Sendable {
    public struct Count: AvdeccCBridgeable {
        typealias AvdeccCType = avdecc_entity_model_descriptors_count_t

        public let descriptorType: avdecc_entity_model_descriptor_type_t
        public let count: UInt16

        init(_ count: AvdeccCType) {
            descriptorType = count.descriptor_type
            self.count = count.count
        }

        func bridgeToAvdeccCType() -> AvdeccCType {
            var count = avdecc_entity_model_descriptors_count_t()
            count.descriptor_type = descriptorType
            count.count = self.count
            return count
        }
    }

    public let objectName: String
    public let localizedDescription: EntityModelLocalizedStringReference
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
    public var localizedDescription: EntityModelLocalizedStringReference {
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

public struct EntityModelJackDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_jack_descriptor_t

    init(_ descriptor: avdecc_entity_model_jack_descriptor_t) {
        self.descriptor = descriptor
    }

    public var objectName: String { descriptor.objectName }
    public var localizedDescription: EntityModelLocalizedStringReference {
        descriptor.localized_description
    }

    public var jackFlags: avdecc_entity_jack_flags_t { descriptor.jack_flags }
    public var jackType: avdecc_entity_model_jack_type_t { descriptor.jack_type }
    public var numberOfControls: UInt16 { descriptor.number_of_controls }
    public var baseControl: EntityModelDescriptorIndex { descriptor.base_control }
}

public struct EntityModelStreamDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_stream_descriptor_t

    public let formats: [EntityModelStreamFormat]

    init(_ descriptor: avdecc_entity_model_stream_descriptor_t) {
        formats = nullTerminatedArrayToSwiftArray(descriptor.formats)
            .map { EntityModelStreamFormat($0) }
        var descriptor = descriptor
        descriptor.formats = nil
        self.descriptor = descriptor
    }

    public var objectName: String { descriptor.objectName }
    public var localizedDescription: EntityModelLocalizedStringReference {
        descriptor.localized_description
    }

    public var clockDomainIndex: EntityModelDescriptorIndex { descriptor.clock_domain_index }
    public var streamFlags: avdecc_entity_stream_flags_t { descriptor.stream_flags }

    public var currentFormat: EntityModelStreamFormat {
        EntityModelStreamFormat(descriptor.current_format)
    }

    public var avbInterfaceIndex: EntityModelDescriptorIndex { descriptor.avb_interface_index }
}

public struct EntityModelAvbInterfaceDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_avb_interface_descriptor_t

    init(_ descriptor: avdecc_entity_model_avb_interface_descriptor_t) {
        self.descriptor = descriptor
    }

    public var objectName: String { descriptor.objectName }
    public var localizedDescription: EntityModelLocalizedStringReference {
        descriptor.localized_description
    }

    public var macAddress: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) { descriptor.mac_address }
    public var interfaceFlags: avdecc_entity_avb_interface_flags_t { descriptor.interface_flags }
    public var clockIdentity: UniqueIdentifier { UniqueIdentifier(descriptor.clock_identity) }
    public var priority1: UInt8 { descriptor.priority1 }
    public var clockClass: UInt8 { descriptor.clock_class }
    public var offsetScaledLogVariance: UInt16 { descriptor.offset_scaled_log_variance }
    public var clockAccuracy: UInt8 { descriptor.clock_accuracy }
    public var priority2: UInt8 { descriptor.priority2 }
    public var domainNumber: UInt8 { descriptor.domain_number }
    public var logSyncInterval: UInt8 { descriptor.log_sync_interval }
    public var logAnnounceInterval: UInt8 { descriptor.log_announce_interval }
    public var logPDelayInterval: UInt8 { descriptor.log_p_delay_interval }
    public var portNumber: UInt16 { descriptor.port_number }
}

public struct EntityModelClockSourceDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_clock_source_descriptor_t

    init(_ descriptor: avdecc_entity_model_clock_source_descriptor_t) {
        self.descriptor = descriptor
    }

    public var objectName: String { descriptor.objectName }
    public var localizedDescription: EntityModelLocalizedStringReference {
        descriptor.localized_description
    }

    public var clockSourceFlags: avdecc_entity_clock_source_flags_t { descriptor.clock_source_flags
    }

    public var clockSourceType: avdecc_entity_model_clock_source_type_t {
        descriptor.clock_source_type
    }

    public var clockSourceIdentifier: UniqueIdentifier {
        UniqueIdentifier(descriptor.clock_source_identifier)
    }

    public var clockSourceLocationType: EntityModelDescriptorType {
        descriptor.clock_source_location_type
    }

    public var clockSourceLocationIndex: EntityModelDescriptorIndex {
        descriptor.clock_source_location_index
    }
}

public struct EntityModelMemoryObjectDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_memory_object_descriptor_t

    init(_ descriptor: avdecc_entity_model_memory_object_descriptor_t) {
        self.descriptor = descriptor
    }

    public var objectName: String { descriptor.objectName }
    public var localizedDescription: EntityModelLocalizedStringReference {
        descriptor.localized_description
    }

    public var memoryObjectType: avdecc_entity_model_memory_object_type_t {
        descriptor.memory_object_type
    }

    public var targetDescriptorType: EntityModelDescriptorType {
        descriptor.target_descriptor_type
    }

    public var targetDescriptorIndex: EntityModelDescriptorIndex {
        descriptor.target_descriptor_index
    }

    public var startAddress: UInt64 { descriptor.start_address }
    public var maximumLength: UInt64 { descriptor.maximum_length }
    public var length: UInt64 { descriptor.length }
}

public struct EntityModelLocaleDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_locale_descriptor_t

    init(_ descriptor: avdecc_entity_model_locale_descriptor_t) {
        self.descriptor = descriptor
    }

    public var localeID: String {
        String(avdeccFixedString: descriptor.locale_id)
    }

    public var numberOfStringDescriptors: UInt16 {
        descriptor.number_of_string_descriptors
    }

    public var baseStringDescriptorIndex: EntityModelDescriptorIndex {
        descriptor.base_string_descriptor_index
    }
}

public struct EntityModelStringsDescriptor: Sendable {
    public let strings: [String]

    init(_ descriptor: avdecc_entity_model_strings_descriptor_t) {
        strings = withUnsafePointer(to: descriptor.strings) { pointer in
            let start = pointer.propertyBasePointer(to: \.0)!
            return Array(UnsafeBufferPointer(
                start: start,
                count: MemoryLayout.size(ofValue: pointer)
            )).map { String(avdeccFixedString: $0) }
        }
    }
}

public struct EntityModelStreamPortDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_stream_port_descriptor_t

    init(_ descriptor: avdecc_entity_model_stream_port_descriptor_t) {
        self.descriptor = descriptor
    }

    public var clockDomainIndex: EntityModelDescriptorIndex { descriptor.clock_domain_index }
    public var portFlags: avdecc_entity_port_flags_t { descriptor.port_flags }

    public var numberOfControls: UInt16 { descriptor.number_of_controls }
    public var baseControl: EntityModelDescriptorIndex { descriptor.base_control }

    public var numberOfClusters: UInt16 { descriptor.number_of_clusters }
    public var baseCluster: EntityModelDescriptorIndex { descriptor.base_cluster }

    public var numberOfMaps: UInt16 { descriptor.number_of_maps }
    public var baseMap: EntityModelDescriptorIndex { descriptor.base_map }
}

public struct EntityModelExternalPortDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_external_port_descriptor_t

    init(_ descriptor: avdecc_entity_model_external_port_descriptor_t) {
        self.descriptor = descriptor
    }

    public var clockDomainIndex: EntityModelDescriptorIndex { descriptor.clock_domain_index }
    public var portFlags: avdecc_entity_port_flags_t { descriptor.port_flags }

    public var numberOfControls: UInt16 { descriptor.number_of_controls }
    public var baseControl: EntityModelDescriptorIndex { descriptor.base_control }

    public var signalType: EntityModelDescriptorType { descriptor.signal_type }
    public var signalIndex: EntityModelDescriptorIndex { descriptor.signal_index }

    public var signalOutput: UInt16 { descriptor.signal_output }
    public var blockLatency: UInt32 { descriptor.block_latency }

    public var jackIndex: EntityModelDescriptorIndex { descriptor.jack_index }
}

public struct EntityModelInternalPortDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_internal_port_descriptor_t

    init(_ descriptor: avdecc_entity_model_internal_port_descriptor_t) {
        self.descriptor = descriptor
    }

    public var clockDomainIndex: EntityModelDescriptorIndex { descriptor.clock_domain_index }
    public var portFlags: avdecc_entity_port_flags_t { descriptor.port_flags }

    public var numberOfControls: UInt16 { descriptor.number_of_controls }
    public var baseControl: EntityModelDescriptorIndex { descriptor.base_control }

    public var signalType: EntityModelDescriptorType { descriptor.signal_type }
    public var signalIndex: EntityModelDescriptorIndex { descriptor.signal_index }

    public var signalOutput: UInt16 { descriptor.signal_output }
    public var blockLatency: UInt32 { descriptor.block_latency }

    public var internalIndex: EntityModelDescriptorIndex { descriptor.internal_index }
}

public struct EntityModelAudioClusterDescriptor: Sendable {
    private let descriptor: avdecc_entity_model_audio_cluster_descriptor_t

    init(_ descriptor: avdecc_entity_model_audio_cluster_descriptor_t) {
        self.descriptor = descriptor
    }

    public var objectName: String { descriptor.objectName }
    public var localizedDescription: EntityModelLocalizedStringReference {
        descriptor.localized_description
    }

    public var signalType: EntityModelDescriptorType { descriptor.signal_type }
    public var signalIndex: EntityModelDescriptorIndex { descriptor.signal_index }

    public var signalOutput: UInt16 { descriptor.signal_output }
    public var pathLatency: UInt32 { descriptor.path_latency }
    public var blockLatency: UInt32 { descriptor.block_latency }
    public var channelCount: UInt16 { descriptor.channel_count }
    public var format: UInt8 { descriptor.format }
}

public struct EntityModelAudioMapping: Sendable, AvdeccCBridgeable {
    typealias AvdeccCType = avdecc_entity_model_audio_mapping_t

    private let mapping: avdecc_entity_model_audio_mapping_t

    public init(
        streamIndex: EntityModelDescriptorIndex,
        streamChannel: UInt16,
        clusterOffset: EntityModelDescriptorIndex,
        clusterChannel: UInt16
    ) {
        mapping = avdecc_entity_model_audio_mapping_t(
            stream_index: streamIndex,
            stream_channel: streamChannel,
            cluster_offset: clusterOffset,
            cluster_channel: clusterChannel
        )
    }

    init(_ mapping: avdecc_entity_model_audio_mapping_t) {
        self.mapping = mapping
    }

    func bridgeToAvdeccCType() -> AvdeccCType {
        mapping
    }

    public var streamIndex: EntityModelDescriptorIndex { mapping.stream_index }
    public var streamChannel: UInt16 { mapping.stream_channel }
    public var clusterOffset: EntityModelDescriptorIndex { mapping.cluster_offset }
    public var clusterChannel: UInt16 { mapping.cluster_channel }
}

public struct EntityModelAudioMapDescriptor: Sendable {
    public let mappings: [EntityModelAudioMapping]

    public init(_ mappings: [EntityModelAudioMapping]) {
        self.mappings = mappings
    }

    init(_ descriptor: avdecc_entity_model_audio_map_descriptor_t) {
        mappings = nullTerminatedArrayToSwiftArray(descriptor.mappings)
            .map { EntityModelAudioMapping($0) }
    }

    init(
        numberOfMaps: EntityModelDescriptorIndex,
        _ mappings: UnsafePointer<avdecc_entity_model_audio_mapping_cp?>?
    ) {
        self.mappings = Array(UnsafeBufferPointer(start: mappings, count: Int(numberOfMaps)))
            .compactMap { map in
                guard let map else { return nil }
                return EntityModelAudioMapping(map.pointee)
            }
    }
}

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

    public var localizedDescription: EntityModelLocalizedStringReference {
        descriptor.localized_description
    }

    public var clockSourceIndex: EntityModelDescriptorIndex {
        descriptor.clock_source_index
    }
}

public struct EntityModelStreamIdentification: Sendable, AvdeccCBridgeable {
    typealias AvdeccCType = avdecc_entity_model_stream_identification_t

    private let id: avdecc_entity_model_stream_identification_t

    init(_ id: avdecc_entity_model_stream_identification_t) {
        self.id = id
    }

    public init(entityID: UniqueIdentifier, streamIndex: EntityModelDescriptorIndex) {
        id = avdecc_entity_model_stream_identification_t(
            entity_id: entityID.bridgeToAvdeccCType(),
            stream_index: streamIndex
        )
    }

    func bridgeToAvdeccCType() -> AvdeccCType {
        id
    }

    public var entityID: UniqueIdentifier { UniqueIdentifier(id.entity_id) }
    public var streamIndex: EntityModelDescriptorIndex { id.stream_index }
}

public struct EntityModelStreamInfo: Sendable, AvdeccCBridgeable {
    typealias AvdeccCType = avdecc_entity_model_stream_info_t

    public let descriptor: avdecc_entity_model_stream_info_t

    init(_ descriptor: avdecc_entity_model_stream_info_t) {
        self.descriptor = descriptor
    }

    func bridgeToAvdeccCType() -> AvdeccCType {
        descriptor
    }

    public var streamInfoFlags: UInt32 { descriptor.stream_info_flags }
    public var streamFormat: EntityModelStreamFormat {
        EntityModelStreamFormat(descriptor.stream_format)
    }

    public var streamID: UniqueIdentifier { UniqueIdentifier(descriptor.stream_id) }
    public var msrpAccumulatedLatency: UInt32 { descriptor.msrp_accumulated_latency }
    public var streamDestinationMacAddress: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
        descriptor.stream_dest_mac
    }

    public var msrpFailureCode: UInt8 { descriptor.msrp_failure_code }
    public var msrpFailureBridgeID: UInt64 { descriptor.msrp_failure_bridge_id }
    public var streamVlanID: UInt16 { descriptor.stream_vlan_id }

    // MILAN additions

    public var streamInfoFlagsEx: UInt32? {
        guard descriptor.stream_info_flags_ex_valid != 0 else { return nil }
        return descriptor.stream_info_flags_ex
    }

    public var probingStatus: UInt8? {
        guard descriptor.probing_status_valid != 0 else { return nil }
        return descriptor.probing_status
    }

    public var acmpStatus: UInt8? {
        guard descriptor.acmp_status_valid != 0 else { return nil }
        return descriptor.acmp_status
    }
}

public struct EntityModelMsrpMapping: Sendable {
    private let descriptor: avdecc_entity_model_msrp_mapping_t

    init(_ descriptor: avdecc_entity_model_msrp_mapping_t) {
        self.descriptor = descriptor
    }

    public var trafficClass: UInt8 { descriptor.traffic_class }
    public var priority: UInt8 { descriptor.priority }
    public var vlanID: UInt16 { descriptor.vlan_id }
}

public struct EntityModelAvbInfo: Sendable {
    private let info: avdecc_entity_model_avb_info_t

    public let mappings: [EntityModelMsrpMapping]

    init(_ info: avdecc_entity_model_avb_info_t) {
        mappings = nullTerminatedArrayToSwiftArray(info.mappings).map { EntityModelMsrpMapping($0) }
        var info = info
        info.mappings = nil
        self.info = info
    }

    public var gptpGrandmasterID: UniqueIdentifier {
        UniqueIdentifier(info.gptp_grandmaster_id)
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

public struct EntityModelMilanInfo: Sendable {
    public let info: avdecc_entity_model_milan_info_t

    init(_ info: avdecc_entity_model_milan_info_t) {
        self.info = info
    }

    public var protocolVersion: UInt32 { info.protocol_version }
    public var featuresFlags: avdecc_entity_milan_info_features_flags_t { info.features_flags }
    public var certificationVersion: UInt32 { info.certification_version }
}

public typealias EntityCommonInformation = avdecc_entity_common_information_t

public extension avdecc_entity_common_information_t {
    var entityID: UniqueIdentifier {
        get {
            UniqueIdentifier(entity_id)
        }
        set {
            entity_id = newValue.id
        }
    }

    var controllerCapabilities: avdecc_entity_controller_capabilities_e {
        get {
            avdecc_entity_controller_capabilities_e(rawValue: UInt32(controller_capabilities))
        }
        set {
            controller_capabilities = UInt16(newValue.rawValue)
        }
    }
}

public typealias EntityInterfaceInformation = avdecc_entity_interface_information_t

public struct Entity: AvdeccCBridgeable, CustomStringConvertible {
    typealias AvdeccCType = avdecc_entity_t

    public let commonInformation: EntityCommonInformation
    public let interfacesInformation: [EntityInterfaceInformation]

    public var entityID: UniqueIdentifier {
        commonInformation.entityID
    }

    public var description: String {
        "\(type(of: self))(entityID: \(entityID))"
    }

    public init(
        commonInformation: EntityCommonInformation,
        interfacesInformation: [EntityInterfaceInformation]
    ) {
        self.commonInformation = commonInformation
        self.interfacesInformation = interfacesInformation
    }

    init(_ entity: AvdeccCType) {
        commonInformation = entity.common_information
        var interfacesInformation = [EntityInterfaceInformation]()
        entity.forEachInterface {
            var interface = $0.pointee
            // zero out next pointer, because it will fall out of scope
            interface.next = nil
            interfacesInformation.append(interface)
        }
        self.interfacesInformation = interfacesInformation
    }

    func bridgeToAvdeccCType() -> AvdeccCType {
        var entity = avdecc_entity_t()
        entity.common_information = commonInformation
        // FIXME: interfaces next
        if !interfacesInformation.isEmpty {
            entity.interfaces_information = interfacesInformation.first!
        }
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

public enum AemCommandType: UInt16 {
    case lockEntity = 0x0001
    case entityAvailable = 0x0002
    case controllerAvailable = 0x0003
    case readDescriptor = 0x0004
    case writeDescriptor = 0x0005
    case setConfiguration = 0x0006
    case getConfiguration = 0x0007
    case setStreamFormat = 0x0008
    case getStreamFormat = 0x0009
    case setVideoFormat = 0x000A
    case getVideoFormat = 0x000B
    case setSensorFormat = 0x000C
    case getSensorFormat = 0x000D
    case setStreamInfo = 0x000E
    case getStreamInfo = 0x000F
    case setName = 0x0010
    case getName = 0x0011
    case setAssociationID = 0x0012
    case getAssociationID = 0x0013
    case setSamplingRate = 0x0014
    case getSamplingRate = 0x0015
    case setClockSource = 0x0016
    case getClockSource = 0x0017
    case setControl = 0x0018
    case getControl = 0x0019
    case incrementControl = 0x001A
    case decrementControl = 0x001B
    case setSignalSelector = 0x001C
    case getSignalSelector = 0x001D
    case setMixer = 0x001E
    case getMixer = 0x001F
    case setMatrix = 0x0020
    case getMatrix = 0x0021
    case startStreaming = 0x0022
    case stopStreaming = 0x0023
    case registerUnsolicitedNotification = 0x0024
    case deregisterUnsolicitedNotification = 0x0025
    case identifyNotification = 0x0026
    case getAvbInfo = 0x0027
    case getAsPath = 0x0028
    case getCounters = 0x0029
    case reboot = 0x002A
    case getAudioMap = 0x002B
    case addAudioMappings = 0x002C
    case removeAudioMappings = 0x002D
    case getVideoMap = 0x002E
    case addVideoMappings = 0x002F
    case removeVideoMappings = 0x0030
    case getSensorMap = 0x0031
    case addSensorMappings = 0x0032
    case removeSensorMappings = 0x0033
    case startOperation = 0x0034
    case abortOperation = 0x0035
    case operationStatus = 0x0036
    case setMemoryObjectLength = 0x0047
    case getMemoryObjectLength = 0x0048
    case setStreamBackup = 0x0049
    case getStreamBackup = 0x004A
    case invalidCommandType = 0xFFFF
}
