import SwiftUI

struct InviteAcceptanceView: View {
    @ObservedObject var authService: AuthService
    let token: String
    let onStepChange: (OnboardingStep) -> Void
    
    @State private var invite: Invite?
    @State private var community: Community?
    @State private var isLoading = true
    @State private var showError = false
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 30) {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading invite details...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let invite = invite, let community = community {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("You've been invited!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You've been invited to join")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Community Details
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        if let logoUrl = community.logoUrl {
                            AsyncImage(url: URL(string: logoUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "building.2.crop.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        } else {
                            Image(systemName: "building.2.crop.circle")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                        }
                        
                        Text(community.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("@\(community.handle)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Role Badge
                    HStack {
                        Image(systemName: "person.badge")
                            .foregroundColor(.blue)
                        Text("Role: \(invite.role.displayName)")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                // Invite Details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("What happens when you accept?")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• You'll gain access to the \(community.name) community")
                        Text("• You'll be able to view and interact based on your \(invite.role.displayName) role")
                        Text("• You can start collaborating with other community members")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: handleAcceptInvite) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Accept Invite")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authService.isLoading)
                    
                    Button("Decline") {
                        // For now, just go back to welcome or dashboard
                        if authService.currentUserProfile?.completedProfile == true {
                            onStepChange(.welcome)
                        } else {
                            onStepChange(.dashboard)
                        }
                    }
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            } else {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                    
                    Text("Invalid Invite")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("This invite link is invalid or has expired")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Continue") {
                        if authService.currentUserProfile?.completedProfile == true {
                            onStepChange(.welcome)
                        } else {
                            onStepChange(.dashboard)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadInviteDetails()
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("Continue") {
                onStepChange(.dashboard)
            }
        } message: {
            Text("Welcome to \(community?.name ?? "the community")! You can now access all community features.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                authService.clearError()
            }
        } message: {
            Text(authService.errorMessage ?? "An unexpected error occurred")
        }
        .onChange(of: authService.errorMessage) { oldValue, newValue in
            showError = newValue != nil
        }
    }
    
    private func loadInviteDetails() {
        Task {
            // For now, we'll need to implement a method to get invite details by token
            // This would require adding a method to AuthService
            isLoading = false
        }
    }
    
    private func handleAcceptInvite() {
        Task {
            do {
                try await authService.acceptInvite(token: token)
                showSuccess = true
                // Navigate to confirmation or dashboard after accepting
                onStepChange(.confirmation)
            } catch {
                authService.setError(error)
            }
        }
    }
} 