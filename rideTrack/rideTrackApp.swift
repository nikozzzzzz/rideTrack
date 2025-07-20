//
//  rideTrackApp.swift
//  rideTrack
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import SwiftData

@main
struct rideTrackApp: App {
    @State private var localizationManager = LocalizationManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RideSession.self,
            LocationPoint.self,
            UserSettings.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(localizationManager)
                .onAppear {
                    // Load saved language preference
                    let savedLanguage = localizationManager.loadSavedLanguage()
                    localizationManager.setLanguage(savedLanguage)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
