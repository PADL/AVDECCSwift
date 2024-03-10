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

#pragma once

#include "la/avdecc/avdecc.h"

/* Enumeration and Control Protocol (AECP) AEM handlers */
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_acquire_entity_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_unique_identifier_t const /*owningEntity*/,
    avdecc_entity_model_descriptor_type_t const /*descriptorType*/,
    avdecc_entity_model_descriptor_index_t const /*descriptorIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_release_entity_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_unique_identifier_t const /*owningEntity*/,
    avdecc_entity_model_descriptor_type_t const /*descriptorType*/,
    avdecc_entity_model_descriptor_index_t const /*descriptorIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_lock_entity_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_unique_identifier_t const /*lockingEntity*/,
    avdecc_entity_model_descriptor_type_t const /*descriptorType*/,
    avdecc_entity_model_descriptor_index_t const /*descriptorIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_unlock_entity_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_unique_identifier_t const /*lockingEntity*/,
    avdecc_entity_model_descriptor_type_t const /*descriptorType*/,
    avdecc_entity_model_descriptor_index_t const /*descriptorIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_query_entity_available_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_query_controller_available_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_register_unsolicited_notifications_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_unregister_unsolicited_notifications_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_entity_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_entity_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_configuration_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_configuration_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_audio_unit_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*audioUnitIndex*/,
    avdecc_entity_model_audio_unit_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_stream_input_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_stream_output_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_jack_input_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*jackIndex*/,
    avdecc_entity_model_jack_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_jack_output_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*jackIndex*/,
    avdecc_entity_model_jack_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_avb_interface_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*avbInterfaceIndex*/,
    avdecc_entity_model_avb_interface_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_clock_source_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clockSourceIndex*/,
    avdecc_entity_model_clock_source_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_memory_object_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*memoryObjectIndex*/,
    avdecc_entity_model_memory_object_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_locale_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*localeIndex*/,
    avdecc_entity_model_locale_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_strings_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*stringsIndex*/,
    avdecc_entity_model_strings_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_stream_port_input_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*streamPortIndex*/,
    avdecc_entity_model_stream_port_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_stream_port_output_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*streamPortIndex*/,
    avdecc_entity_model_stream_port_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_external_port_input_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*externalPortIndex*/,
    avdecc_entity_model_external_port_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_external_port_output_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*externalPortIndex*/,
    avdecc_entity_model_external_port_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_internal_port_input_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*internalPortIndex*/,
    avdecc_entity_model_internal_port_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_internal_port_output_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*internalPortIndex*/,
    avdecc_entity_model_internal_port_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_audio_cluster_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clusterIndex*/,
    avdecc_entity_model_audio_cluster_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_audio_map_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*mapIndex*/,
    avdecc_entity_model_audio_map_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_read_clock_domain_descriptor_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clockDomainIndex*/,
    avdecc_entity_model_clock_domain_descriptor_cp const /*descriptor*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_configuration_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_configuration_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_stream_input_format_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_format_t const /*streamFormat*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_input_format_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_format_t const /*streamFormat*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_stream_output_format_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_format_t const /*streamFormat*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_output_format_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_format_t const /*streamFormat*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_port_input_audio_map_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamPortIndex*/,
    avdecc_entity_model_descriptor_index_t const /*numberOfMaps*/,
    avdecc_entity_model_descriptor_index_t const /*mapIndex*/,
    avdecc_entity_model_audio_mapping_cp const *const /*mappings*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_port_output_audio_map_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamPortIndex*/,
    avdecc_entity_model_descriptor_index_t const /*numberOfMaps*/,
    avdecc_entity_model_descriptor_index_t const /*mapIndex*/,
    avdecc_entity_model_audio_mapping_cp const *const /*mappings*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_add_stream_port_input_audio_mappings_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamPortIndex*/,
    avdecc_entity_model_audio_mapping_cp const *const /*mappings*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_add_stream_port_output_audio_mappings_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamPortIndex*/,
    avdecc_entity_model_audio_mapping_cp const *const /*mappings*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_remove_stream_port_input_audio_mappings_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamPortIndex*/,
    avdecc_entity_model_audio_mapping_cp const *const /*mappings*/);
typedef void(
    LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
    avdecc_local_entity_remove_stream_port_output_audio_mappings_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamPortIndex*/,
    avdecc_entity_model_audio_mapping_cp const *const /*mappings*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_stream_input_info_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_info_cp const /*info*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_stream_output_info_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_info_cp const /*info*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_input_info_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_info_cp const /*info*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_output_info_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_model_stream_info_cp const /*info*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_entity_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_fixed_string_t const /*entityName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_entity_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_fixed_string_t const /*entityName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_entity_group_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_fixed_string_t const /*entityGroupName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_entity_group_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_fixed_string_t const /*entityGroupName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_configuration_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_fixed_string_t const /*configurationName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_configuration_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_fixed_string_t const /*configurationName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_audio_unit_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*audioUnitIndex*/,
    avdecc_fixed_string_t const /*audioUnitName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_audio_unit_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*audioUnitIndex*/,
    avdecc_fixed_string_t const /*audioUnitName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_stream_input_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_fixed_string_t const /*streamInputName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_input_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_fixed_string_t const /*streamInputName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_stream_output_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_fixed_string_t const /*streamOutputName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_output_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_fixed_string_t const /*streamOutputName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_avb_interface_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*avbInterfaceIndex*/,
    avdecc_fixed_string_t const /*avbInterfaceName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_avb_interface_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*avbInterfaceIndex*/,
    avdecc_fixed_string_t const /*avbInterfaceName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_clock_source_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clockSourceIndex*/,
    avdecc_fixed_string_t const /*clockSourceName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_clock_source_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clockSourceIndex*/,
    avdecc_fixed_string_t const /*clockSourceName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_memory_object_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*memoryObjectIndex*/,
    avdecc_fixed_string_t const /*memoryObjectName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_memory_object_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*memoryObjectIndex*/,
    avdecc_fixed_string_t const /*memoryObjectName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_audio_cluster_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*audioClusterIndex*/,
    avdecc_fixed_string_t const /*audioClusterName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_audio_cluster_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*audioClusterIndex*/,
    avdecc_fixed_string_t const /*audioClusterName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_clock_domain_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clockDomainIndex*/,
    avdecc_fixed_string_t const /*clockDomainName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_clock_domain_name_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clockDomainIndex*/,
    avdecc_fixed_string_t const /*clockDomainName*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_audio_unit_sampling_rate_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*audioUnitIndex*/,
    avdecc_entity_model_sampling_rate_t const /*samplingRate*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_audio_unit_sampling_rate_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*audioUnitIndex*/,
    avdecc_entity_model_sampling_rate_t const /*samplingRate*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_video_cluster_sampling_rate_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*videoClusterIndex*/,
    avdecc_entity_model_sampling_rate_t const /*samplingRate*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_video_cluster_sampling_rate_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*videoClusterIndex*/,
    avdecc_entity_model_sampling_rate_t const /*samplingRate*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_sensor_cluster_sampling_rate_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*sensorClusterIndex*/,
    avdecc_entity_model_sampling_rate_t const /*samplingRate*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_sensor_cluster_sampling_rate_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*sensorClusterIndex*/,
    avdecc_entity_model_sampling_rate_t const /*samplingRate*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_set_clock_source_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*clockDomainIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clockSourceIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_clock_source_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*clockDomainIndex*/,
    avdecc_entity_model_descriptor_index_t const /*clockSourceIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_start_stream_input_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_start_stream_output_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_stop_stream_input_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_stop_stream_output_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_avb_info_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*avbInterfaceIndex*/,
    avdecc_entity_model_avb_info_cp const /*info*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_as_path_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*avbInterfaceIndex*/,
    avdecc_entity_model_as_path_cp const /*asPath*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_entity_counters_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_entity_counter_valid_flags_t const /*validCounters*/,
    avdecc_entity_model_descriptor_counters_t const /*counters*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_avb_interface_counters_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*avbInterfaceIndex*/,
    avdecc_entity_avb_interface_counter_valid_flags_t const /*validCounters*/,
    avdecc_entity_model_descriptor_counters_t const /*counters*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_clock_domain_counters_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*clockDomainIndex*/,
    avdecc_entity_clock_domain_counter_valid_flags_t const /*validCounters*/,
    avdecc_entity_model_descriptor_counters_t const /*counters*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_input_counters_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_stream_input_counter_valid_flags_t const /*validCounters*/,
    avdecc_entity_model_descriptor_counters_t const /*counters*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_stream_output_counters_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_aem_command_status_t const /*status*/,
    avdecc_entity_model_descriptor_index_t const /*streamIndex*/,
    avdecc_entity_stream_output_counter_valid_flags_t const /*validCounters*/,
    avdecc_entity_model_descriptor_counters_t const /*counters*/);
// using StartOperationHandler)(LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
// avdecc_unique_identifier_t const /*entityID*/,
// avdecc_local_entity_aem_command_status_t const /*status*/,
// la::avdecc::entity::model::DescriptorType const descriptorType,
// la::avdecc::entity::model::DescriptorIndex const descriptorIndex,
// la::avdecc::entity::model::OperationID const operationID,
// la::avdecc::entity::model::MemoryObjectOperationType const operationType,
// la::avdecc::MemoryBuffer const& memoryBuffer); using
// AbortOperationHandler)(LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
// avdecc_unique_identifier_t const /*entityID*/,
// avdecc_local_entity_aem_command_status_t const /*status*/,
// la::avdecc::entity::model::DescriptorType const descriptorType,
// la::avdecc::entity::model::DescriptorIndex const descriptorIndex,
// la::avdecc::entity::model::OperationID const operationID); using
// SetMemoryObjectLengthHandler)(LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
// avdecc_unique_identifier_t const /*entityID*/,
// avdecc_local_entity_aem_command_status_t const /*status*/,
// avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
// avdecc_entity_model_descriptor_index_t const /*memoryObjectIndex*/, unsigned
// long long const length); using
// GetMemoryObjectLengthHandler)(LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
// avdecc_unique_identifier_t const /*entityID*/,
// avdecc_local_entity_aem_command_status_t const /*status*/,
// avdecc_entity_model_descriptor_index_t const /*configurationIndex*/,
// avdecc_entity_model_descriptor_index_t const /*memoryObjectIndex*/, unsigned
// long long const length);
///* Enumeration and Control Protocol (AECP) AA handlers */
// typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION^
// avdecc_local_entity_address_access_block)(LA_AVDECC_LOCAL_ENTITY_HANDLE const
// /*handle*/, avdecc_unique_identifier_t const /*entityID*/,
// avdecc_local_entity_aa_command_status_t const /*status*/,
// avdecc_entity_address_access_tlvs_cp const /*tlvs*/);
///* Enumeration and Control Protocol (AECP) MVU handlers (Milan Vendor Unique)
///*/
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_milan_info_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_unique_identifier_t const /*entityID*/,
    avdecc_local_entity_mvu_command_status_t const /*status*/,
    avdecc_entity_model_milan_info_cp const /*info*/);
///* Connection Management Protocol (ACMP) handlers */
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_connect_stream_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_entity_model_stream_identification_cp const /*talkerStream*/,
    avdecc_entity_model_stream_identification_cp const /*listenerStream*/,
    unsigned short const /*connectionCount*/,
    avdecc_entity_connection_flags_t const /*flags*/,
    avdecc_local_entity_control_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_disconnect_stream_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_entity_model_stream_identification_cp const /*talkerStream*/,
    avdecc_entity_model_stream_identification_cp const /*listenerStream*/,
    unsigned short const /*connectionCount*/,
    avdecc_entity_connection_flags_t const /*flags*/,
    avdecc_local_entity_control_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_disconnect_talker_stream_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_entity_model_stream_identification_cp const /*talkerStream*/,
    avdecc_entity_model_stream_identification_cp const /*listenerStream*/,
    unsigned short const /*connectionCount*/,
    avdecc_entity_connection_flags_t const /*flags*/,
    avdecc_local_entity_control_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_talker_stream_state_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_entity_model_stream_identification_cp const /*talkerStream*/,
    avdecc_entity_model_stream_identification_cp const /*listenerStream*/,
    unsigned short const /*connectionCount*/,
    avdecc_entity_connection_flags_t const /*flags*/,
    avdecc_local_entity_control_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_listener_stream_state_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_entity_model_stream_identification_cp const /*talkerStream*/,
    avdecc_entity_model_stream_identification_cp const /*listenerStream*/,
    unsigned short const /*connectionCount*/,
    avdecc_entity_connection_flags_t const /*flags*/,
    avdecc_local_entity_control_status_t const /*status*/);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_local_entity_get_talker_stream_connection_block)(
    LA_AVDECC_LOCAL_ENTITY_HANDLE const /*handle*/,
    avdecc_entity_model_stream_identification_cp const /*talkerStream*/,
    avdecc_entity_model_stream_identification_cp const /*listenerStream*/,
    unsigned short const /*connectionCount*/,
    avdecc_entity_connection_flags_t const /*flags*/,
    avdecc_local_entity_control_status_t const /*status*/);

LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_acquireEntity_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_bool_t const isPersistent,
        avdecc_entity_model_descriptor_type_t const descriptorType,
        avdecc_entity_model_descriptor_index_t const descriptorIndex,
        avdecc_local_entity_acquire_entity_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_releaseEntity_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const descriptorType,
        avdecc_entity_model_descriptor_index_t const descriptorIndex,
        avdecc_local_entity_release_entity_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_lockEntity_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const descriptorType,
        avdecc_entity_model_descriptor_index_t const descriptorIndex,
        avdecc_local_entity_lock_entity_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_unlockEntity_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const descriptorType,
        avdecc_entity_model_descriptor_index_t const descriptorIndex,
        avdecc_local_entity_unlock_entity_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_queryEntityAvailable_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_query_entity_available_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_queryControllerAvailable_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_query_controller_available_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_registerUnsolicitedNotifications_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_register_unsolicited_notifications_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_unregisterUnsolicitedNotifications_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_unregister_unsolicited_notifications_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readEntityDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_read_entity_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readConfigurationDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_local_entity_read_configuration_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readAudioUnitDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const audioUnitIndex,
        avdecc_local_entity_read_audio_unit_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readStreamInputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_read_stream_input_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readStreamOutputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_read_stream_output_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readJackInputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const jackIndex,
        avdecc_local_entity_read_jack_input_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readJackOutputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const jackIndex,
        avdecc_local_entity_read_jack_output_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readAvbInterfaceDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const avbInterfaceIndex,
        avdecc_local_entity_read_avb_interface_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readClockSourceDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const clockSourceIndex,
        avdecc_local_entity_read_clock_source_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readMemoryObjectDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const memoryObjectIndex,
        avdecc_local_entity_read_memory_object_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readLocaleDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const localeIndex,
        avdecc_local_entity_read_locale_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readStringsDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const stringsIndex,
        avdecc_local_entity_read_strings_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readStreamPortInputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const streamPortIndex,
        avdecc_local_entity_read_stream_port_input_descriptor_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readStreamPortOutputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const streamPortIndex,
        avdecc_local_entity_read_stream_port_output_descriptor_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readExternalPortInputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const externalPortIndex,
        avdecc_local_entity_read_external_port_input_descriptor_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readExternalPortOutputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const externalPortIndex,
        avdecc_local_entity_read_external_port_output_descriptor_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readInternalPortInputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const internalPortIndex,
        avdecc_local_entity_read_internal_port_input_descriptor_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readInternalPortOutputDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const internalPortIndex,
        avdecc_local_entity_read_internal_port_output_descriptor_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readAudioClusterDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const clusterIndex,
        avdecc_local_entity_read_audio_cluster_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readAudioMapDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const mapIndex,
        avdecc_local_entity_read_audio_map_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_readClockDomainDescriptor_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const clockDomainIndex,
        avdecc_local_entity_read_clock_domain_descriptor_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setConfiguration_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_local_entity_set_configuration_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getConfiguration_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_get_configuration_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setStreamInputFormat_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_entity_model_stream_format_t const streamFormat,
        avdecc_local_entity_set_stream_input_format_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamInputFormat_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_get_stream_input_format_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setStreamOutputFormat_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_entity_model_stream_format_t const streamFormat,
        avdecc_local_entity_set_stream_output_format_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamOutputFormat_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_get_stream_output_format_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamPortInputAudioMap_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamPortIndex,
        avdecc_entity_model_descriptor_index_t const mapIndex,
        avdecc_local_entity_get_stream_port_input_audio_map_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamPortOutputAudioMap_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamPortIndex,
        avdecc_entity_model_descriptor_index_t const mapIndex,
        avdecc_local_entity_get_stream_port_output_audio_map_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_addStreamPortInputAudioMappings_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamPortIndex,
        avdecc_entity_model_audio_mapping_cp const *const mappings,
        avdecc_local_entity_add_stream_port_input_audio_mappings_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_addStreamPortOutputAudioMappings_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamPortIndex,
        avdecc_entity_model_audio_mapping_cp const *const mappings,
        avdecc_local_entity_add_stream_port_output_audio_mappings_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_removeStreamPortInputAudioMappings_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamPortIndex,
        avdecc_entity_model_audio_mapping_cp const *const mappings,
        avdecc_local_entity_remove_stream_port_input_audio_mappings_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_removeStreamPortOutputAudioMappings_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamPortIndex,
        avdecc_entity_model_audio_mapping_cp const *const mappings,
        avdecc_local_entity_remove_stream_port_output_audio_mappings_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setStreamInputInfo_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_entity_model_stream_info_cp const info,
        avdecc_local_entity_set_stream_input_info_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setStreamOutputInfo_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_entity_model_stream_info_cp const info,
        avdecc_local_entity_set_stream_output_info_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamInputInfo_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_get_stream_input_info_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamOutputInfo_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_get_stream_output_info_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setEntityName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_fixed_string_t const entityName,
        avdecc_local_entity_set_entity_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getEntityName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_get_entity_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setEntityGroupName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_fixed_string_t const entityGroupName,
        avdecc_local_entity_set_entity_group_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getEntityGroupName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_get_entity_group_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setConfigurationName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_fixed_string_t const configurationName,
        avdecc_local_entity_set_configuration_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getConfigurationName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_local_entity_get_configuration_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setAudioUnitName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const audioUnitIndex,
        avdecc_fixed_string_t const audioUnitName,
        avdecc_local_entity_set_audio_unit_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getAudioUnitName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const audioUnitIndex,
        avdecc_local_entity_get_audio_unit_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setStreamInputName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_fixed_string_t const streamInputName,
        avdecc_local_entity_set_stream_input_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamInputName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_get_stream_input_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setStreamOutputName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_fixed_string_t const streamOutputName,
        avdecc_local_entity_set_stream_output_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamOutputName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_get_stream_output_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setAvbInterfaceName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const avbInterfaceIndex,
        avdecc_fixed_string_t const avbInterfaceName,
        avdecc_local_entity_set_avb_interface_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getAvbInterfaceName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const avbInterfaceIndex,
        avdecc_local_entity_get_avb_interface_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setClockSourceName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const clockSourceIndex,
        avdecc_fixed_string_t const clockSourceName,
        avdecc_local_entity_set_clock_source_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getClockSourceName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const clockSourceIndex,
        avdecc_local_entity_get_clock_source_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setMemoryObjectName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const memoryObjectIndex,
        avdecc_fixed_string_t const memoryObjectName,
        avdecc_local_entity_set_memory_object_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getMemoryObjectName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const memoryObjectIndex,
        avdecc_local_entity_get_memory_object_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setAudioClusterName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const audioClusterIndex,
        avdecc_fixed_string_t const audioClusterName,
        avdecc_local_entity_set_audio_cluster_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getAudioClusterName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const audioClusterIndex,
        avdecc_local_entity_get_audio_cluster_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setClockDomainName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const clockDomainIndex,
        avdecc_fixed_string_t const clockDomainName,
        avdecc_local_entity_set_clock_domain_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getClockDomainName_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const configurationIndex,
        avdecc_entity_model_descriptor_type_t const clockDomainIndex,
        avdecc_local_entity_get_clock_domain_name_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setAudioUnitSamplingRate_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const audioUnitIndex,
        avdecc_entity_model_sampling_rate_t const samplingRate,
        avdecc_local_entity_set_audio_unit_sampling_rate_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getAudioUnitSamplingRate_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const audioUnitIndex,
        avdecc_local_entity_get_audio_unit_sampling_rate_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setVideoClusterSamplingRate_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const videoClusterIndex,
        avdecc_entity_model_sampling_rate_t const samplingRate,
        avdecc_local_entity_set_video_cluster_sampling_rate_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getVideoClusterSamplingRate_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const videoClusterIndex,
        avdecc_local_entity_get_video_cluster_sampling_rate_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setSensorClusterSamplingRate_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const sensorClusterIndex,
        avdecc_entity_model_sampling_rate_t const samplingRate,
        avdecc_local_entity_set_sensor_cluster_sampling_rate_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getSensorClusterSamplingRate_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const sensorClusterIndex,
        avdecc_local_entity_get_sensor_cluster_sampling_rate_block const
            onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_setClockSource_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const clockDomainIndex,
        avdecc_entity_model_descriptor_type_t const clockSourceIndex,
        avdecc_local_entity_set_clock_source_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getClockSource_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const clockDomainIndex,
        avdecc_local_entity_get_clock_source_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_startStreamInput_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_start_stream_input_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_startStreamOutput_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_start_stream_output_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_stopStreamInput_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_stop_stream_input_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_stopStreamOutput_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_stop_stream_output_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getAvbInfo_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const avbInterfaceIndex,
        avdecc_local_entity_get_avb_info_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getAsPath_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const avbInterfaceIndex,
        avdecc_local_entity_get_as_path_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getEntityCounters_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_get_entity_counters_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getAvbInterfaceCounters_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const avbInterfaceIndex,
        avdecc_local_entity_get_avb_interface_counters_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getClockDomainCounters_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const clockDomainIndex,
        avdecc_local_entity_get_clock_domain_counters_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamInputCounters_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_get_stream_input_counters_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getStreamOutputCounters_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_entity_model_descriptor_type_t const streamIndex,
        avdecc_local_entity_get_stream_output_counters_block const onResult);
// LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t
// LA_AVDECC_BINDINGS_C_CALL_CONVENTION
// LA_AVDECC_LocalEntity_startOperation_block(LA_AVDECC_LOCAL_ENTITY_HANDLE
// const handle, avdecc_unique_identifier_t const entityID,
// model::DescriptorType const descriptorType, model::DescriptorIndex const
// descriptorIndex, model::MemoryObjectOperationType const operationType,
// MemoryBuffer const& memoryBuffer, StartOperationHandler const onResult);
// LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t
// LA_AVDECC_BINDINGS_C_CALL_CONVENTION
// LA_AVDECC_LocalEntity_abortOperation_block(LA_AVDECC_LOCAL_ENTITY_HANDLE
// const handle, avdecc_unique_identifier_t const entityID,
// model::DescriptorType const descriptorType, model::DescriptorIndex const
// descriptorIndex, model::OperationID const operationID, AbortOperationHandler
// const onResult); LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t
// LA_AVDECC_BINDINGS_C_CALL_CONVENTION
// LA_AVDECC_LocalEntity_setMemoryObjectLength_block(LA_AVDECC_LOCAL_ENTITY_HANDLE
// const handle, avdecc_unique_identifier_t const entityID,
// avdecc_entity_model_descriptor_type_t const configurationIndex,
// avdecc_entity_model_descriptor_type_t const memoryObjectIndex, unsigned long
// long const length, SetMemoryObjectLengthHandler const onResult);
// LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t
// LA_AVDECC_BINDINGS_C_CALL_CONVENTION
// LA_AVDECC_LocalEntity_getMemoryObjectLength_block(LA_AVDECC_LOCAL_ENTITY_HANDLE
// const handle, avdecc_unique_identifier_t const entityID,
// avdecc_entity_model_descriptor_type_t const configurationIndex,
// avdecc_entity_model_descriptor_type_t const memoryObjectIndex,
// GetMemoryObjectLengthHandler const onResult);

/* Enumeration and Control Protocol (AECP) AA */
// LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t
// LA_AVDECC_BINDINGS_C_CALL_CONVENTION
// LA_AVDECC_LocalEntity_addressAccess_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const
// handle, avdecc_unique_identifier_t const entityID, addressAccess::Tlvs const&
// tlvs, avdecc_local_entity_address_access_block const onResult);

/* Enumeration and Control Protocol (AECP) MVU (Milan Vendor Unique) */
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getMilanInfo_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_unique_identifier_t const entityID,
        avdecc_local_entity_get_milan_info_block const onResult);

/* Connection Management Protocol (ACMP) */
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_connectStream_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_entity_model_stream_identification_cp const talkerStream,
        avdecc_entity_model_stream_identification_cp const listenerStream,
        avdecc_local_entity_connect_stream_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_disconnectStream_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_entity_model_stream_identification_cp const talkerStream,
        avdecc_entity_model_stream_identification_cp const listenerStream,
        avdecc_local_entity_disconnect_stream_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_disconnectTalkerStream_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_entity_model_stream_identification_cp const talkerStream,
        avdecc_entity_model_stream_identification_cp const listenerStream,
        avdecc_local_entity_disconnect_talker_stream_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getTalkerStreamState_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_entity_model_stream_identification_cp const talkerStream,
        avdecc_local_entity_get_talker_stream_state_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getListenerStreamState_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_entity_model_stream_identification_cp const listenerStream,
        avdecc_local_entity_get_listener_stream_state_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_LocalEntity_getTalkerStreamConnection_block(
        LA_AVDECC_LOCAL_ENTITY_HANDLE const handle,
        avdecc_entity_model_stream_identification_cp const talkerStream,
        unsigned short const connectionIndex,
        avdecc_local_entity_get_talker_stream_connection_block const onResult);

typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_protocol_interfaces_send_aem_aecp_command_block)(
    avdecc_protocol_aem_aecpdu_cp const response,
    avdecc_protocol_interface_error_t const error);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_protocol_interfaces_send_mvu_aecp_command_block)(
    avdecc_protocol_mvu_aecpdu_cp const response,
    avdecc_protocol_interface_error_t const error);
typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^
             avdecc_protocol_interfaces_send_acmp_command_block)(
    avdecc_protocol_acmpdu_cp const response,
    avdecc_protocol_interface_error_t const error);

LA_AVDECC_BINDINGS_C_API
    avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_ProtocolInterface_sendAemAecpCommand_block(
        LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle,
        avdecc_protocol_aem_aecpdu_cp const aecpdu,
        avdecc_protocol_interfaces_send_aem_aecp_command_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_ProtocolInterface_sendMvuAecpCommand_block(
        LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle,
        avdecc_protocol_mvu_aecpdu_cp const aecpdu,
        avdecc_protocol_interfaces_send_mvu_aecp_command_block const onResult);
LA_AVDECC_BINDINGS_C_API
    avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_ProtocolInterface_sendAcmpCommand_block(
        LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle,
        avdecc_protocol_acmpdu_cp const acmpdu,
        avdecc_protocol_interfaces_send_acmp_command_block const onResult);
