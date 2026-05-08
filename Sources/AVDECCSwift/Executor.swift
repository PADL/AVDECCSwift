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

/// Error thrown by `Executor` factories. Distinct from
/// `ProtocolInterfaceError` so callers can `catch let e as ExecutorError`
/// when they know they're dealing with executor-registration failures
/// (typically a name collision via std::invalid_argument from
/// `ExecutorManager::registerExecutor`, surfaced here as
/// `code == .internalError` with the std exception's `what()` text in
/// `message`). Carries the same shape as the other AVDECCSwift error
/// types — see `CapturedError`.
public struct ExecutorError: CapturedError {
  public let code: ProtocolInterfaceErrorCode
  public let message: String

  init(_ captured: AVDECCSwift.CapturedException) {
    code = ProtocolInterfaceErrorCode(rawValue: captured.protocolInterfaceErrorCode)
      ?? .internalError
    message = String(captured.message)
  }
}

/// Wraps an la_avdecc dispatch-queue executor + ExecutorManager registration.
/// Backed by AVDECCSwift::ExecutorOwner — a refcounted C++ class imported as
/// a Swift foreign reference type via SWIFT_SHARED_REFERENCE; Swift ARC
/// drives retain/release. The C++ wrapper exists because Swift 6.3's
/// importer cannot see la_avdecc's executor types directly.
public struct Executor {
  public nonisolated(unsafe) static let shared = try! Executor()

  let library = Library.shared
  public let name: String

  let owner: AVDECCSwift.ExecutorOwner

  public init(name: String = DefaultExecutorName) throws {
    var captured = AVDECCSwift.CapturedException()
    let owner = AVDECCSwift.ExecutorOwner.create(std.string(name), &captured)
    guard let owner else { throw ExecutorError(captured) }
    self.name = name
    self.owner = owner
  }

  /// Eager teardown of the la_avdecc executor + its ExecutorManager
  /// registration. Idempotent. The C++ ExecutorOwner stays alive (refcount
  /// > 0) until all Swift references release, but the underlying executor
  /// is gone.
  public func close() {
    owner.close()
  }
}

public let DefaultExecutorName = "avdecc::protocol::PI"
