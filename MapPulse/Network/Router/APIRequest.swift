//
//  APIRequest.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/23/25.
//

import Foundation
// MARK: - APIRequest Builds the url for api from above and makes request

// Sits between Router and transport layer
struct APIRequest {
    // Router endpoint
    let endpoint: OneStepGPSEndpoint
    
    
    func asURLRequest() throws -> URLRequest {
        // make url components
        var components = URLComponents(url: endpoint.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        
        // add query items
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }
        
        // error handling
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
       
        // make url request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        
        // return the created request
        return request
    }
    
}
