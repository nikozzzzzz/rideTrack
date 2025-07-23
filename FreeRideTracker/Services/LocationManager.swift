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
import os.log

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
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
        
        // Don't configure background location updates here - only when tracking starts
        print("LocationManager setup completed with authorization: \(authorizationStatus.rawValue)")
    }
    
    
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        switch authorizationStatus {
        case .notDetermined:
            // First request "When In Use" permission
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // If we have "When In Use", request "Always" for background tracking
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            completion(true)
            return
        case .denied, .restricted:
            completion(false)
            return
        @unknown default:
            completion(false)
            return
        }
        
        // Store completion for delegate callback
        // For now, optimistically return true
        completion(true)
    }
    
    func startTracking(for session: RideSession, with context: ModelContext? = nil) {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            print("❌ Location permission not granted")
            return
        }
        
        currentSession = session
        modelContext = context
        isTracking = true
        isPaused = false
        
        // Configure location manager for high accuracy tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumDistanceFilter
        
        // Enable background location updates ONLY if we have Always permission
        if authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            print("✅ Background location updates enabled")
        } else {
            print("⚠️ Only 'When In Use' permission granted. Background tracking will not work.")
        }
        
        locationManager.startUpdatingLocation()
        print("🚀 Started location tracking with authorization: \(authorizationStatus.rawValue)")
        
        // Check notification permission before showing tracking notification
        NotificationManager.shared.checkNotificationPermission { granted in
            if granted {
                NotificationManager.shared.showTrackingNotification(activityType: session.activityType.displayName)
            }
            // If permission not granted, silently skip the notification
        }
        
        // Start Live Activity if available
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.startLiveActivity(
                rideType: session.activityType.displayName,
                startLocation: nil
            )
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
        
        // Disable background location updates when not tracking
        if authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = false
            print("Disabled background location updates")
        }
        
        NotificationManager.shared.hideTrackingNotification()
        
        // Stop Live Activity if available
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.stopLiveActivity()
        }
        
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
        
        // Update Live Activity if available
        if #available(iOS 16.1, *) {
            let distance = session.totalDistance / 1000.0 // Convert to km
            let duration = Date().timeIntervalSince(session.startTime)
            let averageSpeed = duration > 0 ? (distance / (duration / 3600.0)) : 0.0
            
            LiveActivityManager.shared.updateLiveActivity(
                distance: distance,
                duration: duration,
                averageSpeed: averageSpeed,
                currentSpeed: max(0, location.speed) * 3.6 // Convert m/s to km/h
            )
        }
        
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
                print("📍 Location authorization not determined")
            case .denied, .restricted:
                print("❌ Location authorization denied/restricted")
                self.stopTracking()
            case .authorizedWhenInUse:
                print("📍 Location authorized: When In Use")
                if self.isTracking {
                    print("⚠️ Currently tracking but only have 'When In Use' permission")
                }
                self.startUpdating()
            case .authorizedAlways:
                print("✅ Location authorized: Always")
                if self.isTracking {
                    // Re-enable background location updates if we're currently tracking
                    self.locationManager.allowsBackgroundLocationUpdates = true
                    print("✅ Background location updates re-enabled")
                }
                self.startUpdating()
            @unknown default:
                print("❓ Unknown location authorization status")
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
