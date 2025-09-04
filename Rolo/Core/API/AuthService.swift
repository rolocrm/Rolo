import Foundation
import Combine
import Supabase

class AuthService: ObservableObject {
    @Published var currentUserProfile: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        // Set up session listener for instant authentication state changes
        setupSessionListener()
        
        // Quick check for cached authentication data
        Task {
            await quickCheckCachedAuth()
        }
        
        // Check for existing session when AuthService is initialized
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Session Listener Setup
    
    private func setupSessionListener() {
        // Listen for authentication state changes
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn:
                        self.isAuthenticated = true
                        self.isLoading = false
                        print("✅ Auth state changed: User signed in")
                        
                        // Load user profile
                        Task {
                            try? await self.loadCurrentUserProfile()
                        }
                        
                    case .signedOut:
                        self.isAuthenticated = false
                        self.currentUserProfile = nil
                        self.isLoading = false
                        print("✅ Auth state changed: User signed out")
                        
                        // Clear local profile cache
                        if let session = session {
                            self.clearLocalProfile(userId: session.user.id)
                        }
                        
                    case .tokenRefreshed:
                        self.isAuthenticated = true
                        print("✅ Auth state changed: Token refreshed")
                        
                    case .passwordRecovery:
                        print("✅ Auth state changed: Password recovery")
                        
                    case .mfaChallengeVerified:
                        print("✅ Auth state changed: MFA challenge verified")
                        
                    case .initialSession:
                        print("✅ Auth state changed: Initial session")
                        
                    case .userUpdated:
                        print("✅ Auth state changed: User updated")
                        
                    case .userDeleted:
                        self.isAuthenticated = false
                        self.currentUserProfile = nil
                        self.isLoading = false
                        print("✅ Auth state changed: User deleted")
                        
                    @unknown default:
                        print("✅ Auth state changed: Unknown event")
                    }
                }
            }
        }
    }
    
    // MARK: - Cached Authentication Check
    
    private func checkCachedAuthentication() async -> Bool {
        do {
            // Try to get user from local storage/cache
            let user = try await supabase.auth.user()
            print("✅ Found cached user: \(user.email ?? "Unknown")")
            return true
        } catch {
            print("ℹ️ No cached user found")
            return false
        }
    }
    
    // MARK: - Quick Cached Auth Check
    
    private func quickCheckCachedAuth() async {
        // Quick check for cached user data
        if let cachedProfile = await getCachedProfile() {
            await MainActor.run {
                self.currentUserProfile = cachedProfile
                self.isAuthenticated = true
                print("✅ Quick auth check: Found cached profile for \(cachedProfile.firstName) \(cachedProfile.lastName)")
            }
        }
    }
    
    private func getCachedProfile() async -> UserProfile? {
        do {
            let user = try await supabase.auth.user()
            return loadProfileFromLocalStorage(userId: user.id)
        } catch {
            return nil
        }
    }
    
    // MARK: - Session Management
    
    func checkExistingSession() async {
        print("🔍 Debug: Checking for existing session...")
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // First, try to get the current session (this checks both online and cached)
            let session = try await supabase.auth.session
            
            await MainActor.run {
                isAuthenticated = true
                isLoading = false
                print("✅ Found existing session for user: \(session.user.email ?? "Unknown")")
            }
            
            // Load user profile
            print("🔍 Debug: Loading user profile...")
            try await loadCurrentUserProfile()
            
        } catch {
            // If session check fails, try to get the user from local storage
            print("🔍 Debug: No active session found, checking local storage...")
            
            do {
                // Try to get user from local storage/cache
                let user = try await supabase.auth.user()
                
                await MainActor.run {
                    isAuthenticated = true
                    isLoading = false
                    print("✅ Found cached user: \(user.email ?? "Unknown")")
                }
                
                // Load user profile
                print("🔍 Debug: Loading user profile from cache...")
                try await loadCurrentUserProfile()
                
            } catch {
                await MainActor.run {
                    isAuthenticated = false
                    currentUserProfile = nil
                    isLoading = false
                    print("ℹ️ No cached session found: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            await MainActor.run {
                isLoading = false
                // Set authenticated if session was created immediately
                if result.session != nil {
                    isAuthenticated = true
                    print("✅ Signup successful for: \(email)")
                    print("User ID: \(result.user.id)")
                    print("Email confirmed: \(result.user.emailConfirmedAt != nil)")
                    print("Session: \(result.session != nil ? "Created" : "Pending confirmation")")
                }
            }
            
            // If session was created immediately, load user profile
            if result.session != nil {
                print("🔍 Debug: Session created, attempting to load user profile...")
                do {
                    try await loadCurrentUserProfile()
                    print("🔍 Debug: Profile loading completed after signup")
                } catch {
                    print("⚠️ Debug: Profile loading failed after signup: \(error)")
                    // Don't throw the error here, as signup was successful
                    // The user will be directed to profile setup
                }
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
            }
            
            // Check for rate limiting through error description
            let errorDescription = error.localizedDescription.lowercased()
            let isRateLimit = errorDescription.contains("too many requests") || 
                             errorDescription.contains("rate limit") ||
                             errorDescription.contains("429")
            
            if isRateLimit {
                await MainActor.run {
                    setError("Too many requests. Please wait a moment and try again.")
                }
            } else {
                print("❌ Signup error: \(error)")
                print("Error type: \(type(of: error))")
                throw error
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                isLoading = false
                isAuthenticated = true
                print("✅ Sign in successful for: \(email)")
                print("User ID: \(session.user.id)")
            }
            
            // Load user profile after successful sign in
            try await loadCurrentUserProfile()
            
        } catch {
            await MainActor.run {
                isLoading = false
                print("❌ Sign in error: \(error)")
                print("Error type: \(type(of: error))")
            }
            throw error
        }
    }
    
    func refreshSession() async throws {
        do {
            _ = try await supabase.auth.refreshSession()
            await MainActor.run {
                isAuthenticated = true
                print("✅ Session refreshed successfully")
            }
            try await loadCurrentUserProfile()
        } catch {
            await MainActor.run {
                isAuthenticated = false
                currentUserProfile = nil
                print("❌ Failed to refresh session: \(error)")
            }
            throw error
        }
    }
    
    func signOut() async throws {
        // Get current user ID before signing out to clear local cache
        let currentUserId = try? await supabase.auth.user().id
        
        do {
            try await supabase.auth.signOut()
            
            await MainActor.run {
                isAuthenticated = false
                currentUserProfile = nil
                print("✅ Signed out successfully")
            }
            
            // Clear local profile cache
            if let userId = currentUserId {
                clearLocalProfile(userId: userId)
            }
        } catch {
            print("❌ Sign out error: \(error)")
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            
            await MainActor.run {
                isLoading = false
                print("✅ Password reset email sent to: \(email)")
            }
        } catch {
            await MainActor.run {
                isLoading = false
                print("❌ Password reset error: \(error)")
            }
            throw error
        }
    }
    
    // MARK: - User Profile Methods
    
    func createUserProfile(firstName: String, lastName: String, phoneNumber: String?, avatarUrl: String?) async throws {
        guard let currentUser = try? await supabase.auth.user() else {
            throw SupabaseError.authError("No authenticated user")
        }
        
        // Check session state
        let session = try? await supabase.auth.session
        print("🔍 Debug: Session exists: \(session != nil)")
        print("🔍 Debug: Current user ID: \(currentUser.id)")
        print("🔍 Debug: Current user email: \(currentUser.email ?? "No email")")
        print("🔍 Debug: User ID type: \(type(of: currentUser.id))")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let profileData: [String: Any] = [
            "user_id": currentUser.id.uuidString.lowercased(),  // Convert UUID to lowercase string for JSON to match JWT format
            "first_name": firstName,
            "last_name": lastName,
            "phone_number": phoneNumber as Any,
            "avatar_url": avatarUrl as Any,
            "completed_profile": true
        ]
        
        print("🔍 Debug: Profile data being sent: \(profileData)")
        print("🔍 Debug: user_id value: \(profileData["user_id"] ?? "nil")")
        print("🔍 Debug: user_id type: \(type(of: profileData["user_id"] ?? "nil"))")
        
        // Compare with JWT sub value
        if let session = try? await supabase.auth.session {
            let jwtSub = session.user.id.uuidString.lowercased()
            let profileUserId = profileData["user_id"] as? String
            print("🔍 Debug: JWT sub value: \(jwtSub)")
            print("🔍 Debug: Profile user_id value: \(profileUserId ?? "nil")")
            print("🔍 Debug: Values match: \(jwtSub == (profileUserId ?? ""))")
        }
        
        do {
            print("🔍 Debug: About to send profile creation request...")
            let profiles: [UserProfile] = try await supabaseService.performRequest(
                endpoint: "user_profiles",
                method: "POST",
                body: profileData,
                headers: ["Prefer": "return=representation"]
            )
            
            print("🔍 Debug: Profile creation request completed successfully")
            print("🔍 Debug: Number of profiles returned: \(profiles.count)")
            
            await MainActor.run {
                isLoading = false
                if let profile = profiles.first {
                    currentUserProfile = profile
                    isAuthenticated = true  // Ensure user is marked as authenticated
                    // Store profile locally for offline access
                    self.storeProfileLocally(profile)
                    print("✅ User profile created successfully: \(profile.firstName) \(profile.lastName)")
                } else {
                    print("⚠️ No profile returned from server")
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                print("❌ Profile creation error: \(error)")
                print("❌ Error type: \(type(of: error))")
                if let supabaseError = error as? SupabaseError {
                    print("❌ SupabaseError: \(supabaseError.localizedDescription)")
                }
            }
            throw error
        }
    }
    
    func loadCurrentUserProfile() async throws {
        guard let currentUser = try? await supabase.auth.user() else {
            throw SupabaseError.authError("No authenticated user")
        }
        
        print("🔍 Debug: Loading profile for user: \(currentUser.email ?? "Unknown")")
        print("🔍 Debug: User ID: \(currentUser.id.uuidString)")
        print("🔍 Debug: User ID (lowercase): \(currentUser.id.uuidString.lowercased())")
        
        do {
            let profiles: [UserProfile] = try await supabaseService.performRequest(
                endpoint: "user_profiles?user_id=eq.\(currentUser.id.uuidString.lowercased())"
            )
            
            await MainActor.run {
                if let profile = profiles.first {
                    currentUserProfile = profile
                    // Store profile locally for offline access
                    self.storeProfileLocally(profile)
                    print("✅ User profile loaded: \(profile.firstName) \(profile.lastName)")
                } else {
                    print("⚠️ No user profile found for user: \(currentUser.email ?? "Unknown")")
                }
            }
        } catch {
            print("❌ Failed to load user profile from server: \(error)")
            
            // Try to load from local storage as fallback
            if let cachedProfile = loadProfileFromLocalStorage(userId: currentUser.id) {
                await MainActor.run {
                    currentUserProfile = cachedProfile
                    print("✅ User profile loaded from cache: \(cachedProfile.firstName) \(cachedProfile.lastName)")
                }
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Local Storage Methods
    
    private func storeProfileLocally(_ profile: UserProfile) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(profile) {
            UserDefaults.standard.set(data, forKey: "cached_profile_\(profile.userId.uuidString)")
            print("✅ Profile cached locally for user: \(profile.userId)")
        }
    }
    
    private func loadProfileFromLocalStorage(userId: UUID) -> UserProfile? {
        let key = "cached_profile_\(userId.uuidString)"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        if let profile = try? decoder.decode(UserProfile.self, from: data) {
            print("✅ Profile loaded from local storage for user: \(userId)")
            return profile
        }
        
        return nil
    }
    
    private func clearLocalProfile(userId: UUID) {
        let key = "cached_profile_\(userId.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)
        print("✅ Local profile cleared for user: \(userId)")
    }
    
    // Alias for compatibility with existing views
    func loadUserProfile() async {
        do {
            try await loadCurrentUserProfile()
        } catch {
            print("❌ Failed to load user profile: \(error)")
            setError(error)
        }
    }
    
    func updateUserProfile(firstName: String, lastName: String, phoneNumber: String?, avatarUrl: String? = nil) async throws {
        guard let currentUser = try? await supabase.auth.user() else {
            throw SupabaseError.authError("No authenticated user")
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        var updateData: [String: Any] = [
            "first_name": firstName,
            "last_name": lastName,
            "phone_number": phoneNumber as Any
        ]
        
        // Add avatar URL if provided
        if let avatarUrl = avatarUrl {
            updateData["avatar_url"] = avatarUrl
        }
        
        do {
            let profiles: [UserProfile] = try await supabaseService.performRequest(
                endpoint: "user_profiles?user_id=eq.\(currentUser.id.uuidString.lowercased())",
                method: "PATCH",
                body: updateData,
                headers: ["Prefer": "return=representation"]
            )
            
            await MainActor.run {
                isLoading = false
                if let profile = profiles.first {
                    currentUserProfile = profile
                    // Update local cache
                    self.storeProfileLocally(profile)
                    print("✅ User profile updated successfully")
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                print("❌ Profile update error: \(error)")
            }
            throw error
        }
    }
    
    func signInWithGoogle() async throws {
        // TODO: Implement Google OAuth
        throw SupabaseError.authError("Google sign-in not implemented yet")
    }
    
    func getCurrentUser() async throws -> UUID {
        let user = try await supabase.auth.user()
        return user.id
    }
    
    // MARK: - Community Methods
    
    func createCommunity(_ request: CommunityCreationRequest) async throws {
        let userId = try await getCurrentUser()
        
        print("🔍 Debug: Creating community with user ID: \(userId)")
        
        // Check session state
        let session = try? await supabase.auth.session
        print("🔍 Debug: Session exists: \(session != nil)")
        print("🔍 Debug: Session access token: \(session?.accessToken.prefix(20) ?? "None")...")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let communityData: [String: Any] = [
            "handle": request.handle,
            "name": request.name,
            "email": request.email,
            "phone_number": request.phoneNumber,
            "tax_id": request.taxId as Any,
            "address": request.address as Any,
            "city": request.city as Any,
            "state": request.state as Any,
            "zip": request.zip as Any,
            "country": request.country as Any,
            "logo_url": request.logoUrl as Any,
            "created_by": userId.uuidString.lowercased()  // Convert to lowercase to match JWT format
        ]
        
        print("🔍 Debug: Community data being sent: \(communityData)")
        print("🔍 Debug: created_by value: \(communityData["created_by"] ?? "nil")")
        print("🔍 Debug: created_by type: \(type(of: communityData["created_by"] ?? "nil"))")
        
        // Compare with JWT sub value
        if let session = try? await supabase.auth.session {
            let jwtSub = session.user.id.uuidString.lowercased()
            let createdByString = communityData["created_by"] as? String
            print("🔍 Debug: JWT sub value: \(jwtSub)")
            print("🔍 Debug: created_by string value: \(createdByString ?? "nil")")
            print("🔍 Debug: Values match: \(jwtSub == (createdByString ?? ""))")
        }
        
        do {
            print("🔍 Debug: About to send community creation request...")
            let communities: [Community] = try await supabaseService.performRequest(
                endpoint: "communities",
                method: "POST",
                body: communityData,
                headers: ["Prefer": "return=representation"]
            )
            
            print("🔍 Debug: Community creation request completed successfully")
            print("🔍 Debug: Number of communities returned: \(communities.count)")
            
            guard let community = communities.first else {
                print("❌ Debug: No community returned from creation")
                throw SupabaseError.serverError("No community returned from creation")
            }
            
            print("🔍 Debug: Community created successfully: \(community.name)")
            print("🔍 Debug: Community ID: \(community.id)")
            
            // Add creator as owner
            print("🔍 Debug: About to add creator as owner...")
            try await addCollaborator(
                userId: userId,
                communityId: community.id,
                role: .owner,
                status: .approved
            )
            print("🔍 Debug: Creator added as owner successfully")
            
            // Send invites to collaborators
            if !request.collaborators.isEmpty {
                print("🔍 Debug: About to send \(request.collaborators.count) invites...")
                for collaborator in request.collaborators {
                    do {
                        print("🔍 Debug: Sending invite to \(collaborator.email)...")
                        _ = try await sendInvite(
                            email: collaborator.email,
                            communityId: community.id,
                            role: collaborator.role
                        )
                        print("🔍 Debug: Invite sent successfully to \(collaborator.email)")
                    } catch {
                        print("⚠️ Failed to send invite to \(collaborator.email): \(error)")
                    }
                }
                print("🔍 Debug: All invites processed")
            }
            
            await MainActor.run {
                isLoading = false
                print("✅ Community created successfully: \(community.name)")
            }
            
        } catch {
            print("❌ Debug: Community creation failed with error: \(error)")
            print("❌ Debug: Error type: \(type(of: error))")
            await MainActor.run {
                isLoading = false
                print("❌ Community creation error: \(error)")
                print("❌ Error type: \(type(of: error))")
            }
            throw error
        }
    }
    
    func requestToJoinCommunity(handle: String) async throws {
        let userId = try await getCurrentUser()
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // First find the community by handle
            let communities: [Community] = try await supabaseService.performRequest(
                endpoint: "communities?handle=eq.\(handle)"
            )
            
            guard let community = communities.first else {
                throw SupabaseError.notFound("Community not found")
            }
            
            // Add user as pending collaborator
            try await addCollaborator(
                userId: userId,
                communityId: community.id,
                role: .viewer,
                status: .pending
            )
            
            await MainActor.run {
                isLoading = false
                print("✅ Join request sent for community: \(community.name)")
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                print("❌ Join request error: \(error)")
            }
            throw error
        }
    }
    
    private func addCollaborator(userId: UUID, communityId: UUID, role: UserRole, status: CollaboratorStatus) async throws {
        print("🔍 Debug: addCollaborator - Starting with userId: \(userId), communityId: \(communityId), role: \(role.rawValue)")
        
        let collaboratorData: [String: Any] = [
            "user_id": userId.uuidString.lowercased(),  // Convert UUID to lowercase string for JSON to match JWT format
            "community_id": communityId.uuidString.lowercased(),  // Convert UUID to lowercase string for JSON
            "role": role.rawValue,
            "status": status.rawValue,
            "invited_by": userId.uuidString.lowercased()  // Convert UUID to lowercase string for JSON
        ]
        
        print("🔍 Debug: addCollaborator - Sending data: \(collaboratorData)")
        
        let _: [Collaborator] = try await supabaseService.performRequest(
            endpoint: "collaborators",
            method: "POST",
            body: collaboratorData,
            headers: ["Prefer": "return=representation"]
        )
        
        print("🔍 Debug: addCollaborator - Completed successfully")
    }
    
    func sendInvite(email: String, communityId: UUID, role: UserRole) async throws -> Invite {
        let userId = try await getCurrentUser()
        let token = UUID().uuidString
        let expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        
        let inviteData: [String: Any] = [
            "email": email,
            "community_id": communityId.uuidString,  // Convert UUID to string for JSON
            "role": role.rawValue,
            "token": token,
            "status": InviteStatus.pending.rawValue,
            "invited_by": userId.uuidString,  // Convert UUID to string for JSON
            "expires_at": ISO8601DateFormatter().string(from: expiresAt)
        ]
        
        let invites: [Invite] = try await supabaseService.performRequest(
            endpoint: "invites",
            method: "POST",
            body: inviteData,
            headers: ["Prefer": "return=representation"]
        )
        
        guard let invite = invites.first else {
            throw SupabaseError.serverError("No invite returned from creation")
        }
        
        return invite
    }
    
    func acceptInvite(token: String) async throws {
        let userId = try await getCurrentUser()
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Find the invite by token
            let invites: [Invite] = try await supabaseService.performRequest(
                endpoint: "invites?token=eq.\(token)&status=eq.pending"
            )
            
            guard let invite = invites.first else {
                throw SupabaseError.notFound("Invalid or expired invite")
            }
            
            guard let communityId = invite.communityId else {
                throw SupabaseError.notFound("Invite missing community information")
            }
            
            // Add user as collaborator
            try await addCollaborator(
                userId: userId,
                communityId: communityId,
                role: invite.role,
                status: .approved
            )
            
            // Update invite status to accepted
            let updateData: [String: Any] = ["status": InviteStatus.accepted.rawValue]
            let _: [Invite] = try await supabaseService.performRequest(
                endpoint: "invites?id=eq.\(invite.id.uuidString)",  // Keep as string for query parameter
                method: "PATCH",
                body: updateData
            )
            
            await MainActor.run {
                isLoading = false
                print("✅ Invite accepted successfully")
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                print("❌ Accept invite error: \(error)")
            }
            throw error
        }
    }
    
    func checkUserCommunityAccess() async throws -> Bool {
        guard let currentUser = try? await supabase.auth.user() else {
            throw SupabaseError.authError("No authenticated user")
        }
        
        do {
            let collaborators: [Collaborator] = try await supabaseService.performRequest(
                endpoint: "collaborators?user_id=eq.\(currentUser.id.uuidString.lowercased())&status=eq.approved"
            )
            
            return !collaborators.isEmpty
        } catch {
            print("❌ Failed to check community access: \(error)")
            throw error
        }
    }
    
    // MARK: - Community Update Methods
    
    func checkHandleAvailability(handle: String, excludeCommunityId: UUID? = nil) async throws -> Bool {
        var endpoint = "communities?handle=eq.\(handle)"
        
        // If we're updating an existing community, exclude it from the check
        if let excludeId = excludeCommunityId {
            endpoint += "&id=neq.\(excludeId.uuidString)"
        }
        
        let communities: [Community] = try await supabaseService.performRequest(endpoint: endpoint)
        return communities.isEmpty // Return true if handle is available (no communities found)
    }
    
    func updateCommunity(communityId: UUID, updates: [String: Any]) async throws -> Community {
        let communities: [Community] = try await supabaseService.performRequest(
            endpoint: "communities?id=eq.\(communityId.uuidString)",
            method: "PATCH",
            body: updates,
            headers: ["Prefer": "return=representation"]
        )
        
        guard let updatedCommunity = communities.first else {
            throw SupabaseError.serverError("No community returned from update")
        }
        
        return updatedCommunity
    }
    
    func getCurrentUserCommunities() async throws -> [Community] {
        let userId = try await getCurrentUser()
        
        // Get communities where user is a collaborator
        let collaborators: [Collaborator] = try await supabaseService.performRequest(
            endpoint: "collaborators?user_id=eq.\(userId.uuidString)&status=eq.approved"
        )
        
        // Filter out collaborators with nil communityId and map to UUID strings
        let communityIds = collaborators.compactMap { $0.communityId?.uuidString }
        
        if communityIds.isEmpty {
            return []
        }
        
        // Build query to get communities by IDs
        let idQuery = communityIds.map { "id=eq.\($0)" }.joined(separator: "&or=id=eq.")
        let communities: [Community] = try await supabaseService.performRequest(
            endpoint: "communities?\(idQuery)"
        )
        
        return communities
    }
    
    // MARK: - Utility Methods
    
    func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
    
    func setError(_ error: Error) {
        DispatchQueue.main.async {
            if let supabaseError = error as? SupabaseError {
                self.errorMessage = supabaseError.localizedDescription
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
    }
    
    // MARK: - Debug Methods
    
    func debugTestDatabaseConnection() async {
        print("🔍 Debug: Testing database connection...")
        
        guard let currentUser = try? await supabase.auth.user() else {
            print("❌ Debug: No authenticated user")
            return
        }
        
        print("🔍 Debug: Current user ID: \(currentUser.id.uuidString)")
        print("🔍 Debug: Current user ID (lowercase): \(currentUser.id.uuidString.lowercased())")
        
        // Test 1: Try to read from user_profiles table
        do {
            print("🔍 Debug: Testing user_profiles table read...")
            let profiles: [UserProfile] = try await supabaseService.performRequest(
                endpoint: "user_profiles?user_id=eq.\(currentUser.id.uuidString.lowercased())"
            )
            print("🔍 Debug: Read test successful, found \(profiles.count) profiles")
        } catch {
            print("❌ Debug: Read test failed: \(error)")
        }
        
        // Test 2: Try to create a test profile
        do {
            print("🔍 Debug: Testing user_profiles table write...")
            let testData: [String: Any] = [
                "user_id": currentUser.id.uuidString.lowercased(),
                "first_name": "Test",
                "last_name": "User",
                "phone_number": "123-456-7890",
                "completed_profile": true
            ]
            
            let profiles: [UserProfile] = try await supabaseService.performRequest(
                endpoint: "user_profiles",
                method: "POST",
                body: testData,
                headers: ["Prefer": "return=representation"]
            )
            print("🔍 Debug: Write test successful, created profile: \(profiles.first?.firstName ?? "Unknown")")
        } catch {
            print("❌ Debug: Write test failed: \(error)")
            if let supabaseError = error as? SupabaseError {
                print("❌ Debug: SupabaseError: \(supabaseError.localizedDescription)")
            }
        }
    }
} 