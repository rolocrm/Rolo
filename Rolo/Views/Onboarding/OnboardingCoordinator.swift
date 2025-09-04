import SwiftUI

enum OnboardingStep {
    case login
    case signup
    case forgotPassword
    case profileSetup
    case welcome
    case joinCommunity
    case createCommunity
    case inviteAcceptance(token: String)
    case confirmation
    case dashboard
}

struct OnboardingCoordinator: View {
    @ObservedObject var authService: AuthService
    @State private var currentStep: OnboardingStep = .login
    @State private var inviteToken: String?
    @State private var hasCheckedInitialState = false
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .login:
                LoginView(authService: authService, onStepChange: handleStepChange)
                
            case .signup:
                SignupView(authService: authService, onStepChange: handleStepChange)
                
            case .forgotPassword:
                ForgotPasswordView(authService: authService, onStepChange: handleStepChange)
                
            case .profileSetup:
                ProfileSetupView(authService: authService, onStepChange: handleStepChange)
                
            case .welcome:
                WelcomeView(authService: authService, onStepChange: handleStepChange)
                
            case .joinCommunity:
                JoinCommunityView(authService: authService, onStepChange: handleStepChange)
                
            case .createCommunity:
                CreateCommunityView(authService: authService, onStepChange: handleStepChange)
                
            case .inviteAcceptance(let token):
                InviteAcceptanceView(authService: authService, token: token, onStepChange: handleStepChange)
                
            case .confirmation:
                ConfirmationView(authService: authService, onStepChange: handleStepChange)
                
            case .dashboard:
                HomeView(authService: authService)
            }
        }
        .onAppear {
            if !hasCheckedInitialState {
                checkInitialState()
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            print("🔍 Debug: isAuthenticated changed to: \(isAuthenticated)")
            if !hasCheckedInitialState && !authService.isLoading {
                print("🔍 Debug: First time checking initial state")
                checkInitialState()
            } else if hasCheckedInitialState && !isAuthenticated {
                // User logged out, navigate to login screen
                print("🔍 Debug: User logged out, navigating to login")
                currentStep = .login
            } else if hasCheckedInitialState && isAuthenticated {
                print("🔍 Debug: User authenticated, checking profile state")
                // User just authenticated, check if they need profile setup
                if authService.currentUserProfile == nil {
                    print("🔍 Debug: No profile found, going to profile setup")
                    currentStep = .profileSetup
                } else {
                    print("🔍 Debug: Profile found, determining next step")
                    determineNextStep()
                }
            }
        }
        .onChange(of: authService.currentUserProfile) { _, profile in
            print("🔍 Debug: currentUserProfile changed - profile exists: \(profile != nil)")
            if hasCheckedInitialState && authService.isAuthenticated {
                // User profile loaded, determine next step
                print("🔍 Debug: Profile state changed, determining next step")
                determineNextStep()
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    private func handleStepChange(_ newStep: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = newStep
        }
    }
    
    private func checkInitialState() {
        guard !hasCheckedInitialState else { return }
        
        print("🔍 Debug: Checking initial state - isAuthenticated: \(authService.isAuthenticated), isLoading: \(authService.isLoading)")
        
        // Check if user is already authenticated
        if authService.isAuthenticated {
            print("🔍 Debug: User is authenticated, checking profile")
            hasCheckedInitialState = true
            
            // If we already have the profile, determine next step immediately
            if authService.currentUserProfile != nil {
                print("🔍 Debug: Profile already loaded, determining next step")
                determineNextStep()
            } else {
                print("🔍 Debug: No profile loaded yet, waiting for profile to load...")
                // The profile will be loaded via the onChange listener
            }
        } else {
            print("🔍 Debug: User is not authenticated, going to login")
            hasCheckedInitialState = true
            currentStep = .login
        }
    }
    
    private func determineNextStep() {
        print("🔍 Debug: determineNextStep called - currentUserProfile: \(authService.currentUserProfile != nil)")
        
        guard let profile = authService.currentUserProfile else {
            print("🔍 Debug: No profile available, going to profile setup")
            currentStep = .profileSetup
            return
        }
        
        print("🔍 Debug: Profile found - completedProfile: \(profile.completedProfile)")
        
        if profile.completedProfile {
            print("🔍 Debug: User profile is complete, checking community access")
            Task {
                do {
                    let hasAccess = try await authService.checkUserCommunityAccess()
                    await MainActor.run {
                        if hasAccess {
                            print("🔍 Debug: User has community access, going to dashboard")
                            currentStep = .dashboard
                        } else {
                            print("🔍 Debug: User has no community access, going to welcome")
                            currentStep = .welcome
                        }
                    }
                } catch {
                    print("❌ Failed to check community access: \(error)")
                    await MainActor.run {
                        currentStep = .welcome
                    }
                }
            }
        } else {
            print("🔍 Debug: User profile is incomplete, going to profile setup")
            currentStep = .profileSetup
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle invite links
        if url.scheme == "rolo" && url.host == "invite" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let token = components?.queryItems?.first(where: { $0.name == "token" })?.value {
                inviteToken = token
                if authService.isAuthenticated {
                    currentStep = .inviteAcceptance(token: token)
                } else {
                    // Store token and redirect to login
                    currentStep = .login
                }
            }
        }
    }
} 