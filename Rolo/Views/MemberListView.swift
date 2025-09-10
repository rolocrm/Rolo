import SwiftUI

// Helper to convert string to ColorTag
func colorTag(from string: String?) -> ColorTag {
    guard let string = string else { return .none }
    return ColorTag(rawValue: string) ?? .none
}

// Load members from Broomfield data
let loadedMembers: [Member] = BroomfieldDataLoader.shared.getBroomfieldMembers()

// MARK: - Searchable Field Protocol and Config
protocol MemberSearchableField {
    var displayName: String { get }
    var isEnabled: Bool { get }
    func value(from member: Member) -> String
}

struct EmailSearchableField: MemberSearchableField {
    let displayName = "Email"
    let isEnabled: Bool = true
    func value(from member: Member) -> String { member.email }
}

struct MembershipAmountSearchableField: MemberSearchableField {
    let displayName = "Memberships"
    let isEnabled: Bool = true
    func value(from member: Member) -> String {
        guard let amount = member.membershipAmount else { return "" }
        // Format as plain string for search (no currency symbol)
        return String(format: "%.2f", amount)
    }
}

// Add more fields in the future by conforming to MemberSearchableField
let searchableFields: [MemberSearchableField] = [
    EmailSearchableField(),
    MembershipAmountSearchableField()
]

struct MemberListView: View {
    @State private var searchText: String = ""
    @State private var members: [Member] = loadedMembers
    
    @State private var isSearchBarRevealed: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedMemberIDs: Set<UUID> = []
    
    @State private var isPresentingAddMember = false
    @State private var selectedMemberForProfile: Member? = nil
    
    // List filtering state
    @State private var availableLists: [MemberList] = BroomfieldDataLoader.shared.getBroomfieldLists()
    @State private var selectedListId: UUID? = nil
    @State private var showingCreateListSheet = false
    @State private var newListName = ""
    @State private var newListDescription = ""
    @State private var listCreationError: String?
    
    // List modification state
    @State private var showingEditListSheet = false
    @State private var editingList: MemberList? = nil
    @State private var editListName = ""
    @State private var editListDescription = ""
    @State private var listEditError: String?
    @State private var showingDeleteConfirmation = false
    
    // Lists management state
    @State private var showingListsManagement = false
    
    // MARK: - Search Logic
    var nameMatches: [Member] {
        let filteredMembers = filterMembersByList(members)
        
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return filteredMembers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            return filteredMembers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    // MARK: - List Filtering Logic
    private func filterMembersByList(_ members: [Member]) -> [Member] {
        guard let selectedListId = selectedListId else {
            // No list selected, show all members
            return members
        }
        
        // Special handling for Membership list
        if selectedListId == UUID(uuidString: "00000000-0000-0000-0000-000000000001") {
            return members.filter { $0.isMember }
        }
        
        // Find the selected list to get its name
        guard let selectedList = availableLists.first(where: { $0.id == selectedListId }) else {
            return []
        }
        
        // Filter by custom list using list name
        let listAssignments = BroomfieldDataLoader.shared.getListAssignments()
        let listName = selectedList.name
        
        // Find the list name in listAssignments (exact match first)
        var memberNamesInList: [String] = []
        
        // Try exact match first
        if let exactMatch = listAssignments[listName] {
            memberNamesInList = exactMatch
        } else {
            // Try case-insensitive match
            for (key, memberNames) in listAssignments {
                if key.lowercased() == listName.lowercased() {
                    memberNamesInList = memberNames
                    break
                }
            }
        }
        
        // If still no match, try partial matching for common variations
        if memberNamesInList.isEmpty {
            let lowerListName = listName.lowercased()
            for (key, memberNames) in listAssignments {
                let lowerKey = key.lowercased()
                // Handle common variations like "Chabad List" vs "chabad"
                if lowerKey.contains(lowerListName) || lowerListName.contains(lowerKey) {
                    memberNamesInList = memberNames
                    break
                }
            }
        }
        
        guard !memberNamesInList.isEmpty else {
            print("DEBUG: No members found for list '\(listName)'. Available list keys: \(Array(listAssignments.keys))")
            return []
        }
        
        let filteredMembers = members.filter { member in
            memberNamesInList.contains(member.name)
        }
        
        print("DEBUG: List '\(listName)' has \(memberNamesInList.count) member names, filtered to \(filteredMembers.count) members")
        
        return filteredMembers
    }
    
    struct FieldMatch {
        let member: Member
        let field: MemberSearchableField
        let matchedString: String
    }
    
    var showFieldMatches: Bool {
        // Only show field matches if any field meets its minimum character requirement
        for field in searchableFields where field.isEnabled {
            if field is MembershipAmountSearchableField {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 1 {
                    return true
                }
            } else {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
                    return true
                }
            }
        }
        return false
    }
    
    var fieldMatches: [String: [FieldMatch]] {
        guard showFieldMatches else { return [:] }
        var result: [String: [FieldMatch]] = [:]
        let filteredMembers = filterMembersByList(members)
        
        for field in searchableFields where field.isEnabled {
            let minChars = (field is MembershipAmountSearchableField) ? 1 : 3
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < minChars { continue }
            let matches = filteredMembers.filter { member in
                field.value(from: member).localizedCaseInsensitiveContains(searchText)
            }.map { member in
                FieldMatch(member: member, field: field, matchedString: field.value(from: member))
            }.sorted { lhs, rhs in
                let lhsFirst = lhs.member.name.components(separatedBy: " ").first ?? lhs.member.name
                let rhsFirst = rhs.member.name.components(separatedBy: " ").first ?? rhs.member.name
                return lhsFirst.localizedCaseInsensitiveCompare(rhsFirst) == .orderedAscending
            }
            if !matches.isEmpty {
                result[field.displayName] = matches
            }
        }
        return result
    }
    
    var isSelectionMode: Bool { !selectedMemberIDs.isEmpty }
    
    var body: some View {
        ZStack(alignment: .top) {
            // ScrollView with top padding for overlay
            ScrollView {
                
                Spacer()
                    .frame(height: 60)
                
                CustomSearchBar(text: $searchText)
                    .padding(.bottom, 8)
                
                // Filter pills
                FilterPillsView(
                    availableLists: $availableLists,
                    selectedListId: $selectedListId,
                    showingCreateListSheet: $showingCreateListSheet
                )
                

                
                

                // Filter indicator
                if selectedListId != nil {
                    HStack {
                        Text("\(nameMatches.count) members")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(GlobalTheme.coloredGrey)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Name matches
                LazyVStack(spacing: 0) {
                    ForEach(nameMatches) { member in
                        let isSelected = selectedMemberIDs.contains(member.id)
                        MemberListItemView(
                            member: member,
                            selected: isSelected,
                            onTap: {
                                if isSelectionMode {
                                    if isSelected {
                                        selectedMemberIDs.remove(member.id)
                                    } else {
                                        selectedMemberIDs.insert(member.id)
                                    }
                                } else {
                                    // Navigate to member profile
                                    selectedMemberForProfile = member
                                }
                            },
                            onLongPress: {
                                if !isSelectionMode {
                                    selectedMemberIDs.insert(member.id)
                                }
                            }
                        )
                    }

                }
                // Field matches (e.g., Email)
                ForEach(Array(fieldMatches.keys.sorted()), id: \.self) { fieldName in
                    if let matches = fieldMatches[fieldName] {
                        Section(header: FieldSectionHeader(title: fieldName)) {
                            ForEach(matches, id: \.member.id) { match in
                                Button(action: {
                                    selectedMemberForProfile = match.member
                                }) {
                                    MemberFieldResultRow(member: match.member, fieldName: fieldName, fieldValue: match.matchedString, searchText: searchText)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                // Show "No results" if searching and no matches
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && nameMatches.isEmpty && fieldMatches.isEmpty {
                    VStack {
                        Spacer(minLength: 40)
                        HStack {
                            Spacer()
                            Text("No results")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.vertical, 40)
                            Spacer()
                        }
                        Spacer(minLength: 40)
                    }
                } else if selectedListId != nil && nameMatches.isEmpty && fieldMatches.isEmpty {
                    // Show message when filter is active but no members match
                    VStack {
                        Spacer(minLength: 40)
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Text("No members in this list")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                                if let selectedList = availableLists.first(where: { $0.id == selectedListId }) {
                                    Text("The '\(selectedList.name)' list is empty")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 40)
                            Spacer()
                        }
                        Spacer(minLength: 40)
                    }
                }
                
                // Modify list button - only show when a list is selected
                if selectedListId != nil, let selectedList = availableLists.first(where: { $0.id == selectedListId }) {
                    VStack {
                        Button(action: {
                            editingList = selectedList
                            editListName = selectedList.name
                            editListDescription = selectedList.description ?? ""
                            showingEditListSheet = true
                        }) {
                            Text("Modify \(selectedList.name)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(GlobalTheme.highlightGreen)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    }
                }
                
                Spacer()
                    .frame(height: 80)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                withAnimation(.easeInOut) {
                    if value > 60 {
                        isSearchBarRevealed = true
                    }
                }
            }
            // Selection header (only when in selection mode)
            if isSelectionMode {
                MemberSelectionHeader(
                    selectedCount: selectedMemberIDs.count,
                    onBack: { selectedMemberIDs.removeAll() },
                    onMore: {
                        // Placeholder for ellipsis action
                    }
                )
            } else {
                // Overlay: Members title and profile image
                HStack {
                    Text("Members")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    Spacer()
                    Menu {
                        Button("Lists") {
                            showingListsManagement = true
                        }
                        // Add other menu items here as needed
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(GlobalTheme.roloLightGrey)
                            .rotationEffect(Angle(degrees: 90))
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(
                    ZStack {
                        Color.white.opacity(0.85) // White overlay for color
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial) // Blur effect
                    }
                )
            }
            
            
            // Floating Add Member Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isPresentingAddMember = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(GlobalTheme.brandPrimary)
                                .frame(width: 60, height: 60)
                            Image(systemName: "plus")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(GlobalTheme.highlightGreen)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .fullScreenCover(isPresented: $isPresentingAddMember) {
            NavigationStack {
                AddNewMemberView()
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
        .sheet(isPresented: $showingEditListSheet) {
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
        .onChange(of: selectedMemberIDs) {
            if selectedMemberIDs.isEmpty {
                // Exiting selection mode
            }
        }
        .sheet(isPresented: $showingListsManagement) {
            ListsManagementView(availableLists: $availableLists)
        }
        .sheet(item: $selectedMemberForProfile) { member in
            NavigationStack {
                MemberProfilePage(member: member)
            }
        }
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
        
        // Reset form
        newListName = ""
        newListDescription = ""
        showingCreateListSheet = false
    }
    
    private func updateList() {
        guard let currentEditingList = editingList else { return }
        let trimmedName = editListName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear previous error
        listEditError = nil
        
        // Validation checks with specific error messages
        guard !trimmedName.isEmpty else {
            listEditError = "List name cannot be empty"
            return
        }
        guard trimmedName != "All" else {
            listEditError = "List name 'All' is reserved"
            return
        }
        guard trimmedName != "Membership" else {
            listEditError = "List name 'Membership' is reserved"
            return
        }
        guard !availableLists.contains(where: { $0.id != currentEditingList.id && $0.name.lowercased() == trimmedName.lowercased() }) else {
            listEditError = "A list with this name already exists"
            return
        }
        
        // Check for special characters only (no letters or numbers)
        let hasValidCharacters = trimmedName.rangeOfCharacter(from: CharacterSet.alphanumerics) != nil
        guard hasValidCharacters else {
            listEditError = "List name must contain at least one letter or number"
            return
        }
        
        // Update the list
        if let index = availableLists.firstIndex(where: { $0.id == currentEditingList.id }) {
            availableLists[index] = MemberList(
                id: currentEditingList.id,
                communityId: currentEditingList.communityId,
                name: trimmedName,
                description: editListDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editListDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                color: currentEditingList.color,
                emoji: currentEditingList.emoji,
                isDefault: currentEditingList.isDefault,
                createdBy: currentEditingList.createdBy,
                createdAt: currentEditingList.createdAt,
                updatedAt: Date(),
                memberCount: currentEditingList.memberCount
            )
        }
        
        // Reset form
        editListName = ""
        editListDescription = ""
        editingList = nil
        showingEditListSheet = false
    }
    
    private func deleteList() {
        guard let currentEditingList = editingList else { return }
        
        // Remove from available lists
        availableLists.removeAll { $0.id == currentEditingList.id }
        
        // If this was the selected list, clear selection
        if selectedListId == currentEditingList.id {
            selectedListId = nil
        }
        
        // Reset form
        editListName = ""
        editListDescription = ""
        editingList = nil
        showingEditListSheet = false
        showingDeleteConfirmation = false
    }
}

// PreferenceKey for scroll offset
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Minimal selection header for member selection
private struct MemberSelectionHeader: View {
    let selectedCount: Int
    let onBack: () -> Void
    let onMore: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 24))
                    .foregroundColor(GlobalTheme.brandPrimary)
            }
            // Selected count
            Text("\(selectedCount)")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(GlobalTheme.brandPrimary)
            Spacer()
            // Only the ellipsis button
            Button(action: onMore) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(GlobalTheme.brandPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(GlobalTheme.tertiaryGreen)
    }
}

// MARK: - Section Header for Fields
private struct FieldSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(GlobalTheme.coloredGrey)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .background(Color.clear)
    }
}

// MARK: - Highlight Helper
private func highlightedText(_ text: String, search: String) -> Text {
    guard !search.isEmpty else { return Text(text).foregroundColor(.gray) }
    let lcText = text.lowercased()
    let lcSearch = search.lowercased()
    var result = Text("")
    var currentIndex = lcText.startIndex
    while let range = lcText.range(of: lcSearch, options: [], range: currentIndex..<lcText.endIndex) {
        let before = String(text[currentIndex..<range.lowerBound])
        if !before.isEmpty {
            result = result + Text(before).foregroundColor(.gray)
        }
        let match = String(text[range])
        result = result + Text(match).bold().foregroundColor(GlobalTheme.brandPrimary)
        currentIndex = range.upperBound
    }
    let after = String(text[currentIndex..<lcText.endIndex])
    if !after.isEmpty {
        result = result + Text(after).foregroundColor(.gray)
    }
    return result
}

// MARK: - Member Field Result Row
private struct MemberFieldResultRow: View {
    let member: Member
    let fieldName: String
    let fieldValue: String
    let searchText: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(member.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(GlobalTheme.coloredGrey)
                    .lineLimit(1)
                if fieldName == "Memberships" {
                    highlightedText("$" + fieldValue, search: searchText)
                        .font(.system(size: 15, weight: .regular))
                        .lineLimit(1)
                } else {
                    highlightedText(fieldValue, search: searchText)
                        .font(.system(size: 15, weight: .regular))
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Filter Pills View
struct FilterPillsView: View {
    @Binding var availableLists: [MemberList]
    @Binding var selectedListId: UUID?
    @Binding var showingCreateListSheet: Bool
    
    // Ordered lists for display (All first, then custom order)
    private var orderedLists: [MemberList] {
        let customOrder = UserDefaults.standard.getListOrder()
        
        // Start with custom lists in the saved order
        var orderedLists: [MemberList] = []
        for listId in customOrder {
            if let list = availableLists.first(where: { $0.id == listId }) {
                orderedLists.append(list)
            }
        }
        
        // Add any new lists that aren't in the saved order yet
        let orderedIds = Set(orderedLists.map { $0.id })
        for list in availableLists {
            if !orderedIds.contains(list.id) {
                orderedLists.append(list)
            }
        }
        
        return orderedLists
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All members pill (always first)
                //spacer to keep the pills aligned to the list
                Spacer()
                    .frame(width: 4)
                
                FilterPill(
                    title: "All",
                    isSelected: selectedListId == nil
                ) {
                    selectedListId = nil
                }
                
                // Membership pill
                FilterPill(
                    title: "Membership",
                    isSelected: selectedListId == UUID(uuidString: "00000000-0000-0000-0000-000000000001") // Special UUID for membership
                ) {
                    selectedListId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
                }
                
                // Custom lists in user's preferred order
                ForEach(orderedLists) { list in
                    FilterPill(
                        title: list.name,
                        isSelected: selectedListId == list.id
                    ) {
                        selectedListId = list.id
                    }
                }
                
                // Create list button
                if availableLists.isEmpty {
                    // Show "Create list" button when no lists exist
                    Button(action: {
                        showingCreateListSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            Text("Create list")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(GlobalTheme.roloDarkGrey)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 100)
                                        .stroke(GlobalTheme.roloLightGrey40, lineWidth: 1)
                                )
                        )
                    }
                } else {
                    // Show "+" button when lists exist
                    Button(action: {
                        showingCreateListSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(GlobalTheme.roloDarkGrey)
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(GlobalTheme.roloLightGrey40, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Filter Pill Component
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .foregroundColor(isSelected ? GlobalTheme.highlightGreen : GlobalTheme.roloDarkGrey)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(isSelected ? GlobalTheme.tertiaryGreen : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(GlobalTheme.roloLightGrey40, lineWidth: isSelected ? 0 : 1)
                        )
                )
        }
    }
}

// MARK: - Edit List Sheet
struct EditListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var listName: String
    @Binding var listDescription: String
    @Binding var errorMessage: String?
    let onSave: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // List name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("List name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Example: Work, Friends", text: $listName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                        .onChange(of: listName) { _ in
                            // Clear error when user starts typing
                            errorMessage = nil
                        }
                }
                
                // Description input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (optional)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Brief description of this list", text: $listDescription)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                // Error message display
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(listName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button("Delete List") {
                        onDelete()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

#if DEBUG
struct MemberListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MemberListView()
        }
    }
}
#endif 
