//
//  CurrentRideView.swift
//  rideTrack
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct CurrentRideView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activeSessions: [RideSession]
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var showingStopAlert = false
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    init() {
        // Query for active sessions
        let predicate = #Predicate<RideSession> { session in
            session.isActive == true
        }
        _activeSessions = Query(filter: predicate)
    }
    
    var currentSession: RideSession? {
        activeSessions.first
    }
    
    var mapAnnotations: [MapAnnotationItem] {
        guard let session = currentSession else { return [] }
        var items: [MapAnnotationItem] = []
        
        if let first = session.locationPoints.first {
            items.append(MapAnnotationItem(coordinate: first.coordinate, color: .green))
        }
        
        return items
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let session = currentSession {
                VStack(spacing: 0) {
                    // Map View - 40% of screen height
                    ZStack(alignment: .topTrailing) {
                        Map(position: $mapCameraPosition, interactionModes: .all) {
                            UserAnnotation()
                            
                            MapPolyline(coordinates: session.locationPoints.map { $0.coordinate })
                                .stroke(.blue, lineWidth: 4)
                            
                            ForEach(mapAnnotations) { item in
                                Annotation("", coordinate: item.coordinate) {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 10, height: 10)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .ignoresSafeArea(edges: .top)
                        
                        // Map Controls
                        VStack(spacing: 12) {
                            Button(action: centerOnUser) {
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.black.opacity(0.7))
                                    .cornerRadius(22)
                            }
                            
                            Button(action: toggleMapType) {
                                Image(systemName: "map")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.black.opacity(0.7))
                                    .cornerRadius(22)
                            }
                        }
                        .padding()
                    }
                    .frame(height: geometry.size.height * 0.4)
                    
                    // Scrollable Metrics Panel
                    ScrollView {
                        VStack(spacing: 20) {
                            // Activity Header
                            HStack {
                                Image(systemName: session.activityType.icon)
                                    .font(.title)
                                    .foregroundColor(session.activityType.color)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.displayTitle)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text("Started at \(session.startTime.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if session.isPaused {
                                    Text("PAUSED")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Live Metrics
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                LiveMetricCard(
                                    title: "Distance",
                                    value: session.formattedDistance,
                                    icon: "road.lanes",
                                    color: .blue
                                )
                                
                                LiveMetricCard(
                                    title: "Duration",
                                    value: formatLiveDuration(session.duration),
                                    icon: "clock",
                                    color: .orange
                                )
                                
                                LiveMetricCard(
                                    title: "Current Speed",
                                    value: formatCurrentSpeed(),
                                    icon: "speedometer",
                                    color: .green
                                )
                                
                                LiveMetricCard(
                                    title: "Max Speed",
                                    value: session.formattedMaxSpeed,
                                    icon: "gauge.high",
                                    color: .red
                                )
                                
                                if session.activityType == .running || session.activityType == .walking {
                                    LiveMetricCard(
                                        title: "Current Pace",
                                        value: formatCurrentPace(),
                                        icon: "timer",
                                        color: .purple
                                    )
                                    
                                    LiveMetricCard(
                                        title: "Avg Pace",
                                        value: session.formattedPace,
                                        icon: "timer.circle",
                                        color: .indigo
                                    )
                                } else {
                                    LiveMetricCard(
                                        title: "Avg Speed",
                                        value: session.formattedAverageSpeed,
                                        icon: "speedometer.circle",
                                        color: .teal
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Add some bottom padding to ensure content doesn't get hidden behind buttons
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    
                    // Fixed Control Buttons at Bottom
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 20) {
                            // Pause/Resume Button
                            Button(action: togglePause) {
                                HStack {
                                    Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                                        .font(.title2)
                                    Text(session.isPaused ? "Resume" : "Pause")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(session.isPaused ? .green : .orange)
                                .cornerRadius(12)
                            }
                            
                            // Stop Button
                            Button(action: { showingStopAlert = true }) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                        .font(.title2)
                                    Text("Stop")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.red)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                    }
                }
                .navigationTitle("Current Ride")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
                .alert("Stop Ride", isPresented: $showingStopAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Stop", role: .destructive) {
                        stopRide()
                    }
                } message: {
                    Text("Are you sure you want to stop this ride? Your progress will be saved.")
                }
                .onAppear {
                    startTimer()
                }
                .onDisappear {
                    stopTimer()
                }
            } else {
                // No active session
                VStack(spacing: 20) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No Active Ride")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start a new ride from the 'New Ride' tab")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Current Ride")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func togglePause() {
        guard let session = currentSession else { return }
        
        if session.isPaused {
            session.resume()
            LocationManager.shared.resumeTracking()
        } else {
            session.pause()
            LocationManager.shared.pauseTracking()
        }
        
        try? modelContext.save()
    }
    
    private func stopRide() {
        guard let session = currentSession else { return }
        
        session.stop()
        LocationManager.shared.stopTracking()
        
        try? modelContext.save()
    }
    
    private func centerOnUser() {
        if let userLocation = LocationManager.shared.currentLocation {
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapCameraPosition = .region(region)
        }
    }
    
    private func toggleMapType() {
        // Toggle between standard and satellite map
        // This would be implemented with proper map configuration
    }
    
    private func formatLiveDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatCurrentSpeed() -> String {
        let currentSpeed = LocationManager.shared.currentSpeed
        let kmh = currentSpeed * 3.6
        return String(format: "%.1f km/h", kmh)
    }
    
    private func formatCurrentPace() -> String {
        let currentSpeed = LocationManager.shared.currentSpeed
        guard currentSpeed > 0 else {
            return "--:--"
        }
        let pace = (1000 / currentSpeed) / 60 // minutes per km
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

struct LiveMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}


#Preview {
    CurrentRideView()
        .modelContainer(for: [RideSession.self, LocationPoint.self, UserSettings.self], inMemory: true)
}