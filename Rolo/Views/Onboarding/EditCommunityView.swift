import SwiftUI
import PhotosUI
import Supabase

struct EditCommunityView: View {
    @ObservedObject var authService: AuthService
    @Binding var isPresented: Bool
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    // Community data
    @State private var handle = ""
    @State private var name = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var taxId = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var country = ""
    @State private var logoUrl = ""
    
    // Handle validation
    @State private var isCheckingHandle = false
    @State private var handleAvailable = true
    @State private var handleError = ""
    
    // Logo upload
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploadingImage = false
    
    // Current community
    @State private var currentCommunity: Community?
    
    var isFormValid: Bool {
        !handle.isEmpty && handle.count >= 3 &&
        !name.isEmpty &&
        !email.isEmpty && email.contains("@") &&
        !phoneNumber.isEmpty &&
        handleAvailable
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        // Community Logo Section
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                ZStack {
                                    if let selectedImageData = selectedImageData,
                                       let uiImage = UIImage(data: selectedImageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else if !logoUrl.isEmpty {
                                        AsyncImage(url: URL(string: logoUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Image(systemName: "building.2.circle.fill")
                                                .font(.system(size: 80))
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            
                            Text("Tap to change logo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Edit Community")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Update your community settings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Basic Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Information")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Community Handle")
                                        .font(.headline)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                
                                HStack {
                                    TextField("community-handle", text: $handle)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .autocapitalization(.none)
                                        .onChange(of: handle) { oldValue, newValue in
                                            let filtered = newValue.lowercased().filter { $0.isLetter || $0.isNumber }
                                            if filtered != newValue {
                                                handle = filtered
                                            }
                                            // Check handle availability
                                            if handle.count >= 3 {
                                                checkHandleAvailability()
                                            } else {
                                                handleAvailable = true
                                                handleError = ""
                                            }
                                        }
                                    
                                    if isCheckingHandle {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else if !handle.isEmpty && handle.count >= 3 {
                                        Image(systemName: handleAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(handleAvailable ? .green : .red)
                                    }
                                }
                                
                                if !handleError.isEmpty {
                                    Text(handleError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else {
                                    Text("Unique, lowercase, no spaces, 3+ characters")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Community Name")
                                        .font(.headline)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField("Enter community name", text: $name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contact Information")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Email")
                                        .font(.headline)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField("Enter email", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Phone Number")
                                        .font(.headline)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField("Enter phone number", text: $phoneNumber)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.phonePad)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tax ID (Optional)")
                                    .font(.headline)
                                TextField("Enter tax ID", text: $taxId)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        // Address Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Address Information")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Address (Optional)")
                                    .font(.headline)
                                TextField("Enter address", text: $address)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("City (Optional)")
                                        .font(.headline)
                                    TextField("Enter city", text: $city)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("State (Optional)")
                                        .font(.headline)
                                    TextField("Enter state", text: $state)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ZIP Code (Optional)")
                                        .font(.headline)
                                    TextField("Enter ZIP", text: $zip)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Country (Optional)")
                                        .font(.headline)
                                    TextField("Enter country", text: $country)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: handleSaveCommunity) {
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
            loadCurrentCommunity()
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
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                successMessage = ""
                showSuccess = false
                isPresented = false
            }
        } message: {
            Text(successMessage)
        }
    }
    
    private func loadCurrentCommunity() {
        Task {
            do {
                let communities = try await authService.getCurrentUserCommunities()
                if let community = communities.first {
                    await MainActor.run {
                        currentCommunity = community
                        handle = community.handle
                        name = community.name
                        email = community.email
                        phoneNumber = community.phoneNumber
                        taxId = community.taxId ?? ""
                        address = community.address ?? ""
                        city = community.city ?? ""
                        state = community.state ?? ""
                        zip = community.zip ?? ""
                        country = community.country ?? ""
                        logoUrl = community.logoUrl ?? ""
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load community: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func checkHandleAvailability() {
        guard let communityId = currentCommunity?.id else { return }
        
        isCheckingHandle = true
        handleError = ""
        
        Task {
            do {
                let available = try await authService.checkHandleAvailability(handle: handle, excludeCommunityId: communityId)
                await MainActor.run {
                    handleAvailable = available
                    if !available {
                        handleError = "This handle is already taken"
                    }
                    isCheckingHandle = false
                }
            } catch {
                await MainActor.run {
                    handleError = "Failed to check handle availability"
                    isCheckingHandle = false
                }
            }
        }
    }
    
    private func handleSaveCommunity() {
        guard let communityId = currentCommunity?.id else {
            errorMessage = "No community found"
            showError = true
            return
        }
        
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                var updates: [String: Any] = [
                    "handle": handle,
                    "name": name,
                    "email": email,
                    "phone_number": phoneNumber
                ]
                
                // Add optional fields only if they have values
                if !taxId.isEmpty {
                    updates["tax_id"] = taxId
                }
                if !address.isEmpty {
                    updates["address"] = address
                }
                if !city.isEmpty {
                    updates["city"] = city
                }
                if !state.isEmpty {
                    updates["state"] = state
                }
                if !zip.isEmpty {
                    updates["zip"] = zip
                }
                if !country.isEmpty {
                    updates["country"] = country
                }
                if !logoUrl.isEmpty {
                    updates["logo_url"] = logoUrl
                }
                
                _ = try await authService.updateCommunity(communityId: communityId, updates: updates)
                
                await MainActor.run {
                    isLoading = false
                    successMessage = "Community updated successfully!"
                    showSuccess = true
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
                    logoUrl = uploadedUrl
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
        guard let _ = try? await supabase.auth.user(),
              let communityId = currentCommunity?.id else {
            throw SupabaseError.authError("No authenticated user or community")
        }
        
        // Organize files by community ID and add timestamp
        let fileName = "community-logos/\(communityId.uuidString)/logo_\(Date().timeIntervalSince1970).jpg"
        
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