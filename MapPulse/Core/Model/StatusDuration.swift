//
//  StatusDuration.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//

import Foundation

// Swift representation of drive_status_duration, drive_status_distance
struct StatusDuration: Codable {
    let value: Double
    let unit: String
    let display: String
}
