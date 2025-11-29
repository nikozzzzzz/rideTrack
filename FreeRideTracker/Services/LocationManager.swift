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

@MainActor
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
    @Published var lastError: LocationError?
    
    private var lastLocationUpdate: Date = Date()
    private let minimumDistanceFilter: CLLocationDistance = AppConstants.Location.minimumDistanceFilter
    private let minimumTimeInterval: TimeInterval = AppConstants.Location.minimumTimeInterval
    
    override init() {
        super.init()
        setupLocationManager()
        NotificationManager.shared.requestNotificationPermission()
    }
    
    deinit {
        // Cleanup resources
        stopTracking()
        locationManager.delegate = nil
        AppLogger.debug("LocationManager deallocated", category: AppLogger.location)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumDistanceFilter
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
        
        AppLogger.info("LocationManager setup completed with authorization: \(authorizationStatus.rawValue)", category: AppLogger.location)
    }
    
    
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        switch authorizationStatus {
        case .notDetermined:
            // First request "When In Use" permission
            locationManager.requestWhenInUseAuthorization()
            AppLogger.info("Requesting 'When In Use' location permission", category: AppLogger.location)
        case .authorizedWhenInUse:
            // If we have "When In Use", request "Always" for background tracking
            locationManager.requestAlwaysAuthorization()
            AppLogger.info("Requesting 'Always' location permission", category: AppLogger.location)
        case .authorizedAlways:
            completion(true)
            return
        case .denied, .restricted:
            lastError = authorizationStatus == .denied ? .permissionDenied : .permissionRestricted
            AppLogger.warning("Location permission denied or restricted", category: AppLogger.location)
            completion(false)
            return
        @unknown default:
            lastError = .locationUnavailable
            AppLogger.warning("Unknown location authorization status", category: AppLogger.location)
            completion(false)
            return
        }
        
        // Store completion for delegate callback
        // For now, optimistically return true
        completion(true)
    }
    
    func startTracking(for session: RideSession, with context: ModelContext? = nil) {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            lastError = .permissionDenied
            AppLogger.error("Cannot start tracking: Location permission not granted", category: AppLogger.location)
            return
        }
        
        currentSession = session
        modelContext = context
        isTracking = true
        isPaused = false
        lastError = nil
        
        // Configure location manager for high accuracy tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumDistanceFilter
        
        // Enable background location updates ONLY if we have Always permission
        if authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            AppLogger.info("Background location updates enabled", category: AppLogger.location)
        } else {
            AppLogger.warning("Only 'When In Use' permission granted. Background tracking will not work.", category: AppLogger.location)
        }
        
        locationManager.startUpdatingLocation()
        AppLogger.info("Started location tracking for session: \(session.id)", category: AppLogger.location)
        
        // Start Live Activity if available
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.startLiveActivity(
                rideType: session.activityType.displayName,
                startLocation: nil
            )
        }
    }
    
    func pauseTracking() {
        guard isTracking else { return }
        isPaused = true
        locationManager.stopUpdatingLocation()
        AppLogger.info("Paused location tracking", category: AppLogger.location)
    }
    
    func resumeTracking() {
        guard isTracking, isPaused, currentSession != nil else { return }
        isPaused = false
        locationManager.startUpdatingLocation()
        AppLogger.info("Resumed location tracking", category: AppLogger.location)
    }
    
    func stopTracking() {
        isTracking = false
        isPaused = false
        currentSession = nil
        
        locationManager.stopUpdatingLocation()
        
        // Disable background location updates when not tracking
        if authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = false
            AppLogger.info("Disabled background location updates", category: AppLogger.location)
        }
        
        // Stop Live Activity if available
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.stopLiveActivity()
        }
        
        AppLogger.info("Stopped location tracking", category: AppLogger.location)
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
    
    // MARK: - Validation
    
    private func validateLocation(_ location: CLLocation) throws {
        // Validate coordinates
        guard AppConstants.Location.validLatitudeRange.contains(location.coordinate.latitude) else {
            throw LocationError.invalidCoordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
        
        guard AppConstants.Location.validLongitudeRange.contains(location.coordinate.longitude) else {
            throw LocationError.invalidCoordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
        
        // Validate accuracy
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy <= AppConstants.Location.maxAcceptableAccuracy else {
            throw LocationError.invalidAccuracy(accuracy: location.horizontalAccuracy)
        }
        
        // Validate timestamp (not too old, not in future)
        let age = abs(location.timestamp.timeIntervalSinceNow)
        guard age <= AppConstants.Location.maxLocationAge else {
            throw LocationError.invalidTimestamp(location.timestamp)
        }
        
        // Validate speed if available
        if location.speed >= 0 {
            guard location.speed <= AppConstants.Location.maxReasonableSpeed else {
                throw LocationError.invalidSpeed(speed: location.speed)
            }
        }
        
        // Validate altitude
        guard location.altitude >= AppConstants.Location.minReasonableAltitude &&
              location.altitude <= AppConstants.Location.maxReasonableAltitude else {
            throw LocationError.invalidAltitude(altitude: location.altitude)
        }
    }
    
    private func shouldRecordLocation(_ location: CLLocation) -> Bool {
        // Validate location first
        do {
            try validateLocation(location)
        } catch {
            if let locationError = error as? LocationError {
                AppLogger.warning("Location validation failed: \(locationError.localizedDescription)", category: AppLogger.location)
            }
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
            AppLogger.debug("Recorded location: \(location.coordinate.latitude), \(location.coordinate.longitude)", category: AppLogger.location)
        } catch {
            AppLogger.error("Failed to save location point", error: error, category: AppLogger.data)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
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
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLogger.error("Location manager failed", error: error, category: AppLogger.location)
        
        if let clError = error as? CLError {
            Task { @MainActor in
                switch clError.code {
                case .denied:
                    self.lastError = .permissionDenied
                    AppLogger.warning("Location access denied", category: AppLogger.location)
                case .locationUnknown:
                    self.lastError = .locationUnavailable
                    AppLogger.warning("Location unknown", category: AppLogger.location)
                case .network:
                    AppLogger.warning("Network error while getting location", category: AppLogger.location)
                default:
                    AppLogger.error("Other location error: \(clError.localizedDescription)", category: AppLogger.location)
                }
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            
            switch status {
            case .notDetermined:
                AppLogger.info("Location authorization not determined", category: AppLogger.location)
            case .denied, .restricted:
                AppLogger.warning("Location authorization denied/restricted", category: AppLogger.location)
                self.lastError = status == .denied ? .permissionDenied : .permissionRestricted
                self.stopTracking()
            case .authorizedWhenInUse:
                AppLogger.info("Location authorized: When In Use", category: AppLogger.location)
                if self.isTracking {
                    AppLogger.warning("Currently tracking but only have 'When In Use' permission", category: AppLogger.location)
                }
                self.startUpdating()
            case .authorizedAlways:
                AppLogger.info("Location authorized: Always", category: AppLogger.location)
                if self.isTracking {
                    // Re-enable background location updates if we're currently tracking
                    self.locationManager.allowsBackgroundLocationUpdates = true
                    AppLogger.info("Background location updates re-enabled", category: AppLogger.location)
                }
                self.startUpdating()
            @unknown default:
                AppLogger.warning("Unknown location authorization status", category: AppLogger.location)
            }
        }
    }
    
    nonisolated func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        AppLogger.info("Location updates paused by system", category: AppLogger.location)
    }
    
    nonisolated func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        AppLogger.info("Location updates resumed by system", category: AppLogger.location)
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
