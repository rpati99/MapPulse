//
//  UserIconManager.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/22/25.
//

import UIKit
/*
 Service that performs
     • Saving: converts the image to PNG, writes it to a per-device file, and remembers that path in UserDefaults.
     • Loading: looks up the path in UserDefaults, verifies it’s there, and constructs a UIImage from it.
 */
struct UserIconManager {
    
    // WRITE
    static func saveUserIcon(_ image: UIImage, for deviceID: String) {
        // get png data of provided image
        guard let data = image.pngData() else { return }
        // give image file a name
        let filename = "\(deviceID).png"
        // URL construction for saving file in sandbox environment
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)

        do {
            // write png data to url
            try data.write(to: url)
            // save to user preferences storage
            UserDefaults.standard.set(url.path, forKey: "icon-\(deviceID)")
        } catch {
            print("Failed to save icon: \(error)")
        }
    }

    // READ
    static func getUserIcon(for deviceID: String) -> UIImage? {
        // fetch file path
        guard let path = UserDefaults.standard.string(forKey: "icon-\(deviceID)"),
              FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        
        // return image if filepath existed
        return UIImage(contentsOfFile: path)
    }
}
