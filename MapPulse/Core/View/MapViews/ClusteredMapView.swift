//
//  ClusteredMapView.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/19/25.
//

import SwiftUI
import MapKit
import UIKit

/*
 ClusteredMapView bridges array of device into map pins with clustering, handles initial fit-to-bounds, preserves the user panning, and zooms in when a device is selected — all wrapped as a SwiftUI component.
 */

struct ClusteredMapView: UIViewRepresentable {
    let devices: [Device] // holds fetched devices
    var onDeviceTap: ((String) -> Void)? // handler callback when pin tapped
    static var hasZoomedInitially = false // auto-zoom indicator on first load
    @Binding var selectedDeviceID: String? // holds selected device id for particular zooming on it
    
    
    // Required conformance for setting up the delegate method required by UIKit driven operation logic
    func makeCoordinator() -> Coordinator {
        Coordinator(onDeviceTap: onDeviceTap)
    }

    // Configure map
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator // adding delegate method to Map
        mapView.register(DeviceAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Device") // registering device pin on map
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Cluster") // registering cluster indicator(pin) on map
        mapView.showsUserLocation = false
        return mapView
    }

    // Updates map view
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let previousRegion = mapView.region // preserve previous region on map data

        // clear out all pins before any updation
        mapView.removeAnnotations(mapView.annotations)

        // render device pins on the map
        let annotations : [MKAnnotation] = devices.compactMap { device in
            guard let point = device.latestPoint else { return nil }
            let annotation = DeviceAnnotation(device: device) // declare custom pin
            annotation.coordinate = point.coordinate // give coordinates
            annotation.title = device.name // register name of pin as device name
            return annotation
        }

        // add pins
        mapView.addAnnotations(annotations)

        // initial app opening auto zooming, only till it convers all devices
        if !Self.hasZoomedInitially, !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: false)
            Self.hasZoomedInitially = true
        } else {
            mapView.setRegion(previousRegion, animated: false)
        }
        
        // Auto zoom on specific device pin
        if let selected = selectedDeviceID, let annotation = annotations.first(where: {
              guard let deviceAnnotation = $0 as? DeviceAnnotation else { return false }
              return deviceAnnotation.device.id == selected
           }) {
            // zoom to region
            let zoomRegion = MKCoordinateRegion(
              center: annotation.coordinate,
              span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
            // with animation
            mapView.setRegion(zoomRegion, animated: true)
        }
        
    }

    // MARK: - Coordinator conformance
    class Coordinator: NSObject, MKMapViewDelegate {
        // handler for tap callback
        let onDeviceTap: ((String) -> Void)?

        init(onDeviceTap: ((String) -> Void)?) {
            self.onDeviceTap = onDeviceTap
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // skip blue dot which indicates user location (making sure it doesn't appear)
            if annotation is MKUserLocation { return nil }

            // Clustering logic below
            
            // Declare cluster pin view and show device count as text that appears on pin
            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Cluster") as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "Cluster")
                view.markerTintColor = .systemBlue
                view.glyphText = "\(cluster.memberAnnotations.count)"
                return view
            }

            // reuse the pin when using it to show specific device
            if let deviceAnnotation = annotation as? DeviceAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Device", for: deviceAnnotation) as! DeviceAnnotationView
                view.configure(for: deviceAnnotation.device)
                return view
            }

            return nil
        }

        // When user taps on the pin, pass the id of device for features (User image upload)
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let deviceAnnotation = view.annotation as? DeviceAnnotation else { return }
            onDeviceTap?(deviceAnnotation.device.id)
        }
    }
}
