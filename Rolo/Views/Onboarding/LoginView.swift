import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthService
    let onStepChange: (OnboardingStep) -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo/Header
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to Rolo")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Login Form
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
                            .textContentType(.password)
                    }
                    
                    // Forgot Password Link
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            onStepChange(.forgotPassword)
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Login Button
                    Button(action: handleLogin) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Log In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                    
                    // Google Sign In Button
                    Button(action: handleGoogleSignIn) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Log in with Google")
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
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign Up") {
                        onStepChange(.signup)
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
    
    private func handleLogin() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                authService.setError(error)
            }
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                authService.setError(error)
            }
        }
    }
} 