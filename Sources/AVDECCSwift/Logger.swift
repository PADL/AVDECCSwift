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

internal import CxxAVDECC
import Logging

/// Mirrors `la::avdecc::logger::Level`. Numeric values match la_avdecc's
/// enum so we can cross the C++ boundary as a single `UInt8`.
public enum LogLevel: UInt8, Sendable, Comparable {
  case trace = 0
  case debug = 1
  case info = 2
  case warn = 3
  case error = 4
  /// la_avdecc's "compatibility" channel — used for logging when the
  /// library compensates for a non-conformant peer. Maps to swift-log
  /// `.notice` since it's not a hard failure but worth surfacing.
  case compat = 5
  /// `Logger::setLevel(.none)` silences all output.
  case none = 99

  public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

  /// Map to the closest swift-log severity. `.compat` lands on `.notice`
  /// (informational but unusual); `.none` only appears as a filter
  /// setting and never on actual log items.
  public var swiftLogLevel: Logging.Logger.Level {
    switch self {
    case .trace: .trace
    case .debug: .debug
    case .info: .info
    case .warn: .warning
    case .error: .error
    case .compat: .notice
    case .none: .critical
    }
  }
}

/// Mirrors `la::avdecc::logger::Layer`. Surfaced on each forwarded
/// log event as the `avdecc.layer` metadata key so consumers can
/// filter or route by subsystem (e.g. ProtocolInterface vs Controller).
public enum LogLayer: UInt8, Sendable {
  case generic = 0
  case serialization = 1
  case protocolInterface = 2
  case aemPayload = 3
  case entity = 4
  case controllerEntity = 5
  case controllerStateMachine = 6
  case controller = 7
  case jsonSerializer = 8

  /// Short identifier used as the `avdecc.layer` metadata value.
  public var name: String {
    switch self {
    case .generic: "generic"
    case .serialization: "serialization"
    case .protocolInterface: "protocolInterface"
    case .aemPayload: "aemPayload"
    case .entity: "entity"
    case .controllerEntity: "controllerEntity"
    case .controllerStateMachine: "controllerStateMachine"
    case .controller: "controller"
    case .jsonSerializer: "jsonSerializer"
    }
  }
}

/// Forwards la_avdecc's log events to swift-log. Construct one and hold
/// a reference for as long as you want logs forwarded; deinit (or an
/// explicit `close()`) detaches the observer from la_avdecc's singleton.
///
/// Thread-safety: la_avdecc fires log events from arbitrary internal
/// threads (executor, state machine, watch dog). The forwarding closure
/// runs on whichever thread emitted the event; swift-log's `Logger` is
/// thread-safe, so no extra synchronisation is required on our side.
///
/// Filtering: the `level` setting is la_avdecc's *global* emit filter —
/// messages below it are dropped before our observer is invoked, saving
/// the `getMessage()` allocation. Per-instance filtering still happens
/// in the forwarder via the captured `Logger.logLevel`. Setting `level`
/// affects every other observer too, so prefer the most permissive
/// across all consumers and let swift-log handle finer-grained filters.
public final class Logger: Sendable {
  nonisolated(unsafe) let owner: AVDECCSwift.LoggerOwner

  /// The destination swift-log Logger. Reassign to redirect output;
  /// the new value takes effect on the next la_avdecc log event.
  public let logger: Logging.Logger

  /// Most-permissive level la_avdecc will emit. Backed by the C++ Logger
  /// singleton (no Swift-side storage), so reading and writing are both
  /// thread-safe and the property is `Sendable`-compatible. Setting this
  /// affects the global la_avdecc Logger, so it influences other observers
  /// if any exist — prefer the most permissive across consumers.
  public var level: LogLevel {
    get { LogLevel(rawValue: owner.getLevel()) ?? .info }
    set { owner.setLevel(newValue.rawValue) }
  }

  public init(
    forwardingTo logger: Logging.Logger,
    level: LogLevel = .info
  ) {
    self.logger = logger
    owner = AVDECCSwift.LoggerOwner.create()
    owner.setLevel(level.rawValue)

    // The block captures `self` weakly so that an unreleased
    // Logger doesn't keep itself alive via the la_avdecc
    // observer registration. Deinit calls owner.close(), which
    // detaches before we're freed.
    owner.setOnLogItem { [weak self] rawLevel, rawLayer, dataPtr, size in
      guard let self else { return }
      let level = LogLevel(rawValue: rawLevel) ?? .info
      let layer = LogLayer(rawValue: rawLayer) ?? .generic
      let message: String
      if let dataPtr, size > 0 {
        let buf = UnsafeBufferPointer(
          start: UnsafePointer<UInt8>(OpaquePointer(dataPtr)), count: size
        )
        message = String(decoding: buf, as: UTF8.self)
      } else {
        message = ""
      }
      var l = self.logger
      l[metadataKey: "avdecc.layer"] = .string(layer.name)
      l.log(level: level.swiftLogLevel, "\(message)")
    }

    owner.registerObserver()
  }

  /// Eager teardown. Detaches from la_avdecc's Logger singleton and
  /// drops the forwarding closure. Idempotent.
  public func close() {
    owner.close()
  }

  deinit {
    owner.close()
  }
}
