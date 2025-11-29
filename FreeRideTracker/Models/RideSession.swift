//
//  RideSession.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class RideSession {
    var id: UUID
    var activityType: ActivityType
    var startTime: Date
    var endTime: Date?
    var isActive: Bool
    var isPaused: Bool
    var pausedDuration: TimeInterval // Total time paused
    var title: String?
    var notes: String?
    
    // Calculated properties stored for performance
    var totalDistance: Double // meters
    var maxSpeed: Double // m/s
    var averageSpeed: Double // m/s
    var totalElevationGain: Double // meters
    var totalElevationLoss: Double // meters
    var calories: Double?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \LocationPoint.rideSession)
    var locationPoints: [LocationPoint] = []
    
    init(
        activityType: ActivityType,
        startTime: Date = Date(),
        title: String? = nil
    ) {
        self.id = UUID()
        self.activityType = activityType
        self.startTime = startTime
        self.endTime = nil
        self.isActive = true
        self.isPaused = false
        self.pausedDuration = 0
        self.title = title
        self.notes = nil
        
        // Initialize calculated properties
        self.totalDistance = 0
        self.maxSpeed = 0
        self.averageSpeed = 0
        self.totalElevationGain = 0
        self.totalElevationLoss = 0
        self.calories = nil
    }
    
    // MARK: - Computed Properties
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        let rawDuration = end.timeIntervalSince(startTime) - pausedDuration
        // Ensure non-negative duration
        return max(0, rawDuration)
    }
    
    var activeDuration: TimeInterval {
        guard !isActive else { return duration }
        return duration
    }
    
    var displayTitle: String {
        title ?? "\(activityType.displayName) - \(startTime.formatted(date: .abbreviated, time: .shortened))"
    }
    
    var averagePace: TimeInterval {
        guard totalDistance > 0, duration > 0 else { return 0 }
        let pace = (duration / 60) / (totalDistance / 1000) // minutes per kilometer
        // Validate pace is reasonable (not NaN, not infinite)
        guard pace.isFinite, pace >= 0 else { return 0 }
        return pace
    }
    
    var formattedDistance: String {
        guard totalDistance >= 0, totalDistance.isFinite else { return "0.00 km" }
        let km = totalDistance / 1000
        return String(format: "%.2f km", km)
    }
    
    var formattedDuration: String {
        guard duration >= 0, duration.isFinite else { return "0:00" }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedMaxSpeed: String {
        guard maxSpeed >= 0, maxSpeed.isFinite else { return "0.0 km/h" }
        let kmh = maxSpeed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", kmh)
    }
    
    var formattedAverageSpeed: String {
        guard averageSpeed >= 0, averageSpeed.isFinite else { return "0.0 km/h" }
        let kmh = averageSpeed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", kmh)
    }
    
    var formattedPace: String {
        guard averagePace > 0, averagePace.isFinite else { return "--:--" }
        let minutes = Int(averagePace)
        let seconds = Int((averagePace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    // MARK: - Methods
    
    func addLocationPoint(_ point: LocationPoint) {
        // Validate we're not exceeding reasonable limits
        guard locationPoints.count < AppConstants.Validation.maxLocationPointsPerRide else {
            AppLogger.warning("Maximum location points reached for ride session", category: .data)
            return
        }
        
        locationPoints.append(point)
        point.rideSession = self
        updateCalculatedProperties()
    }
    
    func pause() {
        isPaused = true
    }
    
    func resume() {
        isPaused = false
    }
    
    func stop() {
        isActive = false
        endTime = Date()
        updateCalculatedProperties()
    }
    
    private func updateCalculatedProperties() {
        guard locationPoints.count > 1 else { return }
        
        // Calculate total distance
        var distance: Double = 0
        var maxSpd: Double = 0
        var totalSpd: Double = 0
        var validSpeedCount = 0
        var elevationGain: Double = 0
        var elevationLoss: Double = 0
        
        for i in 1..<locationPoints.count {
            let previousPoint = locationPoints[i-1]
            let currentPoint = locationPoints[i]
            
            // Distance calculation with validation
            let prevLocation = CLLocation(latitude: previousPoint.latitude, longitude: previousPoint.longitude)
            let currLocation = CLLocation(latitude: currentPoint.latitude, longitude: currentPoint.longitude)
            let segmentDistance = prevLocation.distance(from: currLocation)
            
            // Validate distance is reasonable
            if segmentDistance >= 0 && segmentDistance.isFinite {
                distance += segmentDistance
            } else {
                AppLogger.warning("Invalid distance calculated between points", category: .data)
            }
            
            // Speed calculations with validation
            if currentPoint.speed >= 0 && currentPoint.speed.isFinite && currentPoint.speed <= AppConstants.Location.maxReasonableSpeed {
                maxSpd = max(maxSpd, currentPoint.speed)
                totalSpd += currentPoint.speed
                validSpeedCount += 1
            }
            
            // Elevation calculations with validation
            let elevationDiff = currentPoint.altitude - previousPoint.altitude
            if elevationDiff.isFinite {
                if elevationDiff > 0 {
                    elevationGain += elevationDiff
                } else {
                    elevationLoss += abs(elevationDiff)
                }
            }
        }
        
        // Update properties with validated values
        self.totalDistance = max(0, distance)
        self.maxSpeed = max(0, maxSpd)
        
        // Calculate average speed with division by zero protection
        if validSpeedCount > 0 {
            let avgSpd = totalSpd / Double(validSpeedCount)
            self.averageSpeed = avgSpd.isFinite ? max(0, avgSpd) : 0
        } else {
            self.averageSpeed = 0
        }
        
        self.totalElevationGain = max(0, elevationGain)
        self.totalElevationLoss = max(0, elevationLoss)
    }
}