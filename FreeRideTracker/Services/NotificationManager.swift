//
//  NotificationManager.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 20/07/25.
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                AppLogger.error("Error requesting notification permission", error: error, category: AppLogger.general)
                return
            }
            
            if granted {
                AppLogger.info("Notification permission granted", category: AppLogger.general)
            } else {
                AppLogger.warning("Notification permission denied by user", category: AppLogger.general)
            }
        }
    }
    
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized: Bool
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    isAuthorized = true
                    AppLogger.debug("Notification permission: authorized", category: AppLogger.general)
                case .denied:
                    isAuthorized = false
                    AppLogger.debug("Notification permission: denied", category: AppLogger.general)
                case .notDetermined:
                    isAuthorized = false
                    AppLogger.debug("Notification permission: not determined", category: AppLogger.general)
                case .ephemeral:
                    isAuthorized = false
                    AppLogger.debug("Notification permission: ephemeral", category: AppLogger.general)
                @unknown default:
                    isAuthorized = false
                    AppLogger.warning("Unknown notification permission status", category: AppLogger.general)
                }
                completion(isAuthorized)
            }
        }
    }
    
    /// Opens the app settings page
    func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}