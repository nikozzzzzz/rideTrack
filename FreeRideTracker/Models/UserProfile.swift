//
//  UserProfile.swift
//  FreeRideTracker
//
//  Created by RideTrack on 2024-01-01.
//

import Foundation
import SwiftData
import CloudKit

@Model
class UserProfile {
    var id: UUID
    var iCloudUserID: String?
    var firstName: String
    var lastName: String
    var email: String?
    var profileImageData: Data?
    var dateJoined: Date
    var totalRides: Int
    var totalDistance: Double // in meters
    var totalDuration: TimeInterval // in seconds
    var preferredActivities: [ActivityType]
    var isCloudSyncEnabled: Bool
    var lastSyncDate: Date?
    
    init(
        id: UUID = UUID(),
        iCloudUserID: String? = nil,
        firstName: String = "",
        lastName: String = "",
        email: String? = nil,
        profileImageData: Data? = nil,
        dateJoined: Date = Date(),
        totalRides: Int = 0,
        totalDistance: Double = 0,
        totalDuration: TimeInterval = 0,
        preferredActivities: [ActivityType] = [],
        isCloudSyncEnabled: Bool = false,
        lastSyncDate: Date? = nil
    ) {
        self.id = id
        self.iCloudUserID = iCloudUserID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.profileImageData = profileImageData
        self.dateJoined = dateJoined
        self.totalRides = totalRides
        self.totalDistance = totalDistance
        self.totalDuration = totalDuration
        self.preferredActivities = preferredActivities
        self.isCloudSyncEnabled = isCloudSyncEnabled
        self.lastSyncDate = lastSyncDate
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var displayName: String {
        if !fullName.isEmpty {
            return fullName
        } else if let email = email {
            return email
        } else {
            return "User"
        }
    }
    
    var formattedTotalDistance: String {
        let kilometers = totalDistance / 1000
        return String(format: "%.1f km", kilometers)
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - CloudKit Integration
extension UserProfile {
    static let recordType = "UserProfile"
    
    convenience init(from record: CKRecord) {
        self.init(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            iCloudUserID: record["iCloudUserID"] as? String,
            firstName: record["firstName"] as? String ?? "",
            lastName: record["lastName"] as? String ?? "",
            email: record["email"] as? String,
            profileImageData: record["profileImageData"] as? Data,
            dateJoined: record["dateJoined"] as? Date ?? Date(),
            totalRides: record["totalRides"] as? Int ?? 0,
            totalDistance: record["totalDistance"] as? Double ?? 0,
            totalDuration: record["totalDuration"] as? TimeInterval ?? 0,
            preferredActivities: (record["preferredActivities"] as? [String] ?? []).compactMap { ActivityType(rawValue: $0) },
            isCloudSyncEnabled: record["isCloudSyncEnabled"] as? Bool ?? false,
            lastSyncDate: record["lastSyncDate"] as? Date
        )
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: UserProfile.recordType, recordID: CKRecord.ID(recordName: id.uuidString))
        record["iCloudUserID"] = iCloudUserID
        record["firstName"] = firstName
        record["lastName"] = lastName
        record["email"] = email
        record["profileImageData"] = profileImageData
        record["dateJoined"] = dateJoined
        record["totalRides"] = totalRides
        record["totalDistance"] = totalDistance
        record["totalDuration"] = totalDuration
        record["preferredActivities"] = preferredActivities.map { $0.rawValue }
        record["isCloudSyncEnabled"] = isCloudSyncEnabled
        record["lastSyncDate"] = lastSyncDate
        return record
    }
}