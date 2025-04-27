//
//  Device.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//

import Foundation

// Device structure from JSON

// Decodable: JSON handling
// Identifiable: UI diffing
struct Device: Identifiable, Decodable {
    let id: String             // "device_id"
    let name: String           // "display_name"
    let make: String?
    let model: String?
    let activeState: String?   // "active_state"
    let lastUpdate: Date       // "updated_at"
    let latestPoint: DevicePoint? // Optional nested JSON object for Coordinates, BatteryInfo, Speed, Altitude, Duration, etc.
    
    // Mapping Swift properties from JSON keys
    enum CodingKeys: String, CodingKey {
        case id           = "device_id"
        case name         = "display_name"
        case make, model
        case activeState  = "active_state"
        case lastUpdate   = "updated_at"
        case latestPoint  = "latest_device_point"
    }
}
