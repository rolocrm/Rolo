import SwiftUI
import PhotosUI
import Supabase

struct ProfileSetupView: View {
    @ObservedObject var authService: AuthService
    let onStepChange: (OnboardingStep) -> Void
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var avatarUrl = ""
    @State private var showError = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploadingImage = false
    
    var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                    
                    Text("Set Up Your Profile")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Tell us a bit about yourself")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Profile Form
                VStack(spacing: 20) {
                    // Avatar Section
                    VStack(spacing: 12) {
                        Text("Profile Photo (Optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                if let selectedImageData = selectedImageData,
                                   let uiImage = UIImage(data: selectedImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else if !avatarUrl.isEmpty {
                                    AsyncImage(url: URL(string: avatarUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.gray)
                                }
                                
                                if isUploadingImage {
                                    Color.black.opacity(0.5)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                    
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        }
                        .disabled(isUploadingImage)
                    }
                    
                    // Name Fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("First Name")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            TextField("Enter your first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.givenName)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Last Name")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            TextField("Enter your last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.familyName)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your phone number", text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Action Button
                Button(action: handleCreateProfile) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Create Profile")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.purple : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || authService.isLoading || isUploadingImage)
                .padding(.horizontal, 20)
                
                // Debug Button (temporary)
                Button(action: handleDebugProfileCreation) {
                    Text("Debug: Create Profile with Test Data")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(authService.isLoading)
                .padding(.horizontal, 20)
                
                // Debug Button 2 (temporary)
                Button(action: handleDebugProfileLoading) {
                    Text("Debug: Test Profile Loading")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(authService.isLoading)
                .padding(.horizontal, 20)
                
                // Debug Button 3 (temporary)
                Button(action: handleDebugDatabaseTest) {
                    Text("Debug: Test Database Connection")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(authService.isLoading)
                .padding(.horizontal, 20)
                
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
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let newValue = newValue {
                    await handleImageSelection(newValue)
                }
            }
        }
    }
    
    private func handleImageSelection(_ item: PhotosPickerItem) async {
        isUploadingImage = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    selectedImageData = data
                }
                
                // Upload image to Supabase Storage
                let uploadedUrl = try await uploadImageToSupabase(data)
                
                await MainActor.run {
                    avatarUrl = uploadedUrl
                    isUploadingImage = false
                }
            }
        } catch {
            await MainActor.run {
                isUploadingImage = false
                authService.setError("Failed to upload image: \(error.localizedDescription)")
            }
        }
    }
    
    private func uploadImageToSupabase(_ imageData: Data) async throws -> String {
        guard let currentUser = try? await supabase.auth.user() else {
            throw SupabaseError.authError("No authenticated user")
        }
        
        // Organize files by user ID and add timestamp
        let fileName = "\(currentUser.id.uuidString)/avatar_\(Date().timeIntervalSince1970).jpg"
        
        do {
            _ = try await supabase.storage
                .from("avatars")
                .upload(
                    fileName,
                    data: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true  // Allow overwriting existing files
                    )
                )
            
            // Get the public URL
            let publicURL = try supabase.storage
                .from("avatars")
                .getPublicURL(path: fileName)
            
            return publicURL.absoluteString
        } catch {
            print("❌ Image upload error: \(error)")
            throw error
        }
    }
    
    private func handleCreateProfile() {
        Task {
            do {
                try await authService.createUserProfile(
                    firstName: firstName,
                    lastName: lastName,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                    avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl
                )
                onStepChange(.welcome)
            } catch {
                authService.setError(error)
            }
        }
    }
    
    private func handleDebugProfileCreation() {
        Task {
            do {
                try await authService.createUserProfile(
                    firstName: "Debug",
                    lastName: "User",
                    phoneNumber: "123-456-7890",
                    avatarUrl: nil
                )
                onStepChange(.welcome)
            } catch {
                authService.setError(error)
            }
        }
    }
    
    private func handleDebugProfileLoading() {
        Task {
            do {
                try await authService.loadCurrentUserProfile()
                print("✅ Debug: Profile loading completed successfully")
            } catch {
                print("❌ Debug: Profile loading failed: \(error)")
                authService.setError(error)
            }
        }
    }
    
    private func handleDebugDatabaseTest() {
        Task {
            await authService.debugTestDatabaseConnection()
        }
    }
} 