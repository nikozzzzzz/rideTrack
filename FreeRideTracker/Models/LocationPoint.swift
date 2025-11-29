//
//  LocationPoint.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class LocationPoint {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    var speed: Double // m/s
    var course: Double // degrees
    var horizontalAccuracy: Double
    var verticalAccuracy: Double
    
    // Relationship to RideSession
    var rideSession: RideSession?
    
    init(
        latitude: Double,
        longitude: Double,
        altitude: Double,
        timestamp: Date,
        speed: Double,
        course: Double,
        horizontalAccuracy: Double,
        verticalAccuracy: Double
    ) {
        // Validate and clamp coordinates
        self.latitude = Self.validateLatitude(latitude)
        self.longitude = Self.validateLongitude(longitude)
        self.altitude = Self.validateAltitude(altitude)
        self.timestamp = timestamp
        self.speed = Self.validateSpeed(speed)
        self.course = max(0, min(360, course)) // Clamp to 0-360 degrees
        self.horizontalAccuracy = max(0, horizontalAccuracy)
        self.verticalAccuracy = max(0, verticalAccuracy)
    }
    
    convenience init(from location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp,
            speed: max(0, location.speed), // Ensure non-negative speed
            course: location.course,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy
        )
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var clLocation: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            speed: speed,
            timestamp: timestamp
        )
    }
    
    // MARK: - Validation Helpers
    
    private static func validateLatitude(_ lat: Double) -> Double {
        guard lat.isFinite else {
            AppLogger.warning("Invalid latitude (not finite), using 0.0", category: .data)
            return 0.0
        }
        if !AppConstants.Location.validLatitudeRange.contains(lat) {
            AppLogger.warning("Latitude \(lat) out of range, clamping to valid range", category: .data)
            return max(-90, min(90, lat))
        }
        return lat
    }
    
    private static func validateLongitude(_ lon: Double) -> Double {
        guard lon.isFinite else {
            AppLogger.warning("Invalid longitude (not finite), using 0.0", category: .data)
            return 0.0
        }
        if !AppConstants.Location.validLongitudeRange.contains(lon) {
            AppLogger.warning("Longitude \(lon) out of range, clamping to valid range", category: .data)
            return max(-180, min(180, lon))
        }
        return lon
    }
    
    private static func validateAltitude(_ alt: Double) -> Double {
        guard alt.isFinite else {
            AppLogger.warning("Invalid altitude (not finite), using 0.0", category: .data)
            return 0.0
        }
        if alt < AppConstants.Location.minReasonableAltitude || alt > AppConstants.Location.maxReasonableAltitude {
            AppLogger.warning("Altitude \(alt) out of reasonable range, clamping", category: .data)
            return max(AppConstants.Location.minReasonableAltitude, min(AppConstants.Location.maxReasonableAltitude, alt))
        }
        return alt
    }
    
    private static func validateSpeed(_ speed: Double) -> Double {
        guard speed.isFinite else {
            AppLogger.warning("Invalid speed (not finite), using 0.0", category: .data)
            return 0.0
        }
        if speed < 0 || speed > AppConstants.Location.maxReasonableSpeed {
            AppLogger.warning("Speed \(speed) out of reasonable range, clamping", category: .data)
            return max(0, min(AppConstants.Location.maxReasonableSpeed, speed))
        }
        return speed
    }
}