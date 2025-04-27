//
//  UserIconManager.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import UIKit

struct UserIconManager {
    static func saveUserIcon(_ image: UIImage, for deviceID: String) {
        guard let data = image.pngData() else { return }
        let filename = "\(deviceID).png"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)

        do {
            try data.write(to: url)
            UserDefaults.standard.set(url.path, forKey: "icon-\(deviceID)")
        } catch {
            print("Failed to save icon: \(error)")
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


