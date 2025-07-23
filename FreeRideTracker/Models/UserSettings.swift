//
//  UserSettings.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import Foundation
import SwiftData

enum UnitSystem: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    
    var displayName: String {
        switch self {
        case .metric:
            return "Metric (km, kg)"
        case .imperial:
            return "Imperial (mi, lb)"
        }
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case russian = "ru"
    case indonesian = "id"
    case greek = "el"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .russian:
            return "Русский"
        case .indonesian:
            return "Bahasa Indonesia"
        case .greek:
            return "Ελληνικά"
        }
    }
}

enum ColorTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case colorful = "colorful"
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .colorful:
            return "Colorful"
        }
    }
}

@Model
final class UserSettings {
    var unitSystem: UnitSystem
    var language: AppLanguage
    var colorTheme: ColorTheme
    var iCloudSyncEnabled: Bool
    var healthKitSyncEnabled: Bool
    var notificationsEnabled: Bool
    var autoStartTracking: Bool
    var autoPauseEnabled: Bool
    var voiceAnnouncementsEnabled: Bool
    var distanceAnnouncementInterval: Double // kilometers
    var timeAnnouncementInterval: Double // minutes
    var createdAt: Date
    var updatedAt: Date
    
    init(
        unitSystem: UnitSystem = .metric,
        language: AppLanguage = .english,
        colorTheme: ColorTheme = .light,
        iCloudSyncEnabled: Bool = true,
        healthKitSyncEnabled: Bool = false,
        notificationsEnabled: Bool = true,
        autoStartTracking: Bool = false,
        autoPauseEnabled: Bool = true,
        voiceAnnouncementsEnabled: Bool = false,
        distanceAnnouncementInterval: Double = 1.0,
        timeAnnouncementInterval: Double = 5.0
    ) {
        self.unitSystem = unitSystem
        self.language = language
        self.colorTheme = colorTheme
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self.healthKitSyncEnabled = healthKitSyncEnabled
        self.notificationsEnabled = notificationsEnabled
        self.autoStartTracking = autoStartTracking
        self.autoPauseEnabled = autoPauseEnabled
        self.voiceAnnouncementsEnabled = voiceAnnouncementsEnabled
        self.distanceAnnouncementInterval = distanceAnnouncementInterval
        self.timeAnnouncementInterval = timeAnnouncementInterval
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        updatedAt = Date()
    }
}