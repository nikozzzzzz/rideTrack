//
//  UserProfileView.swift
//  FreeRideTracker
//
//  Created by RideTrack on 2024-01-01.
//

import SwiftUI
import CloudKit

struct UserProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var localizationManager
    @State private var authManager = iCloudAuthManager.shared
    @State private var showingEditProfile = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if authManager.isLoading {
                        loadingView
                    } else if authManager.isSignedIn {
                        signedInView
                    } else {
                        signInPromptView
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizationKeys.Profile.title.localized)
            .refreshable {
                authManager.refreshAuthStatus()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(userProfile: authManager.userProfile)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage,
                   let imageData = image.jpegData(compressionQuality: 0.8),
                   var profile = authManager.userProfile {
                    profile.profileImageData = imageData
                    authManager.updateUserProfile(profile)
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(LocalizationKeys.Profile.checkingStatus.localized)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Signed In View
    
    private var signedInView: some View {
        VStack(spacing: 24) {
            // Profile Header
            profileHeaderView
            
            // iCloud Status
            iCloudStatusView
            
            // Stats Section
            statsSection
            
            // Quick Actions
            quickActionsSection
            
            // Profile Management
            profileManagementSection
        }
    }
    
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            // Profile Image
            Button(action: { showingImagePicker = true }) {
                Group {
                    if let imageData = authManager.userProfile?.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                )
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .offset(x: 35, y: 35)
                )
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(authManager.userProfile?.displayName ?? LocalizationKeys.Profile.unknownUser.localized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let email = authManager.userProfile?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(LocalizationKeys.Profile.memberSince.localized + " " + 
                     (authManager.userProfile?.dateJoined.formatted(date: .abbreviated, time: .omitted) ?? ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var iCloudStatusView: some View {
        HStack {
            Image(systemName: "icloud.fill")
                .foregroundColor(authManager.statusColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.statusMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let lastSync = authManager.userProfile?.lastSyncDate {
                    Text(LocalizationKeys.Profile.lastSync.localized + " " + lastSync.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(LocalizationKeys.Profile.refresh.localized) {
                authManager.refreshAuthStatus()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationKeys.Profile.statistics.localized)
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ProfileStatCard(
                    title: LocalizationKeys.Profile.totalRides.localized,
                    value: "\(authManager.userProfile?.totalRides ?? 0)",
                    icon: "figure.run",
                    color: .blue
                )
                
                ProfileStatCard(
                    title: LocalizationKeys.Profile.totalDistance.localized,
                    value: authManager.userProfile?.formattedTotalDistance ?? "0 km",
                    icon: "location",
                    color: .green
                )
                
                ProfileStatCard(
                    title: LocalizationKeys.Profile.totalTime.localized,
                    value: authManager.userProfile?.formattedTotalDuration ?? "0h 0m",
                    icon: "clock",
                    color: .orange
                )
                
                ProfileStatCard(
                    title: LocalizationKeys.Profile.activities.localized,
                    value: "\(authManager.userProfile?.preferredActivities.count ?? 0)",
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationKeys.Profile.quickActions.localized)
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                QuickActionRow(
                    title: LocalizationKeys.Profile.editProfile.localized,
                    icon: "person.crop.circle",
                    action: { showingEditProfile = true }
                )
                
                QuickActionRow(
                    title: LocalizationKeys.Profile.syncData.localized,
                    icon: "arrow.triangle.2.circlepath",
                    action: { authManager.refreshAuthStatus() }
                )
                
                QuickActionRow(
                    title: LocalizationKeys.Profile.exportData.localized,
                    icon: "square.and.arrow.up",
                    action: { /* TODO: Implement export */ }
                )
            }
        }
    }
    
    private var profileManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationKeys.Profile.management.localized)
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Toggle(LocalizationKeys.Profile.cloudSync.localized, isOn: .constant(authManager.userProfile?.isCloudSyncEnabled ?? false))
                    .disabled(true) // For now, always enabled when signed in
                
                Divider()
                
                Button(action: {
                    authManager.signOut()
                }) {
                    HStack {
                        Image(systemName: "icloud.slash")
                        Text(LocalizationKeys.Profile.signOut.localized)
                        Spacer()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Sign In Prompt View
    
    private var signInPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text(LocalizationKeys.Profile.notSignedIn.localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(LocalizationKeys.Profile.signInPrompt.localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    authManager.refreshAuthStatus()
                }) {
                    HStack {
                        Image(systemName: "icloud")
                        Text(LocalizationKeys.Profile.checkiCloud.localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text(LocalizationKeys.Profile.openSettings.localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 50)
    }
}

// MARK: - Supporting Views

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(.blue)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    UserProfileView()
        .environment(LocalizationManager.shared)
}