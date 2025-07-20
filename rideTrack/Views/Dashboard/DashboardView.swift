//
//  DashboardView.swift
//  rideTrack
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RideSession.startTime, order: .reverse) private var rideSessions: [RideSession]
    @State private var searchText = ""
    @State private var selectedActivityFilter: ActivityType?
    
    var filteredSessions: [RideSession] {
        var sessions = rideSessions.filter { !$0.isActive }
        
        if let activityFilter = selectedActivityFilter {
            sessions = sessions.filter { $0.activityType == activityFilter }
        }
        
        if !searchText.isEmpty {
            sessions = sessions.filter { session in
                session.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                session.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return sessions
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistics Header
                if !rideSessions.isEmpty {
                    StatisticsHeaderView(sessions: rideSessions.filter { !$0.isActive })
                        .padding()
                        .background(Color(.systemGroupedBackground))
                }
                
                // Filter and Search
                VStack(spacing: 12) {
                    // Activity Type Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: LocalizationKeys.all.localized,
                                isSelected: selectedActivityFilter == nil
                            ) {
                                selectedActivityFilter = nil
                            }
                            
                            ForEach(ActivityType.allCases, id: \.self) { activityType in
                                FilterChip(
                                    title: activityType.displayName,
                                    isSelected: selectedActivityFilter == activityType,
                                    color: activityType.color
                                ) {
                                    selectedActivityFilter = selectedActivityFilter == activityType ? nil : activityType
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField(LocalizationKeys.searchRides.localized, text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Rides List
                if filteredSessions.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredSessions) { session in
                                NavigationLink(destination: RideDetailView(session: session)) {
                                    RideCardView(session: session)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle(LocalizationKeys.dashboard.localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatisticsHeaderView: View {
    let sessions: [RideSession]
    
    private var totalDistance: Double {
        sessions.reduce(0) { $0 + $1.totalDistance }
    }
    
    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    private var totalRides: Int {
        sessions.count
    }
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: LocalizationKeys.totalDistance.localized,
                value: String(format: "%.1f km", totalDistance / 1000),
                icon: "road.lanes"
            )
            
            StatCard(
                title: LocalizationKeys.totalTime.localized,
                value: formatDuration(totalDuration),
                icon: "clock"
            )
            
            StatCard(
                title: LocalizationKeys.totalRides.localized,
                value: "\(totalRides)",
                icon: "figure.run"
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(LocalizationKeys.noRidesYet.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationKeys.startFirstRide.localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [RideSession.self, LocationPoint.self, UserSettings.self], inMemory: true)
}