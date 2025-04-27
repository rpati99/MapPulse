//
//  APIRequest.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation

/*
 A simple builder that turns our endpoint definitions into a real URLRequest,
    handling paths, query parameters, and headers in one place
 */
struct APIRequest {
    // The endpoint enum knows its baseURL, path, query items, and headers
    let endpoint: OneStepGPSEndpoint
    
    // Convert the endpoint into a fully configured URLRequest
    // Throws if we can’t form a valid URL
    func asURLRequest() throws -> URLRequest {
        // 1) Start with the base URL and append the endpoint’s path
        var components = URLComponents(url: endpoint.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        
        // 2) If this endpoint has any query parameters, add them now
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }
        // 3) Make sure we ended up with a valid URL
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
       
        // 4) Build the URLRequest, set HTTP method, and apply headers
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        // 5) Attach any custom headers (e.g. "Accept: application/json")
        endpoint.headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
    
}
