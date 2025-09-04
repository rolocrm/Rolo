//
//  SupababaseTest.swift
//  Rolo
//
//  Created by tsuriel.eichenstein on 4/30/25.
//

import SwiftUI

struct DataSourceLabel: View {
    let dataSource: HomeViewModel.DataSource
    let isLoading: Bool
    let onReload: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dataSource == .supabase ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            Text(dataSource == .supabase ? "Supabase" : "Placeholder")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Button(action: onReload) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CommunityListView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.communities.isEmpty {
                Text("Loading...")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))
                    .padding()
            } else {
                ForEach(viewModel.communities) { community in
                    Text(community.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(GlobalTheme.brandPrimary)
                        .padding(.vertical, 4)
                }
            }
        }
        .padding()
    }
}

struct UserListView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Profiles:")
                .font(.headline)
            if viewModel.userProfiles.isEmpty {
                Text("Loading user profiles...")
                    .foregroundColor(.gray)
            } else {
                ForEach(viewModel.userProfiles) { userProfile in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userProfile.fullName)
                            .font(.system(size: 16, weight: .medium))
                        if let phone = userProfile.phoneNumber {
                            Text(phone)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
    }
}

struct SupabaseTestPreview: View {
    @StateObject var viewModel = HomeViewModel()
    @State private var isLoading = false

    private let supabaseURL = SupabaseConfig.projectURL
    private let endpoint = "/rest/v1/communities"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Supabase Integration Test")
                            .font(.title)
                            .bold()
                        
                        Text("Testing connection to: \(supabaseURL)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        DataSourceLabel(
                            dataSource: viewModel.dataSource,
                            isLoading: viewModel.isLoading,
                            onReload: {
                                viewModel.refreshData()
                            }
                        )
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Communities
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Communities:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        CommunityListView(viewModel: viewModel)
                    }
                    
                    Divider()
                    
                    // User Profiles
                    UserListView(viewModel: viewModel)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.loadUserProfiles()
        }
    }
}

#Preview {
    SupabaseTestPreview()
}
