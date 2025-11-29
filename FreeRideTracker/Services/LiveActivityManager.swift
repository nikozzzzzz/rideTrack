import ActivityKit
import Foundation
import CoreLocation

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<RideTrackingAttributes>?
    private var lastUpdateTime: Date?
    private let minimumUpdateInterval: TimeInterval = 1.0 // Prevent too frequent updates
    
    private init() {}
    
    func startLiveActivity(rideType: String, startLocation: String? = nil) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            AppLogger.warning("Live Activities not enabled by user", category: AppLogger.ui)
            return
        }
        
        // Don't start if already active
        guard currentActivity == nil else {
            AppLogger.warning("Live Activity already active, skipping start", category: AppLogger.ui)
            return
        }
        
        let attributes = RideTrackingAttributes(
            rideType: rideType,
            startLocation: startLocation
        )
        
        let initialState = RideTrackingAttributes.ContentState(
            distance: 0.0,
            duration: 0.0,
            averageSpeed: 0.0,
            currentSpeed: 0.0,
            startTime: Date()
        )
        
        do {
            let activity = try Activity<RideTrackingAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            currentActivity = activity
            lastUpdateTime = Date()
            AppLogger.info("Live Activity started with ID: \(activity.id)", category: AppLogger.ui)
        } catch {
            AppLogger.error("Failed to start Live Activity", error: error, category: AppLogger.ui)
        }
    }
    
    func updateLiveActivity(distance: Double, duration: TimeInterval, averageSpeed: Double, currentSpeed: Double) {
        guard let activity = currentActivity else {
            AppLogger.debug("No active Live Activity to update", category: AppLogger.ui)
            return
        }
        
        // Throttle updates to prevent excessive API calls
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < minimumUpdateInterval {
            return
        }
        
        // Validate input values
        guard distance >= 0, distance.isFinite,
              duration >= 0, duration.isFinite,
              averageSpeed >= 0, averageSpeed.isFinite,
              currentSpeed >= 0, currentSpeed.isFinite else {
            AppLogger.warning("Invalid values for Live Activity update", category: AppLogger.ui)
            return
        }
        
        let updatedState = RideTrackingAttributes.ContentState(
            distance: distance,
            duration: duration,
            averageSpeed: averageSpeed,
            currentSpeed: currentSpeed,
            startTime: activity.content.state.startTime
        )
        
        Task {
            do {
                await activity.update(using: updatedState)
                lastUpdateTime = Date()
                AppLogger.debug("Live Activity updated successfully", category: AppLogger.ui)
            } catch {
                AppLogger.error("Failed to update Live Activity", error: error, category: AppLogger.ui)
            }
        }
    }
    
    func stopLiveActivity() {
        guard let activity = currentActivity else {
            AppLogger.debug("No active Live Activity to stop", category: AppLogger.ui)
            return
        }
        
        Task {
            do {
                await activity.end(dismissalPolicy: .default)
                currentActivity = nil
                lastUpdateTime = nil
                AppLogger.info("Live Activity stopped", category: AppLogger.ui)
            } catch {
                AppLogger.error("Failed to stop Live Activity", error: error, category: AppLogger.ui)
                // Still clear the reference even if end fails
                currentActivity = nil
                lastUpdateTime = nil
            }
        }
    }
    
    func isActive() -> Bool {
        return currentActivity != nil
    }
}