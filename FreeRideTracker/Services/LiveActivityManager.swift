import ActivityKit
import Foundation
import CoreLocation

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<RideTrackingAttributes>?
    
    private init() {}
    
    func startLiveActivity(rideType: String, startLocation: String? = nil) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
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
            print("Live Activity started with ID: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateLiveActivity(distance: Double, duration: TimeInterval, averageSpeed: Double, currentSpeed: Double) {
        guard let activity = currentActivity else { return }
        
        let updatedState = RideTrackingAttributes.ContentState(
            distance: distance,
            duration: duration,
            averageSpeed: averageSpeed,
            currentSpeed: currentSpeed,
            startTime: activity.content.state.startTime
        )
        
        Task {
            await activity.update(using: updatedState)
        }
    }
    
    func stopLiveActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .default)
            currentActivity = nil
            print("Live Activity stopped")
        }
    }
    
    func isActive() -> Bool {
        return currentActivity != nil
    }
}