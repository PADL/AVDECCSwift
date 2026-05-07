/*
 * Copyright (C) 2023-2026, PADL Software Pty Ltd
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
import Dispatch
import Foundation
import Logging
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

@main
public final class Discovery: ProtocolInterfaceObserver, @unchecked Sendable {
  public static func main() async throws {
    // Route everything through a stderr StreamLogHandler at .trace so
    // both Swift-side and la_avdecc-side log lines surface. swift-log
    // defaults to .info and an opaque default handler on Linux; without
    // this the AvdeccLogger bridge produces no visible output.
    LoggingSystem.bootstrap { label in
      var h = StreamLogHandler.standardError(label: label)
      h.logLevel = .trace
      return h
    }

    if CommandLine.arguments.count != 2 {
      print("Usage: \(CommandLine.arguments[0]) [interface|/dev/ttyXXX]")
      exit(1)
    }

    let discovery: Discovery
    do {
      let interfaceID = CommandLine.arguments[1]
      if interfaceID.hasPrefix("/") {
        discovery = try Discovery(type: .serial, interfaceID: interfaceID)
      } else {
        discovery = try Discovery(type: .pCap, interfaceID: interfaceID)
      }
    } catch {
      debugPrint("failed to initialize AVDECC library: \(error)")
      exit(2)
    }

    do {
      try await discovery.run()
    } catch {
      debugPrint("local entity test failed with \(error)")
    }
  }

  private let protocolInterface: ProtocolInterface
  private let entitiesChannel = AsyncChannel<UniqueIdentifier>()
  // Hold the dispatch sources so they outlive `init` — destruction
  // tears down the kernel-level signal hook.
  private var signalSources: [DispatchSourceSignal] = []
  // Forwards la_avdecc's internal log to swift-log. Must outlive the
  // ProtocolInterface so transport-error / state-machine warnings
  // surface on stderr.
  private let avdeccLogger: AvdeccLogger

  init(type: ProtocolInterfaceType, interfaceID: String) throws {
    avdeccLogger = AvdeccLogger(forwardingTo: Logger(label: "avdecc"), level: .debug)
    protocolInterface = try ProtocolInterface(type: type, interfaceID: interfaceID)
    protocolInterface.observer = self
    installShutdownHandlers()
  }

  // SIGINT/SIGTERM: finish the entitiesChannel so the for-await loop in
  // `run()` exits naturally, letting the explicit close() chain run.
  // Without this, Ctrl-C terminates the process mid-flight and the
  // pcap capture buffer + 4 la_avdecc threads (Executor, WatchDog,
  // state-machine, dispatch worker) leak. `signal(SIGINT, SIG_IGN)`
  // is required first because libdispatch's signal source competes
  // with the default disposition.
  private func installShutdownHandlers() {
    for sig in [SIGINT, SIGTERM] {
      signal(sig, SIG_IGN)
      let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
      src.setEventHandler { [weak self] in
        self?.entitiesChannel.finish()
      }
      src.resume()
      signalSources.append(src)
    }
  }

  func run() async throws {
    let entityID = try protocolInterface.getDynamicEID()
    let localEntity = try LocalEntity(protocolInterface: protocolInterface, entityID: entityID)

    for await remoteEntityID in entitiesChannel {
      Task {
        do {
          let descriptor = try await localEntity.readEntityDescriptor(id: remoteEntityID)
          debugPrint("entity \(remoteEntityID) descriptor: \(descriptor)")
        } catch {
          debugPrint("readEntityDescriptor failed for \(remoteEntityID): \(error)")
        }

        if let asPath = try? await localEntity.getAsPath(id: remoteEntityID, avbInterfaceIndex: 0) {
          debugPrint("gPTP AS path: \(asPath)")
        }

        if let avbInfo = try? await localEntity.getAvbInfo(id: remoteEntityID, avbInterfaceIndex: 0) {
          debugPrint("AVB info: \(avbInfo)")
        }
      }
    }

    // Channel finished (SIGINT/SIGTERM); release entity ID and tear
    // down both wrappers explicitly so pcap_close + state-machine
    // shutdown + executor join all happen before process exit.
    try? protocolInterface.releaseDynamicEID(entityID)
    localEntity.close()
    protocolInterface.close()
  }

  // MARK: - ProtocolInterfaceObserver

  public func onTransportError(_: ProtocolInterface) {
    debugPrint("transport error")
  }

  public func onLocalEntityOnline(_: ProtocolInterface, entity: Entity) {
    debugPrint("local entity \(entity.entityID) online")
  }

  public func onLocalEntityOffline(_: ProtocolInterface, id: UniqueIdentifier) {
    debugPrint("local entity \(id) offline")
  }

  public func onLocalEntityUpdated(_: ProtocolInterface, entity: Entity) {
    debugPrint("local entity \(entity.entityID) updated")
  }

  public func onRemoteEntityOnline(_: ProtocolInterface, entity: Entity) {
    debugPrint("remote entity \(entity.entityID) online")
    Task { [id = entity.entityID] in
      await entitiesChannel.send(id)
    }
  }

  public func onRemoteEntityOffline(_: ProtocolInterface, id: UniqueIdentifier) {
    debugPrint("remote entity \(id) offline")
  }

  public func onRemoteEntityUpdated(_: ProtocolInterface, entity: Entity) {
    debugPrint("remote entity \(entity.entityID) updated")
  }
}
