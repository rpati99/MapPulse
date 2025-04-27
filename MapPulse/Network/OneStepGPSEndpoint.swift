//
//  OneStepGPSEndpoint.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation

// MARK: - OneStepGPS Endpoints,  Router pattern starts

//  Creating the REST API link

enum OneStepGPSEndpoint {
    case latestDevices
    // add the case for device data or user uploaded image
}

extension OneStepGPSEndpoint: Endpoint {
    private static let apiKey = "Xl-8_ceibpMHqr4YZ72uFy5xQfjbOPXstocE8b_Zkmw"
    
    var baseURL: URL {
        URL(string: "https://track.onestepgps.com/v3/api/public/device?")!
    }
    
    var path: String {
        switch self {
        case .latestDevices:
            return ""
        }
    }
    var method: HTTPMethod {
        switch self {
        case .latestDevices:
            return .get
        }
    }
    var queryItems: [URLQueryItem] {
        switch self {
        case .latestDevices:
            return [
                URLQueryItem(name: "latest_point", value: "true"),
                URLQueryItem(name: "api-key", value: Self.apiKey)
            ]
        }
    }
    var headers: [String : String] {
        ["Accept": "application/json"]
    }
}
