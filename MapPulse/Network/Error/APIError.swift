//
//  APIError.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/22/25.
//

import Foundation

// Type safe error handling in Network layer
enum APIError: Error {
    case invalidStatus(code: Int)
    case decodingError(Error)
}
