import SwiftUI

struct JoinCommunityView: View {
    @ObservedObject var authService: AuthService
    let onStepChange: (OnboardingStep) -> Void
    
    @State private var communityHandle = ""
    @State private var showError = false
    @State private var showSuccess = false
    
    var isFormValid: Bool {
        !communityHandle.isEmpty && communityHandle.count >= 3
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.2.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Join a Community")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter the community handle to request access")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Community Handle")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter community handle", text: $communityHandle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .onChange(of: communityHandle) { oldValue, newValue in
                                // Ensure lowercase and no spaces
                                let filtered = newValue.lowercased().filter { $0.isLetter || $0.isNumber }
                                if filtered != newValue {
                                    communityHandle = filtered
                                }
                            }
                        
                        Text("Handle must be lowercase, no spaces, 3+ characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Info Box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("What happens next?")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Your request will be sent to the community admins")
                            Text("• You'll be notified when your request is reviewed")
                            Text("• Once approved, you'll have access to the community")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: handleJoinRequest) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Request to Join")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || authService.isLoading)
                    
                    Button("Back") {
                        onStepChange(.welcome)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                onStepChange(.confirmation)
            }
        } message: {
            Text("We sent your request, you'll be notified when approved")
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
    
    private func handleJoinRequest() {
        Task {
            do {
                try await authService.requestToJoinCommunity(handle: communityHandle)
                showSuccess = true
            } catch {
                authService.setError(error)
            }
        }
    }
} 