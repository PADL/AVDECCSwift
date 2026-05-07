/*
 * Copyright (C) 2026, PADL Software Pty Ltd
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

// Swift wrappers for the la_avdecc value types we surface to consumers.
// Each wrapper holds the imported C++ value internally and exposes Swift-
// idiomatic accessors over it. Storing the underlying value (rather than
// eagerly extracting every field at the boundary) means we can grow the
// public surface without rewriting initializers, and the wrappers stay
// thin — one C++ value-type field plus computed accessors.
//
// Sendable: the underlying C++ value types are plain value structs (no
// shared state, no internal pointers escape) so we mark each wrapper
// `@unchecked Sendable`. Swift's importer doesn't auto-derive Sendable
// for imported C++ types yet; the unchecked annotation reflects the
// invariant we maintain at the wrapping boundary.
//
// Polymorphic types (la::avdecc::entity::Entity is the notable case)
// cannot be held by value — they're abstract base classes whose copy
// would slice away the subclass-only state. For those we hold a copy of
// the relevant nested value type (CommonInformation), populated through
// the small C++ helpers in AVDECCSwiftHelpers.hpp.

internal import CxxAVDECC

// Lowercase, zero-padded hex without dragging in Foundation's
// `String(format:)`. `String(_:radix:)` is in the Swift stdlib but
// produces no padding; this fills in. Used by description strings of
// UniqueIdentifier, MAC byte arrays, and a few other identifier-shaped
// fields throughout this file.
private extension FixedWidthInteger {
  func paddedHex(width: Int) -> String {
    let s = String(self, radix: 16)
    return s.count >= width
      ? s
      : String(repeating: "0", count: width - s.count) + s
  }
}

// MARK: - UniqueIdentifier

//
// Swift-side wrapper around `la::avdecc::UniqueIdentifier` (a final class
// over a single `uint64_t`, IEEE 1722 EUI-64). Holding the C++ value lets
// us pass the wrapper through to C++ helpers without re-wrapping.
//
// Why a struct (not just a typealias for UInt64): entity IDs share the
// `UInt64` ABI with availableIndex / propagationDelay / configuration
// counters — easy to mix up. The named type makes call sites read better
// and lets us hang `description: %016llx` on it for free.

public struct UniqueIdentifier: @unchecked Sendable, Hashable, CustomStringConvertible {
  let value: la.avdecc.UniqueIdentifier

  /// Default-initialised UniqueIdentifier matching la_avdecc's no-arg
  /// `UniqueIdentifier{}` ctor — represents "unset / no entity" (rawValue 0).
  public init() {
    value = la.avdecc.UniqueIdentifier()
  }

  public init(_ rawValue: UInt64) {
    value = la.avdecc.UniqueIdentifier(rawValue)
  }

  init(_ value: la.avdecc.UniqueIdentifier) {
    self.value = value
  }

  /// 64-bit EUI representation (IEEE 1722 §6.2.1.1).
  public var rawValue: UInt64 { value.getValue() }

  /// The all-ones EUI used by la_avdecc to mean "no entity / null".
  public static let null = UniqueIdentifier(0xFFFF_FFFF_FFFF_FFFF)

  public static func == (lhs: Self, rhs: Self) -> Bool { lhs.rawValue == rhs.rawValue }
  public func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }

  /// IEEE EUI-64 in lowercase hex, zero-padded to 16 digits.
  public var description: String { rawValue.paddedHex(width: 16) }
}

// MARK: - DescriptorType

/// 16-bit AEM descriptor index (IEEE 1722.1-2021 §7.2). Aliases `UInt16`
/// so call sites can document intent (`audioUnitIndex: DescriptorIndex`)
/// without inventing per-descriptor index types. Mirrors la_avdecc's
/// `la::avdecc::entity::model::DescriptorIndex`.
public typealias DescriptorIndex = UInt16

/// AEM descriptor-type codes (IEEE 1722.1-2021 §7.2). Mirrors la_avdecc's
/// `la::avdecc::entity::model::DescriptorType` enum class. The enum surface
/// only covers the descriptor types that ship with current la_avdecc; raw
/// codes outside this set decode to `.invalid` (we don't try to model the
/// reserved/future range).
public enum DescriptorType: UInt16, Sendable, CaseIterable {
  case entity = 0x0000
  case configuration = 0x0001
  case audioUnit = 0x0002
  case videoUnit = 0x0003
  case sensorUnit = 0x0004
  case streamInput = 0x0005
  case streamOutput = 0x0006
  case jackInput = 0x0007
  case jackOutput = 0x0008
  case avbInterface = 0x0009
  case clockSource = 0x000A
  case memoryObject = 0x000B
  case locale = 0x000C
  case strings = 0x000D
  case streamPortInput = 0x000E
  case streamPortOutput = 0x000F
  case externalPortInput = 0x0010
  case externalPortOutput = 0x0011
  case internalPortInput = 0x0012
  case internalPortOutput = 0x0013
  case audioCluster = 0x0014
  case videoCluster = 0x0015
  case sensorCluster = 0x0016
  case audioMap = 0x0017
  case videoMap = 0x0018
  case sensorMap = 0x0019
  case control = 0x001A
  case signalSelector = 0x001B
  case mixer = 0x001C
  case matrix = 0x001D
  case matrixSignal = 0x001E
  case signalSplitter = 0x001F
  case signalCombiner = 0x0020
  case signalDemultiplexer = 0x0021
  case signalMultiplexer = 0x0022
  case signalTranscoder = 0x0023
  case clockDomain = 0x0024
  case controlBlock = 0x0025
  case timing = 0x0026
  case ptpInstance = 0x0027
  case ptpPort = 0x0028
  case invalid = 0xFFFF
}

// MARK: - Capability OptionSets

//
// la_avdecc represents capability bitfields as `EnumBitfield<EnumType>`
// template instantiations; the `.value()` method imports cleanly through
// Swift's C++ interop so we just call it directly when we need the raw
// bits. Each capability set is exposed as a Swift OptionSet so consumers
// can do `.contains(.aemSupported)` etc. Bit values mirror the enum class
// definitions in la_avdecc's `entityEnums.hpp`.

/// ADP Entity Capabilities (IEEE 1722.1-2021 §6.2.2.10).
public struct EntityCapabilities: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let efuMode = EntityCapabilities(rawValue: 1 << 0)
  public static let addressAccessSupported = EntityCapabilities(rawValue: 1 << 1)
  public static let gatewayEntity = EntityCapabilities(rawValue: 1 << 2)
  public static let aemSupported = EntityCapabilities(rawValue: 1 << 3)
  public static let legacyAvc = EntityCapabilities(rawValue: 1 << 4)
  public static let associationIDSupported = EntityCapabilities(rawValue: 1 << 5)
  public static let associationIDValid = EntityCapabilities(rawValue: 1 << 6)
  public static let vendorUniqueSupported = EntityCapabilities(rawValue: 1 << 7)
  public static let classASupported = EntityCapabilities(rawValue: 1 << 8)
  public static let classBSupported = EntityCapabilities(rawValue: 1 << 9)
  public static let gptpSupported = EntityCapabilities(rawValue: 1 << 10)
  public static let aemAuthenticationSupported = EntityCapabilities(rawValue: 1 << 11)
  public static let aemAuthenticationRequired = EntityCapabilities(rawValue: 1 << 12)
  public static let aemPersistentAcquireSupported = EntityCapabilities(rawValue: 1 << 13)
  public static let aemIdentifyControlIndexValid = EntityCapabilities(rawValue: 1 << 14)
  public static let aemInterfaceIndexValid = EntityCapabilities(rawValue: 1 << 15)
  public static let generalControllerIgnore = EntityCapabilities(rawValue: 1 << 16)
  public static let entityNotReady = EntityCapabilities(rawValue: 1 << 17)
}

/// ADP Talker Capabilities (IEEE 1722.1-2021 §6.2.2.11).
public struct TalkerCapabilities: OptionSet, Sendable, Hashable {
  public let rawValue: UInt16
  public init(rawValue: UInt16) { self.rawValue = rawValue }

  public static let implemented = TalkerCapabilities(rawValue: 1 << 0)
  public static let otherSource = TalkerCapabilities(rawValue: 1 << 9)
  public static let controlSource = TalkerCapabilities(rawValue: 1 << 10)
  public static let mediaClockSource = TalkerCapabilities(rawValue: 1 << 11)
  public static let smpteSource = TalkerCapabilities(rawValue: 1 << 12)
  public static let midiSource = TalkerCapabilities(rawValue: 1 << 13)
  public static let audioSource = TalkerCapabilities(rawValue: 1 << 14)
  public static let videoSource = TalkerCapabilities(rawValue: 1 << 15)
}

/// ADP Listener Capabilities (IEEE 1722.1-2021 §6.2.2.13).
public struct ListenerCapabilities: OptionSet, Sendable, Hashable {
  public let rawValue: UInt16
  public init(rawValue: UInt16) { self.rawValue = rawValue }

  public static let implemented = ListenerCapabilities(rawValue: 1 << 0)
  public static let otherSink = ListenerCapabilities(rawValue: 1 << 9)
  public static let controlSink = ListenerCapabilities(rawValue: 1 << 10)
  public static let mediaClockSink = ListenerCapabilities(rawValue: 1 << 11)
  public static let smpteSink = ListenerCapabilities(rawValue: 1 << 12)
  public static let midiSink = ListenerCapabilities(rawValue: 1 << 13)
  public static let audioSink = ListenerCapabilities(rawValue: 1 << 14)
  public static let videoSink = ListenerCapabilities(rawValue: 1 << 15)
}

/// ADP Controller Capabilities (IEEE 1722.1-2021 §6.2.2.14).
public struct ControllerCapabilities: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let implemented = ControllerCapabilities(rawValue: 1 << 0)
}

/// AvbInfo flags (IEEE 1722.1-2021 §7.4.40.2).
public struct AvbInfoFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt8
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  public static let asCapable = AvbInfoFlags(rawValue: 1 << 0)
  public static let gptpEnabled = AvbInfoFlags(rawValue: 1 << 1)
  public static let srpEnabled = AvbInfoFlags(rawValue: 1 << 2)
  public static let avtpDown = AvbInfoFlags(rawValue: 1 << 3)
  public static let avtpDownValid = AvbInfoFlags(rawValue: 1 << 4)
}

/// GET_STREAM_INFO flags (IEEE 1722.1-2021 §7.4.16). Subset of common
/// bits; vendor extensions land in the upper range — read `rawValue` if
/// you need bits this set doesn't name.
public struct StreamInfoFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let classB = StreamInfoFlags(rawValue: 1 << 0)
  public static let fastConnect = StreamInfoFlags(rawValue: 1 << 1)
  public static let savedState = StreamInfoFlags(rawValue: 1 << 2)
  public static let streamingWait = StreamInfoFlags(rawValue: 1 << 3)
  public static let supportsEncrypted = StreamInfoFlags(rawValue: 1 << 4)
  public static let encryptedPdu = StreamInfoFlags(rawValue: 1 << 5)
  public static let talkerFailed = StreamInfoFlags(rawValue: 1 << 6)
  public static let noSrp = StreamInfoFlags(rawValue: 1 << 8)
  public static let ipFlagsValid = StreamInfoFlags(rawValue: 1 << 19)
  public static let ipSrcPortValid = StreamInfoFlags(rawValue: 1 << 20)
  public static let ipDstPortValid = StreamInfoFlags(rawValue: 1 << 21)
}

/// Milan protocol features (Milan-2019 §7.4.1, MILAN_INFO_FEATURES_FLAGS).
/// The C++ enum is open-ended; for now we only name `redundancy` and pass
/// raw bits through `rawValue`.
public struct MilanInfoFeaturesFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let redundancy = MilanInfoFeaturesFlags(rawValue: 1 << 0)
}

/// Packed `major.minor.patch.build` Milan version word (1 byte each, in
/// that order, packed into a uint32). Used by GET_MILAN_INFO's
/// certification/specification fields. Mirrors la_avdecc's `MilanVersion`
/// class — la_avdecc 4.3+ promoted these fields from raw `uint32_t` to
/// this typed wrapper.
public struct MilanVersion: Sendable, Hashable, CustomStringConvertible {
  public let rawValue: UInt32

  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public init(major: UInt8, minor: UInt8, patch: UInt8 = 0, build: UInt8 = 0) {
    rawValue = (UInt32(major) << 24) | (UInt32(minor) << 16) |
      (UInt32(patch) << 8) | UInt32(build)
  }

  public var major: UInt8 { UInt8((rawValue >> 24) & 0xFF) }
  public var minor: UInt8 { UInt8((rawValue >> 16) & 0xFF) }
  public var patch: UInt8 { UInt8((rawValue >> 8) & 0xFF) }
  public var build: UInt8 { UInt8(rawValue & 0xFF) }

  public var description: String { "\(major).\(minor).\(patch).\(build)" }
}

/// Result of GET_MILAN_INFO. `protocolVersion` is the AVDECC Milan
/// protocol revision (raw uint32 bitfield); the two `MilanVersion` fields
/// are dotted version numbers (major.minor.patch.build).
/// `specificationVersion` was added in la_avdecc 4.3 / Milan-2025.
public struct MilanInfo: Sendable, Hashable {
  public let protocolVersion: UInt32
  public let featuresFlags: MilanInfoFeaturesFlags
  public let certificationVersion: MilanVersion
  public let specificationVersion: MilanVersion

  public init(
    protocolVersion: UInt32,
    featuresFlags: MilanInfoFeaturesFlags,
    certificationVersion: MilanVersion,
    specificationVersion: MilanVersion
  ) {
    self.protocolVersion = protocolVersion
    self.featuresFlags = featuresFlags
    self.certificationVersion = certificationVersion
    self.specificationVersion = specificationVersion
  }
}

/// Sampling rate (IEEE 1722.1-2013 §7.3.1). Upper 3 bits are the "pull"
/// modifier (NTSC drop-frame style); lower 29 bits are the nominal base
/// frequency in Hz. Convenience accessors split the field; `nominalSampleRate`
/// applies the pull factor (e.g. 48000 / 1.001 for pull=1).
public struct SamplingRate: @unchecked Sendable, Hashable, CustomStringConvertible {
  public let rawValue: UInt32

  public init(_ rawValue: UInt32) { self.rawValue = rawValue }
  public init(pull: UInt8, baseFrequency: UInt32) {
    rawValue = (UInt32(pull) << 29) | (baseFrequency & 0x1FFF_FFFF)
  }

  public var pull: UInt8 { UInt8(rawValue >> 29) }
  public var baseFrequency: UInt32 { rawValue & 0x1FFF_FFFF }
  public var isValid: Bool { baseFrequency != 0 }

  public var nominalSampleRate: Double {
    let f = Double(baseFrequency)
    switch pull {
    case 0: return f
    case 1: return f * 1.0 / 1.001
    case 2: return f * 1.001
    case 3: return f * 24.0 / 25.0
    case 4: return f * 25.0 / 24.0
    default: return f
    }
  }

  public var description: String {
    "SamplingRate(\(nominalSampleRate) Hz)"
  }
}

/// 32-counter snapshot returned by GET_COUNTERS responses. la_avdecc
/// delivers the raw counters as a `std::array<uint32, 32>`; the `valid`
/// bitfield (typed per descriptor) tells you which slots are meaningful.
public struct DescriptorCounters: Sendable, Hashable {
  public let counters: [UInt32]
  public init(_ counters: [UInt32]) { self.counters = counters }
  public subscript(index: Int) -> UInt32 { counters[index] }
}

/// Valid-counter flags for ENTITY-level GET_COUNTERS (IEEE 1722.1-2013
/// §7.4.42). Bit positions match la_avdecc's `EntityCounterValidFlag`.
public struct EntityCounterValidFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let entitySpecific1 = EntityCounterValidFlags(rawValue: 1 << 31)
  public static let entitySpecific2 = EntityCounterValidFlags(rawValue: 1 << 30)
  public static let entitySpecific3 = EntityCounterValidFlags(rawValue: 1 << 29)
  public static let entitySpecific4 = EntityCounterValidFlags(rawValue: 1 << 28)
  public static let entitySpecific5 = EntityCounterValidFlags(rawValue: 1 << 27)
  public static let entitySpecific6 = EntityCounterValidFlags(rawValue: 1 << 26)
  public static let entitySpecific7 = EntityCounterValidFlags(rawValue: 1 << 25)
  public static let entitySpecific8 = EntityCounterValidFlags(rawValue: 1 << 24)
}

/// Valid-counter flags for AVB_INTERFACE GET_COUNTERS.
public struct AvbInterfaceCounterValidFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let linkUp = AvbInterfaceCounterValidFlags(rawValue: 1 << 31)
  public static let linkDown = AvbInterfaceCounterValidFlags(rawValue: 1 << 30)
  public static let framesTx = AvbInterfaceCounterValidFlags(rawValue: 1 << 29)
  public static let framesRx = AvbInterfaceCounterValidFlags(rawValue: 1 << 28)
  public static let rxCrcError = AvbInterfaceCounterValidFlags(rawValue: 1 << 27)
  public static let gptpGmChanged = AvbInterfaceCounterValidFlags(rawValue: 1 << 26)
}

/// Valid-counter flags for CLOCK_DOMAIN GET_COUNTERS.
public struct ClockDomainCounterValidFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let locked = ClockDomainCounterValidFlags(rawValue: 1 << 31)
  public static let unlocked = ClockDomainCounterValidFlags(rawValue: 1 << 30)
}

/// Valid-counter flags for STREAM_INPUT GET_COUNTERS.
public struct StreamInputCounterValidFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let mediaLocked = StreamInputCounterValidFlags(rawValue: 1 << 31)
  public static let mediaUnlocked = StreamInputCounterValidFlags(rawValue: 1 << 30)
  public static let streamReset = StreamInputCounterValidFlags(rawValue: 1 << 29)
  public static let seqNumMismatch = StreamInputCounterValidFlags(rawValue: 1 << 28)
  public static let mediaReset = StreamInputCounterValidFlags(rawValue: 1 << 27)
  public static let timestampUncertain = StreamInputCounterValidFlags(rawValue: 1 << 26)
  public static let timestampValid = StreamInputCounterValidFlags(rawValue: 1 << 25)
  public static let timestampNotValid = StreamInputCounterValidFlags(rawValue: 1 << 24)
  public static let unsupportedFormat = StreamInputCounterValidFlags(rawValue: 1 << 23)
  public static let lateTimestamp = StreamInputCounterValidFlags(rawValue: 1 << 22)
  public static let earlyTimestamp = StreamInputCounterValidFlags(rawValue: 1 << 21)
  public static let framesRx = StreamInputCounterValidFlags(rawValue: 1 << 20)
  public static let framesTx = StreamInputCounterValidFlags(rawValue: 1 << 19)
}

/// `{entityID, streamIndex}` pair (IEEE 1722.1-2013 §7.3). Identifies one
/// end of an ACMP connection. Pairs are equal when both fields match.
public struct StreamIdentification: Sendable, Hashable, CustomStringConvertible {
  public let entityID: UniqueIdentifier
  public let streamIndex: UInt16

  public init(entityID: UniqueIdentifier, streamIndex: UInt16) {
    self.entityID = entityID
    self.streamIndex = streamIndex
  }

  public var description: String {
    "\(entityID):\(streamIndex)"
  }
}

/// ACMP connection flags (IEEE 1722.1-2021 §8.2.1.17). Mirrors la_avdecc's
/// `ConnectionFlag` enum. Bit 6 has two names depending on the protocol
/// revision (`talkerFailed` in 2013, `srpRegistrationFailed` in 2021); both
/// are exposed as aliases.
public struct ConnectionFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt16
  public init(rawValue: UInt16) { self.rawValue = rawValue }

  public static let classB = ConnectionFlags(rawValue: 1 << 0)
  public static let fastConnect = ConnectionFlags(rawValue: 1 << 1)
  public static let savedState = ConnectionFlags(rawValue: 1 << 2)
  public static let streamingWait = ConnectionFlags(rawValue: 1 << 3)
  public static let supportsEncrypted = ConnectionFlags(rawValue: 1 << 4)
  public static let encryptedPdu = ConnectionFlags(rawValue: 1 << 5)
  public static let talkerFailed = ConnectionFlags(rawValue: 1 << 6)
  public static let srpRegistrationFailed = ConnectionFlags(rawValue: 1 << 6)
  public static let clEntriesValid = ConnectionFlags(rawValue: 1 << 7)
  public static let noSrp = ConnectionFlags(rawValue: 1 << 8)
  public static let udp = ConnectionFlags(rawValue: 1 << 9)
}

/// State of an ACMP connection (talker side, listener side, or single-shot
/// connect/disconnect). Returned by every connection-management call.
public struct StreamConnectionState: Sendable, Hashable {
  public let talkerStream: StreamIdentification
  public let listenerStream: StreamIdentification
  public let connectionCount: UInt16
  public let flags: ConnectionFlags

  public init(
    talkerStream: StreamIdentification, listenerStream: StreamIdentification,
    connectionCount: UInt16, flags: ConnectionFlags
  ) {
    self.talkerStream = talkerStream
    self.listenerStream = listenerStream
    self.connectionCount = connectionCount
    self.flags = flags
  }
}

/// Valid-counter flags for STREAM_OUTPUT GET_COUNTERS (Milan extension; the
/// stock 1722.1 layout has no descriptor-counter assignments).
public struct StreamOutputCounterValidFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  public static let streamStart = StreamOutputCounterValidFlags(rawValue: 1 << 31)
  public static let streamStop = StreamOutputCounterValidFlags(rawValue: 1 << 30)
  public static let mediaReset = StreamOutputCounterValidFlags(rawValue: 1 << 29)
  public static let timestampUncertain = StreamOutputCounterValidFlags(rawValue: 1 << 28)
  public static let framesTx = StreamOutputCounterValidFlags(rawValue: 1 << 27)
}

// MARK: - AEM command type

//
// AEM_COMMAND_TYPE values (IEEE 1722.1-2021 §7.4 / §9.2.1.2.4). Mirror of
// the static `AemCommandType` constants in la_avdecc's protocolDefines.
// `AemAecpdu.commandType` returns one of these so callers can switch on
// it directly instead of comparing raw u16s.

public enum AemCommandType: UInt16, Sendable, CaseIterable {
  case acquireEntity = 0x0000
  case lockEntity = 0x0001
  case entityAvailable = 0x0002
  case controllerAvailable = 0x0003
  case readDescriptor = 0x0004
  case writeDescriptor = 0x0005
  case setConfiguration = 0x0006
  case getConfiguration = 0x0007
  case setStreamFormat = 0x0008
  case getStreamFormat = 0x0009
  case setVideoFormat = 0x000A
  case getVideoFormat = 0x000B
  case setSensorFormat = 0x000C
  case getSensorFormat = 0x000D
  case setStreamInfo = 0x000E
  case getStreamInfo = 0x000F
  case setName = 0x0010
  case getName = 0x0011
  case setAssociationID = 0x0012
  case getAssociationID = 0x0013
  case setSamplingRate = 0x0014
  case getSamplingRate = 0x0015
  case setClockSource = 0x0016
  case getClockSource = 0x0017
  case setControl = 0x0018
  case getControl = 0x0019
  case incrementControl = 0x001A
  case decrementControl = 0x001B
  case setSignalSelector = 0x001C
  case getSignalSelector = 0x001D
  case setMixer = 0x001E
  case getMixer = 0x001F
  case setMatrix = 0x0020
  case getMatrix = 0x0021
  case startStreaming = 0x0022
  case stopStreaming = 0x0023
  case registerUnsolicitedNotification = 0x0024
  case deregisterUnsolicitedNotification = 0x0025
  case identifyNotification = 0x0026
  case getAvbInfo = 0x0027
  case getAsPath = 0x0028
  case getCounters = 0x0029
  case reboot = 0x002A
  case getAudioMap = 0x002B
  case addAudioMappings = 0x002C
  case removeAudioMappings = 0x002D
  case getVideoMap = 0x002E
  case addVideoMappings = 0x002F
  case removeVideoMappings = 0x0030
  case getSensorMap = 0x0031
  case addSensorMappings = 0x0032
  case removeSensorMappings = 0x0033
  case startOperation = 0x0034
  case abortOperation = 0x0035
  case operationStatus = 0x0036
  case authAddKey = 0x0037
  case authDeleteKey = 0x0038
  case authGetKeyList = 0x0039
  case authGetKey = 0x003A
  case authAddKeyToChain = 0x003B
  case authDeleteKeyFromChain = 0x003C
  case authGetKeychainList = 0x003D
  case authGetIdentity = 0x003E
  case authAddToken = 0x003F
  case authDeleteToken = 0x0040
  case authenticate = 0x0041
  case deauthenticate = 0x0042
  case enableTransportSecurity = 0x0043
  case disableTransportSecurity = 0x0044
  case enableStreamEncryption = 0x0045
  case disableStreamEncryption = 0x0046
  case setMemoryObjectLength = 0x0047
  case getMemoryObjectLength = 0x0048
  case setStreamBackup = 0x0049
  case getStreamBackup = 0x004A
  case getDynamicInfo = 0x004B
  case setMaxTransitTime = 0x004C
  case getMaxTransitTime = 0x004D
  case expansion = 0x7FFF
  case invalidCommandType = 0xFFFF
}

/// Wrapper around an la_avdecc `Entity` reference. Entity is polymorphic
/// (abstract base; subclasses such as `LocalEntityImpl` override its
/// virtual surface), so we hold the pointer the AVDECC stack hands us
/// rather than copying — a value copy would slice the subclass state and
/// the C++ class isn't even default-constructible. Accessors call through
/// the pointer.
///
/// **Lifetime**: the underlying `Entity` is borrowed only for the duration
/// of the synchronous observer callback. Do NOT retain the `Entity`
/// past the callback — that's why this type is intentionally not
/// `Sendable`. If you need to act on entity data later (e.g. from a
/// `Task`), copy out the specific fields you care about (`entityID`,
/// etc.) before yielding.
///
/// Per-interface state (mac/gPTP/`AvbInterfaceIndex` enumeration) lives in
/// `InterfacesInformation` (a `std::map<>`) which the Swift importer
/// can't iterate; we'll surface it via a C++ enumeration helper in a
/// follow-up.
public struct Entity: CustomStringConvertible {
  let pointer: UnsafePointer<la.avdecc.entity.Entity>

  init(_ pointer: UnsafePointer<la.avdecc.entity.Entity>) {
    self.pointer = pointer
  }

  public var entityID: UniqueIdentifier { UniqueIdentifier(pointer.pointee.getEntityID()) }
  public var entityModelID: UniqueIdentifier {
    UniqueIdentifier(pointer.pointee.getEntityModelID())
  }

  public var talkerStreamSources: UInt16 { pointer.pointee.getTalkerStreamSources() }
  public var listenerStreamSinks: UInt16 { pointer.pointee.getListenerStreamSinks() }

  public var entityCapabilities: EntityCapabilities {
    EntityCapabilities(rawValue: pointer.pointee.getEntityCapabilities().value())
  }

  public var talkerCapabilities: TalkerCapabilities {
    TalkerCapabilities(rawValue: pointer.pointee.getTalkerCapabilities().value())
  }

  public var listenerCapabilities: ListenerCapabilities {
    ListenerCapabilities(rawValue: pointer.pointee.getListenerCapabilities().value())
  }

  public var controllerCapabilities: ControllerCapabilities {
    ControllerCapabilities(rawValue: pointer.pointee.getControllerCapabilities().value())
  }

  public var associationID: UniqueIdentifier? {
    let a = pointer.pointee.getAssociationID()
    return a.has_value() ? UniqueIdentifier(a.pointee) : nil
  }

  /// Number of AVB interfaces this entity advertises (size of la_avdecc's
  /// `InterfacesInformation` map). Use to size per-interface arrays in
  /// callers that mirror the entity model.
  public var interfaceInformationCount: Int {
    AVDECCSwift.entity_getInterfaceInformationCount(pointer)
  }

  public var description: String {
    "Entity(id: \(entityID)" +
      ", modelID: \(entityModelID)" +
      ", talkerSources: \(talkerStreamSources)" +
      ", listenerSinks: \(listenerStreamSinks)" +
      (associationID.map { ", associationID: \($0)" } ?? "") +
      ")"
  }
}

/// EntityDescriptor (IEEE 1722.1-2013 §7.2.1). Returned by
/// `LocalEntity.readEntityDescriptor`.
public struct EntityDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.EntityDescriptor

  init(_ value: la.avdecc.entity.model.EntityDescriptor) {
    self.value = value
  }

  public var entityID: UniqueIdentifier { UniqueIdentifier(value.entityID) }
  public var entityModelID: UniqueIdentifier { UniqueIdentifier(value.entityModelID) }
  public var talkerStreamSources: UInt16 { value.talkerStreamSources }
  public var listenerStreamSinks: UInt16 { value.listenerStreamSinks }
  public var availableIndex: UInt32 { value.availableIndex }
  public var associationID: UniqueIdentifier { UniqueIdentifier(value.associationID) }
  public var configurationsCount: UInt16 { value.configurationsCount }
  public var currentConfiguration: UInt16 { value.currentConfiguration }

  public var entityCapabilities: EntityCapabilities {
    EntityCapabilities(rawValue: value.entityCapabilities.value())
  }

  public var talkerCapabilities: TalkerCapabilities {
    TalkerCapabilities(rawValue: value.talkerCapabilities.value())
  }

  public var listenerCapabilities: ListenerCapabilities {
    ListenerCapabilities(rawValue: value.listenerCapabilities.value())
  }

  public var controllerCapabilities: ControllerCapabilities {
    ControllerCapabilities(rawValue: value.controllerCapabilities.value())
  }

  public var entityName: String { String(value.entityName.str()) }
  public var firmwareVersion: String { String(value.firmwareVersion.str()) }
  public var groupName: String { String(value.groupName.str()) }
  public var serialNumber: String { String(value.serialNumber.str()) }

  public var description: String {
    "EntityDescriptor(id: \(entityID), modelID: \(entityModelID)" +
      ", name: \"\(entityName)\"" +
      ", firmware: \"\(firmwareVersion)\"" +
      ", group: \"\(groupName)\"" +
      ", serial: \"\(serialNumber)\"" +
      ", talkerSources: \(talkerStreamSources)" +
      ", listenerSinks: \(listenerStreamSinks)" +
      ", availableIndex: \(availableIndex)" +
      ", configurations: \(configurationsCount)" +
      ", currentConfiguration: \(currentConfiguration))"
  }
}

/// ConfigurationDescriptor (IEEE 1722.1-2013 §7.2.2). Returned by
/// `LocalEntity.readConfigurationDescriptor`. The `descriptorCounts`
/// `std::unordered_map` is not exposed yet — it needs a small C++
/// enumeration helper since Swift's importer can't iterate
/// `std::unordered_map`.
public struct ConfigurationDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.ConfigurationDescriptor

  init(_ value: la.avdecc.entity.model.ConfigurationDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }

  /// Number of child descriptors of `type` declared by this
  /// configuration. The wire form is an
  /// `std::unordered_map<DescriptorType, uint16_t>` (descriptor_counts
  /// field); we walk it once per call. For typical callers, prefer the
  /// named accessors below (`audioUnitCount`, `streamInputCount`, …)
  /// which avoid the raw enum dance.
  ///
  /// O(N) per call — the map is small (typically <20 entries). Cache
  /// the result if you're going to look up many types.
  public func descriptorCount(_ type: DescriptorType) -> UInt16 {
    let m = value.descriptorCounts
    let pairs = _cxxIterate(
      from: m.__beginUnsafe(),
      until: m.__endUnsafe(),
      next: { $0.successor() }
    ) {
      (UInt16($0.pointee.first.rawValue), $0.pointee.second)
    }
    return pairs.first { $0.0 == type.rawValue }?.1 ?? 0
  }

  // Typed count accessors. Each one is a single descriptorCount lookup;
  // `for i in 0..<config.streamInputCount { ... }` reads cleanly without
  // exposing the raw type enum to callers.

  public var audioUnitCount: UInt16 { descriptorCount(.audioUnit) }
  public var videoUnitCount: UInt16 { descriptorCount(.videoUnit) }
  public var sensorUnitCount: UInt16 { descriptorCount(.sensorUnit) }
  public var streamInputCount: UInt16 { descriptorCount(.streamInput) }
  public var streamOutputCount: UInt16 { descriptorCount(.streamOutput) }
  public var jackInputCount: UInt16 { descriptorCount(.jackInput) }
  public var jackOutputCount: UInt16 { descriptorCount(.jackOutput) }
  public var avbInterfaceCount: UInt16 { descriptorCount(.avbInterface) }
  public var clockSourceCount: UInt16 { descriptorCount(.clockSource) }
  public var memoryObjectCount: UInt16 { descriptorCount(.memoryObject) }
  public var localeCount: UInt16 { descriptorCount(.locale) }
  public var controlCount: UInt16 { descriptorCount(.control) }
  public var clockDomainCount: UInt16 { descriptorCount(.clockDomain) }
  public var timingCount: UInt16 { descriptorCount(.timing) }
  public var ptpInstanceCount: UInt16 { descriptorCount(.ptpInstance) }

  public var description: String {
    "ConfigurationDescriptor(name: \"\(objectName)\"" +
      ", audioUnits: \(audioUnitCount)" +
      ", streamInputs: \(streamInputCount)" +
      ", streamOutputs: \(streamOutputCount)" +
      ", clockDomains: \(clockDomainCount))"
  }
}

/// AudioUnitDescriptor (IEEE 1722.1-2013 §7.2.3). Sampling-rate set
/// (`std::set<SamplingRate>`) is not exposed yet — needs an enumeration
/// helper. `currentSamplingRate` is reachable by raw value.
public struct AudioUnitDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.AudioUnitDescriptor

  init(_ value: la.avdecc.entity.model.AudioUnitDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var clockDomainIndex: UInt16 { value.clockDomainIndex }
  public var numberOfStreamInputPorts: UInt16 { value.numberOfStreamInputPorts }
  public var baseStreamInputPort: UInt16 { value.baseStreamInputPort }
  public var numberOfStreamOutputPorts: UInt16 { value.numberOfStreamOutputPorts }
  public var baseStreamOutputPort: UInt16 { value.baseStreamOutputPort }
  public var numberOfControls: UInt16 { value.numberOfControls }
  public var baseControl: UInt16 { value.baseControl }
  public var currentSamplingRate: SamplingRate {
    SamplingRate(value.currentSamplingRate.getValue())
  }

  /// Allowed sampling rates for this AudioUnit (the SAMPLING_RATES array
  /// from the descriptor, advertised as the set it can switch between
  /// via SET_SAMPLING_RATE). Sorted ascending by raw rate word.
  public var samplingRates: [SamplingRate] { value.samplingRates.toArray() }

  public var description: String {
    "AudioUnitDescriptor(name: \"\(objectName)\"" +
      ", clockDomain: \(clockDomainIndex)" +
      ", inputPorts: \(numberOfStreamInputPorts), outputPorts: \(numberOfStreamOutputPorts)" +
      ", controls: \(numberOfControls)" +
      ", currentSamplingRate: \(currentSamplingRate)" +
      ", samplingRates: \(samplingRates.count))"
  }
}

/// JackDescriptor (IEEE 1722.1-2013 §7.2.7). Used for both JACK_INPUT and
/// JACK_OUTPUT — la_avdecc returns the same type for both.
public struct JackDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.JackDescriptor

  init(_ value: la.avdecc.entity.model.JackDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var numberOfControls: UInt16 { value.numberOfControls }
  public var baseControl: UInt16 { value.baseControl }

  public var description: String {
    "JackDescriptor(name: \"\(objectName)\", controls: \(numberOfControls))"
  }
}

/// ClockSourceDescriptor (IEEE 1722.1-2013 §7.2.9).
public struct ClockSourceDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.ClockSourceDescriptor

  init(_ value: la.avdecc.entity.model.ClockSourceDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var clockSourceIdentifier: UniqueIdentifier {
    UniqueIdentifier(value.clockSourceIdentifier)
  }

  public var clockSourceLocationIndex: UInt16 { value.clockSourceLocationIndex }

  public var description: String {
    "ClockSourceDescriptor(name: \"\(objectName)\"" +
      ", identifier: \(clockSourceIdentifier)" +
      ", locationIndex: \(clockSourceLocationIndex))"
  }
}

/// MemoryObjectDescriptor (IEEE 1722.1-2013 §7.2.10).
public struct MemoryObjectDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.MemoryObjectDescriptor

  init(_ value: la.avdecc.entity.model.MemoryObjectDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var targetDescriptorIndex: UInt16 { value.targetDescriptorIndex }
  public var startAddress: UInt64 { value.startAddress }
  public var maximumLength: UInt64 { value.maximumLength }

  public var description: String {
    "MemoryObjectDescriptor(name: \"\(objectName)\"" +
      ", startAddress: 0x\(String(startAddress, radix: 16))" +
      ", maxLength: \(maximumLength))"
  }
}

/// LocaleDescriptor (IEEE 1722.1-2013 §7.2.11).
public struct LocaleDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.LocaleDescriptor

  init(_ value: la.avdecc.entity.model.LocaleDescriptor) {
    self.value = value
  }

  public var localeID: String { String(value.localeID.str()) }
  public var numberOfStringDescriptors: UInt16 { value.numberOfStringDescriptors }
  public var baseStringDescriptorIndex: UInt16 { value.baseStringDescriptorIndex }

  public var description: String {
    "LocaleDescriptor(localeID: \"\(localeID)\"" +
      ", strings: \(numberOfStringDescriptors)" +
      ", baseStringIndex: \(baseStringDescriptorIndex))"
  }
}

/// StringsDescriptor (IEEE 1722.1-2013 §7.2.12). Holds 7 fixed strings.
public struct StringsDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.StringsDescriptor

  init(_ value: la.avdecc.entity.model.StringsDescriptor) {
    self.value = value
  }

  /// 7 strings; indexes into `LocaleDescriptor.baseStringDescriptorIndex`-
  /// based ranges. Slots that aren't populated come back empty.
  public var strings: [String] {
    let s = value.strings
    return [
      String(s[0].str()), String(s[1].str()), String(s[2].str()),
      String(s[3].str()), String(s[4].str()), String(s[5].str()),
      String(s[6].str()),
    ]
  }

  public var description: String { "StringsDescriptor(\(strings))" }
}

/// AudioClusterDescriptor (IEEE 1722.1-2013 §7.2.16).
public struct AudioClusterDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.AudioClusterDescriptor

  init(_ value: la.avdecc.entity.model.AudioClusterDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var signalIndex: UInt16 { value.signalIndex }
  public var signalOutput: UInt16 { value.signalOutput }
  public var pathLatency: UInt32 { value.pathLatency }
  public var blockLatency: UInt32 { value.blockLatency }

  public var description: String {
    "AudioClusterDescriptor(name: \"\(objectName)\"" +
      ", signalIndex: \(signalIndex), signalOutput: \(signalOutput)" +
      ", pathLatency: \(pathLatency), blockLatency: \(blockLatency))"
  }
}

/// ClockDomainDescriptor (IEEE 1722.1-2013 §7.2.32). The
/// `clockSources` `std::vector<>` is enumerated lazily.
public struct ClockDomainDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.ClockDomainDescriptor

  init(_ value: la.avdecc.entity.model.ClockDomainDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var clockSourceIndex: UInt16 { value.clockSourceIndex }
  public var clockSources: [UInt16] {
    let v = value.clockSources
    let count = Int(v.size())
    var ids: [UInt16] = []
    ids.reserveCapacity(count)
    for i in 0..<count {
      ids.append(v[i])
    }
    return ids
  }

  public var description: String {
    "ClockDomainDescriptor(name: \"\(objectName)\"" +
      ", currentClockSource: \(clockSourceIndex)" +
      ", clockSources: \(clockSources))"
  }
}

/// AvbInterfaceDescriptor (IEEE 1722.1-2013 §7.2.8). Returned by
/// `LocalEntity.readAvbInterfaceDescriptor`. `macAddress` is reachable
/// via the imported `std::array<uint8_t, 6>`.
public struct AvbInterfaceDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.AvbInterfaceDescriptor

  init(_ value: la.avdecc.entity.model.AvbInterfaceDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var clockIdentity: UniqueIdentifier { UniqueIdentifier(value.clockIdentity) }
  public var priority1: UInt8 { value.priority1 }
  public var priority2: UInt8 { value.priority2 }
  public var clockClass: UInt8 { value.clockClass }
  public var clockAccuracy: UInt8 { value.clockAccuracy }
  public var offsetScaledLogVariance: UInt16 { value.offsetScaledLogVariance }
  public var domainNumber: UInt8 { value.domainNumber }
  public var logSyncInterval: UInt8 { value.logSyncInterval }
  public var logAnnounceInterval: UInt8 { value.logAnnounceInterval }

  public var macAddress: [UInt8] {
    let mac = value.macAddress
    return [mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]]
  }

  public var description: String {
    let macStr = macAddress.map { $0.paddedHex(width: 2) }.joined(separator: ":")
    return "AvbInterfaceDescriptor(name: \"\(objectName)\"" +
      ", mac: \(macStr)" +
      ", clockIdentity: \(clockIdentity)" +
      ", priority1: \(priority1), priority2: \(priority2)" +
      ", clockClass: \(clockClass), domain: \(domainNumber))"
  }
}

/// StreamDescriptor (IEEE 1722.1-2013 §7.2.6). Used for both
/// STREAM_INPUT and STREAM_OUTPUT — la_avdecc returns the same C++ type
/// for both.
public struct StreamDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.StreamDescriptor

  init(_ value: la.avdecc.entity.model.StreamDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var clockDomainIndex: UInt16 { value.clockDomainIndex }
  public var avbInterfaceIndex: UInt16 { value.avbInterfaceIndex }
  public var bufferLength: UInt32 { value.bufferLength }

  /// Current AVTP stream format word (IEEE 1722). Decode into
  /// `StreamFormat` for typed access to the bitfield.
  public var currentFormat: StreamFormat {
    StreamFormat(format: value.currentFormat.getValue())
  }

  /// Stream formats this stream supports (the `formats` `std::set<>`
  /// from the descriptor). Sorted ascending by raw format word.
  public var formats: [StreamFormat] { value.formats.toArray() }

  public var description: String {
    "StreamDescriptor(name: \"\(objectName)\"" +
      ", currentFormat: \(currentFormat)" +
      ", clockDomain: \(clockDomainIndex)" +
      ", avbInterface: \(avbInterfaceIndex)" +
      ", buffer: \(bufferLength) ns" +
      ", formats: \(formats.count))"
  }
}

/// AudioMapping entry (IEEE 1722.1-2013 §7.2.19.1). One row of an audio
/// map: stream channel ↔ cluster channel.
public struct AudioMapping: Sendable, Hashable {
  public let streamIndex: UInt16
  public let streamChannel: UInt16
  public let clusterOffset: UInt16
  public let clusterChannel: UInt16

  public init(
    streamIndex: UInt16, streamChannel: UInt16,
    clusterOffset: UInt16, clusterChannel: UInt16
  ) {
    self.streamIndex = streamIndex
    self.streamChannel = streamChannel
    self.clusterOffset = clusterOffset
    self.clusterChannel = clusterChannel
  }

  init(_ value: la.avdecc.entity.model.AudioMapping) {
    streamIndex = value.streamIndex
    streamChannel = value.streamChannel
    clusterOffset = value.clusterOffset
    clusterChannel = value.clusterChannel
  }
}

/// StreamPortDescriptor (IEEE 1722.1-2013 §7.2.13). Used for both
/// STREAM_PORT_INPUT and STREAM_PORT_OUTPUT — la_avdecc returns the same
/// C++ type for both.
public struct StreamPortDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.StreamPortDescriptor

  init(_ value: la.avdecc.entity.model.StreamPortDescriptor) {
    self.value = value
  }

  public var clockDomainIndex: UInt16 { value.clockDomainIndex }
  public var numberOfControls: UInt16 { value.numberOfControls }
  public var baseControl: UInt16 { value.baseControl }
  public var numberOfClusters: UInt16 { value.numberOfClusters }
  public var baseCluster: UInt16 { value.baseCluster }
  public var numberOfMaps: UInt16 { value.numberOfMaps }
  public var baseMap: UInt16 { value.baseMap }

  public var description: String {
    "StreamPortDescriptor(clockDomain: \(clockDomainIndex)" +
      ", clusters: \(numberOfClusters)@\(baseCluster)" +
      ", maps: \(numberOfMaps)@\(baseMap)" +
      ", controls: \(numberOfControls)@\(baseControl))"
  }
}

/// ExternalPortDescriptor (IEEE 1722.1-2013 §7.2.14). Used for both
/// EXTERNAL_PORT_INPUT and EXTERNAL_PORT_OUTPUT.
public struct ExternalPortDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.ExternalPortDescriptor

  init(_ value: la.avdecc.entity.model.ExternalPortDescriptor) {
    self.value = value
  }

  public var clockDomainIndex: UInt16 { value.clockDomainIndex }
  public var numberOfControls: UInt16 { value.numberOfControls }
  public var baseControl: UInt16 { value.baseControl }
  public var signalIndex: UInt16 { value.signalIndex }
  public var signalOutput: UInt16 { value.signalOutput }
  public var blockLatency: UInt32 { value.blockLatency }
  public var jackIndex: UInt16 { value.jackIndex }

  public var description: String {
    "ExternalPortDescriptor(clockDomain: \(clockDomainIndex)" +
      ", jack: \(jackIndex), signalIndex: \(signalIndex)" +
      ", blockLatency: \(blockLatency))"
  }
}

/// InternalPortDescriptor (IEEE 1722.1-2013 §7.2.15). Used for both
/// INTERNAL_PORT_INPUT and INTERNAL_PORT_OUTPUT.
public struct InternalPortDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.InternalPortDescriptor

  init(_ value: la.avdecc.entity.model.InternalPortDescriptor) {
    self.value = value
  }

  public var clockDomainIndex: UInt16 { value.clockDomainIndex }
  public var numberOfControls: UInt16 { value.numberOfControls }
  public var baseControl: UInt16 { value.baseControl }
  public var signalIndex: UInt16 { value.signalIndex }
  public var signalOutput: UInt16 { value.signalOutput }
  public var blockLatency: UInt32 { value.blockLatency }
  public var internalIndex: UInt16 { value.internalIndex }

  public var description: String {
    "InternalPortDescriptor(clockDomain: \(clockDomainIndex)" +
      ", internalIndex: \(internalIndex), signalIndex: \(signalIndex)" +
      ", blockLatency: \(blockLatency))"
  }
}

/// AudioMapDescriptor (IEEE 1722.1-2013 §7.2.19). The `mappings` array is
/// reachable via the descriptor read but for full enumeration of the audio
/// map at runtime use `LocalEntity.getStreamPortInputAudioMap` /
/// `getStreamPortOutputAudioMap` instead.
public struct AudioMapDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.AudioMapDescriptor

  init(_ value: la.avdecc.entity.model.AudioMapDescriptor) {
    self.value = value
  }

  public var mappings: [AudioMapping] {
    let v = value.mappings
    let count = Int(v.size())
    var out: [AudioMapping] = []
    out.reserveCapacity(count)
    for i in 0..<count {
      out.append(AudioMapping(v[i]))
    }
    return out
  }

  public var description: String { "AudioMapDescriptor(mappings: \(mappings.count))" }
}

/// ControlDescriptor (IEEE 1722.1-2013 §7.2.22). The `valuesStatic` and
/// `valuesDynamic` blobs (typed `ControlValues`) are not exposed yet —
/// they're polymorphic and need value-type-specific decoding.
public struct ControlDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.ControlDescriptor

  init(_ value: la.avdecc.entity.model.ControlDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var blockLatency: UInt32 { value.blockLatency }
  public var controlLatency: UInt32 { value.controlLatency }
  public var controlDomain: UInt16 { value.controlDomain }
  public var controlType: UniqueIdentifier { UniqueIdentifier(value.controlType) }
  public var resetTime: UInt32 { value.resetTime }
  public var signalIndex: UInt16 { value.signalIndex }
  public var signalOutput: UInt16 { value.signalOutput }
  public var numberOfValues: UInt16 { value.numberOfValues }

  public var description: String {
    "ControlDescriptor(name: \"\(objectName)\"" +
      ", controlType: \(controlType), values: \(numberOfValues)" +
      ", controlLatency: \(controlLatency))"
  }
}

/// TimingDescriptor (IEEE 1722.1-2021 §7.2.34).
public struct TimingDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.TimingDescriptor

  init(_ value: la.avdecc.entity.model.TimingDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var ptpInstances: [UInt16] {
    let v = value.ptpInstances
    let count = Int(v.size())
    var out: [UInt16] = []
    out.reserveCapacity(count)
    for i in 0..<count {
      out.append(v[i])
    }
    return out
  }

  public var description: String {
    "TimingDescriptor(name: \"\(objectName)\", ptpInstances: \(ptpInstances))"
  }
}

/// PtpInstanceDescriptor (IEEE 1722.1-2021 §7.2.35).
public struct PtpInstanceDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.PtpInstanceDescriptor

  init(_ value: la.avdecc.entity.model.PtpInstanceDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var clockIdentity: UniqueIdentifier { UniqueIdentifier(value.clockIdentity) }
  public var numberOfControls: UInt16 { value.numberOfControls }
  public var baseControl: UInt16 { value.baseControl }
  public var numberOfPtpPorts: UInt16 { value.numberOfPtpPorts }
  public var basePtpPort: UInt16 { value.basePtpPort }

  public var description: String {
    "PtpInstanceDescriptor(name: \"\(objectName)\"" +
      ", clockIdentity: \(clockIdentity)" +
      ", ptpPorts: \(numberOfPtpPorts)@\(basePtpPort))"
  }
}

/// PtpPortDescriptor (IEEE 1722.1-2021 §7.2.36).
public struct PtpPortDescriptor: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.PtpPortDescriptor

  init(_ value: la.avdecc.entity.model.PtpPortDescriptor) {
    self.value = value
  }

  public var objectName: String { String(value.objectName.str()) }
  public var portNumber: UInt16 { value.portNumber }
  public var avbInterfaceIndex: UInt16 { value.avbInterfaceIndex }
  public var profileIdentifier: [UInt8] {
    let p = value.profileIdentifier
    return [p[0], p[1], p[2], p[3], p[4], p[5]]
  }

  public var description: String {
    "PtpPortDescriptor(name: \"\(objectName)\"" +
      ", portNumber: \(portNumber), avbInterface: \(avbInterfaceIndex))"
  }
}

/// GET_STREAM_INFO / SET_STREAM_INFO dynamic information (IEEE
/// 1722.1-2013 §7.4.16). Returned by `LocalEntity.getStreamInputInfo` /
/// `getStreamOutputInfo`, and accepted by `setStreamInputInfo` /
/// `setStreamOutputInfo`.
///
/// Native Swift value type — every field is settable. The typical write
/// flow is: GET → mutate one or two fields → SET, so the entity sees
/// unchanged fields preserved from the GET response.
///
/// The Milan-specific optional fields (`streamInfoFlagsEx`,
/// `probingStatus`, `acmpStatus`) are not exposed yet — they live in
/// `std::optional<>` on the C++ side and need the same has_value()
/// dance as `Entity.associationID`. Read those via `getStreamInputInfoEx`
/// for now (Milan 1.3 §5.4.4.8).
public struct StreamInfo: Sendable, Hashable, CustomStringConvertible {
  public var streamFormat: StreamFormat
  public var streamID: UniqueIdentifier
  public var msrpAccumulatedLatency: UInt32
  public var streamVlanID: UInt16
  public var streamInfoFlags: StreamInfoFlags
  /// Six-byte stream destination MAC (multicast for talker streams,
  /// derived from the stream class and reservation for AVB).
  public var streamDestMac: [UInt8]

  public init(
    streamFormat: StreamFormat = StreamFormat(format: 0),
    streamID: UniqueIdentifier = UniqueIdentifier(0),
    msrpAccumulatedLatency: UInt32 = 0,
    streamVlanID: UInt16 = 0,
    streamInfoFlags: StreamInfoFlags = [],
    streamDestMac: [UInt8] = [0, 0, 0, 0, 0, 0]
  ) {
    self.streamFormat = streamFormat
    self.streamID = streamID
    self.msrpAccumulatedLatency = msrpAccumulatedLatency
    self.streamVlanID = streamVlanID
    self.streamInfoFlags = streamInfoFlags
    self.streamDestMac = streamDestMac
  }

  /// Lift from the borrowed C++ value handed back through a callback.
  /// Copies all observable fields into Swift-owned storage.
  init(_ value: la.avdecc.entity.model.StreamInfo) {
    streamFormat = StreamFormat(format: value.streamFormat.getValue())
    streamID = UniqueIdentifier(value.streamID)
    msrpAccumulatedLatency = value.msrpAccumulatedLatency
    streamVlanID = value.streamVlanID
    streamInfoFlags = StreamInfoFlags(rawValue: value.streamInfoFlags.value())
    let mac = value.streamDestMac
    streamDestMac = [mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]]
  }

  public var description: String {
    let macStr = streamDestMac.map { $0.paddedHex(width: 2) }.joined(separator: ":")
    return "StreamInfo(streamID: \(streamID)" +
      ", format: \(streamFormat)" +
      ", destMac: \(macStr)" +
      ", vlan: \(streamVlanID)" +
      ", latency: \(msrpAccumulatedLatency) ns" +
      ", flags: \(streamInfoFlags.rawValue))"
  }
}

/// GET_AVB_INFO dynamic information (IEEE 1722.1-2013 §7.4.40.2).
public struct AvbInfo: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.AvbInfo

  init(_ value: la.avdecc.entity.model.AvbInfo) {
    self.value = value
  }

  public var gptpGrandmasterID: UniqueIdentifier {
    UniqueIdentifier(value.gptpGrandmasterID)
  }

  public var propagationDelay: UInt32 { value.propagationDelay }
  public var gptpDomainNumber: UInt8 { value.gptpDomainNumber }

  public var flags: AvbInfoFlags { AvbInfoFlags(rawValue: value.flags.value()) }

  public var description: String {
    "AvbInfo(gmID: \(gptpGrandmasterID)" +
      ", domain: \(gptpDomainNumber)" +
      ", flags: \(flags.rawValue)" +
      ", propagationDelay: \(propagationDelay) ns)"
  }
}

/// GET_AS_PATH dynamic information (IEEE 1722.1-2013 §7.4.41.2). The
/// `sequence` is the chain of gPTP grandmaster IDs from the local
/// interface outward; `sequence[0]` is the immediate upstream master.
public struct AsPath: @unchecked Sendable, CustomStringConvertible {
  let value: la.avdecc.entity.model.AsPath

  init(_ value: la.avdecc.entity.model.AsPath) {
    self.value = value
  }

  /// Walk the underlying `std::vector<UniqueIdentifier>` and return the
  /// grandmaster IDs as Swift `UniqueIdentifier`s. Computed each access —
  /// store the result if you need to read it repeatedly.
  public var sequence: [UniqueIdentifier] {
    let seq = value.sequence
    let count = Int(seq.size())
    var ids: [UniqueIdentifier] = []
    ids.reserveCapacity(count)
    for i in 0..<count {
      ids.append(UniqueIdentifier(seq[i]))
    }
    return ids
  }

  public var description: String {
    let hex = sequence.map(\.description).joined(separator: " -> ")
    return "AsPath([\(hex)])"
  }
}

// MARK: - Milan MVU types

/// BIND_STREAM flags (Milan 1.3 §5.4.4.6). Currently only `streamingWait`
/// is defined; bits 1..15 are reserved.
public struct BindStreamFlags: OptionSet, Sendable, Hashable {
  public let rawValue: UInt16
  public init(rawValue: UInt16) { self.rawValue = rawValue }

  /// Talker holds off streaming until told otherwise via control protocol.
  public static let streamingWait = BindStreamFlags(rawValue: 1 << 0)
}

/// Probing status reported in `StreamInputInfoEx` (Milan 1.3 §5.4.4.8).
public enum ProbingStatus: UInt8, Sendable {
  case disabled = 0
  case passive = 1
  case active = 2
  case completed = 3

  public init(_ raw: UInt8) {
    self = Self(rawValue: raw) ?? .disabled
  }
}

/// ACMP per-stream status reported in `StreamInputInfoEx`. Wider than the
/// 5-bit ACMP wire status to accommodate extension codes; the underlying
/// la_avdecc `protocol::AcmpStatus` is a uint8.
public struct AcmpStatus: RawRepresentable, Sendable, Hashable {
  public let rawValue: UInt8
  public init(rawValue: UInt8) { self.rawValue = rawValue }
}

/// GET_STREAM_INPUT_INFO_EX dynamic information (Milan 1.3 §5.4.4.8).
/// Reports the resolved talker for a listener stream plus the probing /
/// ACMP states the listener has reached for it.
public struct StreamInputInfoEx: Sendable, Hashable, CustomStringConvertible {
  public let talkerStream: StreamIdentification
  public let probingStatus: ProbingStatus
  public let acmpStatus: AcmpStatus

  public var description: String {
    "StreamInputInfoEx(talker: \(talkerStream)" +
      ", probing: \(probingStatus)" +
      ", acmp: \(acmpStatus.rawValue))"
  }
}

/// Media-clock reference priority (Milan 1.3 §5.4.4.4). The wire field is
/// a single byte; values 0xF8–0xFF are spec-defined defaults exposed as
/// `DefaultMediaClockReferencePriority`.
public typealias MediaClockReferencePriority = UInt8

/// Default media-clock reference priorities (Milan 1.3 §5.4.4.4 Table 27).
public enum DefaultMediaClockReferencePriority: UInt8, Sendable {
  case `default` = 0xF8
  case userVariableInternal = 0xFE
  case userVariableExternal = 0xFF

  public init(_ raw: UInt8) {
    self = Self(rawValue: raw) ?? .default
  }
}

/// GET_MEDIA_CLOCK_REFERENCE_INFO payload (Milan 1.3 §5.4.4.5). Both fields
/// are optional on the wire — `nil` means "not reported / not changed" on
/// set, and "field absent in response" on get.
public struct MediaClockReferenceInfo: Sendable, Hashable, CustomStringConvertible {
  public let userMediaClockPriority: MediaClockReferencePriority?
  public let mediaClockDomainName: String?

  public init(
    userMediaClockPriority: MediaClockReferencePriority? = nil,
    mediaClockDomainName: String? = nil
  ) {
    self.userMediaClockPriority = userMediaClockPriority
    self.mediaClockDomainName = mediaClockDomainName
  }

  public var description: String {
    var parts: [String] = []
    if let p = userMediaClockPriority { parts.append("userPriority: \(p)") }
    if let n = mediaClockDomainName { parts.append("domain: \"\(n)\"") }
    return "MediaClockReferenceInfo(\(parts.joined(separator: ", ")))"
  }
}

// MARK: - Operations (AEM)

/// Operation type for START_OPERATION (IEEE 1722.1-2013 §7.2.10.2 Table
/// 7.13). Only meaningful against `MEMORY_OBJECT` descriptors today.
public enum MemoryObjectOperationType: UInt16, Sendable {
  case store = 0x0000
  case storeAndReboot = 0x0001
  case read = 0x0002
  case erase = 0x0003
  case upload = 0x0004
}

/// Result of START_OPERATION. The entity assigns `operationID`; subsequent
/// notifications about progress reference that ID. `payload` is the
/// vendor-defined response data echoed back by the entity.
public struct OperationResult: Sendable, Hashable, CustomStringConvertible {
  public let descriptorType: UInt16
  public let descriptorIndex: UInt16
  public let operationID: UInt16
  public let operationType: MemoryObjectOperationType
  public let payload: [UInt8]

  public var description: String {
    "OperationResult(descType: \(descriptorType), descIdx: \(descriptorIndex)" +
      ", opID: \(operationID), opType: \(operationType)" +
      ", payload: \(payload.count) bytes)"
  }
}

// MARK: - PDU wrappers

/// Wrapper around an la_avdecc AECP PDU pointer. Polymorphic in C++
/// (`Aecpdu` is the base of `AemAecpdu`, `MvuAecpdu`, …), so we hold the
/// pointer rather than copying. Lifetime is bounded by the observer
/// callback invocation — do not retain past the callback. Not `Sendable`
/// for the same reason as `Entity`.
///
/// The pointer is stored as `UnsafeRawPointer` because the underlying
/// type (`la::avdecc::protocol::Aecpdu`) cannot be named in a Swift type
/// annotation: the `protocol` namespace is a Swift keyword and the
/// importer surfaces the namespace as an empty enum even with typedef
/// aliases. Field reads route through free `AVDECCSwift::aecpdu_*`
/// accessors that `static_cast` back to the typed pointer on the C++
/// side. Type safety holds because the wrapper is only constructed at
/// the C++↔Swift boundary, where the pointer is known to be the right
/// PDU kind.
public struct Aecpdu: CustomStringConvertible {
  let pointer: UnsafeRawPointer

  init(_ pointer: UnsafeRawPointer) {
    self.pointer = pointer
  }

  public var targetEntityID: UniqueIdentifier {
    UniqueIdentifier(AVDECCSwift.aecpdu_getTargetEntityID(pointer))
  }

  public var controllerEntityID: UniqueIdentifier {
    UniqueIdentifier(AVDECCSwift.aecpdu_getControllerEntityID(pointer))
  }

  public var sequenceID: UInt16 { AVDECCSwift.aecpdu_getSequenceID(pointer) }
  /// Raw AECP message-type byte (1722.1 Table 9). Typed wrapper TBD.
  public var messageType: UInt8 { AVDECCSwift.aecpdu_getMessageType(pointer) }
  /// Raw AECP status byte. Typed wrapper TBD.
  public var status: UInt8 { AVDECCSwift.aecpdu_getStatus(pointer) }

  public var description: String {
    "Aecpdu(target: \(targetEntityID), controller: \(controllerEntityID)" +
      ", seq: \(sequenceID), msgType: \(messageType), status: \(status))"
  }
}

/// Wrapper around an la_avdecc AEM AECP PDU pointer (an Aecpdu specialised
/// for AEM commands). Same borrowed-pointer lifetime contract as
/// `Aecpdu`. The base-class fields use the same accessors as `Aecpdu`
/// because la_avdecc's `AemAecpdu` inherits from `Aecpdu` and the cast
/// is a no-op at the layout level.
public struct AemAecpdu: CustomStringConvertible {
  let pointer: UnsafeRawPointer

  init(_ pointer: UnsafeRawPointer) {
    self.pointer = pointer
  }

  public var targetEntityID: UniqueIdentifier {
    UniqueIdentifier(AVDECCSwift.aecpdu_getTargetEntityID(pointer))
  }

  public var controllerEntityID: UniqueIdentifier {
    UniqueIdentifier(AVDECCSwift.aecpdu_getControllerEntityID(pointer))
  }

  public var sequenceID: UInt16 { AVDECCSwift.aecpdu_getSequenceID(pointer) }
  /// Decoded AEM command type. Falls back to `.invalidCommandType` for
  /// unrecognised values (e.g. vendor extensions).
  public var commandType: AemCommandType {
    AemCommandType(rawValue: AVDECCSwift.aem_aecpdu_getCommandType(pointer))
      ?? .invalidCommandType
  }

  /// Raw AEM command-type word, in case `commandType` falls back to
  /// `.invalidCommandType` and you want the actual bits.
  public var commandTypeRaw: UInt16 { AVDECCSwift.aem_aecpdu_getCommandType(pointer) }

  public var description: String {
    "AemAecpdu(target: \(targetEntityID), controller: \(controllerEntityID)" +
      ", seq: \(sequenceID), commandType: \(commandType))"
  }
}

/// Wrapper around an la_avdecc ACMP PDU pointer. Same borrowed-pointer
/// lifetime contract as `Aecpdu`. Surfaces the full IEEE 1722.1-2013
/// §8.2.1 ACMP PDU header — talker / listener identification, stream
/// destination MAC, connection count and flags, stream VLAN ID — so
/// sniffer / relay tools can read incoming PDUs in full from
/// `ProtocolInterfaceObserver.onAcmpCommand` / `onAcmpResponse`.
public struct Acmpdu: CustomStringConvertible {
  let pointer: UnsafeRawPointer

  init(_ pointer: UnsafeRawPointer) {
    self.pointer = pointer
  }

  public var messageType: AcmpMessageType {
    AcmpMessageType(rawValue: AVDECCSwift.acmpdu_getMessageType(pointer)) ?? .connectTxCommand
  }

  /// Raw ACMP message-type byte (1722.1 §8.2.1.5). Use when the typed
  /// `messageType` falls back to the default for an unrecognised value.
  public var messageTypeRaw: UInt8 { AVDECCSwift.acmpdu_getMessageType(pointer) }

  /// Raw ACMP status byte (1722.1 §8.2.1.18). Lift via
  /// `LocalEntityControlStatus(UInt16(rawValue))` if you want a typed
  /// status; the wire field is 5 bits in IEEE 1722.1-2013 / 8 bits in
  /// IEEE 1722.1-2021.
  public var status: UInt8 { AVDECCSwift.acmpdu_getStatus(pointer) }

  public var sequenceID: UInt16 { AVDECCSwift.acmpdu_getSequenceID(pointer) }

  public var controllerEntityID: UniqueIdentifier {
    UniqueIdentifier(AVDECCSwift.acmpdu_getControllerEntityID(pointer))
  }

  public var talkerEntityID: UniqueIdentifier {
    UniqueIdentifier(AVDECCSwift.acmpdu_getTalkerEntityID(pointer))
  }

  public var listenerEntityID: UniqueIdentifier {
    UniqueIdentifier(AVDECCSwift.acmpdu_getListenerEntityID(pointer))
  }

  public var talkerUniqueID: UInt16 { AVDECCSwift.acmpdu_getTalkerUniqueID(pointer) }
  public var listenerUniqueID: UInt16 { AVDECCSwift.acmpdu_getListenerUniqueID(pointer) }

  /// Six-byte stream destination MAC. Multicast for normal ACMP traffic;
  /// la_avdecc fills this from the talker's stream descriptor on
  /// connect-response so the listener can subscribe to the right group.
  public var streamDestAddress: [UInt8] {
    var bytes = [UInt8](repeating: 0, count: 6)
    bytes.withUnsafeMutableBufferPointer { buf in
      AVDECCSwift.acmpdu_copyStreamDestAddress(pointer, buf.baseAddress!)
    }
    return bytes
  }

  public var connectionCount: UInt16 { AVDECCSwift.acmpdu_getConnectionCount(pointer) }

  public var flags: ConnectionFlags {
    ConnectionFlags(rawValue: AVDECCSwift.acmpdu_getFlags(pointer))
  }

  public var streamVlanID: UInt16 { AVDECCSwift.acmpdu_getStreamVlanID(pointer) }

  public var description: String {
    let macStr = streamDestAddress.map { $0.paddedHex(width: 2) }.joined(separator: ":")
    return "Acmpdu(msgType: \(messageType), status: \(status), seq: \(sequenceID)" +
      ", controller: \(controllerEntityID)" +
      ", talker: \(talkerEntityID):\(talkerUniqueID)" +
      ", listener: \(listenerEntityID):\(listenerUniqueID)" +
      ", destMac: \(macStr), count: \(connectionCount)" +
      ", flags: \(flags.rawValue), vlan: \(streamVlanID))"
  }
}

// MARK: - Raw PDU send-side builders

/// AdpMessageType (IEEE 1722.1-2013 §6.2.1.5).
public enum AdpMessageType: UInt8, Sendable {
  case entityAvailable = 0
  case entityDeparting = 1
  case entityDiscover = 2
}

/// AcmpMessageType (IEEE 1722.1-2013 §8.2.1.5).
public enum AcmpMessageType: UInt8, Sendable {
  case connectTxCommand = 0
  case connectTxResponse = 1
  case disconnectTxCommand = 2
  case disconnectTxResponse = 3
  case getTxStateCommand = 4
  case getTxStateResponse = 5
  case connectRxCommand = 6
  case connectRxResponse = 7
  case disconnectRxCommand = 8
  case disconnectRxResponse = 9
  case getRxStateCommand = 10
  case getRxStateResponse = 11
  case getTxConnectionCommand = 12
  case getTxConnectionResponse = 13
}

/// AECP message type (IEEE 1722.1-2013 §9.2.1.1.5). The non-AEM variants
/// (AddressAccess, Avc, Vendor, Hdcp) are not yet exposed through Swift
/// builders.
public enum AecpMessageType: UInt8, Sendable {
  case aemCommand = 0
  case aemResponse = 1
  case addressAccessCommand = 2
  case addressAccessResponse = 3
  case avcCommand = 4
  case avcResponse = 5
  case vendorUniqueCommand = 6
  case vendorUniqueResponse = 7
  case hdcpAemCommand = 8
  case hdcpAemResponse = 9
  case extendedCommand = 14
  case extendedResponse = 15
}

/// Ethernet destination for raw send. Most ADP/ACMP traffic uses the
/// IEEE 1722.1 multicast (Annex B); unicast targets a specific MAC.
public enum PduDestination: Sendable {
  case multicast
  case unicast([UInt8])
}

private func _writeMac(
  _ ptr: UnsafeMutableRawPointer,
  _ mac: [UInt8],
  _ setter: (UnsafeMutableRawPointer, UnsafePointer<UInt8>) -> ()
) {
  var copy = mac
  if copy.count < 6 { copy.append(contentsOf: [UInt8](repeating: 0, count: 6 - copy.count)) }
  copy.withUnsafeBufferPointer { buf in
    setter(ptr, buf.baseAddress!)
  }
}

/// ADP PDU builder (IEEE 1722.1-2013 §6.2). Owns a heap-allocated la_avdecc
/// `Adpdu` via `AVDECCSwift::adpdu_*` mutators; `deinit` calls
/// `adpdu_destroy` to free.
///
/// Construct with the source-interface MAC + your initial field values,
/// optionally mutate via the public properties, then hand to
/// `ProtocolInterface.sendAdpMessage`. Safe to reuse across sends —
/// la_avdecc copies the PDU at transmit.
public final class AdpMessage: @unchecked Sendable {
  let pointer: UnsafeMutableRawPointer

  public init(
    srcMac: [UInt8],
    messageType: AdpMessageType = .entityAvailable,
    validTime: UInt8 = 31,
    entityID: UniqueIdentifier = UniqueIdentifier(0),
    entityModelID: UniqueIdentifier = UniqueIdentifier(0),
    entityCapabilities: EntityCapabilities = [],
    talkerStreamSources: UInt16 = 0,
    talkerCapabilities: TalkerCapabilities = [],
    listenerStreamSinks: UInt16 = 0,
    listenerCapabilities: ListenerCapabilities = [],
    controllerCapabilities: ControllerCapabilities = [],
    availableIndex: UInt32 = 0,
    gptpGrandmasterID: UniqueIdentifier = UniqueIdentifier(0),
    gptpDomainNumber: UInt8 = 0,
    identifyControlIndex: UInt16 = 0,
    interfaceIndex: UInt16 = 0,
    associationID: UniqueIdentifier = UniqueIdentifier(0),
    destination: PduDestination = .multicast
  ) {
    pointer = AVDECCSwift.adpdu_create()!
    _writeMac(pointer, srcMac, AVDECCSwift.adpdu_setSrcAddress)
    setDestination(destination)
    // Stored properties below — assign through to fire didSet, which pushes
    // each value through to the C++ side (default-value init does not fire
    // didSet, so we have to go via real assignments here).
    self.messageType = messageType
    self.validTime = validTime
    self.entityID = entityID
    self.entityModelID = entityModelID
    self.entityCapabilities = entityCapabilities
    self.talkerStreamSources = talkerStreamSources
    self.talkerCapabilities = talkerCapabilities
    self.listenerStreamSinks = listenerStreamSinks
    self.listenerCapabilities = listenerCapabilities
    self.controllerCapabilities = controllerCapabilities
    self.availableIndex = availableIndex
    self.gptpGrandmasterID = gptpGrandmasterID
    self.gptpDomainNumber = gptpDomainNumber
    self.identifyControlIndex = identifyControlIndex
    self.interfaceIndex = interfaceIndex
    self.associationID = associationID
  }

  deinit { AVDECCSwift.adpdu_destroy(pointer) }

  public func setSourceMac(_ mac: [UInt8]) {
    _writeMac(pointer, mac, AVDECCSwift.adpdu_setSrcAddress)
  }

  public func setDestination(_ dest: PduDestination) {
    switch dest {
    case .multicast: AVDECCSwift.adpdu_setDestAddressMulticast(pointer)
    case let .unicast(mac): _writeMac(pointer, mac, AVDECCSwift.adpdu_setDestAddress)
    }
  }

  public var messageType: AdpMessageType = .entityAvailable {
    didSet { AVDECCSwift.adpdu_setMessageType(pointer, messageType.rawValue) }
  }

  public var validTime: UInt8 = 31 {
    didSet { AVDECCSwift.adpdu_setValidTime(pointer, validTime) }
  }

  public var entityID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.adpdu_setEntityID(pointer, entityID.rawValue) }
  }

  public var entityModelID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.adpdu_setEntityModelID(pointer, entityModelID.rawValue) }
  }

  public var entityCapabilities: EntityCapabilities = [] {
    didSet { AVDECCSwift.adpdu_setEntityCapabilities(pointer, entityCapabilities.rawValue) }
  }

  public var talkerStreamSources: UInt16 = 0 {
    didSet { AVDECCSwift.adpdu_setTalkerStreamSources(pointer, talkerStreamSources) }
  }

  public var talkerCapabilities: TalkerCapabilities = [] {
    didSet { AVDECCSwift.adpdu_setTalkerCapabilities(pointer, talkerCapabilities.rawValue) }
  }

  public var listenerStreamSinks: UInt16 = 0 {
    didSet { AVDECCSwift.adpdu_setListenerStreamSinks(pointer, listenerStreamSinks) }
  }

  public var listenerCapabilities: ListenerCapabilities = [] {
    didSet { AVDECCSwift.adpdu_setListenerCapabilities(pointer, listenerCapabilities.rawValue) }
  }

  public var controllerCapabilities: ControllerCapabilities = [] {
    didSet { AVDECCSwift.adpdu_setControllerCapabilities(pointer, controllerCapabilities.rawValue) }
  }

  public var availableIndex: UInt32 = 0 {
    didSet { AVDECCSwift.adpdu_setAvailableIndex(pointer, availableIndex) }
  }

  public var gptpGrandmasterID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.adpdu_setGptpGrandmasterID(pointer, gptpGrandmasterID.rawValue) }
  }

  public var gptpDomainNumber: UInt8 = 0 {
    didSet { AVDECCSwift.adpdu_setGptpDomainNumber(pointer, gptpDomainNumber) }
  }

  public var identifyControlIndex: UInt16 = 0 {
    didSet { AVDECCSwift.adpdu_setIdentifyControlIndex(pointer, identifyControlIndex) }
  }

  public var interfaceIndex: UInt16 = 0 {
    didSet { AVDECCSwift.adpdu_setInterfaceIndex(pointer, interfaceIndex) }
  }

  public var associationID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.adpdu_setAssociationID(pointer, associationID.rawValue) }
  }
}

/// ACMP PDU builder (IEEE 1722.1-2013 §8.2). Same lifetime contract as
/// `AdpMessage`. Multicast is the default destination (Annex B); set
/// `streamDestAddress` to the talker's stream destination MAC.
public final class AcmpMessage: @unchecked Sendable {
  let pointer: UnsafeMutableRawPointer

  public init(
    srcMac: [UInt8],
    messageType: AcmpMessageType = .connectRxCommand,
    status: UInt8 = 0,
    controllerEntityID: UniqueIdentifier = UniqueIdentifier(0),
    talkerEntityID: UniqueIdentifier = UniqueIdentifier(0),
    listenerEntityID: UniqueIdentifier = UniqueIdentifier(0),
    talkerUniqueID: UInt16 = 0,
    listenerUniqueID: UInt16 = 0,
    streamDestAddress: [UInt8] = [0, 0, 0, 0, 0, 0],
    connectionCount: UInt16 = 0,
    sequenceID: UInt16 = 0,
    flags: ConnectionFlags = [],
    streamVlanID: UInt16 = 0,
    destination: PduDestination = .multicast
  ) {
    pointer = AVDECCSwift.acmpdu_create()!
    _writeMac(pointer, srcMac, AVDECCSwift.acmpdu_setSrcAddress)
    setDestination(destination)
    self.messageType = messageType
    self.status = status
    self.controllerEntityID = controllerEntityID
    self.talkerEntityID = talkerEntityID
    self.listenerEntityID = listenerEntityID
    self.talkerUniqueID = talkerUniqueID
    self.listenerUniqueID = listenerUniqueID
    self.streamDestAddress = streamDestAddress
    self.connectionCount = connectionCount
    self.sequenceID = sequenceID
    self.flags = flags
    self.streamVlanID = streamVlanID
  }

  deinit { AVDECCSwift.acmpdu_destroy(pointer) }

  public func setSourceMac(_ mac: [UInt8]) {
    _writeMac(pointer, mac, AVDECCSwift.acmpdu_setSrcAddress)
  }

  public func setDestination(_ dest: PduDestination) {
    switch dest {
    case .multicast: AVDECCSwift.acmpdu_setDestAddressMulticast(pointer)
    case let .unicast(mac): _writeMac(pointer, mac, AVDECCSwift.acmpdu_setDestAddress)
    }
  }

  public var messageType: AcmpMessageType = .connectRxCommand {
    didSet { AVDECCSwift.acmpdu_setMessageType(pointer, messageType.rawValue) }
  }

  /// Raw ACMP status byte (1722.1 Table 8.2.1.18). Use values from
  /// `LocalEntityControlStatus.rawValue` (capped to 8 bits).
  public var status: UInt8 = 0 {
    didSet { AVDECCSwift.acmpdu_setStatus(pointer, status) }
  }

  public var controllerEntityID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.acmpdu_setControllerEntityID(pointer, controllerEntityID.rawValue) }
  }

  public var talkerEntityID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.acmpdu_setTalkerEntityID(pointer, talkerEntityID.rawValue) }
  }

  public var listenerEntityID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.acmpdu_setListenerEntityID(pointer, listenerEntityID.rawValue) }
  }

  public var talkerUniqueID: UInt16 = 0 {
    didSet { AVDECCSwift.acmpdu_setTalkerUniqueID(pointer, talkerUniqueID) }
  }

  public var listenerUniqueID: UInt16 = 0 {
    didSet { AVDECCSwift.acmpdu_setListenerUniqueID(pointer, listenerUniqueID) }
  }

  public var streamDestAddress: [UInt8] = [0, 0, 0, 0, 0, 0] {
    didSet { _writeMac(pointer, streamDestAddress, AVDECCSwift.acmpdu_setStreamDestAddress) }
  }

  public var connectionCount: UInt16 = 0 {
    didSet { AVDECCSwift.acmpdu_setConnectionCount(pointer, connectionCount) }
  }

  public var sequenceID: UInt16 = 0 {
    didSet { AVDECCSwift.acmpdu_setSequenceID(pointer, sequenceID) }
  }

  public var flags: ConnectionFlags = [] {
    didSet { AVDECCSwift.acmpdu_setFlags(pointer, flags.rawValue) }
  }

  public var streamVlanID: UInt16 = 0 {
    didSet { AVDECCSwift.acmpdu_setStreamVlanID(pointer, streamVlanID) }
  }
}

/// AEM-AECP PDU builder (IEEE 1722.1-2013 §9.2). `isResponse` is set at
/// construction and cannot be changed — pick the right value when building.
/// Destination is unicast to the target entity's MAC; no multicast default.
public final class AemAecpMessage: @unchecked Sendable {
  let pointer: UnsafeMutableRawPointer
  public let isResponse: Bool

  public init(
    isResponse: Bool,
    srcMac: [UInt8],
    destMac: [UInt8],
    status: UInt8 = 0,
    targetEntityID: UniqueIdentifier = UniqueIdentifier(0),
    controllerEntityID: UniqueIdentifier = UniqueIdentifier(0),
    sequenceID: UInt16 = 0,
    unsolicited: Bool = false,
    commandType: AemCommandType = .invalidCommandType,
    payload: [UInt8] = []
  ) {
    self.isResponse = isResponse
    pointer = AVDECCSwift.aemAecpdu_create(isResponse)!
    _writeMac(pointer, srcMac, AVDECCSwift.aecpdu_setSrcAddress)
    _writeMac(pointer, destMac, AVDECCSwift.aecpdu_setDestAddress)
    self.status = status
    self.targetEntityID = targetEntityID
    self.controllerEntityID = controllerEntityID
    self.sequenceID = sequenceID
    self.unsolicited = unsolicited
    self.commandType = commandType
    self.payload = payload
  }

  deinit { AVDECCSwift.aemAecpdu_destroy(pointer) }

  public func setSourceMac(_ mac: [UInt8]) {
    _writeMac(pointer, mac, AVDECCSwift.aecpdu_setSrcAddress)
  }

  public func setDestinationMac(_ mac: [UInt8]) {
    _writeMac(pointer, mac, AVDECCSwift.aecpdu_setDestAddress)
  }

  public var status: UInt8 = 0 {
    didSet { AVDECCSwift.aecpdu_setStatus(pointer, status) }
  }

  public var targetEntityID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.aecpdu_setTargetEntityID(pointer, targetEntityID.rawValue) }
  }

  public var controllerEntityID: UniqueIdentifier = .init(0) {
    didSet { AVDECCSwift.aecpdu_setControllerEntityID(pointer, controllerEntityID.rawValue) }
  }

  public var sequenceID: UInt16 = 0 {
    didSet { AVDECCSwift.aecpdu_setSequenceID(pointer, sequenceID) }
  }

  public var unsolicited: Bool = false {
    didSet { AVDECCSwift.aem_aecpdu_setUnsolicited(pointer, unsolicited) }
  }

  public var commandType: AemCommandType = .invalidCommandType {
    didSet { AVDECCSwift.aem_aecpdu_setCommandType(pointer, commandType.rawValue) }
  }

  /// AEM command-specific data. Length must fit in la_avdecc's AEM payload
  /// limit (524 bytes per IEEE 1722.1-2013 §9.2.1.1.7); larger values
  /// trigger an internal-error path on send.
  public var payload: [UInt8] = [] {
    didSet {
      payload.withUnsafeBufferPointer { buf in
        AVDECCSwift.aem_aecpdu_setCommandSpecificData(
          pointer, UnsafeRawPointer(buf.baseAddress), buf.count
        )
      }
    }
  }
}

// MARK: - C++ container bridges

//
// la_avdecc descriptors carry std::set / std::unordered_map fields whose
// elements don't import as Swift `Sequence`s — Swift's C++ interop
// synthesises CxxConvertibleToCollection only for std::vector/std::array,
// not std::set or std::unordered_map. Walking the iterator pair via
// __beginUnsafe()/__endUnsafe()/successor()/pointee is the supported
// fallback. We funnel every iteration through one helper so those raw
// iterator names never appear at the call sites.

/// Walk a half-open `[begin, end)` C++ iterator range and collect each
/// dereferenced element into a Swift array. The iterator type only has to
/// be Equatable (for the end-of-range comparison); `next` and `deref`
/// describe how to advance and read the iterator. Used by the per-container
/// `toArray()` extensions below — extending the helper itself isn't
/// possible because Swift's importer doesn't expose the iterator type as
/// a nominal type we can constrain on directly. File-private so callers
/// outside this module can't mis-use the raw __beginUnsafe/__endUnsafe
/// interface; they should reach for the typed `toArray()` extensions or
/// the typed accessors built on top of them.
@inline(__always)
private func _cxxIterate<It, T>(
  from begin: It, until end: It,
  next: (It) -> It,
  _ deref: (It) -> T
) -> [T] where It: Equatable {
  var out: [T] = []
  var it = begin
  while it != end {
    out.append(deref(it))
    it = next(it)
  }
  return out
}

extension la.avdecc.entity.model.SamplingRates {
  /// Bridge std::set<SamplingRate> to a Swift array. Order matches the
  /// underlying std::set (ascending raw rate word).
  func toArray() -> [SamplingRate] {
    _cxxIterate(
      from: __beginUnsafe(),
      until: __endUnsafe(),
      next: { $0.successor() }
    ) {
      SamplingRate($0.pointee.getValue())
    }
  }
}

extension la.avdecc.entity.model.StreamFormats {
  /// Bridge std::set<StreamFormat> to a Swift array. Order matches
  /// std::set (ascending raw word).
  func toArray() -> [StreamFormat] {
    _cxxIterate(
      from: __beginUnsafe(),
      until: __endUnsafe(),
      next: { $0.successor() }
    ) {
      StreamFormat(format: $0.pointee.getValue())
    }
  }
}

public struct StreamFormat: CustomStringConvertible, Equatable, Hashable, Sendable {
  var _format: UInt64

  public enum AvtpVersion: UInt8, Equatable, Sendable {
    case version_0 = 0
  }

  public enum AvtpSubtype: UInt8, Equatable, Sendable {
    case iec61883iidc = 0x00
    case mmaStream = 0x01
    case aaf = 0x02
    case cvf = 0x03
    case crf = 0x04
    case tscf = 0x05
    case svc = 0x06
    case rvf = 0x07
  }

  // 61883-6

  enum iec_61883_sf: UInt8, Equatable, Sendable {
    case iidc = 0
    case iec61883 = 1
  }

  enum iec_61883_cip: UInt8, Equatable, Sendable {
    case fmt_4 = 0x20
    case fmt_6 = 0x10
    case fmt_8 = 0x01
  }

  enum iec_61883_6_fdf_evt: UInt8, Equatable, Sendable {
    case am824 = 0x00
    case packed = 0x02
    case floating = 0x04
    case int32 = 0x06
  }

  enum iec_61883_6_fdf_sfc: UInt8, Equatable, Sendable {
    case fs32000 = 0x00
    case fs44100 = 0x01
    case fs48000 = 0x02
    case fs88200 = 0x03
    case fs96000 = 0x04
    case fs176400 = 0x05
    case fs192000 = 0x06
    case reserved = 0x07

    var sampleRate: Int? {
      switch self {
      case .fs32000: 32000
      case .fs44100: 44100
      case .fs48000: 48000
      case .fs88200: 88200
      case .fs96000: 96000
      case .fs176400: 176_400
      case .fs192000: 192_000
      default: nil
      }
    }
  }

  private var iec61883_sf_fmt_r: UInt8 {
    UInt8((_format >> 48) & 0xFF)
  }

  private var iec61883_sf: iec_61883_sf? {
    iec_61883_sf(rawValue: (iec61883_sf_fmt_r & 0x80) >> 7)
  }

  private var iec61883_fmt: iec_61883_cip? {
    iec_61883_cip(rawValue: (iec61883_sf_fmt_r & 0x7E) >> 1)
  }

  private var iec61883_r: Bool {
    iec61883_sf_fmt_r & 0x01 != 0
  }

  private var iec61883_6_fdf: UInt8 {
    UInt8((_format >> 40) & 0xFF)
  }

  private var iec61883_6_fdf_evt: iec_61883_6_fdf_evt? {
    iec_61883_6_fdf_evt(rawValue: iec61883_6_fdf & 0xF8)
  }

  private var iec61883_6_fdf_sfc: iec_61883_6_fdf_sfc? {
    iec_61883_6_fdf_sfc(rawValue: iec61883_6_fdf & 0x07)
  }

  private var iec61883_6_dbs: UInt8 {
    UInt8((_format >> 32) & 0xFF)
  }

  private var iec61883_6_b_nb_ut_sc_rsvd: UInt8 {
    UInt8((_format >> 24) & 0xFF)
  }

  private var iec61883_6_iec_60958_cnt: UInt8 {
    UInt8((_format >> 16) & 0xFF)
  }

  private var iec61883_6_label_mbla_cnt: UInt8 {
    UInt8((_format >> 8) & 0xFF)
  }

  private var iec61883_isFloatingPoint: Bool {
    guard iec61883_sf == .iec61883, iec61883_fmt == .fmt_6 else { return false }
    return iec61883_6_fdf_evt == .floating
  }

  public var iec61883_sampleRate: Int? {
    guard iec61883_sf == .iec61883, iec61883_fmt == .fmt_6,
          let iec61883_6_fdf_sfc else { return nil }
    return iec61883_6_fdf_sfc.sampleRate
  }

  public var iec61883_channelsPerFrame: Int? {
    guard iec61883_sf == .iec61883, iec61883_fmt == .fmt_6,
          let iec61883_6_fdf_evt else { return nil }
    switch iec61883_6_fdf_evt {
    case .am824:
      return Int(iec61883_6_label_mbla_cnt)
    case .floating:
      fallthrough
    case .int32:
      return Int(iec61883_6_dbs)
    default:
      return nil
    }
  }

  public var iec61883_bitDepth: Int? {
    guard iec61883_sf == .iec61883, iec61883_fmt == .fmt_6,
          let iec61883_6_fdf_evt else { return nil }
    switch iec61883_6_fdf_evt {
    case .am824:
      return 24
    default:
      return 32
    }
  }

  public var iec61883_samplesPerFrame: Int? {
    // TODO: implement
    nil
  }

  // AAF

  public enum AafFormat: UInt8, Equatable, Sendable {
    case user = 0
    case float32Bit = 1
    case int32Bit = 2
    case int24Bit = 3
    case int16Bit = 4
    case aes3_32Bit = 5

    public var bitDepth: Int? {
      switch self {
      case .float32Bit: 32
      case .int32Bit: 32
      case .int24Bit: 24
      case .int16Bit: 16
      default: nil
      }
    }
  }

  private var aafFormat: AafFormat? {
    AafFormat(rawValue: UInt8((_format >> 40) & 0xF))
  }

  private var aafBitDepth: Int {
    Int(UInt8((_format >> 32) & 0xFF))
  }

  private var aafIsFloatingPoint: Bool {
    aafFormat == .float32Bit
  }

  private var aafIsAES3Format: Bool {
    aafFormat == .aes3_32Bit
  }

  public enum AafNominalSampleRate: UInt8, Equatable, Sendable {
    case userSpecified = 0
    case fs8000 = 1
    case fs16000 = 2
    case fs32000 = 3
    case fs44100 = 4
    case fs48000 = 5
    case fs88200 = 6
    case fs96000 = 7
    case fs176400 = 8
    case fs192000 = 9
    case fs24000 = 10
    case reserved1 = 11
    case reserved2 = 12
    case reserved3 = 13
    case reserved4 = 14
    case reserved5 = 15

    public var sampleRate: Int? {
      switch self {
      case .fs8000: 8000
      case .fs16000: 16000
      case .fs32000: 32000
      case .fs44100: 44100
      case .fs48000: 48000
      case .fs88200: 88200
      case .fs96000: 96000
      case .fs176400: 176_400
      case .fs192000: 192_000
      case .fs24000: 24000
      default: nil
      }
    }
  }

  private var aafNominalSampleRate: AafNominalSampleRate? {
    AafNominalSampleRate(rawValue: UInt8((_format >> 48) & 0xF))
  }

  private var aafChannelsPerFrame: Int? {
    // TODO: support AES3
    guard !aafIsAES3Format else { return nil }
    return Int(_format >> 22 & 0x3FF)
  }

  private var aafSamplesPerFrame: Int? {
    // TODO: support AES3
    guard !aafIsAES3Format else { return nil }
    return Int(_format >> 12 & 0x3FF)
  }

  // AVTP common

  public var version: AvtpVersion? {
    AvtpVersion(rawValue: UInt8((_format >> 63) & 0x1))
  }

  public var subtype: AvtpSubtype? {
    AvtpSubtype(rawValue: UInt8((_format >> 56) & 0x7F))
  }

  public var sampleRate: Int? {
    switch subtype {
    case .iec61883iidc:
      return iec61883_sampleRate
    case .aaf:
      guard let nsr = aafNominalSampleRate else {
        return nil
      }
      return nsr.sampleRate
    default:
      return nil
    }
  }

  public var channelsPerFrame: Int? {
    switch subtype {
    case .iec61883iidc:
      iec61883_channelsPerFrame
    case .aaf:
      aafChannelsPerFrame
    default:
      nil
    }
  }

  public var bitDepth: Int? {
    switch subtype {
    case .iec61883iidc:
      return iec61883_bitDepth
    case .aaf:
      guard let format = aafFormat, let formatBitDepth = format.bitDepth else {
        return nil
      }
      return formatBitDepth > aafBitDepth ? aafBitDepth : formatBitDepth
    default:
      return nil
    }
  }

  public var samplesPerFrame: Int? {
    switch subtype {
    case .iec61883iidc:
      iec61883_samplesPerFrame
    case .aaf:
      aafSamplesPerFrame
    default:
      nil
    }
  }

  public var isFloatingPoint: Bool {
    switch subtype {
    case .iec61883iidc:
      iec61883_isFloatingPoint
    case .aaf:
      aafIsFloatingPoint
    default:
      false
    }
  }

  public var format: UInt64 {
    _format
  }

  public var formatBytes: [UInt8] {
    withUnsafeBytes(of: format.bigEndian, Array.init)
  }

  public init() {
    _format = 0
  }

  public init(format: UInt64) {
    _format = format
  }

  public var description: String { _format.paddedHex(width: 16) }
}
