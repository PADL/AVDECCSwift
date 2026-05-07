//
// Copyright (c) 2024 PADL Software Pty Ltd
//
// Licensed under the Apache License, Version 2.0 (the License);
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// Plain `import AVDECCSwift` (not @testable) — every public type in the
// module must be reachable without also importing CxxAVDECC. If a public
// API leaks an la.avdecc.* type through its signature, this test target
// will fail to build with "cannot find type" errors that would normally
// only surface in third-party consumers.
import AVDECCSwift
import XCTest

final class AVDECCSwiftTests: XCTestCase {
  // MARK: - StreamFormat

  func test61883_6FormatString() async throws {
    let formatString = StreamFormat(format: 0x00A0_0208_4000_0800)
    XCTAssertEqual(formatString.version, .version_0)
    XCTAssertEqual(formatString.subtype, .iec61883iidc)
    XCTAssertEqual(formatString.isFloatingPoint, false)
    XCTAssertEqual(formatString.sampleRate, 48000)
    XCTAssertEqual(formatString.bitDepth, 24)
    XCTAssertEqual(formatString.channelsPerFrame, 8)
  }

  func testAafFormatString() async throws {
    let formatString = StreamFormat(format: 0x0205_0220_0040_6000)
    XCTAssertEqual(formatString.version, .version_0)
    XCTAssertEqual(formatString.subtype, .aaf)
    XCTAssertEqual(formatString.isFloatingPoint, false)
    XCTAssertEqual(formatString.sampleRate, 48000)
    XCTAssertEqual(formatString.bitDepth, 32)
    XCTAssertEqual(formatString.channelsPerFrame, 1)
    XCTAssertEqual(formatString.samplesPerFrame, 6)
  }

  // MARK: - UniqueIdentifier

  func testUniqueIdentifierDescription() {
    let id = UniqueIdentifier(0x0011_2233_4455_6677)
    XCTAssertEqual(id.rawValue, 0x0011_2233_4455_6677)
    XCTAssertEqual(id.description, "0011223344556677")
  }

  func testUniqueIdentifierHashable() {
    let a = UniqueIdentifier(0x1)
    let b = UniqueIdentifier(0x1)
    let c = UniqueIdentifier(0x2)
    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
    XCTAssertEqual(Set([a, b, c]).count, 2)
  }

  // MARK: - SamplingRate

  func testSamplingRatePullZero() {
    // 48 kHz, no pull.
    let rate = SamplingRate(pull: 0, baseFrequency: 48000)
    XCTAssertEqual(rate.pull, 0)
    XCTAssertEqual(rate.baseFrequency, 48000)
    XCTAssertEqual(rate.nominalSampleRate, 48000.0)
    XCTAssertTrue(rate.isValid)
  }

  func testSamplingRatePullOne() {
    // NTSC pull-down: 48000 / 1.001.
    let rate = SamplingRate(pull: 1, baseFrequency: 48000)
    XCTAssertEqual(rate.pull, 1)
    XCTAssertEqual(rate.baseFrequency, 48000)
    XCTAssertEqual(rate.nominalSampleRate, 48000.0 / 1.001, accuracy: 1e-6)
  }

  func testSamplingRateRawRoundTrip() {
    // Pull bits are bits 31..29; baseFrequency is 28..0.
    let rate = SamplingRate(pull: 0b011, baseFrequency: 0x0100_0000)
    XCTAssertEqual(rate.rawValue, (UInt32(0b011) << 29) | 0x0100_0000)
    XCTAssertEqual(SamplingRate(rate.rawValue).pull, 0b011)
    XCTAssertEqual(SamplingRate(rate.rawValue).baseFrequency, 0x0100_0000)
  }

  func testSamplingRateInvalid() {
    XCTAssertFalse(SamplingRate(0).isValid)
    XCTAssertFalse(SamplingRate(pull: 7, baseFrequency: 0).isValid)
  }

  // MARK: - StreamIdentification & ConnectionFlags

  func testStreamIdentificationEquality() {
    let a = StreamIdentification(entityID: UniqueIdentifier(0x1), streamIndex: 0)
    let b = StreamIdentification(entityID: UniqueIdentifier(0x1), streamIndex: 0)
    let c = StreamIdentification(entityID: UniqueIdentifier(0x1), streamIndex: 1)
    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }

  func testStreamIdentificationDescription() {
    let id = StreamIdentification(
      entityID: UniqueIdentifier(0xDEAD_BEEF_FEED_FACE), streamIndex: 7
    )
    XCTAssertEqual(id.description, "deadbeeffeedface:7")
  }

  func testConnectionFlagsCombination() {
    let flags: ConnectionFlags = [.classB, .fastConnect, .savedState]
    XCTAssertTrue(flags.contains(.classB))
    XCTAssertTrue(flags.contains(.fastConnect))
    XCTAssertTrue(flags.contains(.savedState))
    XCTAssertFalse(flags.contains(.streamingWait))
    // Bit 6 has two names: talkerFailed (2013) and srpRegistrationFailed (2021)
    XCTAssertEqual(ConnectionFlags.talkerFailed, .srpRegistrationFailed)
    XCTAssertEqual(flags.rawValue, 0b0000_0111)
  }

  // MARK: - AudioMapping

  func testAudioMappingEquality() {
    let a = AudioMapping(
      streamIndex: 0, streamChannel: 1, clusterOffset: 2, clusterChannel: 3
    )
    let b = AudioMapping(
      streamIndex: 0, streamChannel: 1, clusterOffset: 2, clusterChannel: 3
    )
    XCTAssertEqual(a, b)
    XCTAssertEqual(Set([a, b]).count, 1)
  }

  // MARK: - DescriptorCounters

  func testDescriptorCountersIndexing() {
    let counters = DescriptorCounters(Array(repeating: UInt32.zero, count: 32) +
      [])
    XCTAssertEqual(counters.counters.count, 32)
    XCTAssertEqual(counters[0], 0)

    let withFrames = DescriptorCounters([
      0, 1, 2, 3, 4, 5, 6, 7,
      8, 9, 10, 11, 12, 13, 14, 15,
      16, 17, 18, 19, 20, 21, 22, 23,
      24, 25, 26, 27, 28, 29, 30, 31,
    ])
    XCTAssertEqual(withFrames[15], 15)
    XCTAssertEqual(withFrames[31], 31)
  }

  // MARK: - Counter valid flags

  func testStreamInputCounterValidFlags() {
    let flags: StreamInputCounterValidFlags = [.mediaLocked, .framesRx]
    XCTAssertTrue(flags.contains(.mediaLocked))
    XCTAssertTrue(flags.contains(.framesRx))
    XCTAssertFalse(flags.contains(.streamReset))
  }

  func testAvbInterfaceCounterValidFlags() {
    let flags: AvbInterfaceCounterValidFlags = [.linkUp, .framesTx]
    XCTAssertTrue(flags.contains(.linkUp))
    XCTAssertTrue(flags.contains(.framesTx))
    XCTAssertFalse(flags.contains(.linkDown))
  }

  // MARK: - MilanInfo / MilanVersion

  func testMilanVersionDecode() {
    let v = MilanVersion(rawValue: 0x0102_0304)
    XCTAssertEqual(v.major, 1)
    XCTAssertEqual(v.minor, 2)
    XCTAssertEqual(v.patch, 3)
    XCTAssertEqual(v.build, 4)
    XCTAssertEqual(v.description, "1.2.3.4")
  }

  func testMilanVersionRoundTrip() {
    let v = MilanVersion(major: 1, minor: 2, patch: 0, build: 42)
    XCTAssertEqual(v.rawValue, 0x0102_002A)
    XCTAssertEqual(MilanVersion(rawValue: v.rawValue), v)
  }

  func testMilanInfoConstruction() {
    let info = MilanInfo(
      protocolVersion: 0x0001_0000,
      featuresFlags: .redundancy,
      certificationVersion: MilanVersion(major: 1, minor: 2),
      specificationVersion: MilanVersion(major: 1, minor: 1)
    )
    XCTAssertEqual(info.protocolVersion, 0x0001_0000)
    XCTAssertTrue(info.featuresFlags.contains(.redundancy))
    XCTAssertEqual(info.certificationVersion.major, 1)
    XCTAssertEqual(info.certificationVersion.minor, 2)
    XCTAssertEqual(info.specificationVersion.minor, 1)
  }

  // MARK: - StreamInfoFlags

  func testStreamInfoFlagsCombination() {
    let flags: StreamInfoFlags = [.classB, .fastConnect, .talkerFailed]
    XCTAssertTrue(flags.contains(.classB))
    XCTAssertTrue(flags.contains(.talkerFailed))
    XCTAssertFalse(flags.contains(.streamingWait))
  }

  // MARK: - LocalEntity status enums

  func testAemCommandStatusFromUnknownRaw() {
    // Out-of-range value collapses to .internalError so callers always
    // get a usable Error rather than a nil parse.
    XCTAssertEqual(LocalEntityAemCommandStatus(0xBEEF), .internalError)
    XCTAssertEqual(LocalEntityAemCommandStatus(0), .success)
    XCTAssertEqual(LocalEntityAemCommandStatus(7), .badArguments)
  }

  func testControlStatusFromUnknownRaw() {
    XCTAssertEqual(LocalEntityControlStatus(0xBEEF), .internalError)
    XCTAssertEqual(LocalEntityControlStatus(0), .success)
    XCTAssertEqual(LocalEntityControlStatus(8), .listenerExclusive)
  }

  func testMvuCommandStatusFromUnknownRaw() {
    XCTAssertEqual(LocalEntityMvuCommandStatus(0xBEEF), .internalError)
    XCTAssertEqual(LocalEntityMvuCommandStatus(0), .success)
    XCTAssertEqual(LocalEntityMvuCommandStatus(13), .payloadTooShort)
  }

  // MARK: - StreamInfo (native Swift struct, used by setStreamInputInfo /

  // setStreamOutputInfo's read-modify-write flow).

  func testStreamInfoDefaultInit() {
    let info = StreamInfo()
    XCTAssertEqual(info.streamFormat.format, 0)
    XCTAssertEqual(info.streamID.rawValue, 0)
    XCTAssertEqual(info.msrpAccumulatedLatency, 0)
    XCTAssertEqual(info.streamVlanID, 0)
    XCTAssertEqual(info.streamInfoFlags, [])
    XCTAssertEqual(info.streamDestMac, [0, 0, 0, 0, 0, 0])
  }

  func testStreamInfoMutation() {
    var info = StreamInfo()
    info.streamFormat = StreamFormat(format: 0xDEAD_BEEF_FEED_FACE)
    info.streamID = UniqueIdentifier(0x1234)
    info.msrpAccumulatedLatency = 2_000_000
    info.streamVlanID = 2
    info.streamInfoFlags = [.classB, .fastConnect]
    info.streamDestMac = [0x91, 0xE0, 0xF0, 0x00, 0x12, 0x34]
    XCTAssertEqual(info.streamFormat.format, 0xDEAD_BEEF_FEED_FACE)
    XCTAssertEqual(info.streamID.rawValue, 0x1234)
    XCTAssertEqual(info.msrpAccumulatedLatency, 2_000_000)
    XCTAssertEqual(info.streamVlanID, 2)
    XCTAssertTrue(info.streamInfoFlags.contains(.fastConnect))
    XCTAssertEqual(info.streamDestMac.count, 6)
  }

  // MARK: - BindStreamFlags / Probing / MediaClock

  func testBindStreamFlagsCombination() {
    var flags: BindStreamFlags = []
    XCTAssertEqual(flags.rawValue, 0)
    flags.insert(.streamingWait)
    XCTAssertTrue(flags.contains(.streamingWait))
    XCTAssertEqual(flags.rawValue, 1)
  }

  func testProbingStatusUnknownDefaults() {
    XCTAssertEqual(ProbingStatus(99), .disabled)
    XCTAssertEqual(ProbingStatus(0), .disabled)
    XCTAssertEqual(ProbingStatus(2), .active)
  }

  func testDefaultMediaClockReferencePriority() {
    XCTAssertEqual(DefaultMediaClockReferencePriority(0xF8), .default)
    XCTAssertEqual(DefaultMediaClockReferencePriority(0xFF), .userVariableExternal)
    // Out-of-range collapses to .default.
    XCTAssertEqual(DefaultMediaClockReferencePriority(0x10), .default)
  }

  func testMediaClockReferenceInfoOptionals() {
    let info = MediaClockReferenceInfo(
      userMediaClockPriority: 5,
      mediaClockDomainName: "primary"
    )
    XCTAssertEqual(info.userMediaClockPriority, 5)
    XCTAssertEqual(info.mediaClockDomainName, "primary")
    let empty = MediaClockReferenceInfo()
    XCTAssertNil(empty.userMediaClockPriority)
    XCTAssertNil(empty.mediaClockDomainName)
  }

  // MARK: - Operations

  func testMemoryObjectOperationType() {
    XCTAssertEqual(MemoryObjectOperationType(rawValue: 0), .store)
    XCTAssertEqual(MemoryObjectOperationType.upload.rawValue, 4)
    XCTAssertNil(MemoryObjectOperationType(rawValue: 0x1000))
  }

  // MARK: - Raw PDU send-side builders. Cover construction + field

  // mutation + deinit (the C++ side does the actual heap allocation;
  // these tests exercise the wrappers don't crash and that the Swift-
  // side stored fields stay in sync with what was set).

  func testAdpMessageDefaults() {
    let msg = AdpMessage(srcMac: [0x02, 0, 0, 0, 0, 1])
    XCTAssertEqual(msg.messageType, .entityAvailable)
    XCTAssertEqual(msg.validTime, 31)
    XCTAssertEqual(msg.entityID.rawValue, 0)
    XCTAssertEqual(msg.entityCapabilities, [])
  }

  func testAdpMessageMutation() {
    let msg = AdpMessage(srcMac: [0x02, 0, 0, 0, 0, 1])
    msg.entityID = UniqueIdentifier(0xDEAD_BEEF_FEED_FACE)
    msg.messageType = .entityDeparting
    msg.validTime = 10
    msg.entityCapabilities = .aemSupported
    msg.availableIndex = 42
    XCTAssertEqual(msg.entityID.rawValue, 0xDEAD_BEEF_FEED_FACE)
    XCTAssertEqual(msg.messageType, .entityDeparting)
    XCTAssertEqual(msg.validTime, 10)
    XCTAssertTrue(msg.entityCapabilities.contains(.aemSupported))
    XCTAssertEqual(msg.availableIndex, 42)
  }

  func testAcmpMessageDefaults() {
    let msg = AcmpMessage(srcMac: [0x02, 0, 0, 0, 0, 1])
    XCTAssertEqual(msg.messageType, .connectRxCommand)
    XCTAssertEqual(msg.status, 0)
    XCTAssertEqual(msg.streamDestAddress, [0, 0, 0, 0, 0, 0])
  }

  func testAcmpMessageMutation() {
    let msg = AcmpMessage(srcMac: [0x02, 0, 0, 0, 0, 1])
    msg.messageType = .disconnectRxCommand
    msg.talkerEntityID = UniqueIdentifier(0xAAAA)
    msg.listenerEntityID = UniqueIdentifier(0xBBBB)
    msg.talkerUniqueID = 3
    msg.listenerUniqueID = 5
    msg.flags = [.classB, .fastConnect]
    msg.streamVlanID = 2
    XCTAssertEqual(msg.messageType, .disconnectRxCommand)
    XCTAssertEqual(msg.talkerEntityID.rawValue, 0xAAAA)
    XCTAssertEqual(msg.listenerEntityID.rawValue, 0xBBBB)
    XCTAssertEqual(msg.talkerUniqueID, 3)
    XCTAssertEqual(msg.listenerUniqueID, 5)
    XCTAssertTrue(msg.flags.contains(.fastConnect))
    XCTAssertEqual(msg.streamVlanID, 2)
  }

  func testAemAecpMessageDefaults() {
    let msg = AemAecpMessage(
      isResponse: false,
      srcMac: [0x02, 0, 0, 0, 0, 1],
      destMac: [0x02, 0, 0, 0, 0, 2]
    )
    XCTAssertFalse(msg.isResponse)
    XCTAssertEqual(msg.commandType, .invalidCommandType)
    XCTAssertFalse(msg.unsolicited)
    XCTAssertEqual(msg.payload, [])
  }

  func testAemAecpMessagePayloadMutation() {
    let msg = AemAecpMessage(
      isResponse: false,
      srcMac: [0x02, 0, 0, 0, 0, 1],
      destMac: [0x02, 0, 0, 0, 0, 2]
    )
    msg.commandType = .readDescriptor
    msg.targetEntityID = UniqueIdentifier(0xCAFE)
    msg.sequenceID = 7
    msg.payload = [0x00, 0x00, 0x00, 0x01]
    XCTAssertEqual(msg.commandType, .readDescriptor)
    XCTAssertEqual(msg.targetEntityID.rawValue, 0xCAFE)
    XCTAssertEqual(msg.sequenceID, 7)
    XCTAssertEqual(msg.payload, [0x00, 0x00, 0x00, 0x01])
  }

  // MARK: - LocalEntityDelegate

  // Smoke-test: a class that doesn't override any of the ~80 methods
  // should still compile thanks to the default no-op extensions, and
  // be assignable to a `LocalEntityDelegate?` slot. We can't drive
  // the delivery side in a unit test without a real interface, so
  // this just exercises the protocol-conformance + default-extension
  // surface.
  final class _DummyDelegate: LocalEntityDelegate {}

  func testLocalEntityDelegateDefaultExtensions() {
    let delegate: LocalEntityDelegate = _DummyDelegate()
    // If any of the protocol methods lacked a default extension, this
    // line wouldn't compile. The defaults are themselves no-ops; we
    // just verify the type checks at the protocol level.
    _ = delegate
  }
}
