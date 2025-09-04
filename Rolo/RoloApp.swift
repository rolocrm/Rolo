//
//  RoloApp.swift
//  Rolo
//
//  Created by tsuriel.eichenstein on 4/1/25.
//

import SwiftUI
// TODO: Add Supabase dependency using Swift Package Manager
// 1. In Xcode, go to File > Add Packages
// 2. Enter the URL: https://github.com/supabase-community/supabase-swift
// 3. Select version: Up to Next Major (1.0.0)

@main
struct RoloApp: App {
    @StateObject private var authService = AuthService()
    @State private var isInitializing = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isInitializing {
                    LaunchScreenView()
                        .onAppear {
                            // Wait for authentication check to complete
                            Task {
                                // Give a minimum time for the launch screen to show
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                
                                // Wait for initial authentication check to complete
                                while authService.isLoading {
                                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                                }
                                
                                await MainActor.run {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        isInitializing = false
                                    }
                                }
                            }
                        }
                } else {
                    OnboardingCoordinator(authService: authService)
                }
            }
        }
    }
}
