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

/// Mirrors `la::avdecc::protocol::ProtocolInterface::Error`. Used as the
/// typed dispatch code on every AVDECCSwift error: la_avdecc throws
/// `ProtocolInterface::Exception` for most failure modes (PI factories,
/// LocalEntity registration via the PI hierarchy), and the C++ helper
/// folds non-PI exceptions to `.internalError` while preserving their
/// `what()` text in `message`.
public enum ProtocolInterfaceErrorCode: UInt8, Sendable {
  case transportError = 1
  case timeout = 2
  case unknownRemoteEntity = 3
  case unknownLocalEntity = 4
  case invalidEntityType = 5
  case duplicateLocalEntityID = 6
  case interfaceNotFound = 7
  case invalidParameters = 8
  case interfaceNotSupported = 9
  case messageNotSupported = 10
  case executorNotInitialized = 11
  case internalError = 99
}

/// Shared shape for AVDECCSwift errors thrown out of factories /
/// synchronous wrappers. Each domain (ProtocolInterface, Executor,
/// LocalEntity) has its own concrete `Error` type so callers can
/// `catch let e as ProtocolInterfaceError` without ambiguity, but the
/// payload is uniform: a typed code plus an optional `what()` string.
public protocol AvdeccCapturedError: Error, CustomStringConvertible, Sendable {
  var code: ProtocolInterfaceErrorCode { get }
  var message: String { get }
}

public extension AvdeccCapturedError {
  var description: String {
    let label = "\(Self.self).\(code)"
    return message.isEmpty ? label : "\(label): \(message)"
  }
}

/// Error thrown by `ProtocolInterface` factories / sync calls.
public struct ProtocolInterfaceError: AvdeccCapturedError {
  public let code: ProtocolInterfaceErrorCode
  public let message: String

  init(_ captured: AVDECCSwift.CapturedException) {
    code = ProtocolInterfaceErrorCode(rawValue: captured.protocolInterfaceErrorCode)
      ?? .internalError
    message = String(captured.message)
  }

  public init(code: ProtocolInterfaceErrorCode, message: String = "") {
    self.code = code
    self.message = message
  }

  // Convenience factories so callers can write `throw .unknownRemoteEntity`
  // / `throw ProtocolInterfaceError.unknownRemoteEntity` without spelling
  // out `(code:)`. Mirrors the enum-style call sites the C-binding API
  // used to support; the message is empty when constructed this way.
  public static let transportError = ProtocolInterfaceError(code: .transportError)
  public static let timeout = ProtocolInterfaceError(code: .timeout)
  public static let unknownRemoteEntity = ProtocolInterfaceError(code: .unknownRemoteEntity)
  public static let unknownLocalEntity = ProtocolInterfaceError(code: .unknownLocalEntity)
  public static let invalidEntityType = ProtocolInterfaceError(code: .invalidEntityType)
  public static let duplicateLocalEntityID = ProtocolInterfaceError(code: .duplicateLocalEntityID)
  public static let interfaceNotFound = ProtocolInterfaceError(code: .interfaceNotFound)
  public static let invalidParameters = ProtocolInterfaceError(code: .invalidParameters)
  public static let interfaceNotSupported = ProtocolInterfaceError(code: .interfaceNotSupported)
  public static let messageNotSupported = ProtocolInterfaceError(code: .messageNotSupported)
  public static let executorNotInitialized = ProtocolInterfaceError(code: .executorNotInitialized)
  public static let internalError = ProtocolInterfaceError(code: .internalError)
}

public enum ProtocolInterfaceType: UInt8 {
  case none = 0
  case pCap = 1
  case macOSNative = 2
  case proxy = 4
  case virtual = 8
  case serial = 16
  case local = 32
}

/// Observer protocol for ProtocolInterface events. Entity and PDU
/// callbacks deliver Swift wrapper structs (`Entity`, `Aecpdu`,
/// `AemAecpdu`, `Acmpdu`) that hold a borrowed pointer to the underlying
/// la_avdecc value; do not retain those wrappers past the callback (they
/// are intentionally not `Sendable`). Read what you need synchronously
/// and copy out specific fields if you want to act on them later.
public protocol ProtocolInterfaceObserver: AnyObject {
  func onTransportError(_: ProtocolInterface)
  func onLocalEntityOnline(_: ProtocolInterface, entity: Entity)
  func onLocalEntityOffline(_: ProtocolInterface, id: UniqueIdentifier)
  func onLocalEntityUpdated(_: ProtocolInterface, entity: Entity)
  func onRemoteEntityOnline(_: ProtocolInterface, entity: Entity)
  func onRemoteEntityOffline(_: ProtocolInterface, id: UniqueIdentifier)
  func onRemoteEntityUpdated(_: ProtocolInterface, entity: Entity)

  func onAecpCommand(_: ProtocolInterface, pdu: Aecpdu)
  func onAecpAemUnsolicitedResponse(_: ProtocolInterface, pdu: AemAecpdu)
  func onAecpAemIdentifyNotification(_: ProtocolInterface, pdu: AemAecpdu)
  func onAcmpCommand(_: ProtocolInterface, pdu: Acmpdu)
  func onAcmpResponse(_: ProtocolInterface, pdu: Acmpdu)
}

public extension ProtocolInterfaceObserver {
  // Default no-op implementations so observers only override what they care about.
  func onTransportError(_: ProtocolInterface) {}
  func onLocalEntityOnline(_: ProtocolInterface, entity _: Entity) {}
  func onLocalEntityOffline(_: ProtocolInterface, id _: UniqueIdentifier) {}
  func onLocalEntityUpdated(_: ProtocolInterface, entity _: Entity) {}
  func onRemoteEntityOnline(_: ProtocolInterface, entity _: Entity) {}
  func onRemoteEntityOffline(_: ProtocolInterface, id _: UniqueIdentifier) {}
  func onRemoteEntityUpdated(_: ProtocolInterface, entity _: Entity) {}
  func onAecpCommand(_: ProtocolInterface, pdu _: Aecpdu) {}
  func onAecpAemUnsolicitedResponse(_: ProtocolInterface, pdu _: AemAecpdu) {}
  func onAecpAemIdentifyNotification(_: ProtocolInterface, pdu _: AemAecpdu) {}
  func onAcmpCommand(_: ProtocolInterface, pdu _: Acmpdu) {}
  func onAcmpResponse(_: ProtocolInterface, pdu _: Acmpdu) {}
}

/// Wraps an la_avdecc ProtocolInterface. Backed by AVDECCSwift::
/// ProtocolInterfaceOwner — a refcounted C++ class imported as a Swift
/// foreign reference type via SWIFT_SHARED_REFERENCE; Swift ARC handles
/// retain/release. The C++ wrapper exists because Swift 6.3's importer
/// cannot see la::avdecc::protocol::ProtocolInterface or its UniquePointer
/// (std::function-typed handlers, templated Subject<>, move-only return).
public final class ProtocolInterface {
  let executor = Executor.shared
  let owner: AVDECCSwift.ProtocolInterfaceOwner

  public weak var observer: ProtocolInterfaceObserver? {
    didSet { rebindObserver() }
  }

  public init(
    type: ProtocolInterfaceType = .pCap,
    interfaceID: String,
    executorName: String = DefaultExecutorName
  ) throws {
    var captured = AVDECCSwift.CapturedException()
    let owner = AVDECCSwift.ProtocolInterfaceOwner.create(
      type.rawValue, std.string(interfaceID), std.string(executorName), &captured
    )
    guard let owner else { throw ProtocolInterfaceError(captured) }
    self.owner = owner
  }

  /// Eager teardown. Detaches the observer (if any) and tears down the
  /// underlying ProtocolInterface. Must be called during graceful shutdown
  /// (rather than relying on Swift refcounts to drop) so that la_avdecc's
  /// static ProtocolInterfaceManager entry doesn't survive into
  /// __cxa_finalize. Idempotent.
  public func close() {
    observer = nil
    owner.close()
  }

  deinit {
    owner.close()
  }

  // MARK: - General entry points

  /// 6-byte MAC address of the underlying interface. Empty array if the
  /// interface has been closed.
  public var macAddressBytes: [UInt8] {
    var bytes = [UInt8](repeating: 0, count: 6)
    let ok = bytes.withUnsafeMutableBufferPointer { buf in
      owner.copyMacAddress(buf.baseAddress!)
    }
    return ok ? bytes : []
  }

  public func getDynamicEID() throws -> UniqueIdentifier {
    let raw = owner.getDynamicEID()
    if raw == 0 {
      throw ProtocolInterfaceError(code: .internalError)
    }
    return UniqueIdentifier(raw)
  }

  public func releaseDynamicEID(_ id: UniqueIdentifier) throws {
    owner.releaseDynamicEID(id.rawValue)
  }

  /// Tear down the underlying transport. Equivalent to `close()` but with
  /// the C++ name; provided for parity with la_avdecc.
  public func shutdown() {
    owner.shutdown()
  }

  /// Drop la_avdecc's cached state for `id`. The next discovery cycle will
  /// see it as a new arrival.
  public func forgetRemoteEntity(_ id: UniqueIdentifier) {
    owner.forgetRemoteEntity(id.rawValue)
  }

  /// True if the transport supports the `sendAdpMessage` / `sendAecpMessage`
  /// raw-PDU send path. The PCAP transport returns true; macOS native does
  /// not.
  public var isDirectMessageSupported: Bool {
    owner.isDirectMessageSupported()
  }

  // MARK: - Raw PDU send

  /// Transmit a fully-built ADP PDU. The PDU may be reused for retransmits
  /// — la_avdecc copies on send. Throws `ProtocolInterfaceError` on
  /// transport / argument failures (the raw-send transports return
  /// `.transportError` on macOS-native, where direct send isn't supported).
  public func sendAdpMessage(_ pdu: AdpMessage) throws {
    let code = owner.sendAdpMessage(UnsafeRawPointer(pdu.pointer))
    if code != 0 {
      throw ProtocolInterfaceError(
        code: ProtocolInterfaceErrorCode(rawValue: code) ?? .internalError)
    }
  }

  /// Transmit a fully-built AEM-AECP PDU. Used for protocol-conformance
  /// tools and for replaying captured traffic; typical apps go through
  /// `LocalEntity` instead.
  public func sendAecpMessage(_ pdu: AemAecpMessage) throws {
    let code = owner.sendAecpMessage(UnsafeRawPointer(pdu.pointer))
    if code != 0 {
      throw ProtocolInterfaceError(
        code: ProtocolInterfaceErrorCode(rawValue: code) ?? .internalError)
    }
  }

  /// Transmit a fully-built ACMP PDU.
  public func sendAcmpMessage(_ pdu: AcmpMessage) throws {
    let code = owner.sendAcmpMessage(UnsafeRawPointer(pdu.pointer))
    if code != 0 {
      throw ProtocolInterfaceError(
        code: ProtocolInterfaceErrorCode(rawValue: code) ?? .internalError)
    }
  }

  /// Coarse lock over la_avdecc's internal state. Use to atomically observe
  /// + mutate. Recursive; pair every `lock()` with `unlock()`.
  public func lock() { owner.lock() }
  public func unlock() { owner.unlock() }
  public var isSelfLocked: Bool { owner.isSelfLocked() }

  // LocalEntity registration is performed inside LocalEntityOwner.create
  // via la_avdecc's AggregateEntity factory — Swift callers don't need to
  // call register/unregister explicitly. Kept here as no-ops for source
  // compatibility while we refactor consumers.
  public func register(localEntity _: LocalEntity) throws {}
  public func unregister(localEntity _: LocalEntity) throws {}

  // MARK: - Observer wiring

  /// Walks the observer protocol's methods, installs blocks on the C++
  /// BlockProtocolInterfaceObserver that forward into the Swift observer.
  /// Called when `observer` is assigned (set or cleared).
  ///
  /// Detaches first so la_avdecc cannot deliver a notification while we
  /// are mutating slots. The C++ observer also locks slot reads/writes,
  /// so this is belt-and-braces — but it shrinks the window where blocks
  /// are being torn down and rebuilt.
  private func rebindObserver() {
    owner.unregisterObserver()
    guard let observer else {
      owner.clearObserverBlocks()
      return
    }
    // Captures must be weak: the C++ side Block_copy's each closure on store,
    // so a strong `self` capture would create a cycle (owner -> Block_copy'd
    // closure -> self -> owner). The observer is held weakly anyway (`weak
    // var observer`); we re-bind weakly here to match.
    owner.setOnTransportError { [weak self, weak observer] _ in
      guard let self, let observer else { return }
      observer.onTransportError(self)
    }
    owner.setOnLocalEntityOnline { [weak self, weak observer] _, e in
      guard let self, let observer, let e else { return }
      observer.onLocalEntityOnline(self, entity: Entity(e))
    }
    owner.setOnLocalEntityOffline { [weak self, weak observer] _, id in
      guard let self, let observer else { return }
      observer.onLocalEntityOffline(self, id: UniqueIdentifier(id))
    }
    owner.setOnLocalEntityUpdated { [weak self, weak observer] _, e in
      guard let self, let observer, let e else { return }
      observer.onLocalEntityUpdated(self, entity: Entity(e))
    }
    owner.setOnRemoteEntityOnline { [weak self, weak observer] _, e in
      guard let self, let observer, let e else { return }
      observer.onRemoteEntityOnline(self, entity: Entity(e))
    }
    owner.setOnRemoteEntityOffline { [weak self, weak observer] _, id in
      guard let self, let observer else { return }
      observer.onRemoteEntityOffline(self, id: UniqueIdentifier(id))
    }
    owner.setOnRemoteEntityUpdated { [weak self, weak observer] _, e in
      guard let self, let observer, let e else { return }
      observer.onRemoteEntityUpdated(self, entity: Entity(e))
    }
    owner.setOnAecpCommand { [weak self, weak observer] _, p in
      guard let self, let observer, let p else { return }
      observer.onAecpCommand(self, pdu: Aecpdu(p))
    }
    owner.setOnAecpAemUnsolicitedResponse { [weak self, weak observer] _, p in
      guard let self, let observer, let p else { return }
      observer.onAecpAemUnsolicitedResponse(self, pdu: AemAecpdu(p))
    }
    owner.setOnAecpAemIdentifyNotification { [weak self, weak observer] _, p in
      guard let self, let observer, let p else { return }
      observer.onAecpAemIdentifyNotification(self, pdu: AemAecpdu(p))
    }
    owner.setOnAcmpCommand { [weak self, weak observer] _, p in
      guard let self, let observer, let p else { return }
      observer.onAcmpCommand(self, pdu: Acmpdu(p))
    }
    owner.setOnAcmpResponse { [weak self, weak observer] _, p in
      guard let self, let observer, let p else { return }
      observer.onAcmpResponse(self, pdu: Acmpdu(p))
    }

    owner.registerObserver()
  }
}
