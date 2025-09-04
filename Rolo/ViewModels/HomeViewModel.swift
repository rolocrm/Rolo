import Foundation
import Combine
import SwiftUI

class HomeViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    @Published var agendaTasks: [AgendaTask] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCommunity: Community?
    @Published var communities: [Community] = []
    @Published var dataSource: DataSource = .placeholder
    @Published var userProfiles: [UserProfile] = []
    
    // Track where data is coming from
    enum DataSource {
        case placeholder
        case supabase
    }
    
    init() {
        // For initial use, we'll load placeholder data
        self.agendaTasks = AgendaTask.placeholderAgendaTasks
        
        // Load communities from Supabase if user is authenticated
        loadCommunitiesFromSupabase()
    }
    
    // MARK: - Data Loading Methods
    
    func loadCommunitiesFromSupabase() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let communities: [Community] = try await SupabaseService.shared.performRequest(
                    endpoint: "communities"
                )
                
                await MainActor.run {
                    self.communities = communities
                    self.isLoading = false
                    
                    // Select the first community by default
                    if let firstCommunity = communities.first {
                        self.selectedCommunity = firstCommunity
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to load communities: \(error.localizedDescription)"
                    print("Failed to load communities: \(error)")
                }
            }
        }
    }
    
    func loadUserProfiles() {
        Task {
            do {
                let profiles: [UserProfile] = try await SupabaseService.shared.performRequest(
                    endpoint: "user_profiles"
                )
                
                await MainActor.run {
                    self.userProfiles = profiles
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load user profiles: \(error.localizedDescription)"
                }
                print("Failed to load user profiles: \(error)")
            }
        }
    }
    
    // MARK: - Community Selection
    
    func selectCommunity(_ community: Community) {
        selectedCommunity = community
        // Future: Load community-specific data here
    }
    
    // MARK: - Card Action Methods
    
    func pinToggle(agendaTask: AgendaTask) {
        if let index = findIndex(for: agendaTask) {
            var updatedAgendaTask = agendaTask
            updatedAgendaTask.priority.toggle()
            agendaTasks[index] = updatedAgendaTask
            
            // TODO: Update in Supabase when agenda task storage is implemented
        }
    }
    
    func delete(agendaTask: AgendaTask) {
        if let index = findIndex(for: agendaTask) {
            var updatedAgendaTask = agendaTask
            updatedAgendaTask.isDeleted.toggle()
            agendaTasks[index] = updatedAgendaTask
            
            // TODO: Update in Supabase when agenda task storage is implemented
        }
    }
    
    func complete(agendaTask: AgendaTask) {
        if let index = findIndex(for: agendaTask) {
            var updatedAgendaTask = agendaTask
            updatedAgendaTask.completed.toggle()
            agendaTasks[index] = updatedAgendaTask
            
            // TODO: Update in Supabase when agenda task storage is implemented
        }
    }
    
    // MARK: - Helper Methods
    
    private func findIndex(for agendaTask: AgendaTask) -> Int? {
        return agendaTasks.firstIndex { $0.id == agendaTask.id }
    }
    
    // MARK: - Refresh Data
    
    func refreshData() {
        loadCommunitiesFromSupabase()
        loadUserProfiles()
    }
} 
