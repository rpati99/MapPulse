//
//  DeviceAnnotationView.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import MapKit
import UIKit
import SwiftUI


/* Custom Map pin (MKAnnotationView) from UIKit that shows a Car icon(if image not uploaded) || User image(if image uploaded)
    Name label + animation (pop-in)
*/
class DeviceAnnotationView: MKAnnotationView {
    // reconfigure view whenever map pin is set or changed
    override var annotation: MKAnnotation? {
        willSet {
            if let deviceAnnotation = newValue as? DeviceAnnotation {
                configure(for: deviceAnnotation.device)
            }
        }
    }
    private let userImageView = UIImageView() // holds user image
    private let nameLabel = UILabel() // holds device name
    private let borderWrapper = UIView() // indicates driver status by color (for user upload image scenario)
    private let containerView = UIView() // holds smaller views for showing pin
    
    
    // Builds the contents of the pin(annotation) view based on the device’s state.
    func configure(for device: Device) {
        canShowCallout = false
        clusteringIdentifier = "device" // enabling clustering

        // Determine current driveStatus for color representation
        let driveStatus = device.latestPoint?.deviceState?.driveStatus.lowercased() ?? "off"

        // Map it to a UIColor
        let statusColor: UIColor
        switch driveStatus {
        case "driving":
            statusColor = .systemGreen
        case "idle":
            statusColor = .systemOrange
        default:    // "off" for unknown
            statusColor = .systemGray
        }

        // Default car icon which is color based based on driveStatus
        let fallbackSystemName: String = (driveStatus == "driving" ? "car.fill" : "car")
        let userImage = UserIconManager.getUserIcon(for: device.id)
        let image = userImage ?? UIImage(systemName: fallbackSystemName)
        
        // prepare imageView to hold user image
        userImageView.image = image
        // tint only if using the system icon
        userImageView.tintColor = (userImage == nil ? statusColor : nil)
        userImageView.contentMode = .scaleAspectFill
        userImageView.layer.cornerRadius = 20  // half of our 40×40 image
        userImageView.clipsToBounds = true
        userImageView.translatesAutoresizingMaskIntoConstraints = false

        // Clean out prior subviews
        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Wrap user uploaded image in a circular border
        let wrapperView = UIView()
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        wrapperView.layer.cornerRadius = 25     // half of our 50×50
        wrapperView.clipsToBounds = true
        wrapperView.layer.borderWidth = (userImage != nil ? 2 : 0)
        wrapperView.layer.borderColor = statusColor.cgColor
        wrapperView.addSubview(userImageView)

        // imageView 40×40 centered in 50×50 wrapper
        NSLayoutConstraint.activate([
            userImageView.widthAnchor.constraint(equalToConstant: 40),
            userImageView.heightAnchor.constraint(equalToConstant: 40),
            userImageView.centerXAnchor.constraint(equalTo: wrapperView.centerXAnchor),
            userImageView.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor),

            wrapperView.widthAnchor.constraint(equalToConstant: 50),
            wrapperView.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Device name Label
        nameLabel.text = device.name
        nameLabel.font = .systemFont(ofSize: 20)
        nameLabel.textColor = .black
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // encapsulate all small views into large view
        containerView.addSubview(wrapperView)
        containerView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            wrapperView.topAnchor.constraint(equalTo: containerView.topAnchor),
            wrapperView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: 2),
            nameLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Pop-in animation (indicates change of device status/location/image)
        containerView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.containerView.transform = .identity
        }

        // Final placement
        addSubview(containerView)
        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerOffset = CGPoint(x: 0, y: -30)
    }
}

/*
 This is used for mini map that is present in Device List view,
    it is SwiftUI wrapper around our UIKit-based DeviceAnnotationView
*/
struct DeviceAnnotationUIView: UIViewRepresentable {
  let device: Device // holds respective device model

    // render the pin
  func makeUIView(context: Context) -> DeviceAnnotationView {
    DeviceAnnotationView(annotation: nil, reuseIdentifier: nil)
  }

    // update pin
  func updateUIView(_ uiView: DeviceAnnotationView, context: Context) {
    // configure it just like in your MKMapViewDelegate
    uiView.configure(for: device)
  }
}
