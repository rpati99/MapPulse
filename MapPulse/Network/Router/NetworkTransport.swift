//
//  NetworkTransport.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation

// MARK: - Network Transport

// A lightweight protocol to fetch raw data and HTTP responses from a URLRequest
protocol NetworkTransport {
    func perform(request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

// Default implementation of NetworkTransport that wraps URLSession for real network calls

final class URLSessionTransport: NetworkTransport {
    
    private let session: URLSession // the URLSession used under the hood to perform requests
    
    // Inject a custom URLSession or use the shared one by default.
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /*
     Performs the given URLRequest asynchronously and returns the data and HTTP response,
         or throws if the response isn’t an HTTPURLResponse or if the request fails.
     */
    func perform(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }
}
