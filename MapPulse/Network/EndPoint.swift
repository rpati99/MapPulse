//
//  EndPoint.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/23/25.
//

import Foundation

// MARK: HTTP Endpoint protocol 
protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
}
