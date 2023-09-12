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
* @file protocolInterface_c_block.cpp
* @author Christophe Calmejane
* @brief C block bindings for la::avdecc::protocol::ProtocolInterface.
*/

#include "CxxAVDECCBlockShimsInternal.hpp"

extern la::avdecc::bindings::HandleManager<la::avdecc::protocol::ProtocolInterface::UniquePointer> s_ProtocolInterfaceManager;

LA_AVDECC_BINDINGS_C_API avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_ProtocolInterface_sendAemAecpCommand_block(LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle, avdecc_protocol_aem_aecpdu_cp const aecpdu, avdecc_protocol_interfaces_send_aem_aecp_command_block const onResultBlock)
{
	auto onResult = CxxAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getProtocolInterface(handle);
		return la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(obj.sendAecpCommand(la::avdecc::bindings::fromCToCpp::make_aem_aecpdu_unique(aecpdu),
			[onResult](la::avdecc::protocol::Aecpdu const* const response, la::avdecc::protocol::ProtocolInterface::Error const error)
			{
				if (!error)
				{
					if (AVDECC_ASSERT_WITH_RET(response->getMessageType() == la::avdecc::protocol::AecpMessageType::AemResponse, "Received AECP is NOT an AEM Response"))
					{
						auto aecpdu = la::avdecc::bindings::fromCppToC::make_aem_aecpdu(static_cast<la::avdecc::protocol::AemAecpdu const&>(*response));
						la::avdecc::utils::invokeProtectedHandler(onResult, &aecpdu, la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(error));
					}
					else
					{
						la::avdecc::utils::invokeProtectedHandler(onResult, nullptr, static_cast<avdecc_protocol_interface_error_t>(avdecc_protocol_interface_error_internal_error));
					}
				}
				else
				{
					la::avdecc::utils::invokeProtectedHandler(onResult, nullptr, la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(error));
				}
			}));
	}
	catch (...)
	{
		return static_cast<avdecc_protocol_interface_error_t>(avdecc_protocol_interface_error_internal_error);
	}
}

LA_AVDECC_BINDINGS_C_API avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_ProtocolInterface_sendMvuAecpCommand_block(LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle, avdecc_protocol_mvu_aecpdu_cp const aecpdu, avdecc_protocol_interfaces_send_mvu_aecp_command_block const onResultBlock)
{
	auto onResult = CxxAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getProtocolInterface(handle);
		return la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(obj.sendAecpCommand(la::avdecc::bindings::fromCToCpp::make_mvu_aecpdu_unique(aecpdu),
			[onResult](la::avdecc::protocol::Aecpdu const* const response, la::avdecc::protocol::ProtocolInterface::Error const error)
			{
				if (!error)
				{
					if (AVDECC_ASSERT_WITH_RET(response->getMessageType() == la::avdecc::protocol::AecpMessageType::VendorUniqueResponse, "Received AECP is NOT a VU Response"))
					{
						auto const& vuaecpdu = static_cast<la::avdecc::protocol::VuAecpdu const&>(*response);
						if (AVDECC_ASSERT_WITH_RET(vuaecpdu.getProtocolIdentifier() == la::avdecc::protocol::MvuAecpdu::ProtocolID, "Received AECP is NOT a MVU Response"))
						{
							auto aecpdu = la::avdecc::bindings::fromCppToC::make_mvu_aecpdu(static_cast<la::avdecc::protocol::MvuAecpdu const&>(*response));
							la::avdecc::utils::invokeProtectedHandler(onResult, &aecpdu, la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(error));
						}
						else
						{
							la::avdecc::utils::invokeProtectedHandler(onResult, nullptr, static_cast<avdecc_protocol_interface_error_t>(avdecc_protocol_interface_error_internal_error));
						}
					}
					else
					{
						la::avdecc::utils::invokeProtectedHandler(onResult, nullptr, static_cast<avdecc_protocol_interface_error_t>(avdecc_protocol_interface_error_internal_error));
					}
				}
				else
				{
					la::avdecc::utils::invokeProtectedHandler(onResult, nullptr, la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(error));
				}
			}));
	}
	catch (...)
	{
		return static_cast<avdecc_protocol_interface_error_t>(avdecc_protocol_interface_error_internal_error);
	}
}

LA_AVDECC_BINDINGS_C_API avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_ProtocolInterface_sendAcmpCommand_block(LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle, avdecc_protocol_acmpdu_cp const acmpdu, avdecc_protocol_interfaces_send_acmp_command_block const onResultBlock)
{
	auto onResult = CxxAVDECC::Block(onResultBlock);

	try
	{
		auto& obj = la::avdecc::bindings::getProtocolInterface(handle);
		return la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(obj.sendAcmpCommand(la::avdecc::bindings::fromCToCpp::make_acmpdu_unique(acmpdu),
			[onResult](la::avdecc::protocol::Acmpdu const* const response, la::avdecc::protocol::ProtocolInterface::Error const error)
			{
				if (!error)
				{
					auto acmpdu = la::avdecc::bindings::fromCppToC::make_acmpdu(*response);
					la::avdecc::utils::invokeProtectedHandler(onResult, &acmpdu, la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(error));
				}
				else
				{
					la::avdecc::utils::invokeProtectedHandler(onResult, nullptr, la::avdecc::bindings::fromCppToC::convertProtocolInterfaceErrorCode(error));
				}
			}));
	}
	catch (...)
	{
		return static_cast<avdecc_protocol_interface_error_t>(avdecc_protocol_interface_error_internal_error);
	}
}
