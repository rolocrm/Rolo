import SwiftUI
import PhotosUI
import Supabase

struct CreateCommunityView: View {
    @ObservedObject var authService: AuthService
    let onStepChange: (OnboardingStep) -> Void
    
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
    @State private var collaborators: [CollaboratorEntry] = []
    @State private var showError = false
    
    // Logo upload states
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploadingImage = false
    
    struct CollaboratorEntry: Identifiable, Equatable {
        let id = UUID()
        var fullName = ""
        var email = ""
        var role: UserRole = .viewer
    }
    
    var isFormValid: Bool {
        !handle.isEmpty && handle.count >= 3 &&
        !name.isEmpty &&
        !email.isEmpty && email.contains("@") &&
        !phoneNumber.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Create Community")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Set up your new community")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Test/Demo button for auto-filling form
                    Button(action: fillTestData) {
                        HStack {
                            Image(systemName: "wand.and.rays")
                            Text("Fill Test Data")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 20)
                
                // Community Logo
                VStack(spacing: 12) {
                    Text("Community Logo (Optional)")
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
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else if !logoUrl.isEmpty {
                                AsyncImage(url: URL(string: logoUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "building.2.crop.circle")
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
                    
                    Text("Tap to upload logo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
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
                        
                        TextField("community-handle", text: $handle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .onChange(of: handle) { oldValue, newValue in
                                let filtered = newValue.lowercased().filter { $0.isLetter || $0.isNumber }
                                if filtered != newValue {
                                    handle = filtered
                                }
                            }
                        
                        Text("Unique, lowercase, no spaces, 3+ characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                .padding(.horizontal, 20)
                
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
                        TextField("community@example.com", text: $email)
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
                .padding(.horizontal, 20)
                
                // Address Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Address (Optional)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        TextField("Street Address", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack(spacing: 12) {
                            TextField("City", text: $city)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("State", text: $state)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack(spacing: 12) {
                            TextField("ZIP", text: $zip)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Country", text: $country)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Collaborators Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Collaborators")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: addCollaborator) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        
                        // Test button for adding sample collaborator
                        Button(action: addTestCollaborator) {
                            Image(systemName: "person.badge.plus")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if collaborators.isEmpty {
                        Text("Add collaborators to invite them to your community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(collaborators.indices, id: \.self) { index in
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Collaborator \(index + 1)")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: {
                                        removeCollaborator(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                VStack(spacing: 8) {
                                    TextField("Full Name", text: $collaborators[index].fullName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    TextField("Email", text: $collaborators[index].email)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                    
                                    Picker("Role", selection: $collaborators[index].role) {
                                        ForEach(UserRole.allCases.filter { $0 != .owner }, id: \.self) { role in
                                            Text(role.displayName).tag(role)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: handleCreateCommunity) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Create Community")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.green : Color.gray)
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
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let photo = newPhoto {
                Task {
                    await handleImageSelection(photo)
                }
            }
        }
    }
    
    private func addCollaborator() {
        collaborators.append(CollaboratorEntry())
    }
    
    private func removeCollaborator(at index: Int) {
        collaborators.remove(at: index)
    }
    
    // Auto-fill form with test data for easier testing
    private func fillTestData() {
        handle = "testcorp"
        name = "Test Corporation"
        email = "hello@testcorp.com"
        phoneNumber = "5551234567"
        taxId = "12-3456789"
        address = "123 Test Street"
        city = "Test City"
        state = "CA"
        zip = "12345"
        country = "USA"
    }
    
    // Add a collaborator with test data
    private func addTestCollaborator() {
        let sampleNames = ["John Doe", "Jane Smith", "Mike Johnson", "Sarah Wilson", "David Brown"]
        let sampleEmails = ["john@testcorp.com", "jane@testcorp.com", "mike@testcorp.com", "sarah@testcorp.com", "david@testcorp.com"]
        let roles: [UserRole] = [.admin, .limitedAdmin, .viewer]
        
        let randomIndex = Int.random(in: 0..<sampleNames.count)
        let randomRole = roles.randomElement() ?? .viewer
        
        var newCollaborator = CollaboratorEntry()
        newCollaborator.fullName = sampleNames[randomIndex]
        newCollaborator.email = sampleEmails[randomIndex]
        newCollaborator.role = randomRole
        
        collaborators.append(newCollaborator)
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
                // Handle error silently for now, or show a toast
                print("Failed to upload image: \(error.localizedDescription)")
            }
        }
    }
    
    private func uploadImageToSupabase(_ imageData: Data) async throws -> String {
        do {
            _ = try await supabase.auth.user()
        } catch {
            throw SupabaseError.authError("No authenticated user")
        }
        
        // Create a temporary ID for the community being created
        let tempCommunityId = UUID()
        let fileName = "community-logos/\(tempCommunityId.uuidString)/logo_\(Date().timeIntervalSince1970).jpg"
        
        do {
            _ = try await supabase.storage
                .from("avatars")
                .upload(
                    fileName,
                    data: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true
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
    
    private func handleCreateCommunity() {
        Task {
            do {
                let collaboratorRequests: [CollaboratorRequest] = collaborators.compactMap { collaborator in
                    guard !collaborator.fullName.isEmpty && !collaborator.email.isEmpty else { return nil }
                    return CollaboratorRequest(
                        fullName: collaborator.fullName,
                        email: collaborator.email,
                        role: collaborator.role
                    )
                }
                
                let request = CommunityCreationRequest(
                    handle: handle,
                    name: name,
                    email: email,
                    phoneNumber: phoneNumber,
                    taxId: taxId.isEmpty ? nil : taxId,
                    address: address.isEmpty ? nil : address,
                    city: city.isEmpty ? nil : city,
                    state: state.isEmpty ? nil : state,
                    zip: zip.isEmpty ? nil : zip,
                    country: country.isEmpty ? nil : country,
                    logoUrl: logoUrl.isEmpty ? nil : logoUrl,
                    collaborators: collaboratorRequests
                )
                
                try await authService.createCommunity(request)
                onStepChange(.confirmation)
            } catch {
                authService.setError(error)
            }
        }
    }
} 