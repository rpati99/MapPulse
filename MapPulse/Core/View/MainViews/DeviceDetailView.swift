//
//  DeviceDetailView.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/23/25.
//

import SwiftUI
import MapKit

/*
 Device Detail view is a single “card” showing the device’s mini-map and key stats.
*/

struct DeviceDetailView: View {
    let device: Device // holds respective device to show data
    let onSelect: (Device) -> Void // handler when card is tapped (for expansion purposes)
    let isExpanded: Bool // indicator for expanding card
    
    // Compute region centered on the device for mini map
    @State private var region: MKCoordinateRegion
    
    
    init(device: Device, isExpanded: Bool, onSelect: @escaping (Device) -> Void) {
        self.device = device
        self.isExpanded = isExpanded
        self.onSelect = onSelect
        
        // add the mini map device to center
        let coord = device.latestPoint?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        // zoom out to show surrounding area in mini map
        let span  = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        // attach region as a SwiftUI view for reacting to changes in region (for showing up to date device location in mini map)
        _region = State(initialValue: MKCoordinateRegion(center: coord, span: span))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Mini-map to show device without manually needing to zoom on map
            Map(position: .constant(.region(region)), interactionModes: []) {
                // Show particular device
                Annotation(device.id, coordinate: device.latestPoint!.coordinate) {
                    // Use that SwiftUI representation of UIKit "DeviceAnnotationView"
                    DeviceAnnotationUIView(device: device)
                        .frame(width: 60, height: 60)
                }
            }
            .frame(height: 120)
            .cornerRadius(8)
            // update map region as per the updates in device coordinates
            .onChange(of: device.latestPoint?.coordinate, { _ , newValue in
                if let c = newValue {
                    region.center = c
                }
            })
            
            
            // Shows name and status line
            HStack {
                Text(device.name)
                    .font(.headline)
                    .foregroundStyle(activeStatusColor(for: device)) // device name label color based on device_status in API
                Spacer()
                if let raw = device.latestPoint?.deviceState?.driveStatus {
                    Text("\(raw.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(driveStatusColor(for: device))
                } else {
                    Text("Unknown")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            // Speed & battery
            VStack(alignment: .leading, spacing: 5) {
                if let speed = device.latestPoint?.speed {
                    Label("\(speed, specifier: "%.0f") mph", systemImage: "speedometer")
                        .font(.caption)
                }
                Text("Last updated: \(device.lastUpdate.formatted(date: .abbreviated, time: .shortened))")
                    .lineLimit(2)
                    .font(.caption)
            }
            
            // Actual Device Detail View to presented upon expansion
            if isExpanded, let pt = device.latestPoint {
                
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("📍 \(pt.latitude, specifier: "%.5f"), \(pt.longitude, specifier: "%.5f")")
                    if let alt = pt.altitude {
                        Text("⛰ Altitude: \(alt, specifier: "%.0f") m")
                    }
                    if let heading = pt.heading {
                        Text("🧭 Heading: \(heading, specifier: "%.0f")°")
                    }
                    if let batt = pt.batteryInfo {
                        Text("🔋 OBD: \(batt.obdVoltage ?? 0, specifier: "%.2f") V")
                        Text("🔋 Raven: \(batt.ravenVoltage ?? 0, specifier: "%.2f") V")
                    }
                    if let ds = pt.deviceState {
                        Text("⏱ Duration: \(ds.driveStatusDuration.display)")
                        Text("📏 Distance: \(ds.driveStatusDistance.display)")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .onTapGesture { onSelect(device) }
        .animation(.easeInOut, value: isExpanded)
    }
    
    // Method that returns color based on drive_status
    private func driveStatusColor(for device: Device) -> Color {
        let driveStatus = device.latestPoint?.deviceState?.driveStatus.lowercased() ?? "off"
        switch driveStatus {
        case "driving":
            return .green
        case "idle":
            return .orange
        default:
            return .gray
        }
    }
    
    // Method that returns color based on device_status
    private func activeStatusColor(for device: Device) -> Color {
        let activeStatus = device.activeState ?? "no status"
        switch activeStatus {
        case "active":
            return .green
        default:
            return .gray
        }
    }
}

// Preview setup
#Preview {
    let isExpanded = true
    let device = DeviceStub.devices.first!
   
        DeviceDetailView(
            device: device,
            isExpanded: isExpanded, onSelect: { _ in  }
        )
}

/* Extension to MapKit's location coordinate and give ability to compare the coordinates
   • Used in .onChange() on Line 51 to update region
*/
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude  == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
}
