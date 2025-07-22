//
//  RideDetailView.swift
//  rideTrack
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import MapKit

struct DetailMapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let color: Color
    let label: String
}

struct RideDetailView: View {
    let session: RideSession
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    var detailAnnotations: [DetailMapAnnotationItem] {
        var items: [DetailMapAnnotationItem] = []
        
        if let first = session.locationPoints.first {
            items.append(DetailMapAnnotationItem(coordinate: first.coordinate, color: .green, label: "Start"))
        }
        
        if let last = session.locationPoints.last, session.locationPoints.count > 1 {
            items.append(DetailMapAnnotationItem(coordinate: last.coordinate, color: .red, label: "End"))
        }
        
        return items
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: session.activityType.icon)
                            .font(.title)
                            .foregroundColor(session.activityType.color)
                        
                        VStack(alignment: .leading) {
                            Text(session.displayTitle)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(session.startTime.formatted(date: .complete, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    if let notes = session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Map
                if !session.locationPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Route")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Map(position: $mapCameraPosition) {
                            MapPolyline(coordinates: session.locationPoints.map { $0.coordinate })
                                .stroke(.blue, lineWidth: 4)
                            
                            ForEach(detailAnnotations) { item in
                                Annotation(item.label, coordinate: item.coordinate) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 12, height: 12)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: 2)
                                            )
                                        
                                        Text(item.label)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.black.opacity(0.6))
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        .frame(height: 300)
                        .cornerRadius(12)
                        .onAppear(perform: calculateMapCameraPosition)
                    }
                }
                
                // Statistics Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Statistics")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        DetailStatCard(
                            title: "Distance",
                            value: session.formattedDistance,
                            icon: "road.lanes",
                            color: .blue
                        )
                        
                        DetailStatCard(
                            title: "Duration",
                            value: session.formattedDuration,
                            icon: "clock",
                            color: .orange
                        )
                        
                        DetailStatCard(
                            title: "Average Speed",
                            value: session.formattedAverageSpeed,
                            icon: "speedometer",
                            color: .green
                        )
                        
                        DetailStatCard(
                            title: "Max Speed",
                            value: session.formattedMaxSpeed,
                            icon: "gauge.high",
                            color: .red
                        )
                        
                        if session.activityType == .running || session.activityType == .walking {
                            DetailStatCard(
                                title: "Average Pace",
                                value: session.formattedPace,
                                icon: "timer",
                                color: .purple
                            )
                        }
                        
                        if session.totalElevationGain > 0 {
                            DetailStatCard(
                                title: "Elevation Gain",
                                value: String(format: "%.0f m", session.totalElevationGain),
                                icon: "mountain.2",
                                color: .brown
                            )
                        }
                        
                        if let calories = session.calories {
                            DetailStatCard(
                                title: "Calories",
                                value: String(format: "%.0f cal", calories),
                                icon: "flame",
                                color: .orange
                            )
                        }
                        
                        DetailStatCard(
                            title: "Data Points",
                            value: "\(session.locationPoints.count)",
                            icon: "point.3.connected.trianglepath.dotted",
                            color: .gray
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Ride Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(
                        item: RideExportData(session: session),
                        preview: SharePreview("Exported Ride Data", icon: "figure.run.circle")
                    ) {
                        Label("Export Ride", systemImage: "square.and.arrow.up")
                    }
                    Button("Delete Ride", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Ride", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRide()
            }
        } message: {
            Text("Are you sure you want to delete this ride? This action cannot be undone.")
        }
    }
    
    private func calculateMapCameraPosition() {
        guard !session.locationPoints.isEmpty else { return }
        let coordinates = session.locationPoints.map { $0.coordinate }
        
        let minLat = coordinates.map(\.latitude).min()!
        let maxLat = coordinates.map(\.latitude).max()!
        let minLon = coordinates.map(\.longitude).min()!
        let maxLon = coordinates.map(\.longitude).max()!
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.4, longitudeDelta: (maxLon - minLon) * 1.4)
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        self.mapCameraPosition = .region(region)
    }

    private func deleteRide() {
        modelContext.delete(session)
        dismiss()
    }
}

struct DetailStatCard: View {
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
                .minimumScaleFactor(0.8)
            
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
    let sampleSession = RideSession(activityType: .cycling, title: "Evening Ride")
    sampleSession.totalDistance = 15000 // 15km
    sampleSession.maxSpeed = 12.5 // m/s
    sampleSession.averageSpeed = 8.3 // m/s
    sampleSession.endTime = Date()
    sampleSession.notes = "Great ride through the park with perfect weather!"
    
    return NavigationView {
        RideDetailView(session: sampleSession)
    }
}