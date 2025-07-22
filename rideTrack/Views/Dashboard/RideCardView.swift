//
//  RideCardView.swift
//  rideTrack
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import MapKit

struct RideCardView: View {
    let session: RideSession
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with activity type and date
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: session.activityType.icon)
                        .foregroundColor(session.activityType.color)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.displayTitle)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Duration badge
                Text(session.formattedDuration)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(session.activityType.color.opacity(0.2))
                    .foregroundColor(session.activityType.color)
                    .cornerRadius(8)
            }
            
            // Map preview
            if !session.locationPoints.isEmpty {
                MapPreviewView(locationPoints: session.locationPoints)
                    .frame(height: 120)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "map")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("No route data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            // Metrics
            HStack(spacing: 20) {
                MetricView(
                    title: "Distance",
                    value: session.formattedDistance,
                    icon: "road.lanes"
                )
                
                MetricView(
                    title: "Avg Speed",
                    value: session.formattedAverageSpeed,
                    icon: "speedometer"
                )
                
                MetricView(
                    title: "Max Speed",
                    value: session.formattedMaxSpeed,
                    icon: "gauge.high"
                )
                
                if session.activityType == .running || session.activityType == .walking {
                    MetricView(
                        title: "Pace",
                        value: session.formattedPace,
                        icon: "timer"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let color: Color
}

struct MapPreviewView: View {
    let locationPoints: [LocationPoint]
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    var annotationItems: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        
        if let first = locationPoints.first {
            items.append(MapAnnotationItem(coordinate: first.coordinate, color: .green))
        }
        
        if let last = locationPoints.last, locationPoints.count > 1 {
            items.append(MapAnnotationItem(coordinate: last.coordinate, color: .red))
        }
        
        return items
    }
    
    var body: some View {
        Map(position: $mapCameraPosition, interactionModes: []) {
            MapPolyline(coordinates: locationPoints.map { $0.coordinate })
                .stroke(.blue, lineWidth: 3)

            ForEach(annotationItems) { item in
                Annotation("", coordinate: item.coordinate) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 1)
                        )
                }
            }
        }
        .onAppear(perform: setupCameraPosition)
    }
    
    private func setupCameraPosition() {
        guard let firstCoordinate = locationPoints.map({ $0.coordinate }).first else {
            mapCameraPosition = .automatic
            return
        }

        if locationPoints.count == 1 {
            let region = MKCoordinateRegion(
                center: firstCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapCameraPosition = .region(region)
            return
        }
        
        let coordinates = locationPoints.map { $0.coordinate }
        let mapRect = coordinates.reduce(MKMapRect.null) { (rect, coord) -> MKMapRect in
            let point = MKMapPoint(coord)
            return rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }

        let paddedRect = mapRect.insetBy(dx: -mapRect.size.width * 0.2, dy: -mapRect.size.height * 0.2)
        
        mapCameraPosition = .rect(paddedRect)
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let sampleSession = RideSession(activityType: .running, title: "Morning Run")
    sampleSession.totalDistance = 5000 // 5km
    sampleSession.maxSpeed = 4.5 // m/s
    sampleSession.averageSpeed = 3.2 // m/s
    sampleSession.endTime = Date()
    
    return RideCardView(session: sampleSession)
        .padding()
        .background(Color(.systemGroupedBackground))
}