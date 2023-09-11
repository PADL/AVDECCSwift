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

import AsyncAlgorithms
import AVDECCSwift
import CxxAVDECC
import Foundation

@main
public actor Discovery: ProtocolInterfaceObserver {
    public static func main() throws {
        if CommandLine.arguments.count != 2 {
            print("Usage: \(CommandLine.arguments[0]) [interface]")
            exit(1)
        }

        let discovery: Discovery

        do {
            discovery = try Discovery(interfaceID: CommandLine.arguments[1])
        } catch {
            debugPrint("failed to initialize AVDECC library: \(error)")
            exit(2)
        }

        Task {
            do {
                try await discovery.localEntity_test()
            } catch {
                debugPrint("local entity test failed with \(error)")
            }
        }

        RunLoop.main.run()
    }

    private let protocolInterface: ProtocolInterface
    private let entitiesChannel = AsyncChannel<Entity>()
    private let progID = UInt16(5)

    init(interfaceID: String) throws {
        protocolInterface = try ProtocolInterface(interfaceID: interfaceID)
        protocolInterface.observer = self
    }

    func localEntity_test() async throws {
        var commonInformation = EntityCommonInformation()
        commonInformation.entity_id = try protocolInterface.getDynamicEID()
        // FIXME: provide accessors to avoid needing to access rawValue
        commonInformation
            .controller_capabilities = UInt16(
                avdecc_entity_controller_capabilities_implemented
                    .rawValue
            )

        var interfaceInfo = EntityInterfaceInformation()
        interfaceInfo.mac_address = try protocolInterface.macAddress

        let entity = Entity(
            commonInformation: commonInformation,
            interfacesInformation: [interfaceInfo]
        )
        let localEntity = try LocalEntity(protocolInterface: protocolInterface, entity: entity)

        for await entity in entitiesChannel {
            let entityDescriptor = try await localEntity.readEntityDescriptor(id: entity.entityID)
            debugPrint("read entity descriptor: \(entityDescriptor) for entity \(entity.entityID)")
        }

        try? protocolInterface.releaseDynamicEID(commonInformation.entity_id)
    }

    public nonisolated func onTransportError(_: ProtocolInterface) {
        debugPrint("transport error")
    }

    public nonisolated func onLocalEntityOnline(
        _ protocolInterface: ProtocolInterface,
        _ entity: Entity
    ) {
        debugPrint("local entity \(entity) online")
    }

    public nonisolated func onLocalEntityOffline(_: ProtocolInterface, id: UniqueIdentifier) {
        debugPrint("local entity \(id) offline")
    }

    public nonisolated func onLocalEntityUpdated(_: ProtocolInterface, _ entity: Entity) {
        debugPrint("local entity \(entity) updated")
    }

    public nonisolated func onRemoteEntityOnline(_: ProtocolInterface, _ entity: Entity) {
        debugPrint("remote entity \(entity) online")
        Task {
            await entitiesChannel.send(entity)
        }
    }

    public nonisolated func onRemoteEntityOffline(_: ProtocolInterface, id: UniqueIdentifier) {
        debugPrint("remote entity \(id) offline")
    }

    public nonisolated func onRemoteEntityUpdated(_: ProtocolInterface, _ entity: Entity) {
        debugPrint("remote entity \(entity) updated")
    }

    public nonisolated func onAecpAemCommand(
        _: ProtocolInterface,
        pdu: avdecc_protocol_aem_aecpdu_t
    ) {}
    public nonisolated func onAecpAemUnsolicitedResponse(
        _: ProtocolInterface,
        pdu: avdecc_protocol_aem_aecpdu_t
    ) {}
    public nonisolated func onAecpAemIdentifyNotification(
        _: ProtocolInterface,
        pdu: avdecc_protocol_aem_aecpdu_t
    ) {}

    public nonisolated func onAcmpCommand(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t) {}
    public nonisolated func onAcmpResponse(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t) {}

    public nonisolated func onAdpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_adpdu_t) {}
    public nonisolated func onAemAecpduReceived(
        _: ProtocolInterface,
        pdu: avdecc_protocol_aem_aecpdu_t
    ) {}
    public nonisolated func onMvuAecpduReceived(
        _: ProtocolInterface,
        pdu: avdecc_protocol_mvu_aecpdu_t
    ) {}
    public nonisolated func onAcmpduReceived(_: ProtocolInterface, pdu: avdecc_protocol_acmpdu_t) {}
}
