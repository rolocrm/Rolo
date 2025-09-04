import SwiftUI

struct SignupView: View {
    @ObservedObject var authService: AuthService
    let onStepChange: (OnboardingStep) -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    
    var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        password.count >= 6 &&
        password == confirmPassword &&
        email.contains("@")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Create Your Account")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Join the Rolo community")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Signup Form
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                        
                        if !password.isEmpty && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Sign Up Button
                    Button(action: handleSignUp) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || authService.isLoading)
                    
                    // Google Sign Up Button
                    Button(action: handleGoogleSignUp) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Sign up with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authService.isLoading)
                }
                .padding(.horizontal, 20)
                
                // Login Link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Log In") {
                        onStepChange(.login)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding(.top, 20)
                
                Spacer()
            }
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
    
    private func handleSignUp() {
        Task {
            do {
                print("🔍 Debug: Starting signup process...")
                try await authService.signUp(email: email, password: password)
                print("🔍 Debug: Signup completed successfully")
                
                // Check if we should navigate to profile setup
                await MainActor.run {
                    if authService.isAuthenticated && authService.currentUserProfile == nil {
                        print("🔍 Debug: User authenticated but no profile, navigating to profile setup")
                        onStepChange(.profileSetup)
                    } else {
                        print("🔍 Debug: User authenticated with profile or not authenticated")
                    }
                }
            } catch {
                print("❌ Debug: Signup failed: \(error)")
                authService.setError(error)
            }
        }
    }
    
    private func handleGoogleSignUp() {
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                authService.setError(error)
            }
        }
    }
} 