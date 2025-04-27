//
//  DeviceState.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//

import Foundation

// Nested JSON model for driving status
struct DeviceState: Decodable {
    let driveStatus: String
    let driveStatusDuration: StatusDuration
    let driveStatusDistance: StatusDuration

    enum CodingKeys: String, CodingKey {
        case driveStatus          = "drive_status"
        case driveStatusDuration  = "drive_status_duration"
        case driveStatusDistance  = "drive_status_distance"
    }
}


