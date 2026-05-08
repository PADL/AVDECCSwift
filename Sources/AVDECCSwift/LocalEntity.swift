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

/// Error thrown by `LocalEntity` factories. Distinct type from
/// `ProtocolInterfaceError` so callers can `catch let e as LocalEntityError`
/// — but its `code` field is meaningful (and useful for dispatch on
/// `.duplicateLocalEntityID` etc.) because la_avdecc's
/// `registerLocalEntity` throws via the ProtocolInterface::Exception
/// hierarchy. Carries the same shape as the other AVDECCSwift error
/// types — see `CapturedError`.
public struct LocalEntityError: CapturedError {
  public let code: ProtocolInterfaceErrorCode
  public let message: String

  init(_ captured: AVDECCSwift.CapturedException) {
    code = ProtocolInterfaceErrorCode(rawValue: captured.protocolInterfaceErrorCode)
      ?? .internalError
    message = String(captured.message)
  }

  init(code: ProtocolInterfaceErrorCode, message: String = "") {
    self.code = code
    self.message = message
  }
}

public enum LocalEntityAemCommandStatus: UInt16, Error {
  case success = 0
  case notImplemented = 1
  case noSuchDescriptor = 2
  case lockedByOther = 3
  case acquiredByOther = 4
  case notAuthenticated = 5
  case authenticationDisabled = 6
  case badArguments = 7
  case noResources = 8
  case inProgress = 9
  case entityMisbehaving = 10
  case notSupported = 11
  case streamIsRunning = 12
  case networkError = 995
  case protocolError = 996
  case timedOut = 997
  case unknownEntity = 998
  case internalError = 999

  /// Lossy init: unknown `raw` values collapse to `.internalError` so
  /// callers always get a usable error rather than nil. Use the synthesised
  /// `init(rawValue:)` if you need to distinguish "unknown value" from
  /// the catch-all internal-error case.
  public init(_ raw: UInt16) {
    self = Self(rawValue: raw) ?? .internalError
  }
}

/// ACMP status code (IEEE 1722.1-2013 §8.2.1.18). Distinct from AEM status:
/// ACMP commands route through Talker/Listener pairs, so the failure modes
/// reflect bandwidth/destination-MAC/connection-state issues rather than
/// descriptor lookups.
public enum LocalEntityControlStatus: UInt16, Error {
  case success = 0
  case listenerUnknownID = 1
  case talkerUnknownID = 2
  case talkerDestMacFail = 3
  case talkerNoStreamIndex = 4
  case talkerNoBandwidth = 5
  case talkerExclusive = 6
  case listenerTalkerTimeout = 7
  case listenerExclusive = 8
  case stateUnavailable = 9
  case notConnected = 10
  case noSuchConnection = 11
  case couldNotSendMessage = 12
  case talkerMisbehaving = 13
  case listenerMisbehaving = 14
  case controllerNotAuthorized = 16
  case incompatibleRequest = 17
  case notSupported = 31
  case baseProtocolViolation = 991
  case networkError = 995
  case protocolError = 996
  case timedOut = 997
  case unknownEntity = 998
  case internalError = 999

  /// Lossy init: unknown `raw` values collapse to `.internalError` so
  /// callers always get a usable error rather than nil. Use the synthesised
  /// `init(rawValue:)` if you need to distinguish "unknown value" from
  /// the catch-all internal-error case.
  public init(_ raw: UInt16) {
    self = Self(rawValue: raw) ?? .internalError
  }
}

/// Milan AECP-MVU status code (Milan 1.3 §5.3.5). Codes 0..10 overlap with
/// AEM but the upper-band reserved values differ; the library-level codes
/// (995..999) match across all three status enums.
public enum LocalEntityMvuCommandStatus: UInt16, Error {
  case success = 0
  case notImplemented = 1
  case noSuchDescriptor = 2
  case entityLocked = 3
  case badArguments = 7
  case entityMisbehaving = 10
  case payloadTooShort = 13
  case baseProtocolViolation = 991
  case partialImplementation = 992
  case busy = 993
  case networkError = 995
  case protocolError = 996
  case timedOut = 997
  case unknownEntity = 998
  case internalError = 999

  public init(_ raw: UInt16) {
    self = Self(rawValue: raw) ?? .internalError
  }
}

/// Notification protocol for `LocalEntity`. Receives change notifications
/// driven by la_avdecc's controller `Delegate` — the events fire whenever
/// another controller mutates a remote entity, sniffed ACMP traffic
/// reveals new connection state, counters tick, or AECP statistics
/// arrive. ~80 methods total; every one has a default no-op
/// implementation in the extension below, so conformers only override
/// the events they care about.
///
/// Threading: la_avdecc fires these on its executor / state-machine
/// threads. `LocalEntityDelegate` is `Sendable`-compatible (held weakly
/// by `LocalEntity`); conformers are responsible for hopping to their
/// own actor / queue if they need to mutate UI state.
///
/// Lifetime of borrowed values:
///   - `Entity`, `StreamInfo`, `AvbInfo`, `AsPath`, `StreamInputInfoEx`
///     hold a borrowed pointer into la_avdecc; do not retain past the
///     callback. Read what you need synchronously.
///   - `[UInt8]` payloads (control values, packed counters) are copied
///     out of la_avdecc's storage before delivery and are safe to keep.
public protocol LocalEntityDelegate: AnyObject {
  // Global / lifecycle
  func onTransportError(_: LocalEntity)
  func onEntityOnline(_: LocalEntity, id: UniqueIdentifier, entity: Entity)
  func onEntityUpdate(_: LocalEntity, id: UniqueIdentifier, entity: Entity)
  func onEntityOffline(_: LocalEntity, id: UniqueIdentifier)
  func onEntityIdentifyNotification(_: LocalEntity, id: UniqueIdentifier)
  func onDeregisteredFromUnsolicitedNotifications(
    _: LocalEntity, id: UniqueIdentifier
  )

  // Sniffed ACMP — six events sharing the same shape.
  func onControllerConnectResponseSniffed(
    _: LocalEntity, state: StreamConnectionState,
    status: LocalEntityControlStatus
  )
  func onControllerDisconnectResponseSniffed(
    _: LocalEntity, state: StreamConnectionState,
    status: LocalEntityControlStatus
  )
  func onListenerConnectResponseSniffed(
    _: LocalEntity, state: StreamConnectionState,
    status: LocalEntityControlStatus
  )
  func onListenerDisconnectResponseSniffed(
    _: LocalEntity, state: StreamConnectionState,
    status: LocalEntityControlStatus
  )
  func onGetTalkerStreamStateResponseSniffed(
    _: LocalEntity, state: StreamConnectionState,
    status: LocalEntityControlStatus
  )
  func onGetListenerStreamStateResponseSniffed(
    _: LocalEntity, state: StreamConnectionState,
    status: LocalEntityControlStatus
  )

  // Acquire / release / lock / unlock.
  func onEntityAcquired(
    _: LocalEntity, id: UniqueIdentifier, owningEntity: UniqueIdentifier,
    descriptorType: UInt16, descriptorIndex: UInt16
  )
  func onEntityReleased(
    _: LocalEntity, id: UniqueIdentifier, owningEntity: UniqueIdentifier,
    descriptorType: UInt16, descriptorIndex: UInt16
  )
  func onEntityLocked(
    _: LocalEntity, id: UniqueIdentifier, lockingEntity: UniqueIdentifier,
    descriptorType: UInt16, descriptorIndex: UInt16
  )
  func onEntityUnlocked(
    _: LocalEntity, id: UniqueIdentifier, lockingEntity: UniqueIdentifier,
    descriptorType: UInt16, descriptorIndex: UInt16
  )

  // Configuration / clock-source / association.
  func onConfigurationChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16
  )
  func onAssociationIDChanged(
    _: LocalEntity, id: UniqueIdentifier, associationID: UniqueIdentifier
  )
  func onClockSourceChanged(
    _: LocalEntity, id: UniqueIdentifier,
    clockDomainIndex: UInt16, clockSourceIndex: UInt16
  )

  // Stream format / mappings / info / start-stop.
  func onStreamInputFormatChanged(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    streamFormat: StreamFormat
  )
  func onStreamOutputFormatChanged(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    streamFormat: StreamFormat
  )
  func onStreamPortInputAudioMappingsChanged(
    _: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16,
    numberOfMaps: UInt16, mapIndex: UInt16, mappings: [AudioMapping]
  )
  func onStreamPortOutputAudioMappingsChanged(
    _: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16,
    numberOfMaps: UInt16, mapIndex: UInt16, mappings: [AudioMapping]
  )
  func onStreamPortInputAudioMappingsAdded(
    _: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16,
    mappings: [AudioMapping]
  )
  func onStreamPortOutputAudioMappingsAdded(
    _: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16,
    mappings: [AudioMapping]
  )
  func onStreamPortInputAudioMappingsRemoved(
    _: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16,
    mappings: [AudioMapping]
  )
  func onStreamPortOutputAudioMappingsRemoved(
    _: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16,
    mappings: [AudioMapping]
  )
  func onStreamInputInfoChanged(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    info: StreamInfo, fromGetResponse: Bool
  )
  func onStreamOutputInfoChanged(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    info: StreamInfo, fromGetResponse: Bool
  )
  func onStreamInputStarted(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16
  )
  func onStreamOutputStarted(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16
  )
  func onStreamInputStopped(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16
  )
  func onStreamOutputStopped(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16
  )
  /// `maxTransitTime` is in nanoseconds (la_avdecc reports
  /// `std::chrono::nanoseconds`).
  func onMaxTransitTimeChanged(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    maxTransitTime: UInt64
  )

  // Names — entity / config / descriptor flavours.
  func onEntityNameChanged(
    _: LocalEntity, id: UniqueIdentifier, name: String
  )
  func onEntityGroupNameChanged(
    _: LocalEntity, id: UniqueIdentifier, name: String
  )
  func onConfigurationNameChanged(
    _: LocalEntity, id: UniqueIdentifier,
    configurationIndex: UInt16, name: String
  )
  func onAudioUnitNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    audioUnitIndex: UInt16, name: String
  )
  func onStreamInputNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    streamIndex: UInt16, name: String
  )
  func onStreamOutputNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    streamIndex: UInt16, name: String
  )
  func onJackInputNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    jackIndex: UInt16, name: String
  )
  func onJackOutputNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    jackIndex: UInt16, name: String
  )
  func onAvbInterfaceNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    avbInterfaceIndex: UInt16, name: String
  )
  func onClockSourceNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    clockSourceIndex: UInt16, name: String
  )
  func onMemoryObjectNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    memoryObjectIndex: UInt16, name: String
  )
  func onAudioClusterNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    audioClusterIndex: UInt16, name: String
  )
  func onControlNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    controlIndex: UInt16, name: String
  )
  func onClockDomainNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    clockDomainIndex: UInt16, name: String
  )
  func onTimingNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    timingIndex: UInt16, name: String
  )
  func onPtpInstanceNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    ptpInstanceIndex: UInt16, name: String
  )
  func onPtpPortNameChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    ptpPortIndex: UInt16, name: String
  )

  // Sampling rates.
  func onAudioUnitSamplingRateChanged(
    _: LocalEntity, id: UniqueIdentifier,
    audioUnitIndex: UInt16, samplingRate: UInt32
  )
  func onVideoClusterSamplingRateChanged(
    _: LocalEntity, id: UniqueIdentifier,
    videoClusterIndex: UInt16, samplingRate: UInt32
  )
  func onSensorClusterSamplingRateChanged(
    _: LocalEntity, id: UniqueIdentifier,
    sensorClusterIndex: UInt16, samplingRate: UInt32
  )

  // Counters.
  func onEntityCountersChanged(
    _: LocalEntity, id: UniqueIdentifier,
    valid: EntityCounterValidFlags, counters: DescriptorCounters
  )
  func onAvbInterfaceCountersChanged(
    _: LocalEntity, id: UniqueIdentifier, avbInterfaceIndex: UInt16,
    valid: AvbInterfaceCounterValidFlags, counters: DescriptorCounters
  )
  func onClockDomainCountersChanged(
    _: LocalEntity, id: UniqueIdentifier, clockDomainIndex: UInt16,
    valid: ClockDomainCounterValidFlags, counters: DescriptorCounters
  )
  func onStreamInputCountersChanged(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    valid: StreamInputCounterValidFlags, counters: DescriptorCounters
  )
  func onStreamOutputCountersChanged(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    valid: StreamOutputCounterValidFlags, counters: DescriptorCounters
  )

  // AVB / AS path / control values.
  func onAvbInfoChanged(
    _: LocalEntity, id: UniqueIdentifier, avbInterfaceIndex: UInt16,
    info: AvbInfo
  )
  func onAsPathChanged(
    _: LocalEntity, id: UniqueIdentifier, avbInterfaceIndex: UInt16,
    asPath: AsPath
  )
  func onControlValuesChanged(
    _: LocalEntity, id: UniqueIdentifier, controlIndex: UInt16,
    packedControlValues: [UInt8]
  )

  // Memory object / operation.
  func onMemoryObjectLengthChanged(
    _: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16,
    memoryObjectIndex: UInt16, length: UInt64
  )
  func onOperationStatus(
    _: LocalEntity, id: UniqueIdentifier,
    descriptorType: UInt16, descriptorIndex: UInt16,
    operationID: UInt16, percentComplete: UInt16
  )

  // Milan MVU.
  func onSystemUniqueIDChanged(
    _: LocalEntity, id: UniqueIdentifier,
    systemUniqueID: UniqueIdentifier, systemName: String
  )
  func onMediaClockReferenceInfoChanged(
    _: LocalEntity, id: UniqueIdentifier, clockDomainIndex: UInt16,
    defaultPriority: DefaultMediaClockReferencePriority,
    info: MediaClockReferenceInfo
  )
  func onBindStream(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    talker: StreamIdentification, flags: BindStreamFlags
  )
  func onUnbindStream(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16
  )
  func onStreamInputInfoExChanged(
    _: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16,
    info: StreamInputInfoEx
  )

  // Statistics.
  func onAecpRetry(_: LocalEntity, id: UniqueIdentifier)
  func onAecpTimeout(_: LocalEntity, id: UniqueIdentifier)
  func onAecpUnexpectedResponse(_: LocalEntity, id: UniqueIdentifier)
  /// `responseTime` is in milliseconds.
  func onAecpResponseTime(
    _: LocalEntity, id: UniqueIdentifier, responseTime: UInt64
  )
  func onAemAecpUnsolicitedReceived(
    _: LocalEntity, id: UniqueIdentifier, sequenceID: UInt16
  )
  func onMvuAecpUnsolicitedReceived(
    _: LocalEntity, id: UniqueIdentifier, sequenceID: UInt16
  )
}

public extension LocalEntityDelegate {
  // Default no-op implementations so conformers override only what they
  // care about. The `_:` parameter labels are unused intentionally —
  // override sites usually shadow them.
  func onTransportError(_: LocalEntity) {}
  func onEntityOnline(_: LocalEntity, id _: UniqueIdentifier, entity _: Entity) {}
  func onEntityUpdate(_: LocalEntity, id _: UniqueIdentifier, entity _: Entity) {}
  func onEntityOffline(_: LocalEntity, id _: UniqueIdentifier) {}
  func onEntityIdentifyNotification(_: LocalEntity, id _: UniqueIdentifier) {}
  func onDeregisteredFromUnsolicitedNotifications(
    _: LocalEntity, id _: UniqueIdentifier
  ) {}

  func onControllerConnectResponseSniffed(
    _: LocalEntity, state _: StreamConnectionState,
    status _: LocalEntityControlStatus
  ) {}
  func onControllerDisconnectResponseSniffed(
    _: LocalEntity, state _: StreamConnectionState,
    status _: LocalEntityControlStatus
  ) {}
  func onListenerConnectResponseSniffed(
    _: LocalEntity, state _: StreamConnectionState,
    status _: LocalEntityControlStatus
  ) {}
  func onListenerDisconnectResponseSniffed(
    _: LocalEntity, state _: StreamConnectionState,
    status _: LocalEntityControlStatus
  ) {}
  func onGetTalkerStreamStateResponseSniffed(
    _: LocalEntity, state _: StreamConnectionState,
    status _: LocalEntityControlStatus
  ) {}
  func onGetListenerStreamStateResponseSniffed(
    _: LocalEntity, state _: StreamConnectionState,
    status _: LocalEntityControlStatus
  ) {}

  func onEntityAcquired(
    _: LocalEntity, id _: UniqueIdentifier, owningEntity _: UniqueIdentifier,
    descriptorType _: UInt16, descriptorIndex _: UInt16
  ) {}
  func onEntityReleased(
    _: LocalEntity, id _: UniqueIdentifier, owningEntity _: UniqueIdentifier,
    descriptorType _: UInt16, descriptorIndex _: UInt16
  ) {}
  func onEntityLocked(
    _: LocalEntity, id _: UniqueIdentifier, lockingEntity _: UniqueIdentifier,
    descriptorType _: UInt16, descriptorIndex _: UInt16
  ) {}
  func onEntityUnlocked(
    _: LocalEntity, id _: UniqueIdentifier, lockingEntity _: UniqueIdentifier,
    descriptorType _: UInt16, descriptorIndex _: UInt16
  ) {}

  func onConfigurationChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16
  ) {}
  func onAssociationIDChanged(
    _: LocalEntity, id _: UniqueIdentifier, associationID _: UniqueIdentifier
  ) {}
  func onClockSourceChanged(
    _: LocalEntity, id _: UniqueIdentifier,
    clockDomainIndex _: UInt16, clockSourceIndex _: UInt16
  ) {}

  func onStreamInputFormatChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    streamFormat _: StreamFormat
  ) {}
  func onStreamOutputFormatChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    streamFormat _: StreamFormat
  ) {}
  func onStreamPortInputAudioMappingsChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamPortIndex _: UInt16,
    numberOfMaps _: UInt16, mapIndex _: UInt16, mappings _: [AudioMapping]
  ) {}
  func onStreamPortOutputAudioMappingsChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamPortIndex _: UInt16,
    numberOfMaps _: UInt16, mapIndex _: UInt16, mappings _: [AudioMapping]
  ) {}
  func onStreamPortInputAudioMappingsAdded(
    _: LocalEntity, id _: UniqueIdentifier, streamPortIndex _: UInt16,
    mappings _: [AudioMapping]
  ) {}
  func onStreamPortOutputAudioMappingsAdded(
    _: LocalEntity, id _: UniqueIdentifier, streamPortIndex _: UInt16,
    mappings _: [AudioMapping]
  ) {}
  func onStreamPortInputAudioMappingsRemoved(
    _: LocalEntity, id _: UniqueIdentifier, streamPortIndex _: UInt16,
    mappings _: [AudioMapping]
  ) {}
  func onStreamPortOutputAudioMappingsRemoved(
    _: LocalEntity, id _: UniqueIdentifier, streamPortIndex _: UInt16,
    mappings _: [AudioMapping]
  ) {}
  func onStreamInputInfoChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    info _: StreamInfo, fromGetResponse _: Bool
  ) {}
  func onStreamOutputInfoChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    info _: StreamInfo, fromGetResponse _: Bool
  ) {}
  func onStreamInputStarted(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16
  ) {}
  func onStreamOutputStarted(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16
  ) {}
  func onStreamInputStopped(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16
  ) {}
  func onStreamOutputStopped(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16
  ) {}
  func onMaxTransitTimeChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    maxTransitTime _: UInt64
  ) {}

  func onEntityNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, name _: String
  ) {}
  func onEntityGroupNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, name _: String
  ) {}
  func onConfigurationNameChanged(
    _: LocalEntity, id _: UniqueIdentifier,
    configurationIndex _: UInt16, name _: String
  ) {}
  func onAudioUnitNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    audioUnitIndex _: UInt16, name _: String
  ) {}
  func onStreamInputNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    streamIndex _: UInt16, name _: String
  ) {}
  func onStreamOutputNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    streamIndex _: UInt16, name _: String
  ) {}
  func onJackInputNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    jackIndex _: UInt16, name _: String
  ) {}
  func onJackOutputNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    jackIndex _: UInt16, name _: String
  ) {}
  func onAvbInterfaceNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    avbInterfaceIndex _: UInt16, name _: String
  ) {}
  func onClockSourceNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    clockSourceIndex _: UInt16, name _: String
  ) {}
  func onMemoryObjectNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    memoryObjectIndex _: UInt16, name _: String
  ) {}
  func onAudioClusterNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    audioClusterIndex _: UInt16, name _: String
  ) {}
  func onControlNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    controlIndex _: UInt16, name _: String
  ) {}
  func onClockDomainNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    clockDomainIndex _: UInt16, name _: String
  ) {}
  func onTimingNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    timingIndex _: UInt16, name _: String
  ) {}
  func onPtpInstanceNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    ptpInstanceIndex _: UInt16, name _: String
  ) {}
  func onPtpPortNameChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    ptpPortIndex _: UInt16, name _: String
  ) {}

  func onAudioUnitSamplingRateChanged(
    _: LocalEntity, id _: UniqueIdentifier,
    audioUnitIndex _: UInt16, samplingRate _: UInt32
  ) {}
  func onVideoClusterSamplingRateChanged(
    _: LocalEntity, id _: UniqueIdentifier,
    videoClusterIndex _: UInt16, samplingRate _: UInt32
  ) {}
  func onSensorClusterSamplingRateChanged(
    _: LocalEntity, id _: UniqueIdentifier,
    sensorClusterIndex _: UInt16, samplingRate _: UInt32
  ) {}

  func onEntityCountersChanged(
    _: LocalEntity, id _: UniqueIdentifier,
    valid _: EntityCounterValidFlags, counters _: DescriptorCounters
  ) {}
  func onAvbInterfaceCountersChanged(
    _: LocalEntity, id _: UniqueIdentifier, avbInterfaceIndex _: UInt16,
    valid _: AvbInterfaceCounterValidFlags, counters _: DescriptorCounters
  ) {}
  func onClockDomainCountersChanged(
    _: LocalEntity, id _: UniqueIdentifier, clockDomainIndex _: UInt16,
    valid _: ClockDomainCounterValidFlags, counters _: DescriptorCounters
  ) {}
  func onStreamInputCountersChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    valid _: StreamInputCounterValidFlags, counters _: DescriptorCounters
  ) {}
  func onStreamOutputCountersChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    valid _: StreamOutputCounterValidFlags, counters _: DescriptorCounters
  ) {}

  func onAvbInfoChanged(
    _: LocalEntity, id _: UniqueIdentifier, avbInterfaceIndex _: UInt16,
    info _: AvbInfo
  ) {}
  func onAsPathChanged(
    _: LocalEntity, id _: UniqueIdentifier, avbInterfaceIndex _: UInt16,
    asPath _: AsPath
  ) {}
  func onControlValuesChanged(
    _: LocalEntity, id _: UniqueIdentifier, controlIndex _: UInt16,
    packedControlValues _: [UInt8]
  ) {}

  func onMemoryObjectLengthChanged(
    _: LocalEntity, id _: UniqueIdentifier, configurationIndex _: UInt16,
    memoryObjectIndex _: UInt16, length _: UInt64
  ) {}
  func onOperationStatus(
    _: LocalEntity, id _: UniqueIdentifier,
    descriptorType _: UInt16, descriptorIndex _: UInt16,
    operationID _: UInt16, percentComplete _: UInt16
  ) {}

  func onSystemUniqueIDChanged(
    _: LocalEntity, id _: UniqueIdentifier,
    systemUniqueID _: UniqueIdentifier, systemName _: String
  ) {}
  func onMediaClockReferenceInfoChanged(
    _: LocalEntity, id _: UniqueIdentifier, clockDomainIndex _: UInt16,
    defaultPriority _: DefaultMediaClockReferencePriority,
    info _: MediaClockReferenceInfo
  ) {}
  func onBindStream(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    talker _: StreamIdentification, flags _: BindStreamFlags
  ) {}
  func onUnbindStream(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16
  ) {}
  func onStreamInputInfoExChanged(
    _: LocalEntity, id _: UniqueIdentifier, streamIndex _: UInt16,
    info _: StreamInputInfoEx
  ) {}

  func onAecpRetry(_: LocalEntity, id _: UniqueIdentifier) {}
  func onAecpTimeout(_: LocalEntity, id _: UniqueIdentifier) {}
  func onAecpUnexpectedResponse(_: LocalEntity, id _: UniqueIdentifier) {}
  func onAecpResponseTime(
    _: LocalEntity, id _: UniqueIdentifier, responseTime _: UInt64
  ) {}
  func onAemAecpUnsolicitedReceived(
    _: LocalEntity, id _: UniqueIdentifier, sequenceID _: UInt16
  ) {}
  func onMvuAecpUnsolicitedReceived(
    _: LocalEntity, id _: UniqueIdentifier, sequenceID _: UInt16
  ) {}
}

/// Wraps an la_avdecc AggregateEntity (controller flavour). Backed by
/// AVDECCSwift::LocalEntityOwner — refcounted C++ class imported via
/// SWIFT_SHARED_REFERENCE; Swift ARC drives retain/release. The C++ wrapper
/// exists because la_avdecc's controller::Interface uses std::function-typed
/// AECP handlers Swift can't construct, and AggregateEntity::create takes a
/// std::map<> Swift can't build.
public final class LocalEntity: @unchecked Sendable {
  let protocolInterface: ProtocolInterface
  let owner: AVDECCSwift.LocalEntityOwner

  /// Subscribes to la_avdecc's controller `Delegate` change-notification
  /// stream. Setting to a non-nil value installs blocks (Block_copy'd into
  /// C++ slots) for every event and attaches the delegate; setting to nil
  /// detaches and clears every slot. The delegate is held weakly to avoid
  /// retain cycles through the captured-block forwarders.
  public weak var delegate: LocalEntityDelegate? {
    didSet { rebindDelegate() }
  }

  public init(protocolInterface: ProtocolInterface, entityID: UniqueIdentifier) throws {
    self.protocolInterface = protocolInterface
    let mac = protocolInterface.macAddressBytes
    guard mac.count == 6 else {
      throw LocalEntityError(code: .invalidParameters, message: "interface MAC unavailable")
    }
    var captured = AVDECCSwift.CapturedException()
    let owner: AVDECCSwift.LocalEntityOwner? = mac.withUnsafeBufferPointer { buf in
      AVDECCSwift.LocalEntityOwner.create(
        protocolInterface.owner, entityID.rawValue, buf.baseAddress!, &captured
      )
    }
    guard let owner else { throw LocalEntityError(captured) }
    self.owner = owner
  }

  public func close() {
    delegate = nil
    owner.close()
  }

  deinit {
    owner.close()
  }

  // MARK: - Discovery + advertising

  /// Begin announcing the local entity on the wire (ADP). `available-
  /// Duration` is in 2-second units (per IEEE 1722.1 §6.2.2.6) — the
  /// number of those units the entity will be considered alive without
  /// re-advertising. `interfaceIndex` defaults to the global interface;
  /// pass a specific index for multi-homed entities. Returns `true` on
  /// success.
  @discardableResult
  public func enableEntityAdvertising(
    availableDuration: UInt32 = 31, interfaceIndex: UInt16? = nil
  ) -> Bool {
    owner.enableEntityAdvertising(
      availableDuration, interfaceIndex != nil, interfaceIndex ?? 0
    )
  }

  public func disableEntityAdvertising(interfaceIndex: UInt16? = nil) {
    owner.disableEntityAdvertising(interfaceIndex != nil, interfaceIndex ?? 0)
  }

  /// Trigger a discovery sweep (DISCOVER ADP message). Returns `false`
  /// if the entity has been closed.
  @discardableResult
  public func discoverRemoteEntities() -> Bool {
    owner.discoverRemoteEntities()
  }

  /// Trigger a directed discovery for a single entity ID.
  @discardableResult
  public func discoverRemoteEntity(id: UniqueIdentifier) -> Bool {
    owner.discoverRemoteEntity(id.rawValue)
  }

  /// Override the controller's default delay before re-issuing automatic
  /// discovery sweeps.
  public func setAutomaticDiscoveryDelay(milliseconds: UInt32) {
    owner.setAutomaticDiscoveryDelay(milliseconds)
  }

  // MARK: - AEM commands (subset)

  /// Acquire (or attempt to acquire) the target entity. `descriptorType`
  /// / `descriptorIndex` default to 0/0 = whole entity. Throws on
  /// failure; on success returns the entity ID that holds the
  /// acquisition (the local controller's, when status is success).
  @discardableResult
  public func acquireEntity(
    id targetEntityID: UniqueIdentifier,
    persistent: Bool = false,
    descriptorType: UInt16 = 0,
    descriptorIndex: UInt16 = 0
  ) async throws -> UniqueIdentifier {
    try await withCheckedThrowingContinuation { cont in
      owner.acquireEntity(
        targetEntityID.rawValue, persistent, descriptorType, descriptorIndex
      ) { status, owning in
        if status == 0 {
          cont.resume(returning: UniqueIdentifier(owning))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  @discardableResult
  public func releaseEntity(
    id targetEntityID: UniqueIdentifier,
    descriptorType: UInt16 = 0,
    descriptorIndex: UInt16 = 0
  ) async throws -> UniqueIdentifier {
    try await withCheckedThrowingContinuation { cont in
      owner
        .releaseEntity(targetEntityID.rawValue, descriptorType, descriptorIndex) { status, owning in
          if status == 0 {
            cont.resume(returning: UniqueIdentifier(owning))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
    }
  }

  @discardableResult
  public func lockEntity(
    id targetEntityID: UniqueIdentifier,
    descriptorType: UInt16 = 0,
    descriptorIndex: UInt16 = 0
  ) async throws -> UniqueIdentifier {
    try await withCheckedThrowingContinuation { cont in
      owner
        .lockEntity(targetEntityID.rawValue, descriptorType, descriptorIndex) { status, locking in
          if status == 0 {
            cont.resume(returning: UniqueIdentifier(locking))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
    }
  }

  @discardableResult
  public func unlockEntity(
    id targetEntityID: UniqueIdentifier,
    descriptorType: UInt16 = 0,
    descriptorIndex: UInt16 = 0
  ) async throws -> UniqueIdentifier {
    try await withCheckedThrowingContinuation { cont in
      owner
        .unlockEntity(targetEntityID.rawValue, descriptorType, descriptorIndex) { status, locking in
          if status == 0 {
            cont.resume(returning: UniqueIdentifier(locking))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
    }
  }

  public func registerUnsolicitedNotifications(id targetEntityID: UniqueIdentifier) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.registerUnsolicitedNotifications(targetEntityID.rawValue) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func unregisterUnsolicitedNotifications(id targetEntityID: UniqueIdentifier) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.unregisterUnsolicitedNotifications(targetEntityID.rawValue) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  /// Read the current active configuration index.
  public func getConfiguration(id targetEntityID: UniqueIdentifier) async throws -> UInt16 {
    try await withCheckedThrowingContinuation { cont in
      owner.getConfiguration(targetEntityID.rawValue) { status, idx in
        if status == 0 {
          cont.resume(returning: idx)
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func setConfiguration(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16
  ) async throws -> UInt16 {
    try await withCheckedThrowingContinuation { cont in
      owner.setConfiguration(targetEntityID.rawValue, configurationIndex) { status, idx in
        if status == 0 {
          cont.resume(returning: idx)
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func setEntityName(id targetEntityID: UniqueIdentifier, to name: String) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      var name = name
      name.withUTF8 { utf8 in
        owner.setEntityName(
          targetEntityID.rawValue, UnsafeRawPointer(utf8.baseAddress), utf8.count
        ) { status in
          if status == 0 {
            cont.resume()
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
      }
    }
  }

  public func setEntityGroupName(id targetEntityID: UniqueIdentifier, name: String) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      var name = name
      name.withUTF8 { utf8 in
        owner.setEntityGroupName(
          targetEntityID.rawValue, UnsafeRawPointer(utf8.baseAddress), utf8.count
        ) { status in
          if status == 0 {
            cont.resume()
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
      }
    }
  }

  public func getEntityGroupName(id targetEntityID: UniqueIdentifier) async throws -> String {
    try await withCheckedThrowingContinuation { cont in
      owner.getEntityGroupName(targetEntityID.rawValue) { status, name in
        if status == 0, let name {
          cont.resume(returning: String(name.pointee.str()))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func setConfigurationName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, name: String
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      var name = name
      name.withUTF8 { utf8 in
        owner.setConfigurationName(
          targetEntityID.rawValue, configurationIndex,
          UnsafeRawPointer(utf8.baseAddress), utf8.count
        ) { status in
          if status == 0 {
            cont.resume()
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
      }
    }
  }

  public func setAudioUnitName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    audioUnitIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, audioUnitIndex, name) {
    self.owner.setAudioUnitName($0, $1, $2, $3, $4, $5)
  }}

  public func getAudioUnitName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, audioUnitIndex: UInt16
  ) async throws
    -> String { try await _getName(targetEntityID, configurationIndex, audioUnitIndex) {
      self.owner.getAudioUnitName($0, $1, $2, $3)
    }}

  public func setStreamInputName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    streamIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, streamIndex, name) {
    self.owner.setStreamInputName($0, $1, $2, $3, $4, $5)
  }}

  public func getStreamInputName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, streamIndex: UInt16
  ) async throws -> String { try await _getName(targetEntityID, configurationIndex, streamIndex) {
    self.owner.getStreamInputName($0, $1, $2, $3)
  }}

  public func setStreamOutputName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    streamIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, streamIndex, name) {
    self.owner.setStreamOutputName($0, $1, $2, $3, $4, $5)
  }}

  public func getStreamOutputName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, streamIndex: UInt16
  ) async throws -> String { try await _getName(targetEntityID, configurationIndex, streamIndex) {
    self.owner.getStreamOutputName($0, $1, $2, $3)
  }}

  public func setAvbInterfaceName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    avbInterfaceIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, avbInterfaceIndex, name) {
    self.owner.setAvbInterfaceName($0, $1, $2, $3, $4, $5)
  }}

  public func getAvbInterfaceName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, avbInterfaceIndex: UInt16
  ) async throws -> String { try await _getName(
    targetEntityID,
    configurationIndex,
    avbInterfaceIndex
  ) {
    self.owner.getAvbInterfaceName($0, $1, $2, $3)
  }}

  public func setClockSourceName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    clockSourceIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, clockSourceIndex, name) {
    self.owner.setClockSourceName($0, $1, $2, $3, $4, $5)
  }}

  public func getClockSourceName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, clockSourceIndex: UInt16
  ) async throws -> String { try await _getName(
    targetEntityID,
    configurationIndex,
    clockSourceIndex
  ) {
    self.owner.getClockSourceName($0, $1, $2, $3)
  }}

  public func setMemoryObjectName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    memoryObjectIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, memoryObjectIndex, name) {
    self.owner.setMemoryObjectName($0, $1, $2, $3, $4, $5)
  }}

  public func getMemoryObjectName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, memoryObjectIndex: UInt16
  ) async throws -> String { try await _getName(
    targetEntityID,
    configurationIndex,
    memoryObjectIndex
  ) {
    self.owner.getMemoryObjectName($0, $1, $2, $3)
  }}

  public func setAudioClusterName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    clusterIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, clusterIndex, name) {
    self.owner.setAudioClusterName($0, $1, $2, $3, $4, $5)
  }}

  public func getAudioClusterName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, clusterIndex: UInt16
  ) async throws -> String { try await _getName(targetEntityID, configurationIndex, clusterIndex) {
    self.owner.getAudioClusterName($0, $1, $2, $3)
  }}

  public func setClockDomainName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    clockDomainIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, clockDomainIndex, name) {
    self.owner.setClockDomainName($0, $1, $2, $3, $4, $5)
  }}

  public func getClockDomainName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, clockDomainIndex: UInt16
  ) async throws -> String { try await _getName(
    targetEntityID,
    configurationIndex,
    clockDomainIndex
  ) {
    self.owner.getClockDomainName($0, $1, $2, $3)
  }}

  public func setJackInputName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    jackIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, jackIndex, name) {
    self.owner.setJackInputName($0, $1, $2, $3, $4, $5)
  }}

  public func getJackInputName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, jackIndex: UInt16
  ) async throws -> String { try await _getName(targetEntityID, configurationIndex, jackIndex) {
    self.owner.getJackInputName($0, $1, $2, $3)
  }}

  public func setJackOutputName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    jackIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, jackIndex, name) {
    self.owner.setJackOutputName($0, $1, $2, $3, $4, $5)
  }}

  public func getJackOutputName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, jackIndex: UInt16
  ) async throws -> String { try await _getName(targetEntityID, configurationIndex, jackIndex) {
    self.owner.getJackOutputName($0, $1, $2, $3)
  }}

  public func setControlName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    controlIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, controlIndex, name) {
    self.owner.setControlName($0, $1, $2, $3, $4, $5)
  }}

  public func getControlName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, controlIndex: UInt16
  ) async throws -> String { try await _getName(targetEntityID, configurationIndex, controlIndex) {
    self.owner.getControlName($0, $1, $2, $3)
  }}

  public func setTimingName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    timingIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, timingIndex, name) {
    self.owner.setTimingName($0, $1, $2, $3, $4, $5)
  }}

  public func getTimingName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, timingIndex: UInt16
  ) async throws -> String { try await _getName(targetEntityID, configurationIndex, timingIndex) {
    self.owner.getTimingName($0, $1, $2, $3)
  }}

  public func setPtpInstanceName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    ptpInstanceIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, ptpInstanceIndex, name) {
    self.owner.setPtpInstanceName($0, $1, $2, $3, $4, $5)
  }}

  public func getPtpInstanceName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, ptpInstanceIndex: UInt16
  ) async throws -> String { try await _getName(
    targetEntityID,
    configurationIndex,
    ptpInstanceIndex
  ) {
    self.owner.getPtpInstanceName($0, $1, $2, $3)
  }}

  public func setPtpPortName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    ptpPortIndex: UInt16, name: String
  ) async throws { try await _setName(targetEntityID, configurationIndex, ptpPortIndex, name) {
    self.owner.setPtpPortName($0, $1, $2, $3, $4, $5)
  }}

  public func getPtpPortName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, ptpPortIndex: UInt16
  ) async throws -> String { try await _getName(targetEntityID, configurationIndex, ptpPortIndex) {
    self.owner.getPtpPortName($0, $1, $2, $3)
  }}

  // Private generic helpers — every set/get-Name pair has the same shape;
  // hide the boilerplate behind a function-typed handle into the C++
  // owner so each public method is one expression. Names are passed as a
  // raw UTF-8 byte span (`String.withUTF8` borrows the native UTF-8
  // backing storage when present, and the C++ helper drops them straight
  // into `AvdeccFixedString(ptr, size)` — no null-terminator round-trip).
  private func _setName(
    _ id: UniqueIdentifier, _ configIdx: UInt16, _ descIdx: UInt16, _ name: String,
    _ call: @escaping (
      UInt64,
      UInt16,
      UInt16,
      UnsafeRawPointer?,
      Int,
      @escaping (UInt16) -> ()
    ) -> ()
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      var mutableName = name
      mutableName.withUTF8 { utf8 in
        call(
          id.rawValue,
          configIdx,
          descIdx,
          UnsafeRawPointer(utf8.baseAddress),
          utf8.count
        ) { status in
          if status == 0 {
            cont.resume()
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
      }
    }
  }

  private func _getName(
    _ id: UniqueIdentifier, _ configIdx: UInt16, _ descIdx: UInt16,
    _ call: @escaping (
      UInt64,
      UInt16,
      UInt16,
      @escaping (UInt16, UnsafePointer<la.avdecc.entity.model.AvdeccFixedString>?) -> ()
    ) -> ()
  ) async throws -> String {
    try await withCheckedThrowingContinuation { cont in
      call(id.rawValue, configIdx, descIdx) { status, name in
        if status == 0, let name {
          cont.resume(returning: String(name.pointee.str()))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getEntityName(id targetEntityID: UniqueIdentifier) async throws -> String {
    try await withCheckedThrowingContinuation { cont in
      owner.getEntityName(targetEntityID.rawValue) { status, name in
        if status == 0, let name {
          cont.resume(returning: String(name.pointee.str()))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getConfigurationName(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16
  ) async throws -> String {
    try await withCheckedThrowingContinuation { cont in
      owner.getConfigurationName(targetEntityID.rawValue, configurationIndex) { status, name in
        if status == 0, let name {
          cont.resume(returning: String(name.pointee.str()))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func startStreamInput(
    id targetEntityID: UniqueIdentifier,
    streamIndex: UInt16
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.startStreamInput(targetEntityID.rawValue, streamIndex) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func startStreamOutput(
    id targetEntityID: UniqueIdentifier,
    streamIndex: UInt16
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.startStreamOutput(targetEntityID.rawValue, streamIndex) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func stopStreamInput(
    id targetEntityID: UniqueIdentifier,
    streamIndex: UInt16
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.stopStreamInput(targetEntityID.rawValue, streamIndex) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func stopStreamOutput(
    id targetEntityID: UniqueIdentifier,
    streamIndex: UInt16
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.stopStreamOutput(targetEntityID.rawValue, streamIndex) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getStreamInputFormat(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws -> StreamFormat {
    try await withCheckedThrowingContinuation { cont in
      owner.getStreamInputFormat(targetEntityID.rawValue, streamIndex) { status, _, fmt in
        if status == 0 {
          cont.resume(returning: StreamFormat(format: fmt))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func setStreamInputFormat(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16,
    to streamFormat: StreamFormat
  ) async throws -> StreamFormat {
    try await withCheckedThrowingContinuation { cont in
      owner
        .setStreamInputFormat(
          targetEntityID.rawValue,
          streamIndex,
          streamFormat.format
        ) { status, _, fmt in
          if status == 0 {
            cont.resume(returning: StreamFormat(format: fmt))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
    }
  }

  public func getStreamOutputFormat(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws -> StreamFormat {
    try await withCheckedThrowingContinuation { cont in
      owner.getStreamOutputFormat(targetEntityID.rawValue, streamIndex) { status, _, fmt in
        if status == 0 {
          cont.resume(returning: StreamFormat(format: fmt))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func setStreamOutputFormat(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16,
    to streamFormat: StreamFormat
  ) async throws -> StreamFormat {
    try await withCheckedThrowingContinuation { cont in
      owner
        .setStreamOutputFormat(
          targetEntityID.rawValue,
          streamIndex,
          streamFormat.format
        ) { status, _, fmt in
          if status == 0 {
            cont.resume(returning: StreamFormat(format: fmt))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
    }
  }

  public func getStreamInputInfo(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws -> StreamInfo {
    try await withCheckedThrowingContinuation { cont in
      owner.getStreamInputInfo(targetEntityID.rawValue, streamIndex) { status, _, info in
        if status == 0, let info {
          cont.resume(returning: StreamInfo(info.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getStreamOutputInfo(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws -> StreamInfo {
    try await withCheckedThrowingContinuation { cont in
      owner.getStreamOutputInfo(targetEntityID.rawValue, streamIndex) { status, _, info in
        if status == 0, let info {
          cont.resume(returning: StreamInfo(info.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  /// SET_STREAM_INPUT_INFO (IEEE 1722.1-2013 §7.4.16). Writes the
  /// changeable fields of a listener stream's `StreamInfo`. The typical
  /// usage is read–modify–write: call `getStreamInputInfo`, mutate the
  /// fields you care about, pass the result here. The entity echoes the
  /// post-set state back through the response.
  public func setStreamInputInfo(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16, info: StreamInfo
  ) async throws -> StreamInfo {
    try await _setStreamInfo(id: targetEntityID, streamIndex: streamIndex, info: info) {
      tid, si, fmt, flags, sid, lat, mac, vlan, cb in
      self.owner.setStreamInputInfo(tid, si, fmt, flags, sid, lat, mac, vlan, cb)
    }
  }

  /// SET_STREAM_OUTPUT_INFO (IEEE 1722.1-2013 §7.4.16). Talker-side
  /// counterpart to `setStreamInputInfo`.
  public func setStreamOutputInfo(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16, info: StreamInfo
  ) async throws -> StreamInfo {
    try await _setStreamInfo(id: targetEntityID, streamIndex: streamIndex, info: info) {
      tid, si, fmt, flags, sid, lat, mac, vlan, cb in
      self.owner.setStreamOutputInfo(tid, si, fmt, flags, sid, lat, mac, vlan, cb)
    }
  }

  /// Shared body for the input/output `setStreamInfo` pair. Pins the
  /// six-byte MAC array via `withUnsafeBufferPointer` for the duration of
  /// the C++ call (the helper memcpy's it before the dispatch returns), and
  /// adapts the StreamInfo response pointer to the Swift wrapper.
  private func _setStreamInfo(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16, info: StreamInfo,
    _ call: (
      UInt64, UInt16, UInt64, UInt32, UInt64, UInt32,
      UnsafePointer<UInt8>?, UInt16,
      @escaping (
        UInt16,
        UInt16,
        UnsafePointer<la.avdecc.entity.model.StreamInfo>?
      ) -> ()
    ) -> ()
  ) async throws -> StreamInfo {
    var mac = info.streamDestMac
    if mac.count < 6 { mac.append(contentsOf: [UInt8](repeating: 0, count: 6 - mac.count)) }
    return try await withCheckedThrowingContinuation { cont in
      mac.withUnsafeBufferPointer { macBuf in
        call(
          targetEntityID.rawValue, streamIndex,
          info.streamFormat.format,
          info.streamInfoFlags.rawValue,
          info.streamID.rawValue,
          info.msrpAccumulatedLatency,
          macBuf.baseAddress,
          info.streamVlanID
        ) { status, _, result in
          if status == 0, let result {
            cont.resume(returning: StreamInfo(result.pointee))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
      }
    }
  }

  /// Read the clock source currently selected for a clock domain.
  public func getClockSource(
    id targetEntityID: UniqueIdentifier, clockDomainIndex: UInt16
  ) async throws -> UInt16 {
    try await withCheckedThrowingContinuation { cont in
      owner.getClockSource(targetEntityID.rawValue, clockDomainIndex) { status, src in
        if status == 0 {
          cont.resume(returning: src)
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func setClockSource(
    id targetEntityID: UniqueIdentifier, clockDomainIndex: UInt16, clockSourceIndex: UInt16
  ) async throws -> UInt16 {
    try await withCheckedThrowingContinuation { cont in
      owner
        .setClockSource(
          targetEntityID.rawValue,
          clockDomainIndex,
          clockSourceIndex
        ) { status, src in
          if status == 0 {
            cont.resume(returning: src)
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
    }
  }

  /// Read the EntityDescriptor from a remote entity. The C++ block hands
  /// back a borrowed pointer to la_avdecc's `EntityDescriptor`; we copy
  /// the value into the Swift `EntityDescriptor` wrapper inside the
  /// closure (while the pointer is still live) and resume the continuation
  /// with the wrapper. The wrapper is `Sendable`, so the unsafe-pointer
  /// gymnastics from the previous revision are no longer required.
  public func readEntityDescriptor(id targetEntityID: UniqueIdentifier) async throws
    -> EntityDescriptor
  {
    try await withCheckedThrowingContinuation { cont in
      owner.readEntityDescriptor(targetEntityID.rawValue) { status, descriptor in
        if status == 0, let descriptor {
          cont.resume(returning: EntityDescriptor(descriptor.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getAvbInfo(
    id targetEntityID: UniqueIdentifier,
    avbInterfaceIndex: UInt16
  ) async throws -> AvbInfo {
    try await withCheckedThrowingContinuation { cont in
      owner.getAvbInfo(targetEntityID.rawValue, avbInterfaceIndex) { status, _, info in
        if status == 0, let info {
          cont.resume(returning: AvbInfo(info.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readConfigurationDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16
  ) async throws -> ConfigurationDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner
        .readConfigurationDescriptor(
          targetEntityID.rawValue,
          configurationIndex
        ) { status, _, desc in
          if status == 0, let desc {
            cont.resume(returning: ConfigurationDescriptor(desc.pointee))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
    }
  }

  public func readAvbInterfaceDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16,
    avbInterfaceIndex: UInt16
  ) async throws -> AvbInterfaceDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readAvbInterfaceDescriptor(
        targetEntityID.rawValue, configurationIndex, avbInterfaceIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: AvbInterfaceDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readStreamInputDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16,
    streamIndex: UInt16
  ) async throws -> StreamDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readStreamInputDescriptor(
        targetEntityID.rawValue, configurationIndex, streamIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: StreamDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readAudioUnitDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, audioUnitIndex: UInt16
  ) async throws -> AudioUnitDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readAudioUnitDescriptor(
        targetEntityID.rawValue, configurationIndex, audioUnitIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: AudioUnitDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readJackInputDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, jackIndex: UInt16
  ) async throws -> JackDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readJackInputDescriptor(
        targetEntityID.rawValue, configurationIndex, jackIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: JackDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readJackOutputDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, jackIndex: UInt16
  ) async throws -> JackDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readJackOutputDescriptor(
        targetEntityID.rawValue, configurationIndex, jackIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: JackDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readClockSourceDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, clockSourceIndex: UInt16
  ) async throws -> ClockSourceDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readClockSourceDescriptor(
        targetEntityID.rawValue, configurationIndex, clockSourceIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: ClockSourceDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readMemoryObjectDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, memoryObjectIndex: UInt16
  ) async throws -> MemoryObjectDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readMemoryObjectDescriptor(
        targetEntityID.rawValue, configurationIndex, memoryObjectIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: MemoryObjectDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readLocaleDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, localeIndex: UInt16
  ) async throws -> LocaleDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readLocaleDescriptor(
        targetEntityID.rawValue, configurationIndex, localeIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: LocaleDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readStringsDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, stringsIndex: UInt16
  ) async throws -> StringsDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readStringsDescriptor(
        targetEntityID.rawValue, configurationIndex, stringsIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: StringsDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readAudioClusterDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, clusterIndex: UInt16
  ) async throws -> AudioClusterDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readAudioClusterDescriptor(
        targetEntityID.rawValue, configurationIndex, clusterIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: AudioClusterDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readClockDomainDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16, clockDomainIndex: UInt16
  ) async throws -> ClockDomainDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readClockDomainDescriptor(
        targetEntityID.rawValue, configurationIndex, clockDomainIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: ClockDomainDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readStreamOutputDescriptor(
    id targetEntityID: UniqueIdentifier,
    configurationIndex: UInt16,
    streamIndex: UInt16
  ) async throws -> StreamDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readStreamOutputDescriptor(
        targetEntityID.rawValue, configurationIndex, streamIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: StreamDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getAsPath(
    id targetEntityID: UniqueIdentifier,
    avbInterfaceIndex: UInt16
  ) async throws -> AsPath {
    try await withCheckedThrowingContinuation { cont in
      owner.getAsPath(targetEntityID.rawValue, avbInterfaceIndex) { status, _, asPath in
        if status == 0, let asPath {
          cont.resume(returning: AsPath(asPath.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Additional descriptor reads

  public func readStreamPortInputDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, streamPortIndex: UInt16
  ) async throws -> StreamPortDescriptor { try await _readPortDescriptor(
    targetEntityID, configurationIndex, streamPortIndex
  ) {
    self.owner.readStreamPortInputDescriptor($0, $1, $2, $3)
  }}

  public func readStreamPortOutputDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, streamPortIndex: UInt16
  ) async throws -> StreamPortDescriptor { try await _readPortDescriptor(
    targetEntityID, configurationIndex, streamPortIndex
  ) {
    self.owner.readStreamPortOutputDescriptor($0, $1, $2, $3)
  }}

  public func readExternalPortInputDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, externalPortIndex: UInt16
  ) async throws -> ExternalPortDescriptor { try await _readExternalPortDescriptor(
    targetEntityID, configurationIndex, externalPortIndex
  ) {
    self.owner.readExternalPortInputDescriptor($0, $1, $2, $3)
  }}

  public func readExternalPortOutputDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, externalPortIndex: UInt16
  ) async throws -> ExternalPortDescriptor { try await _readExternalPortDescriptor(
    targetEntityID, configurationIndex, externalPortIndex
  ) {
    self.owner.readExternalPortOutputDescriptor($0, $1, $2, $3)
  }}

  public func readInternalPortInputDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, internalPortIndex: UInt16
  ) async throws -> InternalPortDescriptor { try await _readInternalPortDescriptor(
    targetEntityID, configurationIndex, internalPortIndex
  ) {
    self.owner.readInternalPortInputDescriptor($0, $1, $2, $3)
  }}

  public func readInternalPortOutputDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, internalPortIndex: UInt16
  ) async throws -> InternalPortDescriptor { try await _readInternalPortDescriptor(
    targetEntityID, configurationIndex, internalPortIndex
  ) {
    self.owner.readInternalPortOutputDescriptor($0, $1, $2, $3)
  }}

  public func readAudioMapDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, mapIndex: UInt16
  ) async throws -> AudioMapDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readAudioMapDescriptor(
        targetEntityID.rawValue, configurationIndex, mapIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: AudioMapDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readControlDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, controlIndex: UInt16
  ) async throws -> ControlDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readControlDescriptor(
        targetEntityID.rawValue, configurationIndex, controlIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: ControlDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readTimingDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, timingIndex: UInt16
  ) async throws -> TimingDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readTimingDescriptor(
        targetEntityID.rawValue, configurationIndex, timingIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: TimingDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readPtpInstanceDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, ptpInstanceIndex: UInt16
  ) async throws -> PtpInstanceDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readPtpInstanceDescriptor(
        targetEntityID.rawValue, configurationIndex, ptpInstanceIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: PtpInstanceDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func readPtpPortDescriptor(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, ptpPortIndex: UInt16
  ) async throws -> PtpPortDescriptor {
    try await withCheckedThrowingContinuation { cont in
      owner.readPtpPortDescriptor(
        targetEntityID.rawValue, configurationIndex, ptpPortIndex
      ) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: PtpPortDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Audio mappings (per-stream-port)

  /// GET_AUDIO_MAP. Returns the (numberOfMaps, mapIndex, mappings)
  /// triple for one map page on the listener. To enumerate every map on a
  /// stream port, call iteratively from `mapIndex=0` up to `numberOfMaps`.
  public func getStreamPortInputAudioMap(
    id targetEntityID: UniqueIdentifier, streamPortIndex: UInt16, mapIndex: UInt16
  ) async throws -> (numberOfMaps: UInt16, mapIndex: UInt16, mappings: [AudioMapping]) {
    try await _getAudioMap(targetEntityID, streamPortIndex, mapIndex) {
      self.owner.getStreamPortInputAudioMap($0, $1, $2, $3)
    }
  }

  public func getStreamPortOutputAudioMap(
    id targetEntityID: UniqueIdentifier, streamPortIndex: UInt16, mapIndex: UInt16
  ) async throws -> (numberOfMaps: UInt16, mapIndex: UInt16, mappings: [AudioMapping]) {
    try await _getAudioMap(targetEntityID, streamPortIndex, mapIndex) {
      self.owner.getStreamPortOutputAudioMap($0, $1, $2, $3)
    }
  }

  /// ADD_AUDIO_MAPPINGS. The talker/listener replaces or extends the
  /// existing audio map; the response echoes back the post-add mappings.
  public func addStreamPortInputAudioMappings(
    id targetEntityID: UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping]
  ) async throws -> [AudioMapping] {
    try await _mutateAudioMappings(targetEntityID, streamPortIndex, mappings) {
      self.owner.addStreamPortInputAudioMappings($0, $1, $2, $3, $4)
    }
  }

  public func addStreamPortOutputAudioMappings(
    id targetEntityID: UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping]
  ) async throws -> [AudioMapping] {
    try await _mutateAudioMappings(targetEntityID, streamPortIndex, mappings) {
      self.owner.addStreamPortOutputAudioMappings($0, $1, $2, $3, $4)
    }
  }

  public func removeStreamPortInputAudioMappings(
    id targetEntityID: UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping]
  ) async throws -> [AudioMapping] {
    try await _mutateAudioMappings(targetEntityID, streamPortIndex, mappings) {
      self.owner.removeStreamPortInputAudioMappings($0, $1, $2, $3, $4)
    }
  }

  public func removeStreamPortOutputAudioMappings(
    id targetEntityID: UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping]
  ) async throws -> [AudioMapping] {
    try await _mutateAudioMappings(targetEntityID, streamPortIndex, mappings) {
      self.owner.removeStreamPortOutputAudioMappings($0, $1, $2, $3, $4)
    }
  }

  // MARK: - Sampling rate

  public func setAudioUnitSamplingRate(
    id targetEntityID: UniqueIdentifier, audioUnitIndex: UInt16, to samplingRate: SamplingRate
  ) async throws -> SamplingRate { try await _setSamplingRate(
    targetEntityID, audioUnitIndex, samplingRate
  ) {
    self.owner.setAudioUnitSamplingRate($0, $1, $2, $3)
  }}

  public func getAudioUnitSamplingRate(
    id targetEntityID: UniqueIdentifier, audioUnitIndex: UInt16
  ) async throws -> SamplingRate { try await _getSamplingRate(targetEntityID, audioUnitIndex) {
    self.owner.getAudioUnitSamplingRate($0, $1, $2)
  }}

  public func setVideoClusterSamplingRate(
    id targetEntityID: UniqueIdentifier, videoClusterIndex: UInt16, to samplingRate: SamplingRate
  ) async throws -> SamplingRate { try await _setSamplingRate(
    targetEntityID, videoClusterIndex, samplingRate
  ) {
    self.owner.setVideoClusterSamplingRate($0, $1, $2, $3)
  }}

  public func getVideoClusterSamplingRate(
    id targetEntityID: UniqueIdentifier, videoClusterIndex: UInt16
  ) async throws -> SamplingRate { try await _getSamplingRate(targetEntityID, videoClusterIndex) {
    self.owner.getVideoClusterSamplingRate($0, $1, $2)
  }}

  public func setSensorClusterSamplingRate(
    id targetEntityID: UniqueIdentifier, sensorClusterIndex: UInt16, to samplingRate: SamplingRate
  ) async throws -> SamplingRate { try await _setSamplingRate(
    targetEntityID, sensorClusterIndex, samplingRate
  ) {
    self.owner.setSensorClusterSamplingRate($0, $1, $2, $3)
  }}

  public func getSensorClusterSamplingRate(
    id targetEntityID: UniqueIdentifier, sensorClusterIndex: UInt16
  ) async throws -> SamplingRate { try await _getSamplingRate(targetEntityID, sensorClusterIndex) {
    self.owner.getSensorClusterSamplingRate($0, $1, $2)
  }}

  // MARK: - Max transit time

  /// SET_MAX_TRANSIT_TIME — Milan-2019 §5.4.7. `maxTransitTime` is in
  /// nanoseconds; returns the value the talker accepted.
  public func setMaxTransitTime(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16, nanoseconds: UInt64
  ) async throws -> UInt64 {
    try await withCheckedThrowingContinuation { cont in
      owner.setMaxTransitTime(targetEntityID.rawValue, streamIndex, nanoseconds) { status, _, ns in
        if status == 0 {
          cont.resume(returning: ns)
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getMaxTransitTime(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws -> UInt64 {
    try await withCheckedThrowingContinuation { cont in
      owner.getMaxTransitTime(targetEntityID.rawValue, streamIndex) { status, _, ns in
        if status == 0 {
          cont.resume(returning: ns)
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Memory object length

  public func setMemoryObjectLength(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16,
    memoryObjectIndex: UInt16, length: UInt64
  ) async throws -> UInt64 {
    try await withCheckedThrowingContinuation { cont in
      owner.setMemoryObjectLength(
        targetEntityID.rawValue, configurationIndex, memoryObjectIndex, length
      ) { status, len in
        if status == 0 {
          cont.resume(returning: len)
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getMemoryObjectLength(
    id targetEntityID: UniqueIdentifier, configurationIndex: UInt16, memoryObjectIndex: UInt16
  ) async throws -> UInt64 {
    try await withCheckedThrowingContinuation { cont in
      owner.getMemoryObjectLength(
        targetEntityID.rawValue, configurationIndex, memoryObjectIndex
      ) { status, len in
        if status == 0 {
          cont.resume(returning: len)
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Liveness pings

  public func queryEntityAvailable(id targetEntityID: UniqueIdentifier) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.queryEntityAvailable(targetEntityID.rawValue) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func queryControllerAvailable(id targetEntityID: UniqueIdentifier) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.queryControllerAvailable(targetEntityID.rawValue) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Association

  public func setAssociation(
    id targetEntityID: UniqueIdentifier, associationID: UniqueIdentifier
  ) async throws -> UniqueIdentifier {
    try await withCheckedThrowingContinuation { cont in
      owner.setAssociation(targetEntityID.rawValue, associationID.rawValue) { status, assoc in
        if status == 0 {
          cont.resume(returning: UniqueIdentifier(assoc))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getAssociation(
    id targetEntityID: UniqueIdentifier
  ) async throws -> UniqueIdentifier {
    try await withCheckedThrowingContinuation { cont in
      owner.getAssociation(targetEntityID.rawValue) { status, assoc in
        if status == 0 {
          cont.resume(returning: UniqueIdentifier(assoc))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Milan info

  public func getMilanInfo(id targetEntityID: UniqueIdentifier) async throws -> MilanInfo {
    try await withCheckedThrowingContinuation { cont in
      owner.getMilanInfo(targetEntityID.rawValue) { status, proto, features, cert, spec in
        if status == 0 {
          cont.resume(returning: MilanInfo(
            protocolVersion: proto,
            featuresFlags: MilanInfoFeaturesFlags(rawValue: features),
            certificationVersion: MilanVersion(rawValue: cert),
            specificationVersion: MilanVersion(rawValue: spec)
          ))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Milan stream binding (MVU)

  /// BIND_STREAM (Milan 1.3 §5.4.4.6). Bind a listener stream to a talker
  /// (`StreamIdentification`); pass `[.streamingWait]` to make the talker
  /// hold off streaming until explicitly enabled. Returns the post-bind
  /// state echoed back by the listener.
  public func bindStream(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16,
    talker: StreamIdentification, flags: BindStreamFlags = []
  ) async throws -> (talker: StreamIdentification, flags: BindStreamFlags) {
    try await withCheckedThrowingContinuation { cont in
      owner.bindStream(
        targetEntityID.rawValue, streamIndex,
        talker.entityID.rawValue, talker.streamIndex, flags.rawValue
      ) { status, _, talkerID, talkerIdx, outFlags in
        if status == 0 {
          cont.resume(returning: (
            StreamIdentification(
              entityID: UniqueIdentifier(talkerID), streamIndex: talkerIdx
            ),
            BindStreamFlags(rawValue: outFlags)
          ))
        } else {
          cont.resume(throwing: LocalEntityMvuCommandStatus(status))
        }
      }
    }
  }

  /// UNBIND_STREAM (Milan 1.3 §5.4.4.7). Clear a listener-side stream
  /// binding. Idempotent against an already-unbound stream.
  public func unbindStream(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.unbindStream(targetEntityID.rawValue, streamIndex) { status, _ in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityMvuCommandStatus(status))
        }
      }
    }
  }

  /// GET_STREAM_INPUT_INFO_EX (Milan 1.3 §5.4.4.8). Like the AEM
  /// `getStreamInputInfo` but returns the resolved talker plus probing /
  /// ACMP state.
  public func getStreamInputInfoEx(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws -> StreamInputInfoEx {
    try await withCheckedThrowingContinuation { cont in
      owner.getStreamInputInfoEx(targetEntityID.rawValue, streamIndex) { status, _, info in
        if status == 0, let info {
          let raw = info.pointee
          cont.resume(returning: StreamInputInfoEx(
            talkerStream: StreamIdentification(
              entityID: UniqueIdentifier(raw.talkerStream.entityID),
              streamIndex: raw.talkerStream.streamIndex
            ),
            probingStatus: ProbingStatus(UInt8(raw.probingStatus.rawValue)),
            acmpStatus: AcmpStatus(rawValue: raw.acmpStatus.getValue())
          ))
        } else {
          cont.resume(throwing: LocalEntityMvuCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Milan system unique ID (MVU)

  /// GET_SYSTEM_UNIQUE_ID (Milan 1.3 §5.4.4.10). Returns the system-wide
  /// identifier and human-readable name an entity advertises for the system
  /// it belongs to.
  public func getSystemUniqueID(
    id targetEntityID: UniqueIdentifier
  ) async throws -> (systemUniqueID: UniqueIdentifier, systemName: String) {
    try await withCheckedThrowingContinuation { cont in
      owner.getSystemUniqueID(targetEntityID.rawValue) { status, sys, name in
        if status == 0, let name {
          cont.resume(returning: (
            UniqueIdentifier(sys), String(name.pointee.str())
          ))
        } else {
          cont.resume(throwing: LocalEntityMvuCommandStatus(status))
        }
      }
    }
  }

  /// SET_SYSTEM_UNIQUE_ID (Milan 1.3 §5.4.4.10). Writes both fields in one
  /// command; the entity may truncate `systemName` to 64 bytes.
  public func setSystemUniqueID(
    id targetEntityID: UniqueIdentifier,
    systemUniqueID: UniqueIdentifier, systemName: String
  ) async throws -> (systemUniqueID: UniqueIdentifier, systemName: String) {
    try await withCheckedThrowingContinuation { cont in
      var name = systemName
      name.withUTF8 { utf8 in
        owner.setSystemUniqueID(
          targetEntityID.rawValue, systemUniqueID.rawValue,
          UnsafeRawPointer(utf8.baseAddress), utf8.count
        ) { status, sys, n in
          if status == 0, let n {
            cont.resume(returning: (
              UniqueIdentifier(sys), String(n.pointee.str())
            ))
          } else {
            cont.resume(throwing: LocalEntityMvuCommandStatus(status))
          }
        }
      }
    }
  }

  // MARK: - Milan media clock reference (MVU)

  /// GET_MEDIA_CLOCK_REFERENCE_INFO (Milan 1.3 §5.4.4.5). Returns the
  /// default priority, plus whichever of the optional fields the entity
  /// reported.
  public func getMediaClockReferenceInfo(
    id targetEntityID: UniqueIdentifier, clockDomainIndex: UInt16
  ) async throws -> (
    defaultPriority: DefaultMediaClockReferencePriority,
    info: MediaClockReferenceInfo
  ) {
    try await withCheckedThrowingContinuation { cont in
      owner.getMediaClockReferenceInfo(
        targetEntityID.rawValue, clockDomainIndex
      ) { status, _, def, hasPrio, prio, hasName, name in
        if status == 0 {
          let resolvedName: String? = (hasName && name != nil)
            ? String(name!.pointee.str()) : nil
          cont.resume(returning: (
            DefaultMediaClockReferencePriority(def),
            MediaClockReferenceInfo(
              userMediaClockPriority: hasPrio ? prio : nil,
              mediaClockDomainName: resolvedName
            )
          ))
        } else {
          cont.resume(throwing: LocalEntityMvuCommandStatus(status))
        }
      }
    }
  }

  /// SET_MEDIA_CLOCK_REFERENCE_INFO (Milan 1.3 §5.4.4.5). Either field may
  /// be `nil` to leave it unchanged. The entity echoes the post-update
  /// state back through the response.
  public func setMediaClockReferenceInfo(
    id targetEntityID: UniqueIdentifier, clockDomainIndex: UInt16,
    userMediaClockPriority: MediaClockReferencePriority? = nil,
    mediaClockDomainName: String? = nil
  ) async throws -> (
    defaultPriority: DefaultMediaClockReferencePriority,
    info: MediaClockReferenceInfo
  ) {
    try await withCheckedThrowingContinuation { cont in
      let prio = userMediaClockPriority ?? 0
      let hasPrio = userMediaClockPriority != nil
      let runWith: (UnsafeRawPointer?, Int) -> () = { ptr, len in
        self.owner.setMediaClockReferenceInfo(
          targetEntityID.rawValue, clockDomainIndex,
          hasPrio, prio,
          mediaClockDomainName != nil, ptr, len
        ) { status, _, def, hasP, p, hasN, n in
          if status == 0 {
            let resolvedName: String? = (hasN && n != nil)
              ? String(n!.pointee.str()) : nil
            cont.resume(returning: (
              DefaultMediaClockReferencePriority(def),
              MediaClockReferenceInfo(
                userMediaClockPriority: hasP ? p : nil,
                mediaClockDomainName: resolvedName
              )
            ))
          } else {
            cont.resume(throwing: LocalEntityMvuCommandStatus(status))
          }
        }
      }
      if var nameStr = mediaClockDomainName {
        nameStr.withUTF8 { utf8 in
          runWith(UnsafeRawPointer(utf8.baseAddress), utf8.count)
        }
      } else {
        runWith(nil, 0)
      }
    }
  }

  // MARK: - Operations (AEM)

  /// START_OPERATION (IEEE 1722.1-2013 §7.4.53). Kick off an operation
  /// against a descriptor (typically a `MEMORY_OBJECT`). The returned
  /// `operationID` lets you correlate later progress notifications and
  /// pass to `abortOperation`.
  public func startOperation(
    id targetEntityID: UniqueIdentifier,
    descriptorType: UInt16, descriptorIndex: UInt16,
    operationType: MemoryObjectOperationType, payload: [UInt8] = []
  ) async throws -> OperationResult {
    try await withCheckedThrowingContinuation { cont in
      payload.withUnsafeBufferPointer { buf in
        owner.startOperation(
          targetEntityID.rawValue, descriptorType, descriptorIndex,
          operationType.rawValue,
          UnsafeRawPointer(buf.baseAddress), buf.count
        ) { status, dt, di, op, ot, ptr, len in
          if status == 0 {
            let bytes: [UInt8] = if let ptr, len > 0 {
              Array(UnsafeBufferPointer(start: ptr, count: len))
            } else {
              []
            }
            cont.resume(returning: OperationResult(
              descriptorType: dt, descriptorIndex: di,
              operationID: op,
              operationType: MemoryObjectOperationType(rawValue: ot) ?? .read,
              payload: bytes
            ))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
      }
    }
  }

  /// ABORT_OPERATION (IEEE 1722.1-2013 §7.4.54). Cancel an operation
  /// previously started via `startOperation`.
  public func abortOperation(
    id targetEntityID: UniqueIdentifier,
    descriptorType: UInt16, descriptorIndex: UInt16, operationID: UInt16
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.abortOperation(
        targetEntityID.rawValue, descriptorType, descriptorIndex, operationID
      ) { status, _, _, _ in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Counters

  public func getEntityCounters(
    id targetEntityID: UniqueIdentifier
  ) async throws -> (valid: EntityCounterValidFlags, counters: DescriptorCounters) {
    try await withCheckedThrowingContinuation { cont in
      owner.getEntityCounters(targetEntityID.rawValue) { status, valid, ptr in
        if status == 0, let ptr {
          cont.resume(returning: (
            EntityCounterValidFlags(rawValue: valid),
            DescriptorCounters(_copyCounters(ptr))
          ))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getAvbInterfaceCounters(
    id targetEntityID: UniqueIdentifier, avbInterfaceIndex: UInt16
  ) async throws -> (valid: AvbInterfaceCounterValidFlags, counters: DescriptorCounters) {
    try await withCheckedThrowingContinuation { cont in
      owner.getAvbInterfaceCounters(
        targetEntityID.rawValue, avbInterfaceIndex
      ) { status, _, valid, ptr in
        if status == 0, let ptr {
          cont.resume(returning: (
            AvbInterfaceCounterValidFlags(rawValue: valid),
            DescriptorCounters(_copyCounters(ptr))
          ))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getClockDomainCounters(
    id targetEntityID: UniqueIdentifier, clockDomainIndex: UInt16
  ) async throws -> (valid: ClockDomainCounterValidFlags, counters: DescriptorCounters) {
    try await withCheckedThrowingContinuation { cont in
      owner.getClockDomainCounters(
        targetEntityID.rawValue, clockDomainIndex
      ) { status, _, valid, ptr in
        if status == 0, let ptr {
          cont.resume(returning: (
            ClockDomainCounterValidFlags(rawValue: valid),
            DescriptorCounters(_copyCounters(ptr))
          ))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getStreamInputCounters(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws -> (valid: StreamInputCounterValidFlags, counters: DescriptorCounters) {
    try await withCheckedThrowingContinuation { cont in
      owner.getStreamInputCounters(
        targetEntityID.rawValue, streamIndex
      ) { status, _, valid, ptr in
        if status == 0, let ptr {
          cont.resume(returning: (
            StreamInputCounterValidFlags(rawValue: valid),
            DescriptorCounters(_copyCounters(ptr))
          ))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  public func getStreamOutputCounters(
    id targetEntityID: UniqueIdentifier, streamIndex: UInt16
  ) async throws -> (valid: StreamOutputCounterValidFlags, counters: DescriptorCounters) {
    try await withCheckedThrowingContinuation { cont in
      owner.getStreamOutputCounters(
        targetEntityID.rawValue, streamIndex
      ) { status, _, valid, ptr in
        if status == 0, let ptr {
          cont.resume(returning: (
            StreamOutputCounterValidFlags(rawValue: valid),
            DescriptorCounters(_copyCounters(ptr))
          ))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - Reboot

  /// REBOOT — IEEE 1722.1-2013 §7.4.55. The target reboots after acking;
  /// the response status confirms acceptance, not completion.
  public func reboot(id targetEntityID: UniqueIdentifier) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.reboot(targetEntityID.rawValue) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  /// REBOOT_TO_FIRMWARE — Milan-2019. Target reboots into the firmware
  /// stored in the named MEMORY_OBJECT.
  public func rebootToFirmware(
    id targetEntityID: UniqueIdentifier, memoryObjectIndex: UInt16
  ) async throws {
    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(), Error>) in
      owner.rebootToFirmware(targetEntityID.rawValue, memoryObjectIndex) { status in
        if status == 0 {
          cont.resume()
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // MARK: - ACMP connection management

  /// CONNECT_TX. Returns the post-connect state (talker/listener pair,
  /// connection count, flags). Throws `LocalEntityControlStatus` on
  /// non-success.
  public func connectStream(
    talker: StreamIdentification, listener: StreamIdentification
  ) async throws -> StreamConnectionState {
    try await _connectionCall { cb in
      self.owner.connectStream(
        talker.entityID.rawValue, talker.streamIndex,
        listener.entityID.rawValue, listener.streamIndex, cb
      )
    }
  }

  public func disconnectStream(
    talker: StreamIdentification, listener: StreamIdentification
  ) async throws -> StreamConnectionState {
    try await _connectionCall { cb in
      self.owner.disconnectStream(
        talker.entityID.rawValue, talker.streamIndex,
        listener.entityID.rawValue, listener.streamIndex, cb
      )
    }
  }

  public func disconnectTalkerStream(
    talker: StreamIdentification, listener: StreamIdentification
  ) async throws -> StreamConnectionState {
    try await _connectionCall { cb in
      self.owner.disconnectTalkerStream(
        talker.entityID.rawValue, talker.streamIndex,
        listener.entityID.rawValue, listener.streamIndex, cb
      )
    }
  }

  public func getTalkerStreamState(
    talker: StreamIdentification
  ) async throws -> StreamConnectionState {
    try await _connectionCall { cb in
      self.owner.getTalkerStreamState(
        talker.entityID.rawValue, talker.streamIndex, cb
      )
    }
  }

  public func getListenerStreamState(
    listener: StreamIdentification
  ) async throws -> StreamConnectionState {
    try await _connectionCall { cb in
      self.owner.getListenerStreamState(
        listener.entityID.rawValue, listener.streamIndex, cb
      )
    }
  }

  public func getTalkerStreamConnection(
    talker: StreamIdentification, connectionIndex: UInt16
  ) async throws -> StreamConnectionState {
    try await _connectionCall { cb in
      self.owner.getTalkerStreamConnection(
        talker.entityID.rawValue, talker.streamIndex, connectionIndex, cb
      )
    }
  }

  // MARK: - Private helpers (sampling rate, counter array copy)

  private func _setSamplingRate(
    _ id: UniqueIdentifier, _ descIdx: UInt16, _ rate: SamplingRate,
    _ call: @escaping (
      UInt64,
      UInt16,
      UInt32,
      @escaping (UInt16, UInt16, UInt32) -> ()
    ) -> ()
  ) async throws -> SamplingRate {
    try await withCheckedThrowingContinuation { cont in
      call(id.rawValue, descIdx, rate.rawValue) { status, _, raw in
        if status == 0 {
          cont.resume(returning: SamplingRate(raw))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  private func _getSamplingRate(
    _ id: UniqueIdentifier, _ descIdx: UInt16,
    _ call: @escaping (
      UInt64,
      UInt16,
      @escaping (UInt16, UInt16, UInt32) -> ()
    ) -> ()
  ) async throws -> SamplingRate {
    try await withCheckedThrowingContinuation { cont in
      call(id.rawValue, descIdx) { status, _, raw in
        if status == 0 {
          cont.resume(returning: SamplingRate(raw))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // Shared shape for read*PortDescriptor / read*ExternalPort* /
  // read*InternalPort* — the callback signature differs only by descriptor
  // type. We parameterise on the closure to avoid 6 identical templates.
  private func _readPortDescriptor(
    _ id: UniqueIdentifier, _ configIdx: UInt16, _ portIdx: UInt16,
    _ call: @escaping (
      UInt64,
      UInt16,
      UInt16,
      @escaping (
        UInt16,
        UInt16,
        UnsafePointer<la.avdecc.entity.model.StreamPortDescriptor>?
      ) -> ()
    ) -> ()
  ) async throws -> StreamPortDescriptor {
    try await withCheckedThrowingContinuation { cont in
      call(id.rawValue, configIdx, portIdx) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: StreamPortDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  private func _readExternalPortDescriptor(
    _ id: UniqueIdentifier, _ configIdx: UInt16, _ portIdx: UInt16,
    _ call: @escaping (
      UInt64,
      UInt16,
      UInt16,
      @escaping (
        UInt16,
        UInt16,
        UnsafePointer<la.avdecc.entity.model.ExternalPortDescriptor>?
      ) -> ()
    ) -> ()
  ) async throws -> ExternalPortDescriptor {
    try await withCheckedThrowingContinuation { cont in
      call(id.rawValue, configIdx, portIdx) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: ExternalPortDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  private func _readInternalPortDescriptor(
    _ id: UniqueIdentifier, _ configIdx: UInt16, _ portIdx: UInt16,
    _ call: @escaping (
      UInt64,
      UInt16,
      UInt16,
      @escaping (
        UInt16,
        UInt16,
        UnsafePointer<la.avdecc.entity.model.InternalPortDescriptor>?
      ) -> ()
    ) -> ()
  ) async throws -> InternalPortDescriptor {
    try await withCheckedThrowingContinuation { cont in
      call(id.rawValue, configIdx, portIdx) { status, _, desc in
        if status == 0, let desc {
          cont.resume(returning: InternalPortDescriptor(desc.pointee))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // GET_AUDIO_MAP shared shape — input/output are byte-identical.
  // Mappings come back as a (data*, count) pair into la_avdecc's vector;
  // we copy out before the callback returns and the C++ vector is freed.
  private func _getAudioMap(
    _ id: UniqueIdentifier, _ streamPortIndex: UInt16, _ mapIndex: UInt16,
    _ call: @escaping (
      UInt64,
      UInt16,
      UInt16,
      @escaping (
        UInt16,
        UInt16,
        UInt16,
        UInt16,
        UnsafePointer<la.avdecc.entity.model.AudioMapping>?,
        Int
      ) -> ()
    ) -> ()
  ) async throws -> (numberOfMaps: UInt16, mapIndex: UInt16, mappings: [AudioMapping]) {
    try await withCheckedThrowingContinuation { cont in
      call(id.rawValue, streamPortIndex, mapIndex) { status, _, numMaps, mi, ptr, count in
        if status == 0 {
          cont.resume(returning: (numMaps, mi, _copyMappings(ptr, count)))
        } else {
          cont.resume(throwing: LocalEntityAemCommandStatus(status))
        }
      }
    }
  }

  // ADD/REMOVE_AUDIO_MAPPINGS shared shape. Swift hands raw `AudioMapping`
  // bytes to la_avdecc, which copies them into a std::vector internally.
  // The response echoes back the post-mutation mapping set, which we copy
  // out the same way as `_getAudioMap`.
  private func _mutateAudioMappings(
    _ id: UniqueIdentifier, _ streamPortIndex: UInt16, _ mappings: [AudioMapping],
    _ call: @escaping (
      UInt64,
      UInt16,
      UnsafePointer<la.avdecc.entity.model.AudioMapping>?,
      Int,
      @escaping (
        UInt16,
        UInt16,
        UnsafePointer<la.avdecc.entity.model.AudioMapping>?,
        Int
      ) -> ()
    ) -> ()
  ) async throws -> [AudioMapping] {
    let cxxMappings = mappings.map { m in
      var v = la.avdecc.entity.model.AudioMapping()
      v.streamIndex = m.streamIndex
      v.streamChannel = m.streamChannel
      v.clusterOffset = m.clusterOffset
      v.clusterChannel = m.clusterChannel
      return v
    }
    return try await withCheckedThrowingContinuation { cont in
      cxxMappings.withUnsafeBufferPointer { buf in
        call(id.rawValue, streamPortIndex, buf.baseAddress, buf.count) { status, _, ptr, count in
          if status == 0 {
            cont.resume(returning: _copyMappings(ptr, count))
          } else {
            cont.resume(throwing: LocalEntityAemCommandStatus(status))
          }
        }
      }
    }
  }

  // Shared callback shape for every ACMP entry point: (status, talkerEID,
  // talkerStreamIdx, listenerEID, listenerStreamIdx, count, flags). Six
  // u16/u64 ints in the middle that we assemble back into a
  // StreamConnectionState. Throws LocalEntityControlStatus (ACMP status)
  // rather than the AEM status.
  private func _connectionCall(
    _ kickoff: @escaping (
      @escaping (UInt16, UInt64, UInt16, UInt64, UInt16, UInt16, UInt16) -> ()
    ) -> ()
  ) async throws -> StreamConnectionState {
    try await withCheckedThrowingContinuation { cont in
      kickoff { status, tEID, tIdx, lEID, lIdx, count, flags in
        if status == 0 {
          cont.resume(returning: StreamConnectionState(
            talkerStream: StreamIdentification(
              entityID: UniqueIdentifier(tEID), streamIndex: tIdx
            ),
            listenerStream: StreamIdentification(
              entityID: UniqueIdentifier(lEID), streamIndex: lIdx
            ),
            connectionCount: count,
            flags: ConnectionFlags(rawValue: flags)
          ))
        } else {
          cont.resume(throwing: LocalEntityControlStatus(status))
        }
      }
    }
  }

  // MARK: - Delegate wiring

  /// Called from `delegate.didSet`. Detaches first so la_avdecc cannot
  /// deliver an event mid-rebind, clears every Block<> slot in the C++
  /// adapter, installs new blocks for each protocol method, then
  /// re-attaches. Captures `self` weakly to avoid the cycle owner →
  /// Block_copy'd closure → self → owner.
  ///
  /// All ~80 callbacks are installed unconditionally; unused ones land
  /// on the protocol's default no-op extension. The cost is one
  /// Block_copy per slot per delegate change; not a hot path.
  private func rebindDelegate() {
    owner.detachDelegate()
    owner.clearDelegateBlocks()
    guard let _ = delegate else { return }

    // Helper for the six sniffed-ACMP callbacks. Each takes the same flat
    // (uint64,uint16,uint64,uint16,uint16,uint16,uint16) and reassembles
    // into (StreamConnectionState, status). Returns a closure ready to
    // hand to `owner.setOnX`.
    let sniffedHandler: (
      @escaping (
        LocalEntityDelegate,
        LocalEntity,
        StreamConnectionState,
        LocalEntityControlStatus
      ) -> ()
    ) -> @convention(block) (
      UInt64,
      UInt16,
      UInt64,
      UInt16,
      UInt16,
      UInt16,
      UInt16
    ) -> () = { fwd in
      { [weak self] tEID, tIdx, lEID, lIdx, count, flags, status in
        guard let self, let d = delegate else { return }
        let state = StreamConnectionState(
          talkerStream: StreamIdentification(
            entityID: UniqueIdentifier(tEID), streamIndex: tIdx
          ),
          listenerStream: StreamIdentification(
            entityID: UniqueIdentifier(lEID), streamIndex: lIdx
          ),
          connectionCount: count, flags: ConnectionFlags(rawValue: flags)
        )
        fwd(d, self, state, LocalEntityControlStatus(status))
      }
    }

    // ---- Global / lifecycle -------------------------------------------
    owner.setOnTransportError { [weak self] in
      guard let self, let d = delegate else { return }
      d.onTransportError(self)
    }
    owner.setOnEntityOnline { [weak self] id, ent in
      guard let self, let d = delegate, let ent else { return }
      d.onEntityOnline(self, id: UniqueIdentifier(id), entity: Entity(ent))
    }
    owner.setOnEntityUpdate { [weak self] id, ent in
      guard let self, let d = delegate, let ent else { return }
      d.onEntityUpdate(self, id: UniqueIdentifier(id), entity: Entity(ent))
    }
    owner.setOnEntityOffline { [weak self] id in
      guard let self, let d = delegate else { return }
      d.onEntityOffline(self, id: UniqueIdentifier(id))
    }
    owner.setOnEntityIdentifyNotification { [weak self] id in
      guard let self, let d = delegate else { return }
      d.onEntityIdentifyNotification(self, id: UniqueIdentifier(id))
    }
    owner.setOnDeregisteredFromUnsolicitedNotifications { [weak self] id in
      guard let self, let d = delegate else { return }
      d.onDeregisteredFromUnsolicitedNotifications(self, id: UniqueIdentifier(id))
    }

    // ---- Sniffed ACMP --------------------------------------------------
    owner.setOnControllerConnectResponseSniffed(
      sniffedHandler { d, le, state, st in
        d.onControllerConnectResponseSniffed(le, state: state, status: st)
      })
    owner.setOnControllerDisconnectResponseSniffed(
      sniffedHandler { d, le, state, st in
        d.onControllerDisconnectResponseSniffed(le, state: state, status: st)
      })
    owner.setOnListenerConnectResponseSniffed(
      sniffedHandler { d, le, state, st in
        d.onListenerConnectResponseSniffed(le, state: state, status: st)
      })
    owner.setOnListenerDisconnectResponseSniffed(
      sniffedHandler { d, le, state, st in
        d.onListenerDisconnectResponseSniffed(le, state: state, status: st)
      })
    owner.setOnGetTalkerStreamStateResponseSniffed(
      sniffedHandler { d, le, state, st in
        d.onGetTalkerStreamStateResponseSniffed(le, state: state, status: st)
      })
    owner.setOnGetListenerStreamStateResponseSniffed(
      sniffedHandler { d, le, state, st in
        d.onGetListenerStreamStateResponseSniffed(le, state: state, status: st)
      })

    // ---- Acquire / release / lock / unlock -----------------------------
    owner.setOnEntityAcquired { [weak self] id, owning, dt, di in
      guard let self, let d = delegate else { return }
      d.onEntityAcquired(
        self,
        id: UniqueIdentifier(id),
        owningEntity: UniqueIdentifier(owning),
        descriptorType: dt,
        descriptorIndex: di
      )
    }
    owner.setOnEntityReleased { [weak self] id, owning, dt, di in
      guard let self, let d = delegate else { return }
      d.onEntityReleased(
        self,
        id: UniqueIdentifier(id),
        owningEntity: UniqueIdentifier(owning),
        descriptorType: dt,
        descriptorIndex: di
      )
    }
    owner.setOnEntityLocked { [weak self] id, locking, dt, di in
      guard let self, let d = delegate else { return }
      d.onEntityLocked(
        self,
        id: UniqueIdentifier(id),
        lockingEntity: UniqueIdentifier(locking),
        descriptorType: dt,
        descriptorIndex: di
      )
    }
    owner.setOnEntityUnlocked { [weak self] id, locking, dt, di in
      guard let self, let d = delegate else { return }
      d.onEntityUnlocked(
        self,
        id: UniqueIdentifier(id),
        lockingEntity: UniqueIdentifier(locking),
        descriptorType: dt,
        descriptorIndex: di
      )
    }

    // ---- Configuration / clock-source / association -------------------
    owner.setOnConfigurationChanged { [weak self] id, cfg in
      guard let self, let d = delegate else { return }
      d.onConfigurationChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg
      )
    }
    owner.setOnAssociationIDChanged { [weak self] id, assoc in
      guard let self, let d = delegate else { return }
      d.onAssociationIDChanged(
        self,
        id: UniqueIdentifier(id),
        associationID: UniqueIdentifier(assoc)
      )
    }
    owner.setOnClockSourceChanged { [weak self] id, cd, cs in
      guard let self, let d = delegate else { return }
      d.onClockSourceChanged(
        self,
        id: UniqueIdentifier(id),
        clockDomainIndex: cd,
        clockSourceIndex: cs
      )
    }

    // ---- Stream format / mappings / info / start-stop -----------------
    owner.setOnStreamInputFormatChanged { [weak self] id, si, fmt in
      guard let self, let d = delegate else { return }
      d.onStreamInputFormatChanged(
        self,
        id: UniqueIdentifier(id),
        streamIndex: si,
        streamFormat: StreamFormat(format: fmt)
      )
    }
    owner.setOnStreamOutputFormatChanged { [weak self] id, si, fmt in
      guard let self, let d = delegate else { return }
      d.onStreamOutputFormatChanged(
        self,
        id: UniqueIdentifier(id),
        streamIndex: si,
        streamFormat: StreamFormat(format: fmt)
      )
    }
    owner.setOnStreamPortInputAudioMappingsChanged { [weak self] id, sp, num, mi, ptr, count in
      guard let self, let d = delegate else { return }
      d.onStreamPortInputAudioMappingsChanged(
        self, id: UniqueIdentifier(id), streamPortIndex: sp,
        numberOfMaps: num, mapIndex: mi,
        mappings: _copyMappings(ptr, count)
      )
    }
    owner.setOnStreamPortOutputAudioMappingsChanged { [weak self] id, sp, num, mi, ptr, count in
      guard let self, let d = delegate else { return }
      d.onStreamPortOutputAudioMappingsChanged(
        self, id: UniqueIdentifier(id), streamPortIndex: sp,
        numberOfMaps: num, mapIndex: mi,
        mappings: _copyMappings(ptr, count)
      )
    }
    owner.setOnStreamPortInputAudioMappingsAdded { [weak self] id, sp, ptr, count in
      guard let self, let d = delegate else { return }
      d.onStreamPortInputAudioMappingsAdded(
        self, id: UniqueIdentifier(id), streamPortIndex: sp,
        mappings: _copyMappings(ptr, count)
      )
    }
    owner.setOnStreamPortOutputAudioMappingsAdded { [weak self] id, sp, ptr, count in
      guard let self, let d = delegate else { return }
      d.onStreamPortOutputAudioMappingsAdded(
        self, id: UniqueIdentifier(id), streamPortIndex: sp,
        mappings: _copyMappings(ptr, count)
      )
    }
    owner.setOnStreamPortInputAudioMappingsRemoved { [weak self] id, sp, ptr, count in
      guard let self, let d = delegate else { return }
      d.onStreamPortInputAudioMappingsRemoved(
        self, id: UniqueIdentifier(id), streamPortIndex: sp,
        mappings: _copyMappings(ptr, count)
      )
    }
    owner.setOnStreamPortOutputAudioMappingsRemoved { [weak self] id, sp, ptr, count in
      guard let self, let d = delegate else { return }
      d.onStreamPortOutputAudioMappingsRemoved(
        self, id: UniqueIdentifier(id), streamPortIndex: sp,
        mappings: _copyMappings(ptr, count)
      )
    }
    owner.setOnStreamInputInfoChanged { [weak self] id, si, info, fromGet in
      guard let self, let d = delegate, let info else { return }
      d.onStreamInputInfoChanged(
        self,
        id: UniqueIdentifier(id),
        streamIndex: si,
        info: StreamInfo(info.pointee),
        fromGetResponse: fromGet
      )
    }
    owner.setOnStreamOutputInfoChanged { [weak self] id, si, info, fromGet in
      guard let self, let d = delegate, let info else { return }
      d.onStreamOutputInfoChanged(
        self,
        id: UniqueIdentifier(id),
        streamIndex: si,
        info: StreamInfo(info.pointee),
        fromGetResponse: fromGet
      )
    }
    owner.setOnStreamInputStarted { [weak self] id, si in
      guard let self, let d = delegate else { return }
      d.onStreamInputStarted(self, id: UniqueIdentifier(id), streamIndex: si)
    }
    owner.setOnStreamOutputStarted { [weak self] id, si in
      guard let self, let d = delegate else { return }
      d.onStreamOutputStarted(self, id: UniqueIdentifier(id), streamIndex: si)
    }
    owner.setOnStreamInputStopped { [weak self] id, si in
      guard let self, let d = delegate else { return }
      d.onStreamInputStopped(self, id: UniqueIdentifier(id), streamIndex: si)
    }
    owner.setOnStreamOutputStopped { [weak self] id, si in
      guard let self, let d = delegate else { return }
      d.onStreamOutputStopped(self, id: UniqueIdentifier(id), streamIndex: si)
    }
    owner.setOnMaxTransitTimeChanged { [weak self] id, si, ns in
      guard let self, let d = delegate else { return }
      d.onMaxTransitTimeChanged(
        self,
        id: UniqueIdentifier(id),
        streamIndex: si,
        maxTransitTime: ns
      )
    }

    // ---- Names ---------------------------------------------------------
    owner.setOnEntityNameChanged { [weak self] id, name in
      guard let self, let d = delegate, let name else { return }
      d.onEntityNameChanged(
        self,
        id: UniqueIdentifier(id),
        name: String(name.pointee.str())
      )
    }
    owner.setOnEntityGroupNameChanged { [weak self] id, name in
      guard let self, let d = delegate, let name else { return }
      d.onEntityGroupNameChanged(
        self,
        id: UniqueIdentifier(id),
        name: String(name.pointee.str())
      )
    }
    owner.setOnConfigurationNameChanged { [weak self] id, cfg, name in
      guard let self, let d = delegate, let name else { return }
      d.onConfigurationNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        name: String(name.pointee.str())
      )
    }
    owner.setOnAudioUnitNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onAudioUnitNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        audioUnitIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnStreamInputNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onStreamInputNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        streamIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnStreamOutputNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onStreamOutputNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        streamIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnJackInputNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onJackInputNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        jackIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnJackOutputNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onJackOutputNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        jackIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnAvbInterfaceNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onAvbInterfaceNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        avbInterfaceIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnClockSourceNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onClockSourceNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        clockSourceIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnMemoryObjectNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onMemoryObjectNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        memoryObjectIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnAudioClusterNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onAudioClusterNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        audioClusterIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnControlNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onControlNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        controlIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnClockDomainNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onClockDomainNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        clockDomainIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnTimingNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onTimingNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        timingIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnPtpInstanceNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onPtpInstanceNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        ptpInstanceIndex: idx,
        name: String(name.pointee.str())
      )
    }
    owner.setOnPtpPortNameChanged { [weak self] id, cfg, idx, name in
      guard let self, let d = delegate, let name else { return }
      d.onPtpPortNameChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        ptpPortIndex: idx,
        name: String(name.pointee.str())
      )
    }

    // ---- Sampling rates ------------------------------------------------
    owner.setOnAudioUnitSamplingRateChanged { [weak self] id, idx, rate in
      guard let self, let d = delegate else { return }
      d.onAudioUnitSamplingRateChanged(
        self,
        id: UniqueIdentifier(id),
        audioUnitIndex: idx,
        samplingRate: rate
      )
    }
    owner.setOnVideoClusterSamplingRateChanged { [weak self] id, idx, rate in
      guard let self, let d = delegate else { return }
      d.onVideoClusterSamplingRateChanged(
        self,
        id: UniqueIdentifier(id),
        videoClusterIndex: idx,
        samplingRate: rate
      )
    }
    owner.setOnSensorClusterSamplingRateChanged { [weak self] id, idx, rate in
      guard let self, let d = delegate else { return }
      d.onSensorClusterSamplingRateChanged(
        self,
        id: UniqueIdentifier(id),
        sensorClusterIndex: idx,
        samplingRate: rate
      )
    }

    // ---- Counters ------------------------------------------------------
    owner.setOnEntityCountersChanged { [weak self] id, valid, ptr in
      guard let self, let d = delegate, let ptr else { return }
      d.onEntityCountersChanged(
        self,
        id: UniqueIdentifier(id),
        valid: EntityCounterValidFlags(rawValue: valid),
        counters: DescriptorCounters(_copyCounters(ptr))
      )
    }
    owner.setOnAvbInterfaceCountersChanged { [weak self] id, idx, valid, ptr in
      guard let self, let d = delegate, let ptr else { return }
      d.onAvbInterfaceCountersChanged(
        self, id: UniqueIdentifier(id), avbInterfaceIndex: idx,
        valid: AvbInterfaceCounterValidFlags(rawValue: valid),
        counters: DescriptorCounters(_copyCounters(ptr))
      )
    }
    owner.setOnClockDomainCountersChanged { [weak self] id, idx, valid, ptr in
      guard let self, let d = delegate, let ptr else { return }
      d.onClockDomainCountersChanged(
        self, id: UniqueIdentifier(id), clockDomainIndex: idx,
        valid: ClockDomainCounterValidFlags(rawValue: valid),
        counters: DescriptorCounters(_copyCounters(ptr))
      )
    }
    owner.setOnStreamInputCountersChanged { [weak self] id, idx, valid, ptr in
      guard let self, let d = delegate, let ptr else { return }
      d.onStreamInputCountersChanged(
        self, id: UniqueIdentifier(id), streamIndex: idx,
        valid: StreamInputCounterValidFlags(rawValue: valid),
        counters: DescriptorCounters(_copyCounters(ptr))
      )
    }
    owner.setOnStreamOutputCountersChanged { [weak self] id, idx, valid, ptr in
      guard let self, let d = delegate, let ptr else { return }
      d.onStreamOutputCountersChanged(
        self, id: UniqueIdentifier(id), streamIndex: idx,
        valid: StreamOutputCounterValidFlags(rawValue: valid),
        counters: DescriptorCounters(_copyCounters(ptr))
      )
    }

    // ---- AVB / AS path / control values --------------------------------
    owner.setOnAvbInfoChanged { [weak self] id, idx, info in
      guard let self, let d = delegate, let info else { return }
      d.onAvbInfoChanged(
        self,
        id: UniqueIdentifier(id),
        avbInterfaceIndex: idx,
        info: AvbInfo(info.pointee)
      )
    }
    owner.setOnAsPathChanged { [weak self] id, idx, path in
      guard let self, let d = delegate, let path else { return }
      d.onAsPathChanged(
        self,
        id: UniqueIdentifier(id),
        avbInterfaceIndex: idx,
        asPath: AsPath(path.pointee)
      )
    }
    owner.setOnControlValuesChanged { [weak self] id, idx, ptr, len in
      guard let self, let d = delegate else { return }
      let bytes: [UInt8] = if let ptr, len > 0 {
        Array(UnsafeBufferPointer(start: ptr, count: len))
      } else {
        []
      }
      d.onControlValuesChanged(
        self,
        id: UniqueIdentifier(id),
        controlIndex: idx,
        packedControlValues: bytes
      )
    }

    // ---- Memory object / operation -------------------------------------
    owner.setOnMemoryObjectLengthChanged { [weak self] id, cfg, idx, length in
      guard let self, let d = delegate else { return }
      d.onMemoryObjectLengthChanged(
        self,
        id: UniqueIdentifier(id),
        configurationIndex: cfg,
        memoryObjectIndex: idx,
        length: length
      )
    }
    owner.setOnOperationStatus { [weak self] id, dt, di, op, pct in
      guard let self, let d = delegate else { return }
      d.onOperationStatus(
        self,
        id: UniqueIdentifier(id),
        descriptorType: dt,
        descriptorIndex: di,
        operationID: op,
        percentComplete: pct
      )
    }

    // ---- Milan MVU -----------------------------------------------------
    owner.setOnSystemUniqueIDChanged { [weak self] id, sys, name in
      guard let self, let d = delegate, let name else { return }
      d.onSystemUniqueIDChanged(
        self,
        id: UniqueIdentifier(id),
        systemUniqueID: UniqueIdentifier(sys),
        systemName: String(name.pointee.str())
      )
    }
    owner.setOnMediaClockReferenceInfoChanged {
      [weak self] id, cd, def, hasPrio, prio, hasName, name in
      guard let self, let d = delegate else { return }
      let resolvedName: String? = (hasName && name != nil)
        ? String(name!.pointee.str()) : nil
      d.onMediaClockReferenceInfoChanged(
        self, id: UniqueIdentifier(id), clockDomainIndex: cd,
        defaultPriority: DefaultMediaClockReferencePriority(def),
        info: MediaClockReferenceInfo(
          userMediaClockPriority: hasPrio ? prio : nil,
          mediaClockDomainName: resolvedName
        )
      )
    }
    owner.setOnBindStream { [weak self] id, si, talkerID, talkerIdx, flags in
      guard let self, let d = delegate else { return }
      d.onBindStream(
        self,
        id: UniqueIdentifier(id),
        streamIndex: si,
        talker: StreamIdentification(
          entityID: UniqueIdentifier(talkerID),
          streamIndex: talkerIdx
        ),
        flags: BindStreamFlags(rawValue: flags)
      )
    }
    owner.setOnUnbindStream { [weak self] id, si in
      guard let self, let d = delegate else { return }
      d.onUnbindStream(self, id: UniqueIdentifier(id), streamIndex: si)
    }
    owner.setOnStreamInputInfoExChanged { [weak self] id, si, info in
      guard let self, let d = delegate, let info else { return }
      let raw = info.pointee
      let wrapped = StreamInputInfoEx(
        talkerStream: StreamIdentification(
          entityID: UniqueIdentifier(raw.talkerStream.entityID),
          streamIndex: raw.talkerStream.streamIndex
        ),
        probingStatus: ProbingStatus(UInt8(raw.probingStatus.rawValue)),
        acmpStatus: AcmpStatus(rawValue: raw.acmpStatus.getValue())
      )
      d.onStreamInputInfoExChanged(
        self,
        id: UniqueIdentifier(id),
        streamIndex: si,
        info: wrapped
      )
    }

    // ---- Statistics ----------------------------------------------------
    owner.setOnAecpRetry { [weak self] id in
      guard let self, let d = delegate else { return }
      d.onAecpRetry(self, id: UniqueIdentifier(id))
    }
    owner.setOnAecpTimeout { [weak self] id in
      guard let self, let d = delegate else { return }
      d.onAecpTimeout(self, id: UniqueIdentifier(id))
    }
    owner.setOnAecpUnexpectedResponse { [weak self] id in
      guard let self, let d = delegate else { return }
      d.onAecpUnexpectedResponse(self, id: UniqueIdentifier(id))
    }
    owner.setOnAecpResponseTime { [weak self] id, ms in
      guard let self, let d = delegate else { return }
      d.onAecpResponseTime(self, id: UniqueIdentifier(id), responseTime: ms)
    }
    owner.setOnAemAecpUnsolicitedReceived { [weak self] id, seq in
      guard let self, let d = delegate else { return }
      d.onAemAecpUnsolicitedReceived(
        self,
        id: UniqueIdentifier(id),
        sequenceID: seq
      )
    }
    owner.setOnMvuAecpUnsolicitedReceived { [weak self] id, seq in
      guard let self, let d = delegate else { return }
      d.onMvuAecpUnsolicitedReceived(
        self,
        id: UniqueIdentifier(id),
        sequenceID: seq
      )
    }

    owner.attachDelegate()
  }
}

/// Copy a borrowed `uint32_t const* counters[32]` callback parameter into
/// a heap array. la_avdecc owns the underlying storage; callers must not
/// hold the pointer past the callback.
private func _copyCounters(_ ptr: UnsafePointer<UInt32>) -> [UInt32] {
  Array(UnsafeBufferPointer(start: ptr, count: 32))
}

/// Copy a borrowed audio-mapping array out of a la_avdecc callback
/// parameter into Swift-owned storage. Tolerates nil/zero-count.
private func _copyMappings(
  _ ptr: UnsafePointer<la.avdecc.entity.model.AudioMapping>?, _ count: Int
) -> [AudioMapping] {
  guard let ptr, count > 0 else { return [] }
  var out: [AudioMapping] = []
  out.reserveCapacity(count)
  for i in 0..<count {
    out.append(AudioMapping(ptr[i]))
  }
  return out
}
