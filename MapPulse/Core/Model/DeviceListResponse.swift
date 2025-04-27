//
//  DeviceListResponse.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//

import Foundation

// Top‑Level Response from API response
struct DeviceListResponse: Decodable {
    let result_list: [Device]
}
