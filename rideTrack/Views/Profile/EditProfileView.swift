//
//  EditProfileView.swift
//  rideTrack
//
//  Created by RideTrack on 2024-01-01.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var localizationManager
    @State private var authManager = iCloudAuthManager.shared
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var selectedActivities: Set<ActivityType>
    @State private var isCloudSyncEnabled: Bool
    
    @State private var showingActivityPicker = false
    @State private var isSaving = false
    @State private var saveError: String?
    
    let userProfile: UserProfile?
    
    init(userProfile: UserProfile?) {
        self.userProfile = userProfile
        self._firstName = State(initialValue: userProfile?.firstName ?? "")
        self._lastName = State(initialValue: userProfile?.lastName ?? "")
        self._email = State(initialValue: userProfile?.email ?? "")
        self._selectedActivities = State(initialValue: Set(userProfile?.preferredActivities ?? []))
        self._isCloudSyncEnabled = State(initialValue: userProfile?.isCloudSyncEnabled ?? true)
    }
    
    var body: some View {
        NavigationView {
            Form {
                personalInfoSection
                preferencesSection
                activitiesSection
                syncSection
                
                if let error = saveError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(LocalizationKeys.Profile.editProfile.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.cancel.localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.save.localized) {
                        saveProfile()
                    }
                    .disabled(isSaving || firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView(LocalizationKeys.Profile.saving.localized)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var personalInfoSection: some View {
        Section(LocalizationKeys.Profile.personalInfo.localized) {
            HStack {
                Text(LocalizationKeys.Profile.firstName.localized)
                Spacer()
                TextField(LocalizationKeys.Profile.firstNamePlaceholder.localized, text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
            }
            
            HStack {
                Text(LocalizationKeys.Profile.lastName.localized)
                Spacer()
                TextField(LocalizationKeys.Profile.lastNamePlaceholder.localized, text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
            }
            
            HStack {
                Text(LocalizationKeys.Profile.email.localized)
                Spacer()
                TextField(LocalizationKeys.Profile.emailPlaceholder.localized, text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .frame(maxWidth: 200)
            }
        }
    }
    
    private var preferencesSection: some View {
        Section {
            Toggle(LocalizationKeys.Profile.cloudSync.localized, isOn: $isCloudSyncEnabled)
        } header: {
            Text(LocalizationKeys.Profile.preferences.localized)
        } footer: {
            Text(LocalizationKeys.Profile.cloudSyncDescription.localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var activitiesSection: some View {
        Section {
            Button(action: { showingActivityPicker = true }) {
                HStack {
                    Text(LocalizationKeys.Profile.selectActivities.localized)
                    Spacer()
                    Text("\(selectedActivities.count) " + LocalizationKeys.Profile.selected.localized)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            
            if !selectedActivities.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(Array(selectedActivities), id: \.self) { activity in
                        ActivityChip(activity: activity)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text(LocalizationKeys.Profile.preferredActivities.localized)
        } footer: {
            Text(LocalizationKeys.Profile.activitiesDescription.localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingActivityPicker) {
            ActivityPickerView(selectedActivities: $selectedActivities)
        }
    }
    
    private var syncSection: some View {
        Section(LocalizationKeys.Profile.dataSync.localized) {
            HStack {
                Image(systemName: "icloud.fill")
                    .foregroundColor(authManager.statusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(authManager.statusMessage)
                        .font(.subheadline)
                    
                    if let lastSync = userProfile?.lastSyncDate {
                        Text(LocalizationKeys.Profile.lastSync.localized + " " + lastSync.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            saveError = LocalizationKeys.Profile.firstNameRequired.localized
            return
        }
        
        isSaving = true
        saveError = nil
        
        // Create updated profile
        let updatedProfile: UserProfile
        if let existingProfile = userProfile {
            updatedProfile = existingProfile
            updatedProfile.firstName = firstName.trimmingCharacters(in: .whitespaces)
            updatedProfile.lastName = lastName.trimmingCharacters(in: .whitespaces)
            updatedProfile.email = email.trimmingCharacters(in: .whitespaces).isEmpty ? nil : email.trimmingCharacters(in: .whitespaces)
            updatedProfile.preferredActivities = Array(selectedActivities)
            updatedProfile.isCloudSyncEnabled = isCloudSyncEnabled
        } else {
            updatedProfile = UserProfile(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces).isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
                preferredActivities: Array(selectedActivities),
                isCloudSyncEnabled: isCloudSyncEnabled
            )
        }
        
        // Save to CloudKit
        authManager.updateUserProfile(updatedProfile)
        
        // Simulate save delay and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Activity Chip View

struct ActivityChip: View {
    let activity: ActivityType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: activity.icon)
                .font(.caption)
            Text(activity.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(activity.color.opacity(0.2))
        .foregroundColor(activity.color)
        .cornerRadius(8)
    }
}

// MARK: - Activity Picker View

struct ActivityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var localizationManager
    @Binding var selectedActivities: Set<ActivityType>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ActivityType.allCases, id: \.self) { activity in
                    Button(action: {
                        if selectedActivities.contains(activity) {
                            selectedActivities.remove(activity)
                        } else {
                            selectedActivities.insert(activity)
                        }
                    }) {
                        HStack {
                            Image(systemName: activity.icon)
                                .foregroundColor(activity.color)
                                .frame(width: 24)
                            
                            Text(activity.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedActivities.contains(activity) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizationKeys.Profile.selectActivities.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.done.localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditProfileView(userProfile: nil)
        .environment(LocalizationManager.shared)
}