////
//  OneStepGPSEndpoint.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation


// Defines the different API endpoints available for OneStepGPS
enum OneStepGPSEndpoint {
    case latestDevices
}

extension OneStepGPSEndpoint: Endpoint {
    private static let apiKey = "Xl-8_ceibpMHqr4YZ72uFy5xQfjbOPXstocE8b_Zkmw" //  API key
    
    // The base URL for all OneStepGPS API requests
    var baseURL: URL {
        URL(string: "https://track.onestepgps.com/v3/api/public/device?")!
    }
    
    // The path to append to the base URL (empty here since query items handle parameters)
    var path: String {
        switch self {
        case .latestDevices:
            return ""
        }
    }
    
    // HTTP method to use for each endpoint
    var method: HTTPMethod {
        switch self {
        case .latestDevices:
            return .get // We're only reading data for latest devices
        }
    }
    
    // Any URL query parameters required by the endpoint
    var queryItems: [URLQueryItem] {
        switch self {
        case .latestDevices:
            return [
                URLQueryItem(name: "latest_point", value: "true"), URLQueryItem(name: "api-key", value: Self.apiKey)
            ]
        }
    }
    
    // HTTP headers to include in every request
    var headers: [String : String] {
        ["Accept": "application/json"]
    }
}
