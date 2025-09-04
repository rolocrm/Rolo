import SwiftUI
import PhotosUI
import Supabase

struct EditProfileView: View {
    @ObservedObject var authService: AuthService
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var phoneNumber: String
    @Binding var isPresented: Bool
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploadingImage = false
    @State private var avatarUrl: String = ""
    
    var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        // Profile Photo Section
                        VStack(spacing: 12) {
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
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.2)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            
                            Text("Tap to change photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Edit Profile")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Update your personal information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter phone number", text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: handleSaveProfile) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? GlobalTheme.brandPrimary : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isLoading)
                        
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Load current avatar URL
            if let profile = authService.currentUserProfile,
               let currentAvatarUrl = profile.avatarUrl {
                avatarUrl = currentAvatarUrl
            }
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let photo = newPhoto {
                Task {
                    await handleImageSelection(photo)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                errorMessage = ""
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSaveProfile() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                try await authService.updateUserProfile(
                    firstName: firstName,
                    lastName: lastName,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                    avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl
                )
                
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
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
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
                showError = true
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
} 