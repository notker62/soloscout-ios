//
//  LocationService.swift
//  SoloScout
//
//  Created by Felix on 30.07.2026.
//  Purpose: Service class utilizing CoreLocation to fetch current coordinates.
//  Module: Services
//

import Foundation
import CoreLocation
import Observation

@Observable
public final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    public var currentCoordinate: CLLocationCoordinate2D?
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public var isLocating = false
    
    override public init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = manager.authorizationStatus
    }
    
    public func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    public func startUpdatingLocation() {
        isLocating = true
        manager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        isLocating = false
        manager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentCoordinate = location.coordinate
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed with error: \(error.localizedDescription)")
    }
}
