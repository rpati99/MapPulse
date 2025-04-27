//
//  EndPoint.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation

/*
 Describes the pieces needed to build an HTTP request for our various API endpoints
    Conforming types supply the base URL, path, query parameters, HTTP method, and any headers
*/
protocol Endpoint {
    // The root URL for this endpoint
    var baseURL: URL { get }
    
    // The URL path to append to the base (often just an empty string or specific resource path)
    var path: String { get }
    
    // The HTTP method to use when talking to this endpoint (GET, POST, etc.)
    var method: HTTPMethod { get }
    
    // Any URL query parameters this endpoint needs (e.g. API keys, filters, flags)
    var queryItems: [URLQueryItem] { get }
    
    // HTTP headers to include on every request (e.g. "Accept": "application/json")
    var headers: [String: String] { get }
}
