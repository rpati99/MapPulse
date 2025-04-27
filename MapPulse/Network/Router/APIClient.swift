//
//  APIClient.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation

// A simple protocol defining our “fetch devices” capability,
protocol APIClientType {
    // Fetches the latest list of devices from the OneStepGPS API
    func fetchLatestDevices() async throws -> [Device]
}

// The real network client that reaches out over HTTP to fetch devices
final class APIClient: APIClientType {
    // Network transport
    private let transport: NetworkTransport
    
    // Dependecy injection
    init(transport: NetworkTransport = URLSessionTransport()) {
        self.transport = transport
    }
    
    // Fetch the JSON from the API, validate, decode, and return Device models
    func fetchLatestDevices() async throws -> [Device] {
        // 1. Build our endpoint and URLRequest
        let endpoint = OneStepGPSEndpoint.latestDevices
        let apiRequest = APIRequest(endpoint: endpoint)
        let urlRequest = try apiRequest.asURLRequest()
        
        // 2. Perform the network call (Data + HTTP metadata)
        let (data, http) = try await transport.perform(request: urlRequest)
        
        // 3. Ensure status code is 2xx, else bubble up an error
        guard (200...299).contains(http.statusCode) else {
            throw APIError.invalidStatus(code: http.statusCode)
        }
        
        // 4. JSON Decoding
        let decoder = JSONDecoder.iso8601
        let response = try decoder.decode(DeviceListResponse.self, from: data)
        
        // 5. Return the array of Device objects
        return response.result_list
    }
}
// MARK: - Custom JSONDecoder Extension

extension JSONDecoder {
    
    // A JSONDecoder preconfigured to parse ISO8601 dates, with fractional-seconds support and a fallback
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        
        // Formatter that handles full Internet date-time + fractional seconds
        let fullFormatter = ISO8601DateFormatter()
        fullFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Simpler formatter without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        // Custom strategy: try fullFormatter, then fallback, else throw
        decoder.dateDecodingStrategy = .custom { decoder throws -> Date in
            
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            if let date = fullFormatter.date(from: str) {
                return date
            } else if let date = fallbackFormatter.date(from: str) {
                return date
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Invalid date: \(str)"
                    )
                )
            }
        }

        return decoder
    }
}
