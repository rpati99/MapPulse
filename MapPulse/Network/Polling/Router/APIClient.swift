//
//  APIClient.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation

protocol APIClientType {
    func fetchLatestDevices() async throws -> [Device]
}

final class APIClient: APIClientType {
    
    private let transport: NetworkTransport
    // DI
    init(transport: NetworkTransport = URLSessionTransport()) {
        self.transport = transport
    }
    
    func fetchLatestDevices() async throws -> [Device] {
        
        let endpoint = OneStepGPSEndpoint.latestDevices
        let apiRequest = APIRequest(endpoint: endpoint)
        let urlRequest = try apiRequest.asURLRequest()
        
        let (data, http) = try await transport.perform(request: urlRequest)
        
        guard (200...299).contains(http.statusCode) else {
            throw APIError.invalidStatus(code: http.statusCode)
        }
        
        // TODO: Formatting error comes from here
        let decoder = JSONDecoder.iso8601
        let response = try decoder.decode(DeviceListResponse.self, from: data)
        return response.result_list
    }
}

// Custom decoder 
extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        
        let fullFormatter = ISO8601DateFormatter()
        fullFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

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
