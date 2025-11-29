//
//  ValidationError.swift
//  FreeRideTracker
//
//  Created by Refactoring on 2025-11-28.
//

import Foundation

// MARK: - Location Errors

enum LocationError: LocalizedError {
    case permissionDenied
    case permissionRestricted
    case permissionNotDetermined
    case invalidCoordinates(latitude: Double, longitude: Double)
    case invalidAccuracy(accuracy: Double)
    case invalidTimestamp(Date)
    case invalidSpeed(speed: Double)
    case invalidAltitude(altitude: Double)
    case locationUnavailable
    case backgroundLocationDisabled
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .permissionRestricted:
            return "Location access is restricted on this device."
        case .permissionNotDetermined:
            return "Location permission has not been requested yet."
        case .invalidCoordinates(let lat, let lon):
            return "Invalid coordinates: latitude \(lat), longitude \(lon)"
        case .invalidAccuracy(let accuracy):
            return "Location accuracy too low: \(accuracy)m"
        case .invalidTimestamp(let date):
            return "Invalid location timestamp: \(date)"
        case .invalidSpeed(let speed):
            return "Invalid speed value: \(speed) m/s"
        case .invalidAltitude(let altitude):
            return "Invalid altitude value: \(altitude)m"
        case .locationUnavailable:
            return "Location services are currently unavailable."
        case .backgroundLocationDisabled:
            return "Background location tracking is not enabled."
        }
    }
}

// MARK: - Data Validation Errors

enum DataValidationError: LocalizedError {
    case invalidDistance(Double)
    case invalidDuration(TimeInterval)
    case invalidMetric(name: String, value: Double)
    case emptyLocationPoints
    case corruptedData
    case calculationError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDistance(let distance):
            return "Invalid distance value: \(distance)m"
        case .invalidDuration(let duration):
            return "Invalid duration value: \(duration)s"
        case .invalidMetric(let name, let value):
            return "Invalid \(name): \(value)"
        case .emptyLocationPoints:
            return "No location data available for this ride."
        case .corruptedData:
            return "The ride data appears to be corrupted."
        case .calculationError(let message):
            return "Calculation error: \(message)"
        }
    }
}

// MARK: - Permission Errors

enum PermissionError: LocalizedError {
    case notificationsDenied
    case locationDenied
    case healthKitDenied
    case cloudKitUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notificationsDenied:
            return "Notification permission denied. Enable notifications in Settings to receive ride updates."
        case .locationDenied:
            return "Location permission denied. This app requires location access to track your rides."
        case .healthKitDenied:
            return "HealthKit access denied. Enable HealthKit integration in Settings to sync workout data."
        case .cloudKitUnavailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        }
    }
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case cloudKitError(String)
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Your data will sync when connection is restored."
        case .timeout:
            return "The request timed out. Please try again."
        case .cloudKitError(let message):
            return "iCloud sync error: \(message)"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}

// MARK: - App Errors

enum AppError: LocalizedError {
    case initializationFailed(String)
    case dataStorageUnavailable
    case featureUnavailable(String)
    case unexpectedState(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "App initialization failed: \(message)"
        case .dataStorageUnavailable:
            return "Data storage is unavailable. Please ensure you have sufficient storage space."
        case .featureUnavailable(let feature):
            return "\(feature) is not available on this device."
        case .unexpectedState(let message):
            return "Unexpected app state: \(message)"
        }
    }
}
