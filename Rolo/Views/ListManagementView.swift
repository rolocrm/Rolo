import SwiftUI

struct ListManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var lists: [MemberList] = []
    @State private var showingCreateListSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var newListName = ""
    @State private var newListDescription = ""
    @State private var listCreationError: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading lists...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if lists.isEmpty {
                    EmptyListsView(showingCreateListSheet: $showingCreateListSheet)
                } else {
                    List {
                        ForEach(lists) { list in
                            ListRowView(list: list) {
                                // Edit action
                                editList(list)
                            } onDelete: {
                                // Delete action
                                deleteList(list)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateListSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateListSheet) {
                CreateListSheet(
                    newListName: $newListName,
                    newListDescription: $newListDescription,
                    errorMessage: $listCreationError,
                    onSave: {
                        createNewList()
                    }
                )
            }
            .onAppear {
                loadLists()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func loadLists() {
        isLoading = true
        // TODO: Implement API call to load lists
        // For now, we'll use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            lists = [
                MemberList(
                    id: UUID(),
                    communityId: UUID(),
                    name: "Board Members",
                    description: "Members of the board",
                    color: "#007AFF",
                    emoji: "👥",
                    isDefault: false,
                    createdBy: UUID(),
                    createdAt: Date(),
                    updatedAt: Date(),
                    memberCount: 5
                ),
                MemberList(
                    id: UUID(),
                    communityId: UUID(),
                    name: "Volunteers",
                    description: "Active volunteers",
                    color: "#34C759",
                    emoji: "🤝",
                    isDefault: false,
                    createdBy: UUID(),
                    createdAt: Date(),
                    updatedAt: Date(),
                    memberCount: 12
                )
            ]
            isLoading = false
        }
    }
    
    private func editList(_ list: MemberList) {
        // TODO: Implement edit functionality
    }
    
    private func deleteList(_ list: MemberList) {
        // TODO: Implement delete functionality
        lists.removeAll { $0.id == list.id }
    }
    
    private func createNewList() {
        let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear previous error
        listCreationError = nil
        
        // Validation checks with specific error messages
        guard !trimmedName.isEmpty else {
            listCreationError = "List name cannot be empty"
            return
        }
        guard trimmedName != "All" else {
            listCreationError = "List name 'All' is reserved"
            return
        }
        guard trimmedName != "Membership" else {
            listCreationError = "List name 'Membership' is reserved"
            return
        }
        guard !lists.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
            listCreationError = "A list with this name already exists"
            return
        }
        
        // Check for special characters only (no letters or numbers)
        let hasValidCharacters = trimmedName.rangeOfCharacter(from: CharacterSet.alphanumerics) != nil
        guard hasValidCharacters else {
            listCreationError = "List name must contain at least one letter or number"
            return
        }
        
        let newList = MemberList(
            id: UUID(),
            communityId: UUID(), // This should be the actual community ID
            name: trimmedName,
            description: newListDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newListDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            color: "#007AFF", // Default color
            emoji: nil, // No emoji
            isDefault: false,
            createdBy: UUID(), // This should be the actual user ID
            createdAt: Date(),
            updatedAt: Date(),
            memberCount: 0
        )
        
        lists.append(newList)
        
        // Reset form
        newListName = ""
        newListDescription = ""
        showingCreateListSheet = false
    }
}

// MARK: - Empty Lists View
struct EmptyListsView: View {
    @Binding var showingCreateListSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Lists Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Create your first list to organize members into groups")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingCreateListSheet = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create List")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(GlobalTheme.brandPrimary)
                .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - List Row View
struct ListRowView: View {
    let list: MemberList
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // List icon
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "list.bullet")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            // List info
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = list.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("\(list.memberCount ?? 0) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(GlobalTheme.brandPrimary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(GlobalTheme.brandPrimary.opacity(0.1))
                        )
                }
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
        }
        .padding(.vertical, 8)
        .alert("Delete List", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(list.name)'? This action cannot be undone.")
        }
    }
}

#Preview {
    ListManagementView()
}
