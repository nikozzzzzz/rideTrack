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
            guard let self = self else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                self.authenticationStatus = status
                
                if let error = error {
                    let sanitizedMessage = self.sanitizeErrorMessage(error)
                    self.errorMessage = sanitizedMessage
                    self.isSignedIn = false
                    AppLogger.error("Failed to check iCloud account status", error: error, category: .auth)
                    return
                }
                
                switch status {
                case .available:
                    self.isSignedIn = true
                    AppLogger.info("iCloud account available", category: .auth)
                    self.fetchUserProfile()
                case .noAccount:
                    self.isSignedIn = false
                    self.errorMessage = "No iCloud account found. Please sign in to iCloud in Settings."
                    AppLogger.warning("No iCloud account found", category: .auth)
                case .restricted:
                    self.isSignedIn = false
                    self.errorMessage = "iCloud access is restricted on this device."
                    AppLogger.warning("iCloud access restricted", category: .auth)
                case .couldNotDetermine:
                    self.isSignedIn = false
                    self.errorMessage = "Could not determine iCloud status."
                    AppLogger.warning("Could not determine iCloud status", category: .auth)
                case .temporarilyUnavailable:
                    self.isSignedIn = false
                    self.errorMessage = "iCloud is temporarily unavailable."
                    AppLogger.warning("iCloud temporarily unavailable", category: .auth)
                @unknown default:
                    self.isSignedIn = false
                    self.errorMessage = "Unknown iCloud status."
                    AppLogger.warning("Unknown iCloud status", category: .auth)
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
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false
                    let sanitizedMessage = self.sanitizeErrorMessage(error)
                    self.errorMessage = "Failed to fetch user ID: \(sanitizedMessage)"
                    AppLogger.error("Failed to fetch user record ID", error: error, category: .auth)
                }
                return
            }
            
            guard let userRecordID = recordID else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false
                    self.errorMessage = "No user record ID found"
                    AppLogger.warning("No user record ID found", category: .auth)
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
            guard let self = self else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    let sanitizedMessage = self.sanitizeErrorMessage(error)
                    self.errorMessage = "Failed to fetch profile: \(sanitizedMessage)"
                    AppLogger.error("Failed to fetch user profile", error: error, category: .network)
                    return
                }
                
                if let record = records?.first {
                    // User profile exists, load it
                    self.userProfile = UserProfile(from: record)
                    AppLogger.info("User profile loaded successfully", category: .auth)
                } else {
                    // No profile exists, create a new one
                    AppLogger.info("No existing profile found, creating new one", category: .auth)
                    self.createNewUserProfile(userRecordID: userRecordID)
                }
            }
        }
    }
    
    private func createNewUserProfile(userRecordID: String) {
        isLoading = true
        
        // Fetch user's name from iCloud if available
        container.discoverUserIdentity(withUserRecordID: CKRecord.ID(recordName: userRecordID)) { [weak self] userIdentity, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    AppLogger.warning("Could not discover user identity", error: error, category: .auth)
                }
                
                let firstName = userIdentity?.nameComponents?.givenName ?? ""
                let lastName = userIdentity?.nameComponents?.familyName ?? ""
                
                let newProfile = UserProfile(
                    iCloudUserID: userRecordID,
                    firstName: firstName,
                    lastName: lastName,
                    dateJoined: Date(),
                    isCloudSyncEnabled: true
                )
                
                AppLogger.info("Creating new user profile", category: .auth)
                self.saveUserProfile(newProfile)
            }
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        guard isSignedIn else {
            AppLogger.warning("Cannot save profile: not signed in to iCloud", category: .auth)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let record = profile.toCKRecord()
        
        database.save(record) { [weak self] savedRecord, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    let sanitizedMessage = self.sanitizeErrorMessage(error)
                    self.errorMessage = "Failed to save profile: \(sanitizedMessage)"
                    AppLogger.error("Failed to save user profile", error: error, category: .network)
                    return
                }
                
                if savedRecord != nil {
                    self.userProfile = profile
                    self.userProfile?.lastSyncDate = Date()
                    AppLogger.info("User profile saved successfully", category: .auth)
                }
            }
        }
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        guard isSignedIn else {
            AppLogger.warning("Cannot update profile: not signed in to iCloud", category: .auth)
            return
        }
        
        profile.lastSyncDate = Date()
        saveUserProfile(profile)
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        isSignedIn = false
        userProfile = nil
        authenticationStatus = .couldNotDetermine
        errorMessage = nil
        AppLogger.info("User signed out", category: .auth)
    }
    
    // MARK: - Utility Methods
    
    func refreshAuthStatus() {
        AppLogger.info("Refreshing iCloud authentication status", category: .auth)
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
    
    // MARK: - Error Sanitization
    
    /// Sanitizes error messages to avoid exposing internal details
    private func sanitizeErrorMessage(_ error: Error) -> String {
        // Don't expose internal error details, provide user-friendly messages
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return "Network connection unavailable"
            case .notAuthenticated:
                return "Please sign in to iCloud"
            case .quotaExceeded:
                return "iCloud storage quota exceeded"
            case .serverRejectedRequest:
                return "Request was rejected by server"
            case .serviceUnavailable:
                return "iCloud service is temporarily unavailable"
            case .requestRateLimited:
                return "Too many requests, please try again later"
            default:
                return "An iCloud error occurred"
            }
        }
        
        // Generic error message for unknown errors
        return "An error occurred. Please try again."
    }
}