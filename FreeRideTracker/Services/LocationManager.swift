//
//  LocationManager.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import Foundation
import CoreLocation
import SwiftData
import UIKit

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private var currentSession: RideSession?
    private var modelContext: ModelContext?
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentSpeed: Double = 0.0
    @Published var currentAltitude: Double = 0.0
    @Published var isTracking = false
    @Published var isPaused = false
    
    private var lastLocationUpdate: Date = Date()
    private let minimumDistanceFilter: CLLocationDistance = 5.0 // meters
    private let minimumTimeInterval: TimeInterval = 2.0 // seconds
    
    override init() {
        super.init()
        setupLocationManager()
        NotificationManager.shared.requestNotificationPermission()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumDistanceFilter
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        // The completion can be called directly in the delegate method `didChangeAuthorization`
        // For simplicity, we assume the user will grant it and update UI accordingly.
        // A more robust solution might use a completion handler stored here.
        completion(true) // Optimistically return true
    }
    
    func startTracking(for session: RideSession, with context: ModelContext? = nil) {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            print("Location permission not granted")
            return
        }
        
        currentSession = session
        modelContext = context
        isTracking = true
        isPaused = false
        
        locationManager.startUpdatingLocation()
        
        // Check notification permission before showing tracking notification
        NotificationManager.shared.checkNotificationPermission { granted in
            if granted {
                NotificationManager.shared.showTrackingNotification(activityType: session.activityType.displayName)
            }
            // If permission not granted, silently skip the notification
        }
        
        print("Started location tracking for session: \(session.id)")
    }
    
    func pauseTracking() {
        guard isTracking else { return }
        isPaused = true
        locationManager.stopUpdatingLocation()
        NotificationManager.shared.hideTrackingNotification()
        print("Paused location tracking")
    }
    
    func resumeTracking() {
        guard isTracking, isPaused, let session = currentSession else { return }
        isPaused = false
        locationManager.startUpdatingLocation()
        
        // Check notification permission before showing tracking notification
        NotificationManager.shared.checkNotificationPermission { granted in
            if granted {
                NotificationManager.shared.showTrackingNotification(activityType: session.activityType.displayName)
            }
            // If permission not granted, silently skip the notification
        }
        
        print("Resumed location tracking")
    }
    
    func stopTracking() {
        isTracking = false
        isPaused = false
        currentSession = nil
        
        locationManager.stopUpdatingLocation()
        NotificationManager.shared.hideTrackingNotification()
        
        print("Stopped location tracking")
    }
    
    func startUpdating() {
        guard isLocationPermissionGranted else { return }
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        if !isTracking {
            locationManager.stopUpdatingLocation()
        }
    }
    
    private func shouldRecordLocation(_ location: CLLocation) -> Bool {
        // Filter out inaccurate readings
        guard location.horizontalAccuracy <= 50 else {
            print("Location accuracy too low: \(location.horizontalAccuracy)m")
            return false
        }
        
        // Filter out old readings
        guard location.timestamp.timeIntervalSinceNow > -10 else {
            print("Location reading too old")
            return false
        }
        
        // Check minimum time interval
        guard Date().timeIntervalSince(lastLocationUpdate) >= minimumTimeInterval else {
            return false
        }
        
        // Check minimum distance (if we have a previous location)
        if let lastLocation = currentLocation {
            let distance = location.distance(from: lastLocation)
            guard distance >= minimumDistanceFilter else {
                return false
            }
        }
        
        return true
    }
    
    private func recordLocation(_ location: CLLocation) {
        guard let session = currentSession,
              let context = modelContext,
              !isPaused else { return }
        
        let locationPoint = LocationPoint(from: location)
        context.insert(locationPoint)
        session.addLocationPoint(locationPoint)
        
        // Update current values
        currentLocation = location
        currentSpeed = max(0, location.speed)
        currentAltitude = location.altitude
        lastLocationUpdate = Date()
        
        // Save context
        do {
            try context.save()
            print("Recorded location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        } catch {
            print("Failed to save location point: \(error)")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            if self.shouldRecordLocation(location) {
                self.recordLocation(location)
            } else {
                // Still update current location for UI purposes
                self.currentLocation = location
                self.currentSpeed = max(0, location.speed)
                self.currentAltitude = location.altitude
             }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied")
            case .locationUnknown:
                print("Location unknown")
            case .network:
                print("Network error")
            default:
                print("Other location error: \(clError.localizedDescription)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .notDetermined:
                print("Location authorization not determined")
            case .denied, .restricted:
                print("Location authorization denied/restricted")
                self.stopTracking()
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location authorized")
                self.startUpdating()
            @unknown default:
                print("Location authorized always")
            //@unknown default:
             //   print("Unknown location authorization status")
            }
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("Location updates paused by system")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("Location updates resumed by system")
    }
}


// MARK: - Utility Methods
extension LocationManager {
    var isLocationPermissionGranted: Bool {
        return authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }
    
    var hasAlwaysPermission: Bool {
        return authorizationStatus == .authorizedAlways
    }
    
    func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
