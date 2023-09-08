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

#include <assert.h>

#include <cstddef>
#include <map>
#include <utility>

#ifdef __APPLE__
#include <Block.h>
#else
#include <Block/Block.h>
#endif

#include <CAVDECCShims.h>

// FIXME: can we template this?

static std::map<
    std::pair<avdecc_unique_identifier_t, avdecc_protocol_acmp_sequence_id_t>,
    avdecc_protocol_interfaces_send_acmp_command_block>
    acmpCommandBlocks;

static void LA_AVDECC_ProtocolInterface_sendAcmpCommand_Thunk(
    avdecc_protocol_acmpdu_cp const response,
    avdecc_protocol_interface_error_t const error) {
    auto pair =
        std::make_pair(response->controller_entity_id, response->sequence_id);
    auto block = (avdecc_protocol_interfaces_send_acmp_command_block)
        acmpCommandBlocks[pair];
    if (block) {
        acmpCommandBlocks.erase(pair);
        block(response, error);
        _Block_release(block);
    }
}

LA_AVDECC_BINDINGS_C_API
    avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_ProtocolInterface_sendAcmpCommand_Block(
        LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle,
        avdecc_protocol_acmpdu_cp const acmPdu,
        avdecc_protocol_interfaces_send_acmp_command_block const onResult) {
    auto error = LA_AVDECC_ProtocolInterface_sendAcmpCommand(
        handle, acmPdu, LA_AVDECC_ProtocolInterface_sendAcmpCommand_Thunk);

    if (error != avdecc_protocol_interface_error_no_error)
        return error;

    // FIXME: race condition here, what happens if we receive a reply before
    // registering callback?
    auto pair =
        std::make_pair(acmPdu->controller_entity_id, acmPdu->sequence_id);
    assert(acmPdu->sequence_id != 0);

    acmpCommandBlocks[pair] =
        (avdecc_protocol_interfaces_send_acmp_command_block)_Block_copy(
            onResult);

    return avdecc_protocol_interface_error_no_error;
}

static std::map<
    std::pair<avdecc_unique_identifier_t, avdecc_protocol_aecp_sequence_id_t>,
    avdecc_protocol_interfaces_send_aem_aecp_command_block>
    aemAecpCommandBlocks;

static void LA_AVDECC_ProtocolInterface_sendAemAecpCommand_Thunk(
    avdecc_protocol_aem_aecpdu_cp const response,
    avdecc_protocol_interface_error_t const error) {
    auto pair =
        std::make_pair(response->controller_entity_id, response->sequence_id);
    auto block = (avdecc_protocol_interfaces_send_aem_aecp_command_block)
        aemAecpCommandBlocks[pair];
    if (block) {
        aemAecpCommandBlocks.erase(pair);
        block(response, error);
        _Block_release(block);
    }
}

LA_AVDECC_BINDINGS_C_API
    avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_ProtocolInterface_sendAemAecpCommand_Block(
        LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle,
        avdecc_protocol_aem_aecpdu_cp const aemAecPdu,
        avdecc_protocol_interfaces_send_aem_aecp_command_block const onResult) {
    auto error = LA_AVDECC_ProtocolInterface_sendAemAecpCommand(
        handle, aemAecPdu, LA_AVDECC_ProtocolInterface_sendAemAecpCommand_Thunk);

    if (error != avdecc_protocol_interface_error_no_error)
        return error;

    // FIXME: race condition here, what happens if we receive a reply before
    // registering callback?
    auto pair =
        std::make_pair(aemAecPdu->controller_entity_id, aemAecPdu->sequence_id);
    assert(aemAecPdu->sequence_id != 0);

    aemAecpCommandBlocks[pair] =
        (avdecc_protocol_interfaces_send_aem_aecp_command_block)_Block_copy(
            onResult);

    return avdecc_protocol_interface_error_no_error;
}

static std::map<
    std::pair<avdecc_unique_identifier_t, avdecc_protocol_aecp_sequence_id_t>,
    avdecc_protocol_interfaces_send_mvu_aecp_command_block>
    mvuAecpCommandBlocks;

static void LA_AVDECC_ProtocolInterface_sendMvuAecpCommand_Thunk(
    avdecc_protocol_mvu_aecpdu_cp const response,
    avdecc_protocol_interface_error_t const error) {
    auto pair =
        std::make_pair(response->controller_entity_id, response->sequence_id);
    auto block = (avdecc_protocol_interfaces_send_mvu_aecp_command_block)
        mvuAecpCommandBlocks[pair];
    if (block) {
        mvuAecpCommandBlocks.erase(pair);
        block(response, error);
        _Block_release(block);
    }
}

LA_AVDECC_BINDINGS_C_API
    avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION
    LA_AVDECC_ProtocolInterface_sendMvuAecpCommand_Block(
        LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle,
        avdecc_protocol_mvu_aecpdu_cp const mvuAecPdu,
        avdecc_protocol_interfaces_send_mvu_aecp_command_block const onResult) {
    auto error = LA_AVDECC_ProtocolInterface_sendMvuAecpCommand(
        handle, mvuAecPdu, LA_AVDECC_ProtocolInterface_sendMvuAecpCommand_Thunk);

    if (error != avdecc_protocol_interface_error_no_error)
        return error;

    // FIXME: race condition here, what happens if we receive a reply before
    // registering callback?
    auto pair =
        std::make_pair(mvuAecPdu->controller_entity_id, mvuAecPdu->sequence_id);
    assert(mvuAecPdu->sequence_id != 0);

    mvuAecpCommandBlocks[pair] =
        (avdecc_protocol_interfaces_send_mvu_aecp_command_block)_Block_copy(
            onResult);

    return avdecc_protocol_interface_error_no_error;
}
