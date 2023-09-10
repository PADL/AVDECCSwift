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

import AVDECCSwift
import CAVDECC
import Foundation

@main
public final class Discovery: ProtocolInterfaceObserver {
    public static func main() throws {
        if CommandLine.arguments.count != 2 {
            print("Usage: \(CommandLine.arguments[0]) [interface]")
            exit(1)
        }
        do {
            _ = try Discovery(interfaceID: CommandLine.arguments[1])
        } catch {
            debugPrint("failed to initialize AVDECC: \(error)")
            exit(2)
        }

        RunLoop.main.run()
    }

    let executor = Executor.shared
    let protocolInterface: ProtocolInterface
    var localEntity: LocalEntity?

    init(interfaceID: String) throws {
        protocolInterface = try ProtocolInterface(interfaceID: interfaceID)
        protocolInterface.observer = self
        try protocolInterface.discoverRemoteEntities()
    }

    public func onTransportError(_: ProtocolInterface) {
        debugPrint("transport error")
    }

    public func onLocalEntityOnline(_ protocolInterface: ProtocolInterface, _ entity: Entity) {
        debugPrint("local entity \(entity) online")
        localEntity = try? LocalEntity(protocolInterface: protocolInterface, entity: entity)
        debugPrint("initialized entity \(localEntity!)")
    }

    public func onLocalEntityOffline(_: ProtocolInterface, id: UniqueIdentifier) {
        debugPrint("local entity \(id) offline")
        if id == localEntity?.entity.entityID {
            localEntity = nil
        }
    }

    public func onLocalEntityUpdated(_: ProtocolInterface, _ entity: Entity) {
        debugPrint("local entity \(entity) updated")
    }

    public func onRemoteEntityOnline(_: ProtocolInterface, _ entity: Entity) {
        debugPrint("remote entity \(entity) online")
    }

    public func onRemoteEntityOffline(_: ProtocolInterface, id: UniqueIdentifier) {
        debugPrint("remote entity \(id) offline")
    }

    public func onRemoteEntityUpdated(_: ProtocolInterface, _ entity: Entity) {
        debugPrint("remote entity \(entity) updated")
    }

    public func onAecpAemCommand(_: ProtocolInterface, pdu: avdecc_protocol_aem_aecpdu_t) {}
    public func onAecpAemUnsolicitedResponse(_: ProtocolInterface, pdu: avdecc_protocol_aem_aecpdu_t) {}
    public func onAecpAemIdentifyNotification(_: ProtocolInterface, pdu: avdecc_protocol_aem_aecpdu_t) {}

    public func onAcmpCommand(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t) {}
    public func onAcmpResponse(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t) {}

    public func onAdpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_adpdu_t) {}
    public func onAemAecpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_aem_aecpdu_t) {}
    public func onMvuAecpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_mvu_aecpdu_t) {}
    public func onAcmpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t) {}
}
