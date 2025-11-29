//
//  NewRideView.swift
//  FreeRideTracker
//
//  Created by Nikos Papadopulos on 19/07/25.
//

import SwiftUI
import SwiftData

struct NewRideView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activeSessions: [RideSession]
    @State private var selectedActivityType: ActivityType = .running
    @State private var customTitle: String = ""
    @State private var showingLocationPermissionAlert = false
    @State private var showingBackgroundPermissionAlert = false
    @State private var isStartingRide = false
    
    init() {
        // Query for active sessions
        let predicate = #Predicate<RideSession> { session in
            session.isActive == true
        }
        _activeSessions = Query(filter: predicate)
    }
    
    var hasActiveSession: Bool {
        !activeSessions.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if hasActiveSession {
                    // Show active session info
                    ActiveSessionBanner(session: activeSessions.first!)
                        .padding(.horizontal)
                } else {
                    // Activity Type Selection
                    VStack(alignment: .leading, spacing: 26) {
                        Text("Choose Activity")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                ForEach(ActivityType.allCases, id: \.self) { activityType in
                                    ActivityTypeCard(
                                        activityType: activityType,
                                        isSelected: selectedActivityType == activityType
                                    ) {
                                        selectedActivityType = activityType
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Custom Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(LocalizationKeys.rideTitle.localized) \(LocalizationKeys.optional.localized)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TextField("\(LocalizationKeys.customTitle.localized)...", text: $customTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Start Button
                    Button(action: startRide) {
                        HStack {
                            if isStartingRide {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                            }
                            
                            Text(isStartingRide ? "\(LocalizationKeys.starting.localized)..." : "\(LocalizationKeys.start.localized) \(selectedActivityType.displayName)")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedActivityType.color)
                        .cornerRadius(12)
                        .shadow(color: selectedActivityType.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(isStartingRide)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Ride")
            .navigationBarTitleDisplayMode(.large)
            .alert("Location Permission Required", isPresented: $showingLocationPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("RideTrack needs location permission to track your rides. Please enable location access in Settings.")
            }
            .alert("Background Location Access", isPresented: $showingBackgroundPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) {
                    isStartingRide = false
                }
            } message: {
                Text("To ensure your ride is tracked continuously, please allow background location access in Settings.")
            }
        }
    }
    
    private func startRide() {
        guard !hasActiveSession else { return }
        
        // Validate custom title if provided
        if !customTitle.isEmpty {
            let trimmedTitle = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedTitle.count > AppConstants.Validation.maxTitleLength {
                AppLogger.warning("Custom title exceeds maximum length", category: .ui)
                customTitle = String(trimmedTitle.prefix(AppConstants.Validation.maxTitleLength))
            }
        }
        
        isStartingRide = true
        
        // Check notification permission but don't block ride start
        // Live Activities are enabled by default
        NotificationManager.shared.checkNotificationPermission { granted in
            if !granted {
                // Request notification permission for future use, but proceed with ride
                NotificationManager.shared.requestNotificationPermission()
            }
        }
        
        // Proceed immediately to location permission check
        checkLocationPermission()
    }
    
    private func checkLocationPermission() {
        let locationManager = LocationManager.shared
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestLocationPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if granted {
                        // After first grant, we might still be 'When In Use'
                        if locationManager.authorizationStatus == .authorizedWhenInUse {
                            self.showingBackgroundPermissionAlert = true
                        } else {
                            self.createAndStartRide()
                        }
                    } else {
                        self.showingLocationPermissionAlert = true
                        self.isStartingRide = false
                    }
                }
            }
        case .denied, .restricted:
            showingLocationPermissionAlert = true
            isStartingRide = false
        case .authorizedWhenInUse:
            // Already authorized for 'When In Use', now ask for 'Always'
            locationManager.requestLocationPermission { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if locationManager.authorizationStatus == .authorizedAlways {
                        self.createAndStartRide()
                    } else {
                        self.showingBackgroundPermissionAlert = true
                    }
                }
            }
        case .authorizedAlways:
            createAndStartRide()
        @unknown default:
            showingLocationPermissionAlert = true
            isStartingRide = false
        }
    }
    
    private func createAndStartRide() {
        // Validate and sanitize title
        let sanitizedTitle: String? = {
            let trimmed = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }()
        
        let newSession = RideSession(activityType: selectedActivityType, title: sanitizedTitle)
        
        modelContext.insert(newSession)
        
        // Start location tracking
        LocationManager.shared.startTracking(for: newSession, with: modelContext)
        
        // Reset form
        customTitle = ""
        isStartingRide = false
        
        // Save context with error handling
        do {
            try modelContext.save()
            AppLogger.info("New ride session created and saved", category: .data)
        } catch {
            AppLogger.error("Failed to save new ride session", error: error, category: .data)
            // Even if save fails, tracking has started, so don't block the user
        }
    }
}

struct ActivityTypeCard: View {
    let activityType: ActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: activityType.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : activityType.color)
                
                Text(activityType.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(isSelected ? activityType.color : Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(activityType.color, lineWidth: isSelected ? 0 : 2)
            )
            .shadow(color: isSelected ? activityType.color.opacity(0.3) : .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActiveSessionBanner: View {
    let session: RideSession
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: session.activityType.icon)
                    .font(.title)
                    .foregroundColor(session.activityType.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active \(session.activityType.displayName)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Started at \(session.startTime.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if session.isPaused {
                    Text("PAUSED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Text("You already have an active ride session. Go to the 'Current Ride' tab to view and control it.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(session.activityType.color, lineWidth: 2)
        )
    }
}


#Preview {
    NewRideView()
        .modelContainer(for: [RideSession.self, LocationPoint.self, UserSettings.self], inMemory: true)
}
