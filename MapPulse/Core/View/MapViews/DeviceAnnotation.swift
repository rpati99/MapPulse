//
//  DeviceAnnotation.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/25/25.
//

import MapKit

/* Map pin(MKPointAnnotation) subclass that holds device model data
    Wraps a Device in an MKPointAnnotation so the map delegate method can know which device each pin refers to
*/
class DeviceAnnotation: MKPointAnnotation {
    
    let device: Device
    
    init(device: Device) {
        self.device = device
        super.init()
    }
}

