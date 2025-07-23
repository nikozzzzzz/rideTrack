//
//  NotificationManager.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 20/07/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    completion(true)
                case .denied, .notDetermined, .ephemeral:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    func showTrackingNotification(activityType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Ride in Progress"
        content.body = "Currently tracking your \(activityType) session."
        content.sound = .none
        
        let request = UNNotificationRequest(identifier: "ride-tracking", content: content, trigger: nil) // nil trigger for immediate, persistent notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
    
    func hideTrackingNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ride-tracking"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["ride-tracking"])
    }
}