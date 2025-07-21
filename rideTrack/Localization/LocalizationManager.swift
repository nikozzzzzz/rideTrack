//
//  LocalizationManager.swift
//  rideTrack
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import Foundation
import SwiftUI

@Observable
class LocalizationManager {
    static let shared = LocalizationManager()
    
    var currentLanguage: AppLanguage = .english {
        didSet {
            updateBundle()
        }
    }
    
    private var bundle: Bundle = Bundle.main
    
    private init() {
        // Initialize with system language or default to English
        if let systemLanguage = detectSystemLanguage() {
            currentLanguage = systemLanguage
        }
        updateBundle()
    }
    
    private func detectSystemLanguage() -> AppLanguage? {
        let preferredLanguages = Locale.preferredLanguages
        for language in preferredLanguages {
            let languageCode = String(language.prefix(2))
            if let appLanguage = AppLanguage(rawValue: languageCode) {
                return appLanguage
            }
        }
        return nil
    }
    
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
    }
    
    func localizedString(for key: String, comment: String = "") -> String {
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        // Save to UserDefaults for persistence
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
    }
    
    func loadSavedLanguage() -> AppLanguage {
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: savedLanguage) {
            return language
        }
        return detectSystemLanguage() ?? .english
    }
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Localization Keys
struct LocalizationKeys {
    
    // MARK: - Tab Bar
    static let dashboard = "dashboard"
    static let newRide = "new_ride"
    static let currentRide = "current_ride"
    static let profile = "profile"
    static let settings = "settings"
    
    // MARK: - Dashboard
    static let recentRides = "recent_rides"
    static let noRidesYet = "no_rides_yet"
    static let startFirstRide = "start_first_ride"
    static let searchRides = "search_rides"
    static let allRides = "all_rides"
    static let all = "all"
    static let totalDistance = "total_distance"
    static let totalTime = "total_time"
    static let totalRides = "total_rides"
    static let thisWeek = "this_week"
    static let thisMonth = "this_month"
    static let thisYear = "this_year"
    
    // MARK: - New Ride
    static let selectActivity = "select_activity"
    static let chooseActivityType = "choose_activity_type"
    static let rideTitle = "ride_title"
    static let optionalTitle = "optional_title"
    static let locationPermissionRequired = "location_permission_required"
    static let locationPermissionMessage = "location_permission_message"
    static let openSettings = "open_settings"
    static let cancel = "cancel"
    static let start = "start"
    static let starting = "starting"
    static let optional = "optional"
    static let customTitle = "custom_title"
    
    // MARK: - Activity Types
    static let running = "running"
    static let cycling = "cycling"
    static let motorcycle = "motorcycle"
    static let skiing = "skiing"
    static let walking = "walking"
    
    // MARK: - Current Ride
    static let startedAt = "started_at"
    static let paused = "paused"
    static let distance = "distance"
    static let duration = "duration"
    static let currentSpeed = "current_speed"
    static let maxSpeed = "max_speed"
    static let currentPace = "current_pace"
    static let avgPace = "avg_pace"
    static let avgSpeed = "avg_speed"
    static let pause = "pause"
    static let resume = "resume"
    static let stop = "stop"
    static let stopRide = "stop_ride"
    static let stopRideMessage = "stop_ride_message"
    static let noActiveRide = "no_active_ride"
    static let startNewRideFromTab = "start_new_ride_from_tab"

    // MARK: - Map
    static let map = "map"

    // MARK: - Settings
    static let preferences = "preferences"
    static let units = "units"
    static let language = "language"
    static let theme = "theme"
    static let syncData = "sync_data"
    static let icloudSync = "icloud_sync"
    static let syncDataAcrossDevices = "sync_data_across_devices"
    static let appleHealth = "apple_health"
    static let shareWorkoutsWithHealth = "share_workouts_with_health"
    static let exportData = "export_data"
    static let exportRideData = "export_ride_data"
    static let importData = "import_data"
    static let importRideDataFromFile = "import_ride_data_from_file"
    static let notifications = "notifications"
    static let rideMilestonesAndReminders = "ride_milestones_and_reminders"
    static let voiceAnnouncements = "voice_announcements"
    static let audioUpdatesDuringRides = "audio_updates_during_rides"
    static let tracking = "tracking"
    static let autoStartTracking = "auto_start_tracking"
    static let startTrackingWhenMotionDetected = "start_tracking_when_motion_detected"
    static let autoPause = "auto_pause"
    static let pauseWhenStopped = "pause_when_stopped"
    static let about = "about"
    static let version = "version"
    static let deleteAllData = "delete_all_data"
    static let removeAllRidesAndSettings = "remove_all_rides_and_settings"
    static let deleteAllDataMessage = "delete_all_data_message"
    static let deleteAll = "delete_all"
    static let userProfile = "user_profile"
    static let manageYourAccount = "manage_your_account"
    
    // MARK: - Profile
    struct Profile {
        static let title = "profile_title"
        static let checkingStatus = "profile_checking_status"
        static let unknownUser = "profile_unknown_user"
        static let memberSince = "profile_member_since"
        static let lastSync = "profile_last_sync"
        static let refresh = "profile_refresh"
        static let statistics = "profile_statistics"
        static let totalRides = "profile_total_rides"
        static let totalDistance = "profile_total_distance"
        static let totalTime = "profile_total_time"
        static let activities = "profile_activities"
        static let quickActions = "profile_quick_actions"
        static let editProfile = "profile_edit_profile"
        static let syncData = "profile_sync_data"
        static let exportData = "profile_export_data"
        static let management = "profile_management"
        static let cloudSync = "profile_cloud_sync"
        static let signOut = "profile_sign_out"
        static let notSignedIn = "profile_not_signed_in"
        static let signInPrompt = "profile_sign_in_prompt"
        static let checkiCloud = "profile_check_icloud"
        static let openSettings = "profile_open_settings"
        static let personalInfo = "profile_personal_info"
        static let firstName = "profile_first_name"
        static let lastName = "profile_last_name"
        static let email = "profile_email"
        static let firstNamePlaceholder = "profile_first_name_placeholder"
        static let lastNamePlaceholder = "profile_last_name_placeholder"
        static let emailPlaceholder = "profile_email_placeholder"
        static let preferences = "profile_preferences"
        static let cloudSyncDescription = "profile_cloud_sync_description"
        static let preferredActivities = "profile_preferred_activities"
        static let selectActivities = "profile_select_activities"
        static let selected = "profile_selected"
        static let activitiesDescription = "profile_activities_description"
        static let dataSync = "profile_data_sync"
        static let saving = "profile_saving"
        static let firstNameRequired = "profile_first_name_required"
    }
    
    // MARK: - Units
    static let metric = "metric"
    static let imperial = "imperial"
    static let metricDescription = "metric_description"
    static let imperialDescription = "imperial_description"
    
    // MARK: - Common
    static let ok = "ok"
    static let done = "done"
    static let save = "save"
    static let edit = "edit"
    static let delete = "delete"
    static let share = "share"
    static let close = "close"
    static let back = "back"
    static let next = "next"
    static let previous = "previous"
    static let loading = "loading"
    static let error = "error"
    static let success = "success"
    static let warning = "warning"
    static let info = "info"
}
