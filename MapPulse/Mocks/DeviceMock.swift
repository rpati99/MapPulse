//
//  DeviceMock.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation

// Stubs holding mock data for SwiftUI preview loads
struct DevicePointStub {
    static let devicePoints : [DevicePoint] = [
        DevicePoint(
            latitude: 37.78,
            longitude: -122.41,
            speed: 45,
            deviceState: .init(
                driveStatus: "driving",
                driveStatusDuration: .init(value: 1200, unit: "s", display: "20 min"),
                driveStatusDistance: .init(value: 15.2, unit: "mi", display: "15.2 mi")
            ),
            batteryInfo: BatteryInfo(obdVoltage: 12.6, ravenVoltage: 13.1)
        ),
        DevicePoint(
            timestamp: Date(),
            latitude: 40.71,
            longitude: -74.01,
            altitude: 5,
            heading: 90,
            speed: 0,
            deviceState: DeviceState(
                driveStatus: "idle",
                driveStatusDuration: StatusDuration(value: 300, unit: "s", display: "5 min"),
                driveStatusDistance: StatusDuration(value: 0, unit: "mi", display: "0 mi")
            ),
            batteryInfo: BatteryInfo(obdVoltage: 12.7, ravenVoltage: 12.9)
        )
    ]
}


struct DeviceStub {
    static let devices: [Device] = [
        Device(
            id: "1246",
            name: "Explorer One",
            make: "LandRover",
            model: "Series I",
            activeState: "active",
            lastUpdate: Date.now,
            latestPoint: DevicePointStub.devicePoints.first
        ),
        Device(
            id: "9999",
            name: "RoadRunner",
            make: "Porsche",
            model: "911",
            activeState: "inactive",
            lastUpdate: Date().addingTimeInterval(-3600),
            latestPoint: DevicePointStub.devicePoints[1]
        )
    ]
}

