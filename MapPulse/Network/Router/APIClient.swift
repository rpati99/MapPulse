//
//  APIClient.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/23/25.
//

import Foundation


protocol APIClientType {
    func fetchLatestDevices() async throws -> [Device]
}

final class APIClient: APIClientType {
    
    
    private let transport: NetworkTransport
    
    // Dependecy injection
    init(transport: NetworkTransport = URLSessionTransport()) {
        self.transport = transport
    }
    
    // Inherited method implementation
    func fetchLatestDevices() async throws -> [Device] {
        
        // Router Endpoint
        let endpoint = OneStepGPSEndpoint.latestDevices
        
        // API request
        let apiRequest = APIRequest(endpoint: endpoint)
        
        // URL Request
        let urlRequest = try apiRequest.asURLRequest()
        
        let (data, http) = try await transport.perform(request: urlRequest)
        
        // error handling
        guard (200...299).contains(http.statusCode) else {
            throw APIError.invalidStatus(code: http.statusCode)
        }
        
        // JSON Decoding
        let decoder = JSONDecoder.iso8601
        let response = try decoder.decode(DeviceListResponse.self, from: data)
        return response.result_list
    }
}

// Custom decoder for handling ISO8601 date formatting
extension JSONDecoder {
    
    // Computed property to enhance decoder
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        
        // Default date formatter
        let fullFormatter = ISO8601DateFormatter()
        fullFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Fallback date formatter
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        // JSON Decoding strategy
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

        // Return custom decoder
        return decoder
    }
}
