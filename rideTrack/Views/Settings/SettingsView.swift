//
//  SettingsView.swift
//  rideTrack
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @State private var showingDataExport = false
    @State private var showingDataImport = false
    @State private var showingDeleteAllAlert = false
    
    private var settings: UserSettings {
        userSettings.first ?? createDefaultSettings()
    }
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section {
                    NavigationLink(destination: UserProfileView()) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizationKeys.userProfile.localized)
                                    .font(.headline)
                                Text(LocalizationKeys.manageYourAccount.localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Preferences Section
                Section(LocalizationKeys.preferences.localized) {
                    NavigationLink(destination: UnitsSettingsView(settings: settings)) {
                        SettingsRow(
                            icon: "ruler",
                            title: LocalizationKeys.units.localized,
                            subtitle: settings.unitSystem.displayName,
                            color: .orange
                        )
                    }
                    
                    NavigationLink(destination: LanguageSettingsView(settings: settings)) {
                        SettingsRow(
                            icon: "globe",
                            title: LocalizationKeys.language.localized,
                            subtitle: settings.language.displayName,
                            color: .blue
                        )
                    }
                    
                    NavigationLink(destination: ThemeSettingsView(settings: settings)) {
                        SettingsRow(
                            icon: "paintbrush",
                            title: LocalizationKeys.theme.localized,
                            subtitle: settings.colorTheme.displayName,
                            color: .purple
                        )
                    }
                }
                
                // Sync & Data Section
                Section("Sync & Data") {
                    HStack {
                        Image(systemName: "icloud")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                                .font(.headline)
                            Text("Sync data across devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.iCloudSyncEnabled },
                            set: { newValue in
                                settings.iCloudSyncEnabled = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        ))
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "heart")
                            .font(.title2)
                            .foregroundColor(.red)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Health")
                                .font(.headline)
                            Text("Share workouts with Health app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.healthKitSyncEnabled },
                            set: { newValue in
                                settings.healthKitSyncEnabled = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        ))
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: { showingDataExport = true }) {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Data",
                            subtitle: "Export your ride data",
                            color: .green
                        )
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: { showingDataImport = true }) {
                        SettingsRow(
                            icon: "square.and.arrow.down",
                            title: "Import Data",
                            subtitle: "Import ride data from file",
                            color: .blue
                        )
                    }
                    .foregroundColor(.primary)
                }
                
                // Notifications Section
                Section("Notifications") {
                    HStack {
                        Image(systemName: "bell")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications")
                                .font(.headline)
                            Text("Ride milestones and reminders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { newValue in
                                settings.notificationsEnabled = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        ))
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Voice Announcements")
                                .font(.headline)
                            Text("Audio updates during rides")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.voiceAnnouncementsEnabled },
                            set: { newValue in
                                settings.voiceAnnouncementsEnabled = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        ))
                    }
                    .padding(.vertical, 4)
                }
                
                // Tracking Section
                Section("Tracking") {
                    HStack {
                        Image(systemName: "play.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Start Tracking")
                                .font(.headline)
                            Text("Start tracking when motion detected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.autoStartTracking },
                            set: { newValue in
                                settings.autoStartTracking = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        ))
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "pause.circle")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Pause")
                                .font(.headline)
                            Text("Pause when stopped")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.autoPauseEnabled },
                            set: { newValue in
                                settings.autoPauseEnabled = newValue
                                settings.updateTimestamp()
                                try? modelContext.save()
                            }
                        ))
                    }
                    .padding(.vertical, 4)
                }
                
                // About Section
                Section("About") {
                    SettingsRow(
                        icon: "info.circle",
                        title: "Version",
                        subtitle: "1.0.0",
                        color: .gray
                    )
                    
                    Button(action: { showingDeleteAllAlert = true }) {
                        SettingsRow(
                            icon: "trash",
                            title: "Delete All Data",
                            subtitle: "Remove all rides and settings",
                            color: .red
                        )
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle(LocalizationKeys.settings.localized)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
            }
            .sheet(isPresented: $showingDataImport) {
                DataImportView()
            }
            .alert("Delete All Data", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your ride data and settings. This action cannot be undone.")
            }
        }
    }
    
    private func createDefaultSettings() -> UserSettings {
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
    }
    
    private func deleteAllData() {
        // Delete all ride sessions
        let ridePredicate = #Predicate<RideSession> { _ in true }
        try? modelContext.delete(model: RideSession.self, where: ridePredicate)
        
        // Delete all location points
        let locationPredicate = #Predicate<LocationPoint> { _ in true }
        try? modelContext.delete(model: LocationPoint.self, where: locationPredicate)
        
        // Delete all settings
        let settingsPredicate = #Predicate<UserSettings> { _ in true }
        try? modelContext.delete(model: UserSettings.self, where: settingsPredicate)
        
        try? modelContext.save()
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Placeholder views for navigation destinations
struct UnitsSettingsView: View {
    let settings: UserSettings
    
    var body: some View {
        Text("Units Settings")
            .navigationTitle("Units")
    }
}

struct LanguageSettingsView: View {
    let settings: UserSettings
    @Environment(\.modelContext) private var modelContext
    @State private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        List {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.displayName)
                            .font(.headline)
                        
                        Text(getLanguageDescription(for: language))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if settings.language == language {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .font(.headline)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectLanguage(language)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(LocalizationKeys.language.localized)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func selectLanguage(_ language: AppLanguage) {
        settings.language = language
        settings.updateTimestamp()
        
        // Update localization manager
        localizationManager.setLanguage(language)
        
        // Save to model context
        try? modelContext.save()
    }
    
    private func getLanguageDescription(for language: AppLanguage) -> String {
        switch language {
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

struct ThemeSettingsView: View {
    let settings: UserSettings
    
    var body: some View {
        Text("Theme Settings")
            .navigationTitle("Theme")
    }
}

struct DataExportView: View {
    var body: some View {
        Text("Data Export")
    }
}

struct DataImportView: View {
    var body: some View {
        Text("Data Import")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [RideSession.self, LocationPoint.self, UserSettings.self], inMemory: true)
}
