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
#include <mutex>
#include <utility>

#ifdef __APPLE__
#include <Block.h>
#else
#include <Block/Block.h>
#endif  

#include <CAVDECCShims.h>

static std::map<std::pair<avdecc_unique_identifier_t, avdecc_protocol_acmp_sequence_id_t>, avdecc_protocol_interfaces_send_acmp_command_block>
acmpCommandBlocks;
static std::mutex acmpCommandBlocksLock;

static void LA_AVDECC_ProtocolInterface_sendAcmpCommand_Thunk(avdecc_protocol_acmpdu_cp const response, avdecc_protocol_interface_error_t const error) {
    auto pair = std::make_pair(response->controller_entity_id, response->sequence_id);

    acmpCommandBlocksLock.lock();
    auto block = (avdecc_protocol_interfaces_send_acmp_command_block)acmpCommandBlocks[pair];
    acmpCommandBlocks.erase(pair);
    acmpCommandBlocksLock.unlock();

    block(response, error);
    _Block_release(block);
}

LA_AVDECC_BINDINGS_C_API avdecc_protocol_interface_error_t LA_AVDECC_BINDINGS_C_CALL_CONVENTION LA_AVDECC_ProtocolInterface_sendAcmpCommand_Block(LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle, avdecc_protocol_acmpdu_cp const acmpdu, avdecc_protocol_interfaces_send_acmp_command_block const onResult) {
    auto error = LA_AVDECC_ProtocolInterface_sendAcmpCommand(handle, acmpdu, LA_AVDECC_ProtocolInterface_sendAcmpCommand_Thunk);

    if (error != avdecc_protocol_interface_error_no_error)
        return error;

    // FIXME: race condition here?
    auto pair = std::make_pair(acmpdu->controller_entity_id, acmpdu->sequence_id);
    assert(acmpdu->sequence_id != 0);

    acmpCommandBlocksLock.lock();
    acmpCommandBlocks[pair] = (avdecc_protocol_interfaces_send_acmp_command_block)_Block_copy(onResult);
    acmpCommandBlocksLock.unlock();

    return avdecc_protocol_interface_error_no_error;
}

