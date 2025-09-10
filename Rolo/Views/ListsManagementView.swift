import SwiftUI

// MARK: - UserDefaults Extension for List Order
extension UserDefaults {
    private static let listOrderKey = "customListOrder"
    
    func setListOrder(_ listIds: [UUID]) {
        let stringIds = listIds.map { $0.uuidString }
        set(stringIds, forKey: Self.listOrderKey)
    }
    
    func getListOrder() -> [UUID] {
        guard let stringIds = array(forKey: Self.listOrderKey) as? [String] else {
            return []
        }
        return stringIds.compactMap { UUID(uuidString: $0) }
    }
}

struct ListsManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var availableLists: [MemberList]
    
    @State private var showingCreateListSheet = false
    @State private var newListName = ""
    @State private var newListDescription = ""
    @State private var listCreationError: String?
    @State private var editMode: EditMode = .inactive
    @State private var orderedLists: [MemberList] = []
    
    // Preset lists (only Membership, All is removed)
    private let presetLists = [
        MemberList(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            communityId: UUID(),
            name: "Membership (Preset)",
            description: "Members with active membership",
            color: "#007AFF",
            emoji: nil,
            isDefault: true,
            createdBy: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            memberCount: 0
        )
    ]
    
    // Combined lists for display with custom ordering
    private var allLists: [MemberList] {
        // Start with preset lists (always first)
        var combinedLists = presetLists
        
        // Add custom lists in the saved order
        for list in orderedLists {
            combinedLists.append(list)
        }
        
        return combinedLists
    }
    
    var body: some View {
        NavigationView {
            List {
                // New List Section
                Section {
                    Button(action: {
                        showingCreateListSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(GlobalTheme.highlightGreen)
                            Text("New List")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                
                // All Lists Section (Preset + Custom)
                Section {
                    ForEach(allLists) { list in
                        ListManagementRowView(list: list, isPreset: list.isDefault)
                    }
                    .onMove(perform: moveLists)
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode == .active ? "Done" : "Reorder") {
                        withAnimation {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    }
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
            loadOrderedLists()
        }
        .onDisappear {
            // Ensure we save the current order when leaving the view
            saveOrderedLists()
        }
        .onChange(of: orderedLists) {
            saveOrderedLists()
            // Update the binding to reflect the new order
            availableLists = orderedLists
        }
    }
    
    private func moveLists(from source: IndexSet, to destination: Int) {
        // Adjust indices to account for preset lists
        let adjustedSource = IndexSet(source.map { $0 - presetLists.count })
        let adjustedDestination = destination - presetLists.count
        
        // Only move if we're moving custom lists (not preset)
        if adjustedDestination >= 0 {
            orderedLists.move(fromOffsets: adjustedSource, toOffset: adjustedDestination)
        }
    }
    
    private func loadOrderedLists() {
        let customOrder = UserDefaults.standard.getListOrder()
        
        // Start with custom lists in the saved order
        var loadedLists: [MemberList] = []
        for listId in customOrder {
            if let list = availableLists.first(where: { $0.id == listId }) {
                loadedLists.append(list)
            }
        }
        
        // Add any new lists that aren't in the saved order yet
        let orderedIds = Set(loadedLists.map { $0.id })
        for list in availableLists {
            if !orderedIds.contains(list.id) {
                loadedLists.append(list)
            }
        }
        
        orderedLists = loadedLists
    }
    
    private func saveOrderedLists() {
        let customListIds = orderedLists.map { $0.id }
        UserDefaults.standard.setListOrder(customListIds)
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
        guard !availableLists.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
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
        
        availableLists.append(newList)
        orderedLists.append(newList)
        
        // Reset form
        newListName = ""
        newListDescription = ""
        showingCreateListSheet = false
    }
}

// MARK: - List Management Row View
struct ListManagementRowView: View {
    let list: MemberList
    let isPreset: Bool
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var editListName = ""
    @State private var editListDescription = ""
    @State private var listEditError: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = list.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(list.memberCount ?? 0) members")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isPreset {
                Button(action: {
                    editListName = list.name
                    editListDescription = list.description ?? ""
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(GlobalTheme.highlightGreen)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isPreset {
                editListName = list.name
                editListDescription = list.description ?? ""
                showingEditSheet = true
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditListSheet(
                listName: $editListName,
                listDescription: $editListDescription,
                errorMessage: $listEditError,
                onSave: {
                    updateList()
                },
                onDelete: {
                    showingDeleteConfirmation = true
                }
            )
        }
        .alert("Delete List", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteList()
            }
        } message: {
            Text("Are you sure you want to delete this list? This action cannot be undone.")
        }
    }
    
    private func updateList() {
        // TODO: Implement update functionality
        showingEditSheet = false
    }
    
    private func deleteList() {
        // TODO: Implement delete functionality
        showingEditSheet = false
        showingDeleteConfirmation = false
    }
}

#if DEBUG
struct ListsManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ListsManagementView(availableLists: .constant([]))
    }
}
#endif
