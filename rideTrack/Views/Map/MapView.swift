//
// MapView.swift
// rideTrack
//
// Created by Nikos Papadopulos on 20/07/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                if let location = locationManager.currentLocation {
                    Annotation("", coordinate: location.coordinate) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onAppear(perform: locationManager.startUpdating)
            .onDisappear(perform: locationManager.stopUpdating)

            if let location = locationManager.currentLocation {
                HStack(spacing: 16) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("\(location.coordinate.latitude), \(location.coordinate.longitude)").textSelection(.enabled)
                    }
                    HStack {
                        Image(systemName: "arrow.up.and.down.circle.fill")
                        Text("\(String(format: "%.2f", locationManager.currentAltitude)) m").textSelection(.enabled)

                    }
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(12)
                .padding(.bottom, 32)
            }
        }
        //.edgesIgnoringSafeArea(.all)
    }

}

#Preview {
    MapView()
}
