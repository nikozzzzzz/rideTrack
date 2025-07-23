//
//  ActivityType.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import Foundation
import SwiftUI

enum ActivityType: String, CaseIterable, Codable {
    case running = "running"
    case cycling = "cycling"
    case motorcycle = "motorcycle"
    case skiing = "skiing"
    case walking = "walking"
    
    var displayName: String {
        switch self {
        case .running:
            return LocalizationKeys.running.localized
        case .cycling:
            return LocalizationKeys.cycling.localized
        case .motorcycle:
            return LocalizationKeys.motorcycle.localized
        case .skiing:
            return LocalizationKeys.skiing.localized
        case .walking:
            return LocalizationKeys.walking.localized
        }
    }
    
    var icon: String {
        switch self {
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .motorcycle:
            return "motorcycle"
        case .skiing:
            return "figure.skiing.downhill"
        case .walking:
            return "figure.walk"
        }
    }
    
    var color: Color {
        switch self {
        case .running:
            return .orange
        case .cycling:
            return .blue
        case .motorcycle:
            return .red
        case .skiing:
            return .cyan
        case .walking:
            return .green
        }
    }
}
