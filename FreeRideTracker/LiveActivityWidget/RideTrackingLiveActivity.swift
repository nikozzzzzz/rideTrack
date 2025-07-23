import ActivityKit
import WidgetKit
import SwiftUI

struct RideTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RideTrackingAttributes.self) { context in
            // Lock screen/banner UI
            RideTrackingLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f km", context.state.distance))
                            .font(.headline)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Avg Speed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f km/h", context.state.averageSpeed))
                            .font(.headline)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedDuration(context.state.duration))
                            .font(.headline)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.duration, total: 3600) {
                        Text("Current Ride")
                            .font(.caption)
                    }
                    .tint(.green)
                }
            } compactLeading: {
                Image(systemName: "bicycle")
                    .foregroundColor(.green)
            } compactTrailing: {
                Text(String(format: "%.1f km", context.state.distance))
                    .font(.caption2)
            } minimal: {
                Image(systemName: "bicycle")
                    .foregroundColor(.green)
            }
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct RideTrackingLockScreenView: View {
    let context: ActivityViewContext<RideTrackingAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bicycle")
                    .foregroundColor(.green)
                Text("Ride in Progress")
                    .font(.headline)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f km", context.state.distance))
                        .font(.title2.bold())
                }
                
                VStack(alignment: .leading) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDuration(context.state.duration))
                        .font(.title2.bold())
                }
                
                VStack(alignment: .leading) {
                    Text("Avg Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f km/h", context.state.averageSpeed))
                        .font(.title2.bold())
                }
            }
            
            if let location = context.attributes.startLocation {
                Text("Started from: \(location)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}