//
//  NetworkTransport.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import Foundation

// MARK: - Network Transport

protocol NetworkTransport {
    func perform(request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

final class URLSessionTransport: NetworkTransport {
    private let session: URLSession
    init(session: URLSession = .shared) {
        self.session = session
    }
    func perform(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }
}
