//
//  HiddenDevicesService.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/24/25.
//


import Foundation
import Combine // For publishing changes

/* Service that keeps track of which devices the user has chosen to hide, publishes changes for SwiftUI to react to, and persists that preference across launches via UserDefaults.
 */

// Manage handling of hidden device-IDs, and persisting across launches.
final class HiddenDeviceService: ObservableObject {
    
    // Reactive id for Swift UI views
    @Published private(set) var hiddenIDs: Set<String>
    
    // Storage key
    private let key = "hiddenDeviceIDs"
    
    // initalizer
    init() {
        // fetching saved hidden devices
        let saved = UserDefaults.standard.stringArray(forKey: key) ?? []
        self.hiddenIDs = Set(saved)
    }
    
    
    // Add the device id to hiddenDevices
    func hide(_ id: String) {
        hiddenIDs.insert(id)
        save()
    }
    
    // Remive device id for unhiding
    func unhide(_ id: String) {
        hiddenIDs.remove(id)
        save()
    }
    
    // Handles change of hide status of device through id for UI purpose
    func toggle(_ id: String) {
        if hiddenIDs.contains(id) { unhide(id) }
        else { hide(id) }
    }
    
    // Checks if device is hidden
    func isHidden(_ id: String) -> Bool {
        hiddenIDs.contains(id)
    }
    
    // Save the added ids into user defaults
    private func save() {
        UserDefaults.standard.set(Array(hiddenIDs), forKey: key)
    }
}
