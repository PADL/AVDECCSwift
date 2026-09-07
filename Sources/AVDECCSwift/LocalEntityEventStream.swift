/*
 * Copyright (c) 2026 PADL Software Pty Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

/// A `LocalEntityDelegate` callback as a Sendable value. Entities are referred to by ID
/// because `Entity` borrows la_avdecc storage that does not outlive the callback.
public enum LocalEntityEvent: Sendable {
  case transportError
  case entityOnline(UniqueIdentifier)
  case entityUpdated(UniqueIdentifier)
  case entityOffline(UniqueIdentifier)
  case entityIdentifyNotification(UniqueIdentifier)
  case deregisteredFromUnsolicitedNotifications(UniqueIdentifier)

  case controllerConnectResponse(StreamConnectionState, LocalEntityControlStatus)
  case controllerDisconnectResponse(StreamConnectionState, LocalEntityControlStatus)
  case listenerConnectResponse(StreamConnectionState, LocalEntityControlStatus)
  case listenerDisconnectResponse(StreamConnectionState, LocalEntityControlStatus)
  case talkerStreamStateResponse(StreamConnectionState, LocalEntityControlStatus)
  case listenerStreamStateResponse(StreamConnectionState, LocalEntityControlStatus)

  case entityAcquired(UniqueIdentifier, owningEntity: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16)
  case entityReleased(UniqueIdentifier, owningEntity: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16)
  case entityLocked(UniqueIdentifier, lockingEntity: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16)
  case entityUnlocked(UniqueIdentifier, lockingEntity: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16)

  case configurationChanged(UniqueIdentifier, configurationIndex: UInt16)
  case associationIDChanged(UniqueIdentifier, associationID: UniqueIdentifier)
  case clockSourceChanged(UniqueIdentifier, clockDomainIndex: UInt16, clockSourceIndex: UInt16)

  case streamInputFormatChanged(UniqueIdentifier, streamIndex: UInt16, streamFormat: StreamFormat)
  case streamOutputFormatChanged(UniqueIdentifier, streamIndex: UInt16, streamFormat: StreamFormat)
  case streamPortInputAudioMappingsChanged(UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping])
  case streamPortOutputAudioMappingsChanged(UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping])
  case streamPortInputAudioMappingsAdded(UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping])
  case streamPortOutputAudioMappingsAdded(UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping])
  case streamPortInputAudioMappingsRemoved(UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping])
  case streamPortOutputAudioMappingsRemoved(UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping])
  case streamInputInfoChanged(UniqueIdentifier, streamIndex: UInt16, info: StreamInfo, fromGetResponse: Bool)
  case streamOutputInfoChanged(UniqueIdentifier, streamIndex: UInt16, info: StreamInfo, fromGetResponse: Bool)
  case streamInputStarted(UniqueIdentifier, streamIndex: UInt16)
  case streamOutputStarted(UniqueIdentifier, streamIndex: UInt16)
  case streamInputStopped(UniqueIdentifier, streamIndex: UInt16)
  case streamOutputStopped(UniqueIdentifier, streamIndex: UInt16)
  case maxTransitTimeChanged(UniqueIdentifier, streamIndex: UInt16, maxTransitTime: UInt64)

  case entityNameChanged(UniqueIdentifier, name: String)
  case entityGroupNameChanged(UniqueIdentifier, name: String)
  /// Any descriptor-level name change; `descriptorType` is `.configuration` for the
  /// configuration's own name (then `descriptorIndex` is the configuration index).
  case descriptorNameChanged(
    UniqueIdentifier,
    descriptorType: DescriptorType,
    configurationIndex: UInt16,
    descriptorIndex: UInt16,
    name: String
  )

  case audioUnitSamplingRateChanged(UniqueIdentifier, audioUnitIndex: UInt16, samplingRate: UInt32)
  case videoClusterSamplingRateChanged(UniqueIdentifier, videoClusterIndex: UInt16, samplingRate: UInt32)
  case sensorClusterSamplingRateChanged(UniqueIdentifier, sensorClusterIndex: UInt16, samplingRate: UInt32)

  case entityCountersChanged(UniqueIdentifier, valid: EntityCounterValidFlags, counters: DescriptorCounters)
  case avbInterfaceCountersChanged(UniqueIdentifier, avbInterfaceIndex: UInt16, valid: AvbInterfaceCounterValidFlags, counters: DescriptorCounters)
  case clockDomainCountersChanged(UniqueIdentifier, clockDomainIndex: UInt16, valid: ClockDomainCounterValidFlags, counters: DescriptorCounters)
  case streamInputCountersChanged(UniqueIdentifier, streamIndex: UInt16, valid: StreamInputCounterValidFlags, counters: DescriptorCounters)
  case streamOutputCountersChanged(UniqueIdentifier, streamIndex: UInt16, valid: StreamOutputCounterValidFlags, counters: DescriptorCounters)
  case avbInfoChanged(UniqueIdentifier, avbInterfaceIndex: UInt16, info: AvbInfo)
  case asPathChanged(UniqueIdentifier, avbInterfaceIndex: UInt16, asPath: [UniqueIdentifier])

  case controlValuesChanged(UniqueIdentifier, controlIndex: UInt16, packedControlValues: [UInt8])
  case memoryObjectLengthChanged(UniqueIdentifier, configurationIndex: UInt16, memoryObjectIndex: UInt16, length: UInt64)
  case operationStatus(UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16, operationID: UInt16, percentComplete: UInt16)

  case systemUniqueIDChanged(UniqueIdentifier, systemUniqueID: UniqueIdentifier, systemName: String)
  case mediaClockReferenceInfoChanged(UniqueIdentifier, clockDomainIndex: UInt16, defaultPriority: DefaultMediaClockReferencePriority, info: MediaClockReferenceInfo)
  case bindStream(UniqueIdentifier, streamIndex: UInt16, talker: StreamIdentification, flags: BindStreamFlags)
  case unbindStream(UniqueIdentifier, streamIndex: UInt16)
  case streamInputInfoExChanged(UniqueIdentifier, streamIndex: UInt16, info: StreamInputInfoEx)

  case aecpRetry(UniqueIdentifier)
  case aecpTimeout(UniqueIdentifier)
  case aecpUnexpectedResponse(UniqueIdentifier)
  case aecpResponseTime(UniqueIdentifier, responseTime: UInt64)
  case aemAecpUnsolicitedReceived(UniqueIdentifier, sequenceID: UInt16)
  case mvuAecpUnsolicitedReceived(UniqueIdentifier, sequenceID: UInt16)
}

/// Delivers `LocalEntityDelegate` callbacks as an `AsyncStream`. Install it as the
/// entity's delegate and iterate `events`; the stream buffers so callbacks never block.
public final class LocalEntityEventStream: LocalEntityDelegate, Sendable {
  public let events: AsyncStream<LocalEntityEvent>
  private let continuation: AsyncStream<LocalEntityEvent>.Continuation

  public init() {
    (events, continuation) = AsyncStream.makeStream(bufferingPolicy: .unbounded)
  }

  public func finish() {
    continuation.finish()
  }

  private func yield(_ event: LocalEntityEvent) {
    continuation.yield(event)
  }

  public func onTransportError(_: LocalEntity) { yield(.transportError) }
  public func onEntityOnline(_: LocalEntity, id: UniqueIdentifier, entity _: Entity) { yield(.entityOnline(id)) }
  public func onEntityUpdate(_: LocalEntity, id: UniqueIdentifier, entity _: Entity) { yield(.entityUpdated(id)) }
  public func onEntityOffline(_: LocalEntity, id: UniqueIdentifier) { yield(.entityOffline(id)) }
  public func onEntityIdentifyNotification(_: LocalEntity, id: UniqueIdentifier) { yield(.entityIdentifyNotification(id)) }
  public func onDeregisteredFromUnsolicitedNotifications(_: LocalEntity, id: UniqueIdentifier) {
    yield(.deregisteredFromUnsolicitedNotifications(id))
  }

  public func onControllerConnectResponseSniffed(_: LocalEntity, state: StreamConnectionState, status: LocalEntityControlStatus) {
    yield(.controllerConnectResponse(state, status))
  }

  public func onControllerDisconnectResponseSniffed(_: LocalEntity, state: StreamConnectionState, status: LocalEntityControlStatus) {
    yield(.controllerDisconnectResponse(state, status))
  }

  public func onListenerConnectResponseSniffed(_: LocalEntity, state: StreamConnectionState, status: LocalEntityControlStatus) {
    yield(.listenerConnectResponse(state, status))
  }

  public func onListenerDisconnectResponseSniffed(_: LocalEntity, state: StreamConnectionState, status: LocalEntityControlStatus) {
    yield(.listenerDisconnectResponse(state, status))
  }

  public func onGetTalkerStreamStateResponseSniffed(_: LocalEntity, state: StreamConnectionState, status: LocalEntityControlStatus) {
    yield(.talkerStreamStateResponse(state, status))
  }

  public func onGetListenerStreamStateResponseSniffed(_: LocalEntity, state: StreamConnectionState, status: LocalEntityControlStatus) {
    yield(.listenerStreamStateResponse(state, status))
  }

  public func onEntityAcquired(_: LocalEntity, id: UniqueIdentifier, owningEntity: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16) {
    yield(.entityAcquired(id, owningEntity: owningEntity, descriptorType: descriptorType, descriptorIndex: descriptorIndex))
  }

  public func onEntityReleased(_: LocalEntity, id: UniqueIdentifier, owningEntity: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16) {
    yield(.entityReleased(id, owningEntity: owningEntity, descriptorType: descriptorType, descriptorIndex: descriptorIndex))
  }

  public func onEntityLocked(_: LocalEntity, id: UniqueIdentifier, lockingEntity: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16) {
    yield(.entityLocked(id, lockingEntity: lockingEntity, descriptorType: descriptorType, descriptorIndex: descriptorIndex))
  }

  public func onEntityUnlocked(_: LocalEntity, id: UniqueIdentifier, lockingEntity: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16) {
    yield(.entityUnlocked(id, lockingEntity: lockingEntity, descriptorType: descriptorType, descriptorIndex: descriptorIndex))
  }

  public func onConfigurationChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16) {
    yield(.configurationChanged(id, configurationIndex: configurationIndex))
  }

  public func onAssociationIDChanged(_: LocalEntity, id: UniqueIdentifier, associationID: UniqueIdentifier) {
    yield(.associationIDChanged(id, associationID: associationID))
  }

  public func onClockSourceChanged(_: LocalEntity, id: UniqueIdentifier, clockDomainIndex: UInt16, clockSourceIndex: UInt16) {
    yield(.clockSourceChanged(id, clockDomainIndex: clockDomainIndex, clockSourceIndex: clockSourceIndex))
  }

  public func onStreamInputFormatChanged(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, streamFormat: StreamFormat) {
    yield(.streamInputFormatChanged(id, streamIndex: streamIndex, streamFormat: streamFormat))
  }

  public func onStreamOutputFormatChanged(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, streamFormat: StreamFormat) {
    yield(.streamOutputFormatChanged(id, streamIndex: streamIndex, streamFormat: streamFormat))
  }

  public func onStreamPortInputAudioMappingsChanged(_: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16, numberOfMaps _: UInt16, mapIndex _: UInt16, mappings: [AudioMapping]) {
    yield(.streamPortInputAudioMappingsChanged(id, streamPortIndex: streamPortIndex, mappings: mappings))
  }

  public func onStreamPortOutputAudioMappingsChanged(_: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16, numberOfMaps _: UInt16, mapIndex _: UInt16, mappings: [AudioMapping]) {
    yield(.streamPortOutputAudioMappingsChanged(id, streamPortIndex: streamPortIndex, mappings: mappings))
  }

  public func onStreamPortInputAudioMappingsAdded(_: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping]) {
    yield(.streamPortInputAudioMappingsAdded(id, streamPortIndex: streamPortIndex, mappings: mappings))
  }

  public func onStreamPortOutputAudioMappingsAdded(_: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping]) {
    yield(.streamPortOutputAudioMappingsAdded(id, streamPortIndex: streamPortIndex, mappings: mappings))
  }

  public func onStreamPortInputAudioMappingsRemoved(_: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping]) {
    yield(.streamPortInputAudioMappingsRemoved(id, streamPortIndex: streamPortIndex, mappings: mappings))
  }

  public func onStreamPortOutputAudioMappingsRemoved(_: LocalEntity, id: UniqueIdentifier, streamPortIndex: UInt16, mappings: [AudioMapping]) {
    yield(.streamPortOutputAudioMappingsRemoved(id, streamPortIndex: streamPortIndex, mappings: mappings))
  }

  public func onStreamInputInfoChanged(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, info: StreamInfo, fromGetResponse: Bool) {
    yield(.streamInputInfoChanged(id, streamIndex: streamIndex, info: info, fromGetResponse: fromGetResponse))
  }

  public func onStreamOutputInfoChanged(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, info: StreamInfo, fromGetResponse: Bool) {
    yield(.streamOutputInfoChanged(id, streamIndex: streamIndex, info: info, fromGetResponse: fromGetResponse))
  }

  public func onStreamInputStarted(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16) { yield(.streamInputStarted(id, streamIndex: streamIndex)) }
  public func onStreamOutputStarted(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16) { yield(.streamOutputStarted(id, streamIndex: streamIndex)) }
  public func onStreamInputStopped(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16) { yield(.streamInputStopped(id, streamIndex: streamIndex)) }
  public func onStreamOutputStopped(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16) { yield(.streamOutputStopped(id, streamIndex: streamIndex)) }

  public func onMaxTransitTimeChanged(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, maxTransitTime: UInt64) {
    yield(.maxTransitTimeChanged(id, streamIndex: streamIndex, maxTransitTime: maxTransitTime))
  }

  public func onEntityNameChanged(_: LocalEntity, id: UniqueIdentifier, name: String) { yield(.entityNameChanged(id, name: name)) }
  public func onEntityGroupNameChanged(_: LocalEntity, id: UniqueIdentifier, name: String) { yield(.entityGroupNameChanged(id, name: name)) }

  private func nameChanged(_ id: UniqueIdentifier, _ type: DescriptorType, _ configurationIndex: UInt16, _ index: UInt16, _ name: String) {
    yield(.descriptorNameChanged(id, descriptorType: type, configurationIndex: configurationIndex, descriptorIndex: index, name: name))
  }

  public func onConfigurationNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, name: String) {
    nameChanged(id, .configuration, configurationIndex, configurationIndex, name)
  }

  public func onAudioUnitNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, audioUnitIndex: UInt16, name: String) {
    nameChanged(id, .audioUnit, configurationIndex, audioUnitIndex, name)
  }

  public func onStreamInputNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, streamIndex: UInt16, name: String) {
    nameChanged(id, .streamInput, configurationIndex, streamIndex, name)
  }

  public func onStreamOutputNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, streamIndex: UInt16, name: String) {
    nameChanged(id, .streamOutput, configurationIndex, streamIndex, name)
  }

  public func onJackInputNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, jackIndex: UInt16, name: String) {
    nameChanged(id, .jackInput, configurationIndex, jackIndex, name)
  }

  public func onJackOutputNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, jackIndex: UInt16, name: String) {
    nameChanged(id, .jackOutput, configurationIndex, jackIndex, name)
  }

  public func onAvbInterfaceNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, avbInterfaceIndex: UInt16, name: String) {
    nameChanged(id, .avbInterface, configurationIndex, avbInterfaceIndex, name)
  }

  public func onClockSourceNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, clockSourceIndex: UInt16, name: String) {
    nameChanged(id, .clockSource, configurationIndex, clockSourceIndex, name)
  }

  public func onMemoryObjectNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, memoryObjectIndex: UInt16, name: String) {
    nameChanged(id, .memoryObject, configurationIndex, memoryObjectIndex, name)
  }

  public func onAudioClusterNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, audioClusterIndex: UInt16, name: String) {
    nameChanged(id, .audioCluster, configurationIndex, audioClusterIndex, name)
  }

  public func onControlNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, controlIndex: UInt16, name: String) {
    nameChanged(id, .control, configurationIndex, controlIndex, name)
  }

  public func onClockDomainNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, clockDomainIndex: UInt16, name: String) {
    nameChanged(id, .clockDomain, configurationIndex, clockDomainIndex, name)
  }

  public func onTimingNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, timingIndex: UInt16, name: String) {
    nameChanged(id, .timing, configurationIndex, timingIndex, name)
  }

  public func onPtpInstanceNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, ptpInstanceIndex: UInt16, name: String) {
    nameChanged(id, .ptpInstance, configurationIndex, ptpInstanceIndex, name)
  }

  public func onPtpPortNameChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, ptpPortIndex: UInt16, name: String) {
    nameChanged(id, .ptpPort, configurationIndex, ptpPortIndex, name)
  }

  public func onAudioUnitSamplingRateChanged(_: LocalEntity, id: UniqueIdentifier, audioUnitIndex: UInt16, samplingRate: UInt32) {
    yield(.audioUnitSamplingRateChanged(id, audioUnitIndex: audioUnitIndex, samplingRate: samplingRate))
  }

  public func onVideoClusterSamplingRateChanged(_: LocalEntity, id: UniqueIdentifier, videoClusterIndex: UInt16, samplingRate: UInt32) {
    yield(.videoClusterSamplingRateChanged(id, videoClusterIndex: videoClusterIndex, samplingRate: samplingRate))
  }

  public func onSensorClusterSamplingRateChanged(_: LocalEntity, id: UniqueIdentifier, sensorClusterIndex: UInt16, samplingRate: UInt32) {
    yield(.sensorClusterSamplingRateChanged(id, sensorClusterIndex: sensorClusterIndex, samplingRate: samplingRate))
  }

  public func onEntityCountersChanged(_: LocalEntity, id: UniqueIdentifier, valid: EntityCounterValidFlags, counters: DescriptorCounters) {
    yield(.entityCountersChanged(id, valid: valid, counters: counters))
  }

  public func onAvbInterfaceCountersChanged(_: LocalEntity, id: UniqueIdentifier, avbInterfaceIndex: UInt16, valid: AvbInterfaceCounterValidFlags, counters: DescriptorCounters) {
    yield(.avbInterfaceCountersChanged(id, avbInterfaceIndex: avbInterfaceIndex, valid: valid, counters: counters))
  }

  public func onClockDomainCountersChanged(_: LocalEntity, id: UniqueIdentifier, clockDomainIndex: UInt16, valid: ClockDomainCounterValidFlags, counters: DescriptorCounters) {
    yield(.clockDomainCountersChanged(id, clockDomainIndex: clockDomainIndex, valid: valid, counters: counters))
  }

  public func onStreamInputCountersChanged(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, valid: StreamInputCounterValidFlags, counters: DescriptorCounters) {
    yield(.streamInputCountersChanged(id, streamIndex: streamIndex, valid: valid, counters: counters))
  }

  public func onStreamOutputCountersChanged(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, valid: StreamOutputCounterValidFlags, counters: DescriptorCounters) {
    yield(.streamOutputCountersChanged(id, streamIndex: streamIndex, valid: valid, counters: counters))
  }

  public func onAvbInfoChanged(_: LocalEntity, id: UniqueIdentifier, avbInterfaceIndex: UInt16, info: AvbInfo) {
    yield(.avbInfoChanged(id, avbInterfaceIndex: avbInterfaceIndex, info: info))
  }

  public func onAsPathChanged(_: LocalEntity, id: UniqueIdentifier, avbInterfaceIndex: UInt16, asPath: AsPath) {
    yield(.asPathChanged(id, avbInterfaceIndex: avbInterfaceIndex, asPath: asPath.sequence))
  }

  public func onControlValuesChanged(_: LocalEntity, id: UniqueIdentifier, controlIndex: UInt16, packedControlValues: [UInt8]) {
    yield(.controlValuesChanged(id, controlIndex: controlIndex, packedControlValues: packedControlValues))
  }

  public func onMemoryObjectLengthChanged(_: LocalEntity, id: UniqueIdentifier, configurationIndex: UInt16, memoryObjectIndex: UInt16, length: UInt64) {
    yield(.memoryObjectLengthChanged(id, configurationIndex: configurationIndex, memoryObjectIndex: memoryObjectIndex, length: length))
  }

  public func onOperationStatus(_: LocalEntity, id: UniqueIdentifier, descriptorType: UInt16, descriptorIndex: UInt16, operationID: UInt16, percentComplete: UInt16) {
    yield(.operationStatus(id, descriptorType: descriptorType, descriptorIndex: descriptorIndex, operationID: operationID, percentComplete: percentComplete))
  }

  public func onSystemUniqueIDChanged(_: LocalEntity, id: UniqueIdentifier, systemUniqueID: UniqueIdentifier, systemName: String) {
    yield(.systemUniqueIDChanged(id, systemUniqueID: systemUniqueID, systemName: systemName))
  }

  public func onMediaClockReferenceInfoChanged(_: LocalEntity, id: UniqueIdentifier, clockDomainIndex: UInt16, defaultPriority: DefaultMediaClockReferencePriority, info: MediaClockReferenceInfo) {
    yield(.mediaClockReferenceInfoChanged(id, clockDomainIndex: clockDomainIndex, defaultPriority: defaultPriority, info: info))
  }

  public func onBindStream(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, talker: StreamIdentification, flags: BindStreamFlags) {
    yield(.bindStream(id, streamIndex: streamIndex, talker: talker, flags: flags))
  }

  public func onUnbindStream(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16) { yield(.unbindStream(id, streamIndex: streamIndex)) }

  public func onStreamInputInfoExChanged(_: LocalEntity, id: UniqueIdentifier, streamIndex: UInt16, info: StreamInputInfoEx) {
    yield(.streamInputInfoExChanged(id, streamIndex: streamIndex, info: info))
  }

  public func onAecpRetry(_: LocalEntity, id: UniqueIdentifier) { yield(.aecpRetry(id)) }
  public func onAecpTimeout(_: LocalEntity, id: UniqueIdentifier) { yield(.aecpTimeout(id)) }
  public func onAecpUnexpectedResponse(_: LocalEntity, id: UniqueIdentifier) { yield(.aecpUnexpectedResponse(id)) }
  public func onAecpResponseTime(_: LocalEntity, id: UniqueIdentifier, responseTime: UInt64) { yield(.aecpResponseTime(id, responseTime: responseTime)) }
  public func onAemAecpUnsolicitedReceived(_: LocalEntity, id: UniqueIdentifier, sequenceID: UInt16) { yield(.aemAecpUnsolicitedReceived(id, sequenceID: sequenceID)) }
  public func onMvuAecpUnsolicitedReceived(_: LocalEntity, id: UniqueIdentifier, sequenceID: UInt16) { yield(.mvuAecpUnsolicitedReceived(id, sequenceID: sequenceID)) }
}

public extension LocalEntityEvent {
  /// The remote entity an event concerns; listener-side ACMP responses report the
  /// listener, talker-side ones the talker. nil for events with no entity.
  var entityID: UniqueIdentifier? {
    switch self {
    case .transportError:
      UniqueIdentifier?.none
    case let .entityOnline(id), let .entityUpdated(id), let .entityOffline(id),
         let .entityIdentifyNotification(id), let .deregisteredFromUnsolicitedNotifications(id):
      id
    case let .controllerConnectResponse(state, _), let .controllerDisconnectResponse(state, _),
         let .listenerConnectResponse(state, _), let .listenerDisconnectResponse(state, _),
         let .listenerStreamStateResponse(state, _):
      state.listenerStream.entityID
    case let .talkerStreamStateResponse(state, _):
      state.talkerStream.entityID
    case let .entityAcquired(id, _, _, _), let .entityReleased(id, _, _, _),
         let .entityLocked(id, _, _, _), let .entityUnlocked(id, _, _, _):
      id
    case let .configurationChanged(id, _), let .associationIDChanged(id, _),
         let .clockSourceChanged(id, _, _):
      id
    case let .streamInputFormatChanged(id, _, _), let .streamOutputFormatChanged(id, _, _),
         let .streamPortInputAudioMappingsChanged(id, _, _),
         let .streamPortOutputAudioMappingsChanged(id, _, _),
         let .streamPortInputAudioMappingsAdded(id, _, _),
         let .streamPortOutputAudioMappingsAdded(id, _, _),
         let .streamPortInputAudioMappingsRemoved(id, _, _),
         let .streamPortOutputAudioMappingsRemoved(id, _, _):
      id
    case let .streamInputInfoChanged(id, _, _, _), let .streamOutputInfoChanged(id, _, _, _),
         let .streamInputStarted(id, _), let .streamOutputStarted(id, _),
         let .streamInputStopped(id, _), let .streamOutputStopped(id, _),
         let .maxTransitTimeChanged(id, _, _):
      id
    case let .entityNameChanged(id, _), let .entityGroupNameChanged(id, _),
         let .descriptorNameChanged(id, _, _, _, _):
      id
    case let .audioUnitSamplingRateChanged(id, _, _), let .videoClusterSamplingRateChanged(id, _, _),
         let .sensorClusterSamplingRateChanged(id, _, _):
      id
    case let .entityCountersChanged(id, _, _), let .avbInterfaceCountersChanged(id, _, _, _),
         let .clockDomainCountersChanged(id, _, _, _), let .streamInputCountersChanged(id, _, _, _),
         let .streamOutputCountersChanged(id, _, _, _), let .avbInfoChanged(id, _, _),
         let .asPathChanged(id, _, _):
      id
    case let .controlValuesChanged(id, _, _), let .memoryObjectLengthChanged(id, _, _, _),
         let .operationStatus(id, _, _, _, _), let .systemUniqueIDChanged(id, _, _),
         let .mediaClockReferenceInfoChanged(id, _, _, _):
      id
    case let .bindStream(id, _, _, _), let .unbindStream(id, _), let .streamInputInfoExChanged(id, _, _):
      id
    case let .aecpRetry(id), let .aecpTimeout(id), let .aecpUnexpectedResponse(id),
         let .aecpResponseTime(id, _), let .aemAecpUnsolicitedReceived(id, _),
         let .mvuAecpUnsolicitedReceived(id, _):
      id
    }
  }
}
