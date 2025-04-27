//
//  DevicePoint.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//

import Foundation
import CoreLocation

// Nested JSON model for device details 
struct DevicePoint: Decodable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let heading: Double?
    let speed: Double
    let deviceState: DeviceState?
    let batteryInfo: BatteryInfo?
    
    // Mapping of Swift properties with JSON keys
    enum CodingKeys: String, CodingKey {
        case timestamp = "dt_tracker"
        case latitude  = "lat"
        case longitude = "lng"
        case altitude
        case heading   = "angle"
        case speed
        case deviceState = "device_state"
        case batteryInfo = "params"      // for battery voltage data
    }
    

    init(from decoder: Decoder) throws {
        // Creating keyed decoding container
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Decode the fields respectively with associated type assigned
        timestamp   = try c.decode(Date.self, forKey: .timestamp)
        latitude    = try c.decode(Double.self, forKey: .latitude)
        longitude   = try c.decode(Double.self, forKey: .longitude)
        altitude    = try? c.decodeIfPresent(Double.self, forKey: .altitude)
        heading     = try? c.decodeIfPresent(Double.self, forKey: .heading)
        speed       = try c.decode(Double.self, forKey: .speed)
        deviceState = try? c.decodeIfPresent(DeviceState.self, forKey: .deviceState)
        batteryInfo = try? c.decodeIfPresent(BatteryInfo.self, forKey: .batteryInfo)
    }
}

// Convenience extension to convert coordinate data to Swift Map representation
extension DevicePoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


extension DevicePoint {
    // Stub initializer for previews
    init(
        timestamp: Date = .now,
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        heading: Double? = nil,
        speed: Double,
        deviceState: DeviceState? = nil,
        batteryInfo: BatteryInfo? = nil
    ) {
        self.timestamp   = timestamp
        self.latitude    = latitude
        self.longitude   = longitude
        self.altitude    = altitude
        self.heading     = heading
        self.speed       = speed
        self.deviceState = deviceState
        self.batteryInfo = batteryInfo
    }
}

