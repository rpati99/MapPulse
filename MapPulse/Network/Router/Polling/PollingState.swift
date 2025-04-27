//
//  PollingState.swift
//  MapPulse
//
//  Created by Rachit Prajapati on 4/23/25.
//
import Foundation

// Polling Service state
enum PollingRequestState<Value> {
    case idle
    case loading
    case success(Value)
    case failure(Error)
}
