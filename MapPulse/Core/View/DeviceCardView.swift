//
//  DeviceCardView.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/23/25.
//

import SwiftUI
import MapKit

/// A single “card” showing the device’s mini-map and key stats.
struct DeviceCardView: View {
    let device: Device
    let onSelect: (Device) -> Void
    let isExpanded: Bool
    
    // Compute a small region centered on the device
    @State private var region: MKCoordinateRegion
    
    init(device: Device, isExpanded: Bool, onSelect: @escaping (Device) -> Void) {
            self.device = device
            self.isExpanded = isExpanded
            self.onSelect = onSelect

            let coord = device.latestPoint?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            let span  = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            _region = State(initialValue: MKCoordinateRegion(center: coord, span: span))
        }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Mini-map
            // ─────── NEW iOS 17 Map initializer ───────
            Map(position: .constant(.region(region)), interactionModes: []) {
                // throw in as many annotations as you like—
                // here we only have one Device
                Annotation(device.id, coordinate: device.latestPoint!.coordinate) {
                    DeviceAnnotationUIView(device: device)
                        .frame(width: 60, height: 60)
                }
            }
            .frame(height: 120)
            .cornerRadius(8)
            .onChange(of: device.latestPoint?.coordinate, { _ , newValue in
                if let c = newValue {
                    region.center = c
                }
            })
            
            
            // Name + status line
            HStack {
                Text(device.name)
                    .font(.headline)
                    .foregroundStyle(activeStatusColor(for: device))
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
            
            // ─── expanded only ───
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
    
    private func driveStatusColor(for device: Device) -> Color {
        let driveStatus = device.latestPoint?.deviceState?.driveStatus.lowercased() ?? "off"
        switch driveStatus {
        case "driving": return .green
        case "idle":    return .orange
        default:        return .gray
        }
    }
    
    private func activeStatusColor(for device: Device) -> Color {
        let activeStatus = device.activeState ?? "no status"
        switch activeStatus {
        case "active": return .green
        default:        return .gray
        }
    }
}

/// A horizontally-scrolling carousel of devices
struct DeviceCarouselView: View {
  let devices: [Device]
  var namespace: Namespace.ID
  var onCardTap: (Device) -> Void
  @Binding var selectedDeviceID: String?
  @EnvironmentObject private var hidden: HiddenDeviceService

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 16) {
        ForEach(devices) { device in
          let expanded = device.id == selectedDeviceID

          DeviceCardView(
            device: device,
            isExpanded: expanded,
            onSelect: { onCardTap($0) }
          )
          .contextMenu {
            Button {
              hidden.toggle(device.id)
            } label: {
              Label(
                hidden.isHidden(device.id) ? "Unhide Device" : "Hide Device",
                systemImage: hidden.isHidden(device.id) ? "eye.slash" : "eye"
              )
            }
          }
          .matchedGeometryEffect(id: device.id, in: namespace)
          .frame(width: expanded ? 300 : 220)
          .offset(y: expanded ? -10 : 0)
          .padding(.vertical)
          
          // ←–––––––– Add this contextMenu modifier –––––––––→
       
        }
      }
      .padding()
    }
  }
}
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude  == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
}
