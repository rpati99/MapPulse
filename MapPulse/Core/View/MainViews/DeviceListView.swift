//
//  DeviceListView.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/24/25.
//

import MapKit
import SwiftUI

/*
 DeviceListView is a reusable SwiftUI carousel that lays out a horizontally-scrolling strip of device in cards, handling selection,
    hiding, and expansion animation
 */

struct DeviceListView: View {
  let devices: [Device] // holds fetched devices
  var namespace: Namespace.ID // for expansion animation
  var onCardTap: (Device) -> Void // handler for reacting to tapping of card (expanding animation purpose)
  @Binding var selectedDeviceID: String? // two way binding that holds selected device id
  @EnvironmentObject private var hidden: HiddenDeviceService // Service to manage the hidden devices

  var body: some View {
      // Horizontal scrolling
    ScrollView(.horizontal, showsIndicators: false) {
        // efficient rendering of cards in Device List
      LazyHStack(spacing: 16) {
          // Rendering Device cards
        ForEach(devices) { device in
          let expanded = device.id == selectedDeviceID
         DeviceDetailView(
            device: device,
            isExpanded: expanded,
            onSelect: { onCardTap($0) }
          )
            // Menu appears on long press to hide/unhide device
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
            
        }
      }
      .padding()
    }
  }
}

// Preview setup
struct DeviceListView_Previews: PreviewProvider {
  @Namespace static private var ns

  static var previews: some View {
    // two stubs from before
      let devices = DeviceStub.devices
    let hiddenService = HiddenDeviceService()
      
    DeviceListView(
      devices: devices,
      namespace: ns,                      
      onCardTap: { _ in },
      selectedDeviceID: .constant(nil)
    )
    .environmentObject(hiddenService)
    .previewLayout(.sizeThatFits)
    .padding()
  }
}

