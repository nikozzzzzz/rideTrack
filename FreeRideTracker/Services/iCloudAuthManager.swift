//
//  iCloudAuthManager.swift
//  FreeRideTracker
//
//  Created by RideTrack on 2024-01-01.
//

import Foundation
import CloudKit
import SwiftUI

@Observable
class iCloudAuthManager {
    static let shared = iCloudAuthManager()
    
    private let container = CKContainer.default()
    private let database: CKDatabase
    
    var isSignedIn = false
    var userProfile: UserProfile?
    var authenticationStatus: CKAccountStatus = .couldNotDetermine
    var errorMessage: String?
    var isLoading = false
    
    private init() {
        self.database = container.privateCloudDatabase
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    
    func checkAuthenticationStatus() {
        isLoading = true
        errorMessage = nil
        
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.authenticationStatus = status
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isSignedIn = false
                    return
                }
                
                switch status {
                case .available:
                    self?.isSignedIn = true
                    self?.fetchUserProfile()
                case .noAccount:
                    self?.isSignedIn = false
                    self?.errorMessage = "No iCloud account found. Please sign in to iCloud in Settings."
                case .restricted:
                    self?.isSignedIn = false
                    self?.errorMessage = "iCloud access is restricted on this device."
                case .couldNotDetermine:
                    self?.isSignedIn = false
                    self?.errorMessage = "Could not determine iCloud status."
                case .temporarilyUnavailable:
                    self?.isSignedIn = false
                    self?.errorMessage = "iCloud is temporarily unavailable."
                @unknown default:
                    self?.isSignedIn = false
                    self?.errorMessage = "Unknown iCloud status."
                }
            }
        }
    }
    
    // MARK: - User Profile Management
    
    func fetchUserProfile() {
        guard isSignedIn else { return }
        
        isLoading = true
        errorMessage = nil
        
        // First, get the user's iCloud ID
        container.fetchUserRecordID { [weak self] recordID, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch user ID: \(error.localizedDescription)"
                }
                return
            }
            
            guard let userRecordID = recordID else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "No user record ID found"
                }
                return
            }
            
            // Try to fetch existing user profile
            self.fetchExistingUserProfile(userRecordID: userRecordID.recordName)
        }
    }
    
    private func fetchExistingUserProfile(userRecordID: String) {
        let predicate = NSPredicate(format: "iCloudUserID == %@", userRecordID)
        let query = CKQuery(recordType: UserProfile.recordType, predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                    return
                }
                
                if let record = records?.first {
                    // User profile exists, load it
                    self?.userProfile = UserProfile(from: record)
                } else {
                    // No profile exists, create a new one
                    self?.createNewUserProfile(userRecordID: userRecordID)
                }
            }
        }
    }
    
    private func createNewUserProfile(userRecordID: String) {
        isLoading = true
        
        // Fetch user's name from iCloud if available
        container.discoverUserIdentity(withUserRecordID: CKRecord.ID(recordName: userRecordID)) { [weak self] userIdentity, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let firstName = userIdentity?.nameComponents?.givenName ?? ""
                let lastName = userIdentity?.nameComponents?.familyName ?? ""
                
                let newProfile = UserProfile(
                    iCloudUserID: userRecordID,
                    firstName: firstName,
                    lastName: lastName,
                    dateJoined: Date(),
                    isCloudSyncEnabled: true
                )
                
                self.saveUserProfile(newProfile)
            }
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        guard isSignedIn else { return }
        
        isLoading = true
        errorMessage = nil
        
        let record = profile.toCKRecord()
        
        database.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    return
                }
                
                if savedRecord != nil {
                    self?.userProfile = profile
                    self?.userProfile?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        guard isSignedIn else { return }
        
        profile.lastSyncDate = Date()
        saveUserProfile(profile)
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        isSignedIn = false
        userProfile = nil
        authenticationStatus = .couldNotDetermine
        errorMessage = nil
    }
    
    // MARK: - Utility Methods
    
    func refreshAuthStatus() {
        checkAuthenticationStatus()
    }
    
    var isCloudKitAvailable: Bool {
        return authenticationStatus == .available
    }
    
    var statusMessage: String {
        switch authenticationStatus {
        case .available:
            return "Connected to iCloud"
        case .noAccount:
            return "No iCloud Account"
        case .restricted:
            return "iCloud Restricted"
        case .couldNotDetermine:
            return "Checking iCloud Status..."
        case .temporarilyUnavailable:
            return "iCloud Temporarily Unavailable"
        @unknown default:
            return "Unknown Status"
        }
    }
    
    var statusColor: Color {
        switch authenticationStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .red
        case .couldNotDetermine, .temporarilyUnavailable:
            return .orange
        @unknown default:
            return .gray
        }
    }
}