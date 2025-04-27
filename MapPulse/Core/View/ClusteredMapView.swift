import SwiftUI
import MapKit
import UIKit

struct ClusteredMapView: UIViewRepresentable {
    let devices: [Device]
    var onDeviceTap: ((String) -> Void)?
    static var hasZoomedInitially = false
    @Binding var selectedDeviceID: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(onDeviceTap: onDeviceTap)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        mapView.register(DeviceAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Device")
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Cluster")
        mapView.showsUserLocation = false
        mapView.pointOfInterestFilter = .excludingAll
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let previousRegion = mapView.region

        mapView.removeAnnotations(mapView.annotations)

        let annotations : [MKAnnotation] = devices.compactMap { device in
            guard let point = device.latestPoint else { return nil }
            let annotation = DeviceAnnotation(device: device)
            annotation.coordinate = point.coordinate
            annotation.title = device.name
            return annotation
        }

        mapView.addAnnotations(annotations)

        if !Self.hasZoomedInitially, !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: false)
            Self.hasZoomedInitially = true
        } else {
            mapView.setRegion(previousRegion, animated: false)
        }
        
        if let selected = selectedDeviceID,
           let annotation = annotations.first(where: {
              guard let deviceAnnotation = $0 as? DeviceAnnotation else { return false }
              return deviceAnnotation.device.id == selected
           }) {
            let zoomRegion = MKCoordinateRegion(
              center: annotation.coordinate,
              span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
            mapView.setRegion(zoomRegion, animated: true)
        }
        
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        let onDeviceTap: ((String) -> Void)?

        init(onDeviceTap: ((String) -> Void)?) {
                   self.onDeviceTap = onDeviceTap
               }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Cluster") as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "Cluster")
                view.markerTintColor = .systemBlue
                view.glyphText = "\(cluster.memberAnnotations.count)"
                return view
            }

            if let deviceAnnotation = annotation as? DeviceAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Device", for: deviceAnnotation) as! DeviceAnnotationView
                view.configure(for: deviceAnnotation.device)
                return view
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let deviceAnnotation = view.annotation as? DeviceAnnotation else { return }
            onDeviceTap?(deviceAnnotation.device.id)
        }
    }
}


// Custom Annotation
class DeviceAnnotation: MKPointAnnotation {
    let device: Device
    init(device: Device) {
        self.device = device
        super.init()
    }
}

// Custom View with user icons + label + animation
class DeviceAnnotationView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            if let deviceAnnotation = newValue as? DeviceAnnotation {
                configure(for: deviceAnnotation.device)
            }
        }
    }

    private let userImageView = UIImageView()
    private let nameLabel = UILabel()
    private let borderWrapper = UIView()
    private let containerView = UIView()
    
    

    func configure(for device: Device) {
        canShowCallout = false
        clusteringIdentifier = "device"

        // ✅ 1) Determine current driveStatus (default to "off")
        let driveStatus = device.latestPoint?.deviceState?.driveStatus.lowercased() ?? "off"

        // ✅ 2) Map it to a UIColor
        let statusColor: UIColor
        switch driveStatus {
        case "driving":
            statusColor = .systemGreen
        case "idle":
            statusColor = .systemOrange
        default:    // "off" or unknown
            statusColor = .systemGray
        }

        // ✅ 3) Choose fallback SF symbol based on driveStatus
        let fallbackSystemName: String = (driveStatus == "driving" ? "car.fill" : "car")
        let userImage = UserIconManager.getUserIcon(for: device.id)
        let image = userImage ?? UIImage(systemName: fallbackSystemName)
        
        // — prepare your imageView
        userImageView.image = image
        // tint only if using the system icon
        userImageView.tintColor = (userImage == nil ? statusColor : nil)
        userImageView.contentMode = .scaleAspectFill
        userImageView.layer.cornerRadius = 15  // half of our 30×30 image
        userImageView.clipsToBounds = true
        userImageView.translatesAutoresizingMaskIntoConstraints = false

        // Clean out any prior subviews
        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // ✅ 4) Wrap it in a circular border
        let wrapperView = UIView()
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        wrapperView.layer.cornerRadius = 25     // half of our 40×40 wrapper
        wrapperView.clipsToBounds = true
        wrapperView.layer.borderWidth = (userImage != nil ? 2 : 0)
        wrapperView.layer.borderColor = statusColor.cgColor
        wrapperView.addSubview(userImageView)

        // imageView 30×30 centered in 40×40 wrapper
        NSLayoutConstraint.activate([
            userImageView.widthAnchor.constraint(equalToConstant: 40),
            userImageView.heightAnchor.constraint(equalToConstant: 40),
            userImageView.centerXAnchor.constraint(equalTo: wrapperView.centerXAnchor),
            userImageView.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor),

            wrapperView.widthAnchor.constraint(equalToConstant: 50),
            wrapperView.heightAnchor.constraint(equalToConstant: 50)
        ])

        // ✅ 5) Label underneath
        nameLabel.text = device.name
        nameLabel.font = .systemFont(ofSize: 20)
        nameLabel.textColor = .black
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(wrapperView)
        containerView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            wrapperView.topAnchor.constraint(equalTo: containerView.topAnchor),
            wrapperView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: 2),
            nameLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // ✅ 6) Pop-in animation
        containerView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.containerView.transform = .identity
        }

        // 7) Final placement
        addSubview(containerView)
        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerOffset = CGPoint(x: 0, y: -30)
    }
}

struct UserIconManager {
    static func saveUserIcon(_ image: UIImage, for deviceID: String) {
        guard let data = image.pngData() else { return }
        let filename = "\(deviceID).png"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)

        do {
            try data.write(to: url)
            UserDefaults.standard.set(url.path, forKey: "icon-\(deviceID)")
        } catch {
            print("❌ Failed to save icon: \(error)")
        }
    }

    static func getUserIcon(for deviceID: String) -> UIImage? {
        guard let path = UserDefaults.standard.string(forKey: "icon-\(deviceID)"),
              FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage?) -> Void

        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            onImagePicked(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

// 1) A small SwiftUI wrapper around your MKAnnotationView subclass
struct DeviceAnnotationUIView: UIViewRepresentable {
  let device: Device

  func makeUIView(context: Context) -> DeviceAnnotationView {
    DeviceAnnotationView(annotation: nil, reuseIdentifier: nil)
  }

  func updateUIView(_ uiView: DeviceAnnotationView, context: Context) {
    // configure it just like in your MKMapViewDelegate
    uiView.configure(for: device)
  }
}
