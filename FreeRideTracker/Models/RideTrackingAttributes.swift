import ActivityKit
import Foundation

struct RideTrackingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var distance: Double
        var duration: TimeInterval
        var averageSpeed: Double
        var currentSpeed: Double
        var startTime: Date
    }

    // Fixed non-changing properties about your activity go here!
    var rideType: String
    var startLocation: String?
}