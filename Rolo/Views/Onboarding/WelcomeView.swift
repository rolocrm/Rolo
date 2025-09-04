import SwiftUI

struct WelcomeView: View {
    @ObservedObject var authService: AuthService
    let onStepChange: (OnboardingStep) -> Void
    
    @State private var showProfileMenu = false
    @State private var showEditProfile = false
    @State private var editedFirstName = ""
    @State private var editedLastName = ""
    @State private var editedPhoneNumber = ""
    @State private var showLogoutAlert = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Profile Image and Menu
            HStack {
                Spacer()
                
                Button(action: {
                    showProfileMenu = true
                }) {
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
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    }
                }
                .confirmationDialog("Profile Options", isPresented: $showProfileMenu) {
                    Button("Edit Profile") {
                        if let profile = authService.currentUserProfile {
                            editedFirstName = profile.firstName
                            editedLastName = profile.lastName
                            editedPhoneNumber = profile.phoneNumber ?? ""
                        }
                        showEditProfile = true
                    }
                    
                    Button("Log Out", role: .destructive) {
                        showLogoutAlert = true
                    }
                    
                    Button("Cancel", role: .cancel) { }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Header
            VStack(spacing: 20) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.orange)
                
                if let profile = authService.currentUserProfile {
                    Text("Welcome \(profile.firstName)!")
                        .font(.title)
                        .fontWeight(.bold)
                } else {
                    Text("Welcome!")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Text("What would you like to do?")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action Buttons
            VStack(spacing: 20) {
                Button(action: {
                    onStepChange(.joinCommunity)
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Join a Community")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Enter a community handle to request access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
                
                Button(action: {
                    onStepChange(.createCommunity)
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("Create a Community")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Start your own community and invite others")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.green, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 40)
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
                        onStepChange(.login)
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