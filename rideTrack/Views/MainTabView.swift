//
//  MainTabView.swift
//  rideTrack
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activeSessions: [RideSession]
    @State private var selectedTab = 0
    
    init() {
        // Query for active sessions
        let predicate = #Predicate<RideSession> { session in
            session.isActive == true
        }
        _activeSessions = Query(filter: predicate, sort: \RideSession.startTime, order: .reverse)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text(LocalizationKeys.dashboard.localized)
                }
                .tag(0)
            
            NewRideView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text(LocalizationKeys.newRide.localized)
                }
                .tag(1)
            
            if hasActiveSession {
                CurrentRideView()
                    .tabItem {
                        Image(systemName: "location.fill")
                        Text(LocalizationKeys.currentRide.localized)
                    }
                    .tag(2)
            }
            
//            UserProfileView()
//                .tabItem {
//                    Image(systemName: "person.circle.fill")
//                    Text(LocalizationKeys.profile.localized)
//                }
//                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(LocalizationKeys.settings.localized)
                }
                .tag(4)
        }
        .onAppear {
            // Fix transparent tab bar background
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: hasActiveSession) { _, newValue in
            // Auto-switch to current ride tab when a session starts
            if newValue && selectedTab != 2 {
                selectedTab = 2
            }
            // Switch away from current ride tab when session ends
            else if !newValue && selectedTab == 2 {
                selectedTab = 0
            }
        }
    }
    
    private var hasActiveSession: Bool {
        !activeSessions.isEmpty
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [RideSession.self, LocationPoint.self, UserSettings.self, UserProfile.self], inMemory: true)
}
