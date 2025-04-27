//
//  OneStepGPSEndpoint.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/23/25.
//

import Foundation

//  Make the URL Endpoint
enum OneStepGPSEndpoint {
    case latestDevices
}

extension OneStepGPSEndpoint: Endpoint {
    // API key
    private static let apiKey = "Xl-8_ceibpMHqr4YZ72uFy5xQfjbOPXstocE8b_Zkmw"
    
    // Base URL
    var baseURL: URL {
        URL(string: "https://track.onestepgps.com/v3/api/public/device?")!
    }
    
    // URL Path
    var path: String {
        switch self {
        case .latestDevices:
            return ""
        }
    }
    
    // HTTP Method
    var method: HTTPMethod {
        switch self {
        case .latestDevices:
            return .get
        }
    }
    
    // URL Query items
    var queryItems: [URLQueryItem] {
        switch self {
        case .latestDevices:
            return [
                URLQueryItem(name: "latest_point", value: "true"), URLQueryItem(name: "api-key", value: Self.apiKey)
            ]
        }
    }
    
    // HTTP headers
    var headers: [String : String] {
        ["Accept": "application/json"]
    }
}
