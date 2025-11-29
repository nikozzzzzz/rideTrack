//
//  FreeRideTrackerApp.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import SwiftData

@main
struct FreeRideTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var localizationManager = LocalizationManager.shared
    @State private var initializationError: Error?
    
    var sharedModelContainer: ModelContainer? = {
        let schema = Schema([
            RideSession.self,
            LocationPoint.self,
            UserSettings.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            AppLogger.info("ModelContainer initialized successfully", category: AppLogger.data)
            return container
        } catch {
            AppLogger.critical("Failed to create ModelContainer", error: error, category: AppLogger.data)
            // Don't crash - allow app to show error UI
            return nil
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = sharedModelContainer {
                    MainTabView()
                        .environment(localizationManager)
                        .modelContainer(container)
                        .onAppear {
                            // Load saved language preference
                            let savedLanguage = localizationManager.loadSavedLanguage()
                            localizationManager.setLanguage(savedLanguage)
                        }
                } else {
                    // Show error UI if initialization failed
                    DataStorageErrorView()
                }
            }
        }
    }
}

// MARK: - Error View

struct DataStorageErrorView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Storage Initialization Failed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("The app was unable to initialize its data storage. This may be due to insufficient storage space or file system permissions.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Text("Please try:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Free up storage space on your device", systemImage: "externaldrive.fill")
                    Label("Restart the app", systemImage: "arrow.clockwise")
                    Label("Restart your device", systemImage: "iphone.gen3")
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Button(action: {
                // Attempt to restart the app
                exit(0)
            }) {
                Text("Restart App")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .padding()
    }
}
