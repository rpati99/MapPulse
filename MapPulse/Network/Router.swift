//
//  NetworkModule.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//

import Foundation
import Combine






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

// MARK: - APIClient

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

// MARK: - API Errors

enum APIError: Error {
    case invalidStatus(code: Int)
    case decodingError(Error)
}

// MARK: - JSONDecoder Extension

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

// MARK: - Polling Service State
enum RequestState<Value> {
    case idle
    case loading
    case success(Value)
    case failure(Error)
}


// MARK: - Device Polling Service
@MainActor
final class DevicePollingService: ObservableObject {

    
    @Published private(set) var state: RequestState<[Device]> = .idle
    
    private let client: APIClientType
    private var pollingTask: Task<Void, Never>? = nil
    private let interval: TimeInterval

    init(client: APIClientType = APIClient(), interval: TimeInterval = 15) {
        self.client = client
        self.interval = interval
    }

    func start() {
        pollingTask?.cancel()
        state = .loading
        
        pollingTask = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled {
              // 1) fetch
              do {
                let devices = try await self.client.fetchLatestDevices()
                await MainActor.run { self.state = .success(devices) }
              } catch {
                await MainActor.run { self.state = .failure(error) }
              }

              // 2) sleep, but catch so we don't throw out of the closure
              do {
                try await Task.sleep(nanoseconds: UInt64(self.interval * 1_000_000_000))
              } catch is CancellationError {
                // we've been cancelled — break out of the loop
                break
              } catch {
                // any other unexpected error
                print("Sleep error:", error)
              }
            }
          }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }

    deinit {
        pollingTask?.cancel()
    }
}
