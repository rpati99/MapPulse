//
//  NetworkViewModel.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/21/25.
//
import SwiftUI
import Combine
import Observation
/*
 NetworkTestViewModel is a SwiftUI view model that periodically polls the OneStep GPS API for the latest devices, throttles updates to once per second and publishes both its loading state and the device list for your UI.
 */

@MainActor
final public class NetworkViewModel: ObservableObject {
    
    // Reactive polling state for SwiftUI views to react
    @Published var state: PollingRequestState<[Device]> = .idle
    
    // API Client and Poller from Netowrk layer
    private let client: APIClientType
    let pollingService: DevicePollingService
    
    // Reactive cancellables from Combine
    private var cancellables = Set<AnyCancellable>()
    
    // Holds fetched devices
    var devices : [Device] = []
    
    init(client: APIClientType = APIClient(), interval: TimeInterval = 8) {
        // referencing API client
        self.client = client
        
        // inject the client into your poller
        pollingService = DevicePollingService(client: client, interval: interval)
        
        // Bind poller's state to our devices and published state
        pollingService.$state
        
            .compactMap { state -> [Device]? in
                // only pass along the array when we get .success
                if case .success(let devices) = state {
                    return devices
                }
                return nil
            }
        // throttle UI to at most one update per second
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
        
        // sink(send data) on the main actor (thread)
            .sink { [weak self] latestDevices in
                guard let self = self else { return }
                
                // log the incoming state in console
//                _ = self.log(.success(latestDevices))
                
                // batch‐assign without implicit animation
                withTransaction(Transaction(animation: nil)) {
                    self.devices = latestDevices
                    self.state = .success(latestDevices)
                }
            }
            .store(in: &cancellables) // holds subscription status in View model
        
        // Start polling
        pollingService.start()
    }
    
    // clean up
    deinit {
        // stop() lives on the MainActor thus wrapping it:
        Task { [pollingService]  in
            await pollingService.stop()
        }
    }
    
    // One shot fetch async/await method
    func fetchOnceAndPrint() async -> [Device]? {
        
        do {
            let devices = try await client.fetchLatestDevices()
            print("One‑shot fetched \(devices.count) devices")
            Task { @MainActor in
                self.devices = devices
                return devices
            }
        } catch {
            print("One‑shot fetch error:", error)
        }
        return nil
    }
    
    // helper to log each poll result in console
    func log(_ state: PollingRequestState<[Device]>) -> [Device]? {
        
        switch state {
        case .idle:
            print("Paused Polling idle")
            return nil
        case .loading:
            print("Polling…")
            return nil
        case .success(let devices):
            print("Polled \(devices.count) devices")
            devices.forEach { d in
                let lat = d.latestPoint?.latitude ?? 0
                let lng = d.latestPoint?.longitude ?? 0
                print(" • \(d.name) @ [\(lat),\(lng)]  status=\(d.activeState ?? "-")  drive_status=\(d.latestPoint?.deviceState?.driveStatus ?? "-") obdVoltage=\(String(describing: d.latestPoint?.batteryInfo?.obdVoltage)) ravenVoltage=\(String(describing: d.latestPoint?.batteryInfo?.ravenVoltage))")
            }
            self.devices = devices
            return devices
        case .failure(let error):
            print("Poll error:", error.localizedDescription)
            return nil
        }
    }
}

extension NetworkViewModel {
    // Expose method to restart the polling from VM (Retry button in MapView.swift)
    func restartPolling() {
        pollingService.start()
    }
    
    // Prints the one-off fetch to console, updates devices, but doesn’t affect the ongoing poll
    func fetchOnceAndPrintTask() {
        Task { await fetchOnceAndPrint() }
    }
}
