import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var authService: AuthService
    let onStepChange: (OnboardingStep) -> Void
    
    @State private var email = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    var isFormValid: Bool {
        !email.isEmpty && email.contains("@")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Oops, Locked Out?")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your email to receive a password reset link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                    }
                    
                    // Info Text
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("What happens next?")
                                .font(.headline)
                        }
                        
                        Text("We'll send you an email with a link to reset your password. Check your inbox and follow the instructions to create a new password.")
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
                    Button(action: handleResetPassword) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.orange : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || authService.isLoading)
                    
                    Button("Back to Login") {
                        onStepChange(.login)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                onStepChange(.login)
            }
        } message: {
            Text("Password reset link sent! Check your email and follow the instructions to reset your password.")
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
    
    private func handleResetPassword() {
        Task {
            do {
                try await authService.resetPassword(email: email)
                showSuccess = true
            } catch {
                authService.setError(error)
            }
        }
    }
} 