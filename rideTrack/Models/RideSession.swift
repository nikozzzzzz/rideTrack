//
//  RideSession.swift
//  rideTrack
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
        return end.timeIntervalSince(startTime) - pausedDuration
    }
    
    var activeDuration: TimeInterval {
        guard !isActive else { return duration }
        return duration
    }
    
    var displayTitle: String {
        title ?? "\(activityType.displayName) - \(startTime.formatted(date: .abbreviated, time: .shortened))"
    }
    
    var averagePace: TimeInterval {
        guard totalDistance > 0 else { return 0 }
        return (duration / 60) / (totalDistance / 1000) // minutes per kilometer
    }
    
    var formattedDistance: String {
        let km = totalDistance / 1000
        return String(format: "%.2f km", km)
    }
    
    var formattedDuration: String {
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
        let kmh = maxSpeed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", kmh)
    }
    
    var formattedAverageSpeed: String {
        let kmh = averageSpeed * 3.6 // Convert m/s to km/h
        return String(format: "%.1f km/h", kmh)
    }
    
    var formattedPace: String {
        guard averagePace > 0 else { return "--:--" }
        let minutes = Int(averagePace)
        let seconds = Int((averagePace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    // MARK: - Methods
    
    func addLocationPoint(_ point: LocationPoint) {
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
            
            // Distance calculation
            let prevLocation = CLLocation(latitude: previousPoint.latitude, longitude: previousPoint.longitude)
            let currLocation = CLLocation(latitude: currentPoint.latitude, longitude: currentPoint.longitude)
            distance += prevLocation.distance(from: currLocation)
            
            // Speed calculations
            if currentPoint.speed >= 0 {
                maxSpd = max(maxSpd, currentPoint.speed)
                totalSpd += currentPoint.speed
                validSpeedCount += 1
            }
            
            // Elevation calculations
            let elevationDiff = currentPoint.altitude - previousPoint.altitude
            if elevationDiff > 0 {
                elevationGain += elevationDiff
            } else {
                elevationLoss += abs(elevationDiff)
            }
        }
        
        self.totalDistance = distance
        self.maxSpeed = maxSpd
        self.averageSpeed = validSpeedCount > 0 ? totalSpd / Double(validSpeedCount) : 0
        self.totalElevationGain = elevationGain
        self.totalElevationLoss = elevationLoss
    }
}