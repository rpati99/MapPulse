//
//  APIRequest.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation
// MARK: - APIRequest Builds the url for api from above and makes request

struct APIRequest {
    let endpoint: OneStepGPSEndpoint
    
    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(url: endpoint.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
       
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        return request
    }
    
}
