import SwiftUI
import Supabase

struct TestAuthenticationView: View {
    @State private var email: String = ""
    @State private var password: String = "securePassword"
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    @State private var retryCount = 0
    @State private var isLoading = false
    
    private func signUp() {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                let result = try await supabase.auth.signUp(
                    email: email,
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    let user = result.user
                    successMessage = "✅ Signup successful! User ID: \(user.id)"
                    print("✅ Signup successful for: \(email)")
                    print("User ID: \(user.id)")
                    print("Email confirmed: \(user.emailConfirmedAt != nil)")
                    print("Session: \(result.session != nil ? "Created" : "Pending confirmation")")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    
                    // Check for rate limiting through error description or status codes
                    let errorDescription = error.localizedDescription.lowercased()
                    let isRateLimit = errorDescription.contains("too many requests") || 
                                     errorDescription.contains("rate limit") ||
                                     errorDescription.contains("429")
                    
                    if isRateLimit {
                        // Rate limit error handling
                        let delay = min(60.0, pow(2.0, Double(retryCount)))
                        Task {
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            retryCount += 1
                            
                            if retryCount < 3 {
                                signUp() // Retry
                            } else {
                                errorMessage = "Too many authentication attempts. Please try again later."
                            }
                        }
                    } else {
                        // Handle other types of errors
                        errorMessage = "❌ Signup failed: \(error.localizedDescription)"
                        print("❌ Signup error: \(error)")
                        print("Error type: \(type(of: error))")
                        
                        // Print more detailed error info
                        if let authError = error as? AuthError {
                            print("Auth error: \(authError)")
                        }
                        if let urlError = error as? URLError {
                            print("URL error code: \(urlError.code.rawValue)")
                        }
                        
                        // Check if it's an NSError with status code
                        let nsError = error as NSError
                        print("NSError domain: \(nsError.domain)")
                        print("NSError code: \(nsError.code)")
                        print("NSError userInfo: \(nsError.userInfo)")
                    }
                }
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                let session = try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    successMessage = "✅ Sign in successful! User: \(session.user.email ?? "Unknown")"
                    print("✅ Sign in successful for: \(email)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "❌ Sign in failed: \(error.localizedDescription)"
                    print("❌ Sign in error: \(error)")
                    print("Error type: \(type(of: error))")
                }
            }
        }
    }
    
    private func getCurrentUser() {
        Task {
            do {
                let user = try await supabase.auth.user()
                await MainActor.run {
                    successMessage = "✅ Current user: \(user.email ?? "Unknown")"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "❌ No current user: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await supabase.auth.signOut()
                await MainActor.run {
                    successMessage = "✅ Signed out successfully"
                    errorMessage = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = "❌ Sign out failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("🧪 Auth Test")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: signUp) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text("Sign Up")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(email.isEmpty || isLoading)
                        
                        Button(action: signIn) {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(email.isEmpty || isLoading)
                        
                        HStack(spacing: 12) {
                            Button("Get Current User") {
                                getCurrentUser()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            
                            Button("Sign Out") {
                                signOut()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                    
                    // Success Message
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Debug Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔧 Debug Info:")
                            .font(.headline)
                        Text("Supabase URL: \(supabaseProjectURL)")
                            .font(.caption)
                        Text("API Key: \(String(supabaseAPIKey.prefix(20)))...")
                            .font(.caption)
                        Text("Retry Count: \(retryCount)")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Auth Test")
        }
    }
}

#Preview {
    TestAuthenticationView()
} 