//
//  NetworkModule.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//

import Foundation
import Combine










// MARK: - APIClient



// MARK: - API Errors



// MARK: - JSONDecoder Extension



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
