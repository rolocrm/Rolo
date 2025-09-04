//
//  LaunchScreenView.swift
//  Rolo
//
//  Created by tsuriel.eichenstein on 4/1/25.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background color matching your app's theme
            Color("AccentColor")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App icon or logo
                Image("AppIcon")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                
                // App name
                Text("Rolo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
