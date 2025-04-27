//
//  DevicePollingService.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/23/25.
//

import Foundation
import Combine

// State driven polling service for updating device on map periodically
@MainActor
final class DevicePollingService: ObservableObject {
    
    // Reactive polling state
    @Published private(set) var state: PollingRequestState<[Device]> = .idle
    
    // API Client
    private let client: APIClientType
    
    // Polling compute unit
    private var pollingTask: Task<Void, Never>? = nil
    
    // Time interval
    private let interval: TimeInterval
    
    // DI
    init(client: APIClientType = APIClient(), interval: TimeInterval = 8) {
        self.client = client
        self.interval = interval
    }
    
    // Polling start
    func start() {
        pollingTask?.cancel()
        state = .loading // change state to loading
        
        // Polling compute logic
        pollingTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Until polling task unit isn't cancelled, continue fetching
            while !Task.isCancelled {
                // 1) fetch
                do {
                    let devices = try await self.client.fetchLatestDevices()
                    
                    await MainActor.run {
                        self.state = .success(devices)
                    }
                } catch {
                    await MainActor.run {
                        self.state = .failure(error)
                    }
                }
                
                // 2) Add time delay in fetch, and perform error handling
                do {
                    try await Task.sleep(nanoseconds: UInt64(self.interval * 1_000_000_000))
                } catch is CancellationError {
                    // break out of the loop
                    break
                } catch {
                    // other unexpected error
                    print("Sleep error:", error)
                }
            }
        }
    }
    
    // Polling stop
    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }
    
    // De-initialize polling compute
    deinit {
        pollingTask?.cancel()
    }
}
