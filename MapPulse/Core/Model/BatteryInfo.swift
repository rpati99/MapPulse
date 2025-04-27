//
//  BatteryInfo.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//

import Foundation

// Nested JSON model for fetching battery data
struct BatteryInfo: Decodable {
    let obdVoltage: Double? // optional type
    let ravenVoltage: Double? // optional type
    
    // Maps Swift properties with JSON keys
    enum CodingKeys: String, CodingKey {
        case obd = "obd_battery_voltage"
        case raven = "obd_batt_volt_raven"
    }
    
    // Initializer that holds decoding logic
    init(from decoder: Decoder) throws {
        // Takes the keyed container from decoder using CodingKeys enum
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // try string → Double, then Double, else nil
        func decodeFlexible(_ key: CodingKeys) -> Double? {
            // Decodes as String -> Double
            if let str = try? c.decode(String.self, forKey: key), let d = Double(str) {
                return d
            }
            return try? c.decode(Double.self, forKey: key)
        }
        obdVoltage   = decodeFlexible(.obd)
        ravenVoltage = decodeFlexible(.raven)
    }
}

extension BatteryInfo {
    // Stub initializer for previews
    init(
        obdVoltage: Double? = nil,
        ravenVoltage: Double? = nil
    ) {
        self.obdVoltage   = obdVoltage
        self.ravenVoltage = ravenVoltage
    }
}
