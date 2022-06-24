//
//  AppState.swift
//  GlucoseDirect
//

import Combine
import Foundation

// MARK: - AppState

protocol AppState {
    var alarmHigh: Int { get set }
    var alarmLow: Int { get set }
    var alarmSnoozeUntil: Date? { get set }
    var appleCalendarExport: Bool { get set }
    var appleHealthExport: Bool { get set }
    var bellmanAlarm: Bool { get set }
    var bellmanConnectionState: BellmanConnectionState { get set }
    var chartShowLines: Bool { get set }
    var chartZoomLevel: Int { get set }
    var connectionAlarmSound: NotificationSound { get set }
    var connectionError: String? { get set }
    var connectionErrorIsCritical: Bool { get set }
    var connectionErrorTimestamp: Date? { get set }
    var connectionInfos: [SensorConnectionInfo] { get set }
    var connectionState: SensorConnectionState { get set }
    var customCalibration: [CustomCalibration] { get set }
    var connectionPeripheralUUID: String? { get set }
    var expiringAlarmSound: NotificationSound { get set }
    var glucoseNotification: Bool { get set }
    var glucoseUnit: GlucoseUnit { get set }
    var glucoseValues: [Glucose] { get set }
    var highGlucoseAlarmSound: NotificationSound { get set }
    var isConnectionPaired: Bool { get set }
    var ignoreMute: Bool { get set }
    var lowGlucoseAlarmSound: NotificationSound { get set }
    var missedReadings: Int { get set }
    var nightscoutApiSecret: String { get set }
    var nightscoutUpload: Bool { get set }
    var nightscoutURL: String { get set }
    var preventScreenLock: Bool { get set }
    var readGlucose: Bool { get set }
    var selectedCalendarTarget: String? { get set }
    var selectedConnection: SensorBLEConnection? { get set }
    var selectedConnectionID: String? { get set }
    var selectedView: Int { get set }
    var sensor: Sensor? { get set }
    var sensorInterval: Int { get set }
    var targetValue: Int { get set }
    var transmitter: Transmitter? { get set }
}

extension AppState {
    var latestGlucose: Glucose? {
        glucoseValues.last
    }

    var latestSensorGlucose: Glucose? {
        glucoseValues.last(where: { $0.type == .cgm })
    }

    var latestBloodGlucose: Glucose? {
        glucoseValues.last(where: { $0.type == .bgm })
    }

    var connectionAlarm: Bool {
        connectionAlarmSound != .none
    }

    var expiringAlarm: Bool {
        expiringAlarmSound != .none
    }

    var highGlucoseAlarm: Bool {
        highGlucoseAlarmSound != .none
    }

    var lowGlucoseAlarm: Bool {
        lowGlucoseAlarmSound != .none
    }

    var isConnectable: Bool {
        if transmitter != nil, connectableStates.contains(connectionState) {
            return true
        }

        if let sensor = sensor {
            return sensorConnectableStates.contains(sensor.state) && connectableStates.contains(connectionState)
        }

        return false
    }

    var hasSelectedConnection: Bool {
        selectedConnection != nil
    }

    var isDisconnectable: Bool {
        disconnectableStates.contains(connectionState)
    }

    var isSensor: Bool {
        selectedConnection is IsSensor
    }

    var isTransmitter: Bool {
        selectedConnection is IsTransmitter
    }

    var isPairable: Bool {
        !isConnectionPaired && !(connectionState != .disconnected && connectionState != .pairing && connectionState != .scanning && connectionState != .connecting)
    }

    var isBusy: Bool {
        !(connectionState != .pairing && connectionState != .scanning && connectionState != .connecting)
    }

    var isReady: Bool {
        sensor != nil && sensor!.state == .ready
    }
}

// MARK: - private

private var sensorConnectableStates: Set<SensorState> = [.starting, .ready]
private var connectableStates: Set<SensorConnectionState> = [.disconnected]
private var disconnectableStates: Set<SensorConnectionState> = [.connected, .connecting, .scanning]
