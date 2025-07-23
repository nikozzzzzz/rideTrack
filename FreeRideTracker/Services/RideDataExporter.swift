//
//  RideDataExporter.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct RideExportData: Transferable {
    let session: RideSession
    
    private func generateCSVString() -> String {
        let header = "Timestamp,Latitude,Longitude,Altitude,Speed,Course,HorizontalAccuracy,VerticalAccuracy\n"
        
        let trackData = session.locationPoints.map { point in
            "\(point.timestamp.ISO8601Format()),\(point.latitude),\(point.longitude),\(point.altitude),\(point.speed),\(point.course),\(point.horizontalAccuracy),\(point.verticalAccuracy)"
        }.joined(separator: "\n")
        
        let summary = """
        "Distance (m)","\(session.totalDistance)"
        "Duration (s)","\(session.duration)"
        "Average Speed (m/s)","\(session.averageSpeed)"
        "Max Speed (m/s)","\(session.maxSpeed)"
        "Average Pace (min/km)","\(session.averagePace)"
        "Data Points","\(session.locationPoints.count)"
        
        
        """
        
        return summary + header + trackData
    }
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { exportData in
            let csvString = exportData.generateCSVString()
            let filename = "ride-\(exportData.session.id.uuidString).csv"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            do {
                try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            } catch {
                // If writing fails, we can't produce the file.
                // The system will handle the error gracefully.
                throw error
            }

            return SentTransferredFile(tempURL)
        }
    }
}