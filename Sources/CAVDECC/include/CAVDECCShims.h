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

#include "../avdecc/include/la/avdecc/avdecc.h"

// ACMP

typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^ avdecc_protocol_interfaces_send_acmp_command_block)(avdecc_protocol_acmpdu_cp const response, avdecc_protocol_interface_error_t const error);

LA_AVDECC_BINDINGS_C_API avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_ProtocolInterface_sendAcmpCommand_Block(LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle, avdecc_protocol_acmpdu_cp const acmpdu, avdecc_protocol_interfaces_send_acmp_command_block const onResult);

// AEM AECP

typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^ avdecc_protocol_interfaces_send_aem_aecp_command_block)(avdecc_protocol_aem_aecpdu_cp const response, avdecc_protocol_interface_error_t const error);

LA_AVDECC_BINDINGS_C_API avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_ProtocolInterface_sendAemAecpCommand_Block(LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle, avdecc_protocol_aem_aecpdu_cp const aecpu, avdecc_protocol_interfaces_send_aem_aecp_command_block const onResult);

// MVU AECP

typedef void(LA_AVDECC_BINDINGS_C_CALL_CONVENTION ^ avdecc_protocol_interfaces_send_mvu_aecp_command_block)(avdecc_protocol_mvu_aecpdu_cp const response, avdecc_protocol_interface_error_t const error);

LA_AVDECC_BINDINGS_C_API avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_ProtocolInterface_sendMvuAecpCommand_Block(LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle, avdecc_protocol_mvu_aecpdu_cp const aecpu, avdecc_protocol_interfaces_send_mvu_aecp_command_block const onResult);

