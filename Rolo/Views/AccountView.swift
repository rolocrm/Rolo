//
//  AccountView.swift
//  Rolo
//
//  Created by tsuriel.eichenstein on 7/30/25.
//

import SwiftUI


struct AccountView: View {
    @ObservedObject var authService: AuthService
    @Binding var showingEditCommunity: Bool
    
    @State private var showProfileMenu = false
    @State private var showEditProfile = false
    @State private var editedFirstName = ""
    @State private var editedLastName = ""
    @State private var editedPhoneNumber = ""
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                        if let profile = authService.currentUserProfile,
                           let avatarUrl = profile.avatarUrl,
                           !avatarUrl.isEmpty {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                        }
                    
                    if let profile = authService.currentUserProfile {
                        Text("\(profile.firstName) \(profile.lastName)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 20)
                
                // Account Options
                VStack(spacing: 16) {
                    Button(action: {
                        if let profile = authService.currentUserProfile {
                            editedFirstName = profile.firstName
                            editedLastName = profile.lastName
                            editedPhoneNumber = profile.phoneNumber ?? ""
                        }
                        showEditProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(GlobalTheme.brandPrimary)
                            Text("Edit Profile")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    Button(action: {
                        showingEditCommunity = true
                    }) {
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(GlobalTheme.brandPrimary)
                            Text("Edit Community")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Log Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(
                authService: authService,
                firstName: $editedFirstName,
                lastName: $editedLastName,
                phoneNumber: $editedPhoneNumber,
                isPresented: $showEditProfile
            )
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task {
                    do {
                        try await authService.signOut()
                    } catch {
                        print("❌ Logout error: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

#Preview {
    AccountView(
        authService: {
            let service = AuthService()
            // Mock user profile for preview
            service.currentUserProfile = UserProfile(
                userId: UUID(),
                firstName: "Tsuriel",
                lastName: "Eichenstein",
                phoneNumber: "+1234567890",
                avatarUrl: nil,
                completedProfile: true,
                createdAt: Date(),
                updatedAt: Date()
            )
            return service
        }(),
        showingEditCommunity: .constant(false)
    )
}



