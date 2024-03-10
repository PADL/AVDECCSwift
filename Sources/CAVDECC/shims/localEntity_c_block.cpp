/*
* Copyright (C) 2016-2023, L-Acoustics and its contributors

* This file is part of LA_avdecc.

* LA_avdecc is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* LA_avdecc is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Lesser General Public License for more details.

* You should have received a copy of the GNU Lesser General Public License
* along with LA_avdecc.  If not, see <http://www.gnu.org/licenses/>.
*/

/**
* @file localEntity_c.cpp
* @author Christophe Calmejane
* @brief C block bindings for la::avdecc::LocalEntity.
*/

#include "CAVDECCBlockShimsInternal.hpp"

extern la::avdecc::bindings::HandleManager<la::avdecc::entity::AggregateEntity::UniquePointer> s_AggregateEntityManager;

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_acquireEntity_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_bool_t const isPersistent, avdecc_entity_model_descriptor_type_t const descriptorType, avdecc_entity_model_descriptor_index_t const descriptorIndex, avdecc_local_entity_acquire_entity_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.acquireEntity(la::avdecc::UniqueIdentifier{ entityID }, isPersistent, la::avdecc::entity::model::DescriptorType{ descriptorType }, descriptorIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::UniqueIdentifier const owningEntity, la::avdecc::entity::model::DescriptorType const descriptorType, la::avdecc::entity::model::DescriptorIndex const descriptorIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), owningEntity, static_cast<avdecc_entity_model_descriptor_type_t>(descriptorType), static_cast<avdecc_entity_model_descriptor_index_t>(descriptorIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_releaseEntity_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const descriptorType, avdecc_entity_model_descriptor_index_t const descriptorIndex, avdecc_local_entity_release_entity_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.releaseEntity(la::avdecc::UniqueIdentifier{ entityID }, la::avdecc::entity::model::DescriptorType{ descriptorType }, descriptorIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::UniqueIdentifier const owningEntity, la::avdecc::entity::model::DescriptorType const descriptorType, la::avdecc::entity::model::DescriptorIndex const descriptorIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), owningEntity, static_cast<avdecc_entity_model_descriptor_type_t>(descriptorType), static_cast<avdecc_entity_model_descriptor_index_t>(descriptorIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_lockEntity_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const descriptorType, avdecc_entity_model_descriptor_index_t const descriptorIndex, avdecc_local_entity_lock_entity_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.lockEntity(la::avdecc::UniqueIdentifier{ entityID }, la::avdecc::entity::model::DescriptorType{ descriptorType }, descriptorIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::UniqueIdentifier const lockingEntity, la::avdecc::entity::model::DescriptorType const descriptorType, la::avdecc::entity::model::DescriptorIndex const descriptorIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), lockingEntity, static_cast<avdecc_entity_model_descriptor_type_t>(descriptorType), static_cast<avdecc_entity_model_descriptor_index_t>(descriptorIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_unlockEntity_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const descriptorType, avdecc_entity_model_descriptor_index_t const descriptorIndex, avdecc_local_entity_unlock_entity_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.unlockEntity(la::avdecc::UniqueIdentifier{ entityID }, la::avdecc::entity::model::DescriptorType{ descriptorType }, descriptorIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::UniqueIdentifier const lockingEntity, la::avdecc::entity::model::DescriptorType const descriptorType, la::avdecc::entity::model::DescriptorIndex const descriptorIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), lockingEntity, static_cast<avdecc_entity_model_descriptor_type_t>(descriptorType), static_cast<avdecc_entity_model_descriptor_index_t>(descriptorIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_queryEntityAvailable_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_query_entity_available_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.queryEntityAvailable(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_queryControllerAvailable_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_query_controller_available_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.queryControllerAvailable(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_registerUnsolicitedNotifications_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_register_unsolicited_notifications_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.registerUnsolicitedNotifications(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_unregisterUnsolicitedNotifications_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_unregister_unsolicited_notifications_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.unregisterUnsolicitedNotifications(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readEntityDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_read_entity_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readEntityDescriptor(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::EntityDescriptor const& descriptor)
			{
				auto const d = la::avdecc::bindings::fromCppToC::make_entity_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readConfigurationDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_local_entity_read_configuration_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readConfigurationDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ConfigurationDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_configuration_descriptor(descriptor);
				auto c = la::avdecc::bindings::fromCppToC::make_descriptors_count(descriptor.descriptorCounts);
				auto cp = la::avdecc::bindings::fromCppToC::make_descriptors_count_pointer(c);
				d.counts = cp.data();

				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readAudioUnitDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const audioUnitIndex, avdecc_local_entity_read_audio_unit_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readAudioUnitDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, audioUnitIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::AudioUnitIndex const audioUnitIndex, la::avdecc::entity::model::AudioUnitDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_audio_unit_descriptor(descriptor);
				auto r = la::avdecc::bindings::fromCppToC::make_sampling_rates(descriptor.samplingRates);
				auto rp = la::avdecc::bindings::fromCppToC::make_sampling_rates_pointer(r);
				d.sampling_rates = rp.data();

				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t const>(audioUnitIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readStreamInputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_read_stream_input_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readStreamInputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_stream_descriptor(descriptor);
				auto f = la::avdecc::bindings::fromCppToC::make_stream_formats(descriptor.formats);
				auto fp = la::avdecc::bindings::fromCppToC::make_stream_formats_pointer(f);
				d.formats = fp.data();
#ifdef ENABLE_AVDECC_FEATURE_REDUNDANCY
				auto r = la::avdecc::bindings::fromCppToC::make_redundant_stream_indexes(descriptor.redundantStreams);
				auto rp = la::avdecc::bindings::fromCppToC::make_redundant_stream_indexes_pointer(r);
				d.redundant_streams = rp.data();
#endif // ENABLE_AVDECC_FEATURE_REDUNDANCY

				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readStreamOutputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_read_stream_output_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readStreamOutputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_stream_descriptor(descriptor);
				auto f = la::avdecc::bindings::fromCppToC::make_stream_formats(descriptor.formats);
				auto fp = la::avdecc::bindings::fromCppToC::make_stream_formats_pointer(f);
				d.formats = fp.data();
#ifdef ENABLE_AVDECC_FEATURE_REDUNDANCY
				auto r = la::avdecc::bindings::fromCppToC::make_redundant_stream_indexes(descriptor.redundantStreams);
				auto rp = la::avdecc::bindings::fromCppToC::make_redundant_stream_indexes_pointer(r);
				d.redundant_streams = rp.data();
#endif // ENABLE_AVDECC_FEATURE_REDUNDANCY

				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readJackInputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const jackIndex, avdecc_local_entity_read_jack_input_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readJackInputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, jackIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::JackIndex const jackIndex, la::avdecc::entity::model::JackDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_jack_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(jackIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readJackOutputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const jackIndex, avdecc_local_entity_read_jack_output_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readJackOutputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, jackIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::JackIndex const jackIndex, la::avdecc::entity::model::JackDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_jack_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(jackIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readAvbInterfaceDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const avbInterfaceIndex, avdecc_local_entity_read_avb_interface_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readAvbInterfaceDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, avbInterfaceIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::AvbInterfaceIndex const avbInterfaceIndex, la::avdecc::entity::model::AvbInterfaceDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_avb_interface_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(avbInterfaceIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readClockSourceDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const clockSourceIndex, avdecc_local_entity_read_clock_source_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readClockSourceDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, clockSourceIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClockSourceIndex const clockSourceIndex, la::avdecc::entity::model::ClockSourceDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_clock_source_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clockSourceIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readMemoryObjectDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const memoryObjectIndex, avdecc_local_entity_read_memory_object_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readMemoryObjectDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, memoryObjectIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::MemoryObjectIndex const memoryObjectIndex, la::avdecc::entity::model::MemoryObjectDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_memory_object_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(memoryObjectIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readLocaleDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const localeIndex, avdecc_local_entity_read_locale_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readLocaleDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, localeIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::LocaleIndex const localeIndex, la::avdecc::entity::model::LocaleDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_locale_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(localeIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readStringsDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const stringsIndex, avdecc_local_entity_read_strings_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readStringsDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, stringsIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StringsIndex const stringsIndex, la::avdecc::entity::model::StringsDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_strings_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(stringsIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readStreamPortInputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const streamPortIndex, avdecc_local_entity_read_stream_port_input_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readStreamPortInputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, streamPortIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StreamPortIndex const streamPortIndex, la::avdecc::entity::model::StreamPortDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_stream_port_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(streamPortIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readStreamPortOutputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const streamPortIndex, avdecc_local_entity_read_stream_port_output_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readStreamPortOutputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, streamPortIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StreamPortIndex const streamPortIndex, la::avdecc::entity::model::StreamPortDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_stream_port_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(streamPortIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readExternalPortInputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const externalPortIndex, avdecc_local_entity_read_external_port_input_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readExternalPortInputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, externalPortIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ExternalPortIndex const externalPortIndex, la::avdecc::entity::model::ExternalPortDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_external_port_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(externalPortIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readExternalPortOutputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const externalPortIndex, avdecc_local_entity_read_external_port_output_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readExternalPortOutputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, externalPortIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ExternalPortIndex const externalPortIndex, la::avdecc::entity::model::ExternalPortDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_external_port_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(externalPortIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readInternalPortInputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const internalPortIndex, avdecc_local_entity_read_internal_port_input_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readInternalPortInputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, internalPortIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::InternalPortIndex const internalPortIndex, la::avdecc::entity::model::InternalPortDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_internal_port_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(internalPortIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readInternalPortOutputDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const internalPortIndex, avdecc_local_entity_read_internal_port_output_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readInternalPortOutputDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, internalPortIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::InternalPortIndex const internalPortIndex, la::avdecc::entity::model::InternalPortDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_internal_port_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(internalPortIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readAudioClusterDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const clusterIndex, avdecc_local_entity_read_audio_cluster_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readAudioClusterDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, clusterIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClusterIndex const clusterIndex, la::avdecc::entity::model::AudioClusterDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_audio_cluster_descriptor(descriptor);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clusterIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readAudioMapDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const mapIndex, avdecc_local_entity_read_audio_map_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readAudioMapDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, mapIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::MapIndex const mapIndex, la::avdecc::entity::model::AudioMapDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_audio_map_descriptor(descriptor);
				auto m = la::avdecc::bindings::fromCppToC::make_audio_mappings(descriptor.mappings);
				auto mp = la::avdecc::bindings::fromCppToC::make_audio_mappings_pointer(m);
				d.mappings = mp.data();
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(mapIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_readClockDomainDescriptor_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const clockDomainIndex, avdecc_local_entity_read_clock_domain_descriptor_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.readClockDomainDescriptor(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, clockDomainIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClockDomainIndex const clockDomainIndex, la::avdecc::entity::model::ClockDomainDescriptor const& descriptor)
			{
				auto d = la::avdecc::bindings::fromCppToC::make_clock_domain_descriptor(descriptor);
				auto s = la::avdecc::bindings::fromCppToC::make_clock_sources(descriptor.clockSources);
				auto sp = la::avdecc::bindings::fromCppToC::make_clock_sources_pointer(s);
				d.clock_sources = sp.data();
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clockDomainIndex), &d);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setConfiguration_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_local_entity_set_configuration_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setConfiguration(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getConfiguration_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_get_configuration_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getConfiguration(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setStreamInputFormat_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_entity_model_stream_format_t const streamFormat, avdecc_local_entity_set_stream_input_format_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setStreamInputFormat(la::avdecc::UniqueIdentifier{ entityID }, streamIndex, la::avdecc::entity::model::StreamFormat{ streamFormat },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamFormat const streamFormat)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), streamFormat);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamInputFormat_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_get_stream_input_format_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamInputFormat(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamFormat const streamFormat)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), streamFormat);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setStreamOutputFormat_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_entity_model_stream_format_t const streamFormat, avdecc_local_entity_set_stream_output_format_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setStreamOutputFormat(la::avdecc::UniqueIdentifier{ entityID }, streamIndex, la::avdecc::entity::model::StreamFormat{ streamFormat },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamFormat const streamFormat)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), streamFormat);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamOutputFormat_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_get_stream_output_format_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamOutputFormat(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamFormat const streamFormat)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), streamFormat);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamPortInputAudioMap_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamPortIndex, avdecc_entity_model_descriptor_index_t const mapIndex, avdecc_local_entity_get_stream_port_input_audio_map_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamPortInputAudioMap(la::avdecc::UniqueIdentifier{ entityID }, streamPortIndex, mapIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamPortIndex const streamPortIndex, la::avdecc::entity::model::MapIndex const numberOfMaps, la::avdecc::entity::model::MapIndex const mapIndex, la::avdecc::entity::model::AudioMappings const& mappings)
			{
				auto m = la::avdecc::bindings::fromCppToC::make_audio_mappings(mappings);
				auto const mp = la::avdecc::bindings::fromCppToC::make_audio_mappings_pointer(m);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamPortIndex), static_cast<avdecc_entity_model_descriptor_type_t>(numberOfMaps), static_cast<avdecc_entity_model_descriptor_type_t>(mapIndex), mp.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamPortOutputAudioMap_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamPortIndex, avdecc_entity_model_descriptor_index_t const mapIndex, avdecc_local_entity_get_stream_port_output_audio_map_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamPortOutputAudioMap(la::avdecc::UniqueIdentifier{ entityID }, streamPortIndex, mapIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamPortIndex const streamPortIndex, la::avdecc::entity::model::MapIndex const numberOfMaps, la::avdecc::entity::model::MapIndex const mapIndex, la::avdecc::entity::model::AudioMappings const& mappings)
			{
				auto m = la::avdecc::bindings::fromCppToC::make_audio_mappings(mappings);
				auto const mp = la::avdecc::bindings::fromCppToC::make_audio_mappings_pointer(m);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamPortIndex), static_cast<avdecc_entity_model_descriptor_type_t>(numberOfMaps), static_cast<avdecc_entity_model_descriptor_type_t>(mapIndex), mp.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_addStreamPortInputAudioMappings_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamPortIndex, avdecc_entity_model_audio_mapping_cp const* const mappings, avdecc_local_entity_add_stream_port_input_audio_mappings_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		auto const m = la::avdecc::bindings::fromCToCpp::make_audio_mappings(mappings);
		obj.addStreamPortInputAudioMappings(la::avdecc::UniqueIdentifier{ entityID }, streamPortIndex, m,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamPortIndex const streamPortIndex, la::avdecc::entity::model::AudioMappings const& mappings)
			{
				auto m = la::avdecc::bindings::fromCppToC::make_audio_mappings(mappings);
				auto const mp = la::avdecc::bindings::fromCppToC::make_audio_mappings_pointer(m);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamPortIndex), mp.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_addStreamPortOutputAudioMappings_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamPortIndex, avdecc_entity_model_audio_mapping_cp const* const mappings, avdecc_local_entity_add_stream_port_output_audio_mappings_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		auto const m = la::avdecc::bindings::fromCToCpp::make_audio_mappings(mappings);
		obj.addStreamPortOutputAudioMappings(la::avdecc::UniqueIdentifier{ entityID }, streamPortIndex, m,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamPortIndex const streamPortIndex, la::avdecc::entity::model::AudioMappings const& mappings)
			{
				auto m = la::avdecc::bindings::fromCppToC::make_audio_mappings(mappings);
				auto const mp = la::avdecc::bindings::fromCppToC::make_audio_mappings_pointer(m);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamPortIndex), mp.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_removeStreamPortInputAudioMappings_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamPortIndex, avdecc_entity_model_audio_mapping_cp const* const mappings, avdecc_local_entity_remove_stream_port_input_audio_mappings_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		auto const m = la::avdecc::bindings::fromCToCpp::make_audio_mappings(mappings);
		obj.removeStreamPortInputAudioMappings(la::avdecc::UniqueIdentifier{ entityID }, streamPortIndex, m,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamPortIndex const streamPortIndex, la::avdecc::entity::model::AudioMappings const& mappings)
			{
				auto m = la::avdecc::bindings::fromCppToC::make_audio_mappings(mappings);
				auto const mp = la::avdecc::bindings::fromCppToC::make_audio_mappings_pointer(m);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamPortIndex), mp.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_removeStreamPortOutputAudioMappings_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamPortIndex, avdecc_entity_model_audio_mapping_cp const* const mappings, avdecc_local_entity_remove_stream_port_output_audio_mappings_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		auto const m = la::avdecc::bindings::fromCToCpp::make_audio_mappings(mappings);
		obj.removeStreamPortOutputAudioMappings(la::avdecc::UniqueIdentifier{ entityID }, streamPortIndex, m,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamPortIndex const streamPortIndex, la::avdecc::entity::model::AudioMappings const& mappings)
			{
				auto m = la::avdecc::bindings::fromCppToC::make_audio_mappings(mappings);
				auto const mp = la::avdecc::bindings::fromCppToC::make_audio_mappings_pointer(m);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamPortIndex), mp.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setStreamInputInfo_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_entity_model_stream_info_cp const info, avdecc_local_entity_set_stream_input_info_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		auto const i = la::avdecc::bindings::fromCToCpp::make_stream_info(info);
		obj.setStreamInputInfo(la::avdecc::UniqueIdentifier{ entityID }, streamIndex, i,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamInfo const& info)
			{
				auto const i = la::avdecc::bindings::fromCppToC::make_stream_info(info);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), &i);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setStreamOutputInfo_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_entity_model_stream_info_cp const info, avdecc_local_entity_set_stream_output_info_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		auto const i = la::avdecc::bindings::fromCToCpp::make_stream_info(info);
		obj.setStreamOutputInfo(la::avdecc::UniqueIdentifier{ entityID }, streamIndex, i,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamInfo const& info)
			{
				auto const i = la::avdecc::bindings::fromCppToC::make_stream_info(info);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), &i);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamInputInfo_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_get_stream_input_info_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamInputInfo(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamInfo const& info)
			{
				auto const i = la::avdecc::bindings::fromCppToC::make_stream_info(info);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), &i);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamOutputInfo_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_get_stream_output_info_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamOutputInfo(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::StreamInfo const& info)
			{
				auto const i = la::avdecc::bindings::fromCppToC::make_stream_info(info);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), &i);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setEntityName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_fixed_string_t const entityName, avdecc_local_entity_set_entity_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setEntityName(la::avdecc::UniqueIdentifier{ entityID }, la::avdecc::entity::model::AvdeccFixedString{ entityName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AvdeccFixedString const& entityName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), entityName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getEntityName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_get_entity_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getEntityName(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AvdeccFixedString const& entityName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), entityName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setEntityGroupName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_fixed_string_t const entityGroupName, avdecc_local_entity_set_entity_group_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setEntityGroupName(la::avdecc::UniqueIdentifier{ entityID }, la::avdecc::entity::model::AvdeccFixedString{ entityGroupName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AvdeccFixedString const& entityGroupName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), entityGroupName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getEntityGroupName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_get_entity_group_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getEntityGroupName(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AvdeccFixedString const& entityGroupName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), entityGroupName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setConfigurationName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_fixed_string_t const configurationName, avdecc_local_entity_set_configuration_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setConfigurationName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, la::avdecc::entity::model::AvdeccFixedString{ configurationName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::AvdeccFixedString const& configurationName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), configurationName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getConfigurationName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_local_entity_get_configuration_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getConfigurationName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::AvdeccFixedString const& configurationName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), configurationName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setAudioUnitName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const audioUnitIndex, avdecc_fixed_string_t const audioUnitName, avdecc_local_entity_set_audio_unit_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setAudioUnitName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, audioUnitIndex, la::avdecc::entity::model::AvdeccFixedString{ audioUnitName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::AudioUnitIndex const audioUnitIndex, la::avdecc::entity::model::AvdeccFixedString const& audioUnitName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t const>(audioUnitIndex), audioUnitName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getAudioUnitName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const audioUnitIndex, avdecc_local_entity_get_audio_unit_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getAudioUnitName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, audioUnitIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::AudioUnitIndex const audioUnitIndex, la::avdecc::entity::model::AvdeccFixedString const& audioUnitName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t const>(audioUnitIndex), audioUnitName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setStreamInputName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_fixed_string_t const streamInputName, avdecc_local_entity_set_stream_input_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setStreamInputName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, streamIndex, la::avdecc::entity::model::AvdeccFixedString{ streamInputName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::AvdeccFixedString const& streamInputName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), streamInputName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamInputName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_get_stream_input_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamInputName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::AvdeccFixedString const& streamInputName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), streamInputName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setStreamOutputName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_fixed_string_t const streamOutputName, avdecc_local_entity_set_stream_output_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setStreamOutputName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, streamIndex, la::avdecc::entity::model::AvdeccFixedString{ streamOutputName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::AvdeccFixedString const& streamOutputName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), streamOutputName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamOutputName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_get_stream_output_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamOutputName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::model::AvdeccFixedString const& streamOutputName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), streamOutputName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setAvbInterfaceName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const avbInterfaceIndex, avdecc_fixed_string_t const avbInterfaceName, avdecc_local_entity_set_avb_interface_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setAvbInterfaceName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, avbInterfaceIndex, la::avdecc::entity::model::AvdeccFixedString{ avbInterfaceName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::AvbInterfaceIndex const avbInterfaceIndex, la::avdecc::entity::model::AvdeccFixedString const& avbInterfaceName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(avbInterfaceIndex), avbInterfaceName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getAvbInterfaceName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const avbInterfaceIndex, avdecc_local_entity_get_avb_interface_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getAvbInterfaceName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, avbInterfaceIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::AvbInterfaceIndex const avbInterfaceIndex, la::avdecc::entity::model::AvdeccFixedString const& avbInterfaceName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(avbInterfaceIndex), avbInterfaceName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setClockSourceName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const clockSourceIndex, avdecc_fixed_string_t const clockSourceName, avdecc_local_entity_set_clock_source_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setClockSourceName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, clockSourceIndex, la::avdecc::entity::model::AvdeccFixedString{ clockSourceName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClockSourceIndex const clockSourceIndex, la::avdecc::entity::model::AvdeccFixedString const& clockSourceName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clockSourceIndex), clockSourceName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getClockSourceName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const clockSourceIndex, avdecc_local_entity_get_clock_source_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getClockSourceName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, clockSourceIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClockSourceIndex const clockSourceIndex, la::avdecc::entity::model::AvdeccFixedString const& clockSourceName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clockSourceIndex), clockSourceName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setMemoryObjectName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const memoryObjectIndex, avdecc_fixed_string_t const memoryObjectName, avdecc_local_entity_set_memory_object_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setMemoryObjectName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, memoryObjectIndex, la::avdecc::entity::model::AvdeccFixedString{ memoryObjectName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::MemoryObjectIndex const memoryObjectIndex, la::avdecc::entity::model::AvdeccFixedString const& memoryObjectName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(memoryObjectIndex), memoryObjectName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getMemoryObjectName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const memoryObjectIndex, avdecc_local_entity_get_memory_object_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getMemoryObjectName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, memoryObjectIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::MemoryObjectIndex const memoryObjectIndex, la::avdecc::entity::model::AvdeccFixedString const& memoryObjectName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(memoryObjectIndex), memoryObjectName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setAudioClusterName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const audioClusterIndex, avdecc_fixed_string_t const audioClusterName, avdecc_local_entity_set_audio_cluster_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setAudioClusterName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, audioClusterIndex, la::avdecc::entity::model::AvdeccFixedString{ audioClusterName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClusterIndex const audioClusterIndex, la::avdecc::entity::model::AvdeccFixedString const& audioClusterName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(audioClusterIndex), audioClusterName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getAudioClusterName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const audioClusterIndex, avdecc_local_entity_get_audio_cluster_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getAudioClusterName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, audioClusterIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClusterIndex const audioClusterIndex, la::avdecc::entity::model::AvdeccFixedString const& audioClusterName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(audioClusterIndex), audioClusterName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setClockDomainName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const clockDomainIndex, avdecc_fixed_string_t const clockDomainName, avdecc_local_entity_set_clock_domain_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setClockDomainName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, clockDomainIndex, la::avdecc::entity::model::AvdeccFixedString{ clockDomainName },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClockDomainIndex const clockDomainIndex, la::avdecc::entity::model::AvdeccFixedString const& clockDomainName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clockDomainIndex), clockDomainName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getClockDomainName_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const configurationIndex, avdecc_entity_model_descriptor_type_t const clockDomainIndex, avdecc_local_entity_get_clock_domain_name_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getClockDomainName(la::avdecc::UniqueIdentifier{ entityID }, configurationIndex, clockDomainIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ConfigurationIndex const configurationIndex, la::avdecc::entity::model::ClockDomainIndex const clockDomainIndex, la::avdecc::entity::model::AvdeccFixedString const& clockDomainName)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(configurationIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clockDomainIndex), clockDomainName.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setAudioUnitSamplingRate_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const audioUnitIndex, avdecc_entity_model_sampling_rate_t const samplingRate, avdecc_local_entity_set_audio_unit_sampling_rate_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setAudioUnitSamplingRate(la::avdecc::UniqueIdentifier{ entityID }, audioUnitIndex, la::avdecc::entity::model::SamplingRate{ samplingRate },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AudioUnitIndex const audioUnitIndex, la::avdecc::entity::model::SamplingRate const samplingRate)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t const>(audioUnitIndex), samplingRate.getValue());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getAudioUnitSamplingRate_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const audioUnitIndex, avdecc_local_entity_get_audio_unit_sampling_rate_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getAudioUnitSamplingRate(la::avdecc::UniqueIdentifier{ entityID }, audioUnitIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AudioUnitIndex const audioUnitIndex, la::avdecc::entity::model::SamplingRate const samplingRate)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t const>(audioUnitIndex), samplingRate.getValue());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setVideoClusterSamplingRate_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const videoClusterIndex, avdecc_entity_model_sampling_rate_t const samplingRate, avdecc_local_entity_set_video_cluster_sampling_rate_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setVideoClusterSamplingRate(la::avdecc::UniqueIdentifier{ entityID }, videoClusterIndex, la::avdecc::entity::model::SamplingRate{ samplingRate },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ClusterIndex const videoClusterIndex, la::avdecc::entity::model::SamplingRate const samplingRate)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(videoClusterIndex), samplingRate.getValue());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getVideoClusterSamplingRate_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const videoClusterIndex, avdecc_local_entity_get_video_cluster_sampling_rate_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getVideoClusterSamplingRate(la::avdecc::UniqueIdentifier{ entityID }, videoClusterIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ClusterIndex const videoClusterIndex, la::avdecc::entity::model::SamplingRate const samplingRate)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(videoClusterIndex), samplingRate.getValue());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setSensorClusterSamplingRate_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const sensorClusterIndex, avdecc_entity_model_sampling_rate_t const samplingRate, avdecc_local_entity_set_sensor_cluster_sampling_rate_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setSensorClusterSamplingRate(la::avdecc::UniqueIdentifier{ entityID }, sensorClusterIndex, la::avdecc::entity::model::SamplingRate{ samplingRate },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ClusterIndex const sensorClusterIndex, la::avdecc::entity::model::SamplingRate const samplingRate)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(sensorClusterIndex), samplingRate.getValue());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getSensorClusterSamplingRate_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const sensorClusterIndex, avdecc_local_entity_get_sensor_cluster_sampling_rate_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getSensorClusterSamplingRate(la::avdecc::UniqueIdentifier{ entityID }, sensorClusterIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ClusterIndex const sensorClusterIndex, la::avdecc::entity::model::SamplingRate const samplingRate)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(sensorClusterIndex), samplingRate.getValue());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_setClockSource_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const clockDomainIndex, avdecc_entity_model_descriptor_type_t const clockSourceIndex, avdecc_local_entity_set_clock_source_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.setClockSource(la::avdecc::UniqueIdentifier{ entityID }, clockDomainIndex, clockSourceIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ClockDomainIndex const clockDomainIndex, la::avdecc::entity::model::ClockSourceIndex const clockSourceIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(clockDomainIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clockSourceIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getClockSource_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const clockDomainIndex, avdecc_local_entity_get_clock_source_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getClockSource(la::avdecc::UniqueIdentifier{ entityID }, clockDomainIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ClockDomainIndex const clockDomainIndex, la::avdecc::entity::model::ClockSourceIndex const clockSourceIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(clockDomainIndex), static_cast<avdecc_entity_model_descriptor_type_t>(clockSourceIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_startStreamInput_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_start_stream_input_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.startStreamInput(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_startStreamOutput_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_start_stream_output_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.startStreamOutput(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_stopStreamInput_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_stop_stream_input_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.stopStreamInput(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_stopStreamOutput_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_stop_stream_output_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.stopStreamOutput(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getAvbInfo_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const avbInterfaceIndex, avdecc_local_entity_get_avb_info_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getAvbInfo(la::avdecc::UniqueIdentifier{ entityID }, avbInterfaceIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AvbInterfaceIndex const avbInterfaceIndex, la::avdecc::entity::model::AvbInfo const& info)
			{
				auto i = la::avdecc::bindings::fromCppToC::make_avb_info(info);
				auto m = la::avdecc::bindings::fromCppToC::make_msrp_mappings(info.mappings);
				auto mp = la::avdecc::bindings::fromCppToC::make_msrp_mappings_pointer(m);
				i.mappings = mp.data();
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(avbInterfaceIndex), &i);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getAsPath_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const avbInterfaceIndex, avdecc_local_entity_get_as_path_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getAsPath(la::avdecc::UniqueIdentifier{ entityID }, avbInterfaceIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AvbInterfaceIndex const avbInterfaceIndex, la::avdecc::entity::model::AsPath const& asPath)
			{
				auto path = la::avdecc::bindings::fromCppToC::make_as_path(asPath);
				auto p = la::avdecc::bindings::fromCppToC::make_path_sequence(asPath.sequence);
				auto pp = la::avdecc::bindings::fromCppToC::make_path_sequence_pointer(p);
				path.sequence = pp.data();
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(avbInterfaceIndex), &path);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getEntityCounters_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_get_entity_counters_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getEntityCounters(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::EntityCounterValidFlags const validCounters, la::avdecc::entity::model::DescriptorCounters const& counters)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), validCounters.value(), counters.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getAvbInterfaceCounters_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const avbInterfaceIndex, avdecc_local_entity_get_avb_interface_counters_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getAvbInterfaceCounters(la::avdecc::UniqueIdentifier{ entityID }, avbInterfaceIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::AvbInterfaceIndex const avbInterfaceIndex, la::avdecc::entity::AvbInterfaceCounterValidFlags const validCounters, la::avdecc::entity::model::DescriptorCounters const& counters)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(avbInterfaceIndex), validCounters.value(), counters.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getClockDomainCounters_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const clockDomainIndex, avdecc_local_entity_get_clock_domain_counters_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getClockDomainCounters(la::avdecc::UniqueIdentifier{ entityID }, clockDomainIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::ClockDomainIndex const clockDomainIndex, la::avdecc::entity::ClockDomainCounterValidFlags const validCounters, la::avdecc::entity::model::DescriptorCounters const& counters)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(clockDomainIndex), validCounters.value(), counters.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamInputCounters_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_get_stream_input_counters_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamInputCounters(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::StreamInputCounterValidFlags const validCounters, la::avdecc::entity::model::DescriptorCounters const& counters)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), validCounters.value(), counters.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getStreamOutputCounters_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_entity_model_descriptor_type_t const streamIndex, avdecc_local_entity_get_stream_output_counters_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getStreamOutputCounters(la::avdecc::UniqueIdentifier{ entityID }, streamIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::AemCommandStatus const status, la::avdecc::entity::model::StreamIndex const streamIndex, la::avdecc::entity::StreamOutputCounterValidFlags const validCounters, la::avdecc::entity::model::DescriptorCounters const& counters)
			{
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_aem_command_status_t>(status), static_cast<avdecc_entity_model_descriptor_type_t>(streamIndex), validCounters.value(), counters.data());
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

/* Enumeration and Control Protocol (AECP) MVU (Milan Vendor Unique) */

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getMilanInfo_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_unique_identifier_t const entityID, avdecc_local_entity_get_milan_info_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getMilanInfo(la::avdecc::UniqueIdentifier{ entityID },
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::UniqueIdentifier const entityID, la::avdecc::entity::LocalEntity::MvuCommandStatus const status, la::avdecc::entity::model::MilanInfo const& info)
			{
				auto i = la::avdecc::bindings::fromCppToC::make_milan_info(info);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), entityID, static_cast<avdecc_local_entity_mvu_command_status_t>(status), &i);
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

/* Connection Management Protocol (ACMP) */

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_connectStream_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_entity_model_stream_identification_cp const talkerStream, avdecc_entity_model_stream_identification_cp const listenerStream, avdecc_local_entity_connect_stream_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.connectStream(la::avdecc::bindings::fromCToCpp::make_stream_identification(talkerStream), la::avdecc::bindings::fromCToCpp::make_stream_identification(listenerStream),
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::entity::model::StreamIdentification const& talkerStream, la::avdecc::entity::model::StreamIdentification const& listenerStream, std::uint16_t const connectionCount, la::avdecc::entity::ConnectionFlags const flags, la::avdecc::entity::LocalEntity::ControlStatus const status)
			{
				auto ts = la::avdecc::bindings::fromCppToC::make_stream_identification(talkerStream);
				auto ls = la::avdecc::bindings::fromCppToC::make_stream_identification(listenerStream);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), &ts, &ls, static_cast<unsigned short>(connectionCount), static_cast<avdecc_entity_connection_flags_t>(flags.value()), static_cast<avdecc_local_entity_control_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_disconnectStream_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_entity_model_stream_identification_cp const talkerStream, avdecc_entity_model_stream_identification_cp const listenerStream, avdecc_local_entity_disconnect_stream_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.disconnectStream(la::avdecc::bindings::fromCToCpp::make_stream_identification(talkerStream), la::avdecc::bindings::fromCToCpp::make_stream_identification(listenerStream),
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::entity::model::StreamIdentification const& talkerStream, la::avdecc::entity::model::StreamIdentification const& listenerStream, std::uint16_t const connectionCount, la::avdecc::entity::ConnectionFlags const flags, la::avdecc::entity::LocalEntity::ControlStatus const status)
			{
				auto ts = la::avdecc::bindings::fromCppToC::make_stream_identification(talkerStream);
				auto ls = la::avdecc::bindings::fromCppToC::make_stream_identification(listenerStream);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), &ts, &ls, static_cast<unsigned short>(connectionCount), static_cast<avdecc_entity_connection_flags_t>(flags.value()), static_cast<avdecc_local_entity_control_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_disconnectTalkerStream_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_entity_model_stream_identification_cp const talkerStream, avdecc_entity_model_stream_identification_cp const listenerStream, avdecc_local_entity_disconnect_talker_stream_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.disconnectTalkerStream(la::avdecc::bindings::fromCToCpp::make_stream_identification(talkerStream), la::avdecc::bindings::fromCToCpp::make_stream_identification(listenerStream),
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::entity::model::StreamIdentification const& talkerStream, la::avdecc::entity::model::StreamIdentification const& listenerStream, std::uint16_t const connectionCount, la::avdecc::entity::ConnectionFlags const flags, la::avdecc::entity::LocalEntity::ControlStatus const status)
			{
				auto ts = la::avdecc::bindings::fromCppToC::make_stream_identification(talkerStream);
				auto ls = la::avdecc::bindings::fromCppToC::make_stream_identification(listenerStream);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), &ts, &ls, static_cast<unsigned short>(connectionCount), static_cast<avdecc_entity_connection_flags_t>(flags.value()), static_cast<avdecc_local_entity_control_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getTalkerStreamState_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_entity_model_stream_identification_cp const talkerStream, avdecc_local_entity_get_talker_stream_state_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getTalkerStreamState(la::avdecc::bindings::fromCToCpp::make_stream_identification(talkerStream),
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::entity::model::StreamIdentification const& talkerStream, la::avdecc::entity::model::StreamIdentification const& listenerStream, std::uint16_t const connectionCount, la::avdecc::entity::ConnectionFlags const flags, la::avdecc::entity::LocalEntity::ControlStatus const status)
			{
				auto ts = la::avdecc::bindings::fromCppToC::make_stream_identification(talkerStream);
				auto ls = la::avdecc::bindings::fromCppToC::make_stream_identification(listenerStream);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), &ts, &ls, static_cast<unsigned short>(connectionCount), static_cast<avdecc_entity_connection_flags_t>(flags.value()), static_cast<avdecc_local_entity_control_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getListenerStreamState_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_entity_model_stream_identification_cp const listenerStream, avdecc_local_entity_get_listener_stream_state_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getListenerStreamState(la::avdecc::bindings::fromCToCpp::make_stream_identification(listenerStream),
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::entity::model::StreamIdentification const& talkerStream, la::avdecc::entity::model::StreamIdentification const& listenerStream, std::uint16_t const connectionCount, la::avdecc::entity::ConnectionFlags const flags, la::avdecc::entity::LocalEntity::ControlStatus const status)
			{
				auto ts = la::avdecc::bindings::fromCppToC::make_stream_identification(talkerStream);
				auto ls = la::avdecc::bindings::fromCppToC::make_stream_identification(listenerStream);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), &ts, &ls, static_cast<unsigned short>(connectionCount), static_cast<avdecc_entity_connection_flags_t>(flags.value()), static_cast<avdecc_local_entity_control_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}

LA_AVDECC_BINDINGS_C_API avdecc_local_entity_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_LocalEntity_getTalkerStreamConnection_block(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle, avdecc_entity_model_stream_identification_cp const talkerStream, unsigned short const connectionIndex, avdecc_local_entity_get_talker_stream_connection_block const onResultBlock)
{
	auto onResult = CAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getAggregateEntity(handle);
		obj.getTalkerStreamConnection(la::avdecc::bindings::fromCToCpp::make_stream_identification(talkerStream), connectionIndex,
			[handle, onResult](la::avdecc::entity::controller::Interface const* const /*controller*/, la::avdecc::entity::model::StreamIdentification const& talkerStream, la::avdecc::entity::model::StreamIdentification const& listenerStream, std::uint16_t const connectionCount, la::avdecc::entity::ConnectionFlags const flags, la::avdecc::entity::LocalEntity::ControlStatus const status)
			{
				auto ts = la::avdecc::bindings::fromCppToC::make_stream_identification(talkerStream);
				auto ls = la::avdecc::bindings::fromCppToC::make_stream_identification(listenerStream);
				la::avdecc::utils::invokeProtectedHandler(onResult, static_cast<LA_AVDECC_LOCAL_ENTITY_HANDLE>(handle), &ts, &ls, static_cast<unsigned short>(connectionCount), static_cast<avdecc_entity_connection_flags_t>(flags.value()), static_cast<avdecc_local_entity_control_status_t>(status));
			});
	}
	catch (...)
	{
		return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_invalid_entity_handle);
	}

	return static_cast<avdecc_local_entity_error_t>(avdecc_local_entity_error_no_error);
}
