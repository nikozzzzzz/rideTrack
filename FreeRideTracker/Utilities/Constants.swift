//
//  Constants.swift
//  FreeRideTracker
//
//  Created by Refactoring on 2025-11-28.
//

import Foundation
import CoreLocation

enum AppConstants {
    
    // MARK: - Location Validation
    
    enum Location {
        /// Maximum reasonable speed in m/s (500 km/h = 138.89 m/s)
        static let maxReasonableSpeed: Double = 138.89
        
        /// Minimum reasonable speed in m/s (0 km/h)
        static let minReasonableSpeed: Double = 0.0
        
        /// Maximum reasonable altitude in meters (Mount Everest + buffer)
        static let maxReasonableAltitude: Double = 10000.0
        
        /// Minimum reasonable altitude in meters (Dead Sea - buffer)
        static let minReasonableAltitude: Double = -500.0
        
        /// Maximum acceptable horizontal accuracy in meters
        static let maxAcceptableAccuracy: Double = 50.0
        
        /// Minimum distance filter in meters
        static let minimumDistanceFilter: CLLocationDistance = 5.0
        
        /// Minimum time interval between location updates in seconds
        static let minimumTimeInterval: TimeInterval = 2.0
        
        /// Maximum age of location reading in seconds
        static let maxLocationAge: TimeInterval = 10.0
        
        /// Valid latitude range
        static let validLatitudeRange: ClosedRange<Double> = -90.0...90.0
        
        /// Valid longitude range
        static let validLongitudeRange: ClosedRange<Double> = -180.0...180.0
    }
    
    // MARK: - Timeouts
    
    enum Timeout {
        /// Network request timeout in seconds
        static let networkRequest: TimeInterval = 30.0
        
        /// Location permission request timeout in seconds
        static let permissionRequest: TimeInterval = 10.0
        
        /// CloudKit operation timeout in seconds
        static let cloudKitOperation: TimeInterval = 60.0
        
        /// Background task maximum duration in seconds
        static let backgroundTask: TimeInterval = 25.0
        
        /// Live Activity update timeout in seconds
        static let liveActivityUpdate: TimeInterval = 5.0
    }
    
    // MARK: - Retry Configuration
    
    enum Retry {
        /// Maximum number of retry attempts
        static let maxAttempts: Int = 3
        
        /// Initial retry delay in seconds
        static let initialDelay: TimeInterval = 1.0
        
        /// Maximum retry delay in seconds
        static let maxDelay: TimeInterval = 60.0
        
        /// Exponential backoff multiplier
        static let backoffMultiplier: Double = 2.0
    }
    
    // MARK: - Data Validation
    
    enum Validation {
        /// Maximum custom title length
        static let maxTitleLength: Int = 100
        
        /// Maximum notes length
        static let maxNotesLength: Int = 500
        
        /// Minimum ride duration to save (in seconds)
        static let minRideDuration: TimeInterval = 10.0
        
        /// Minimum ride distance to save (in meters)
        static let minRideDistance: Double = 10.0
        
        /// Maximum location points per ride
        static let maxLocationPointsPerRide: Int = 50000
    }
    
    // MARK: - UI Constants
    
    enum UI {
        /// Debounce delay for user input in seconds
        static let inputDebounceDelay: TimeInterval = 0.3
        
        /// Animation duration in seconds
        static let standardAnimationDuration: TimeInterval = 0.3
        
        /// Toast message display duration in seconds
        static let toastDuration: TimeInterval = 3.0
    }
    
    // MARK: - Background Tasks
    
    enum Background {
        /// Minimum time between background location updates in seconds
        static let minLocationUpdateInterval: TimeInterval = 5.0
        
        /// Maximum time to keep location updates paused in seconds
        static let maxPauseDuration: TimeInterval = 300.0
        
        /// Background task identifier
        static let locationTaskIdentifier = "com.freeride.tracker.location"
    }
    
    // MARK: - CloudKit
    
    enum CloudKit {
        /// Maximum batch size for CloudKit operations
        static let maxBatchSize: Int = 100
        
        /// Sync interval in seconds
        static let syncInterval: TimeInterval = 300.0
        
        /// Maximum number of pending sync operations
        static let maxPendingSyncOperations: Int = 10
    }
    
    // MARK: - Feature Flags
    
    enum FeatureFlags {
        /// Enable debug logging
        static let debugLoggingEnabled: Bool = {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }()
        
        /// Enable performance monitoring
        static let performanceMonitoringEnabled: Bool = true
        
        /// Enable crash reporting
        static let crashReportingEnabled: Bool = true
    }
}
