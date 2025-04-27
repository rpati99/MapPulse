//
//  ImagePicker.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import UIKit
import Foundation
import SwiftUI

/*
 ImagePicker is a small SwiftUI wrapper around UIKit's Image picker service that presents the system photo picker and invokes handler with the chosen UIImage.
*/

struct ImagePicker: UIViewControllerRepresentable { // Conformance of protocol that bridges UIKit views into SwiftUI logic
    
    // Handler on parent view
    var onImagePicked: (UIImage?) -> Void
    
    // Required delegate conformance method and receive callbacks on above handler
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    // Calls UIKit's image picker service and wire delegate method for working (UIKit's default approach)
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    // Required onformance method
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    // Required delegate object that performs desired operation of picking image and sending selected image back to SwiftUI
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        // Different handler from object and only concerned with this class
        let onImagePicked: (UIImage?) -> Void
        
        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        // Select image and capture it through handler
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            onImagePicked(image)
            picker.dismiss(animated: true)
        }
        
        // Pass nil if didn't picked anything
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}
