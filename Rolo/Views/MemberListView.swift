import SwiftUI

// Helper to convert string to ColorTag
func colorTag(from string: String?) -> ColorTag {
    guard let string = string else { return .none }
    return ColorTag(rawValue: string) ?? .none
}

// Load members from placeholder data
let loadedMembers: [Member] = placeholderMembersData.map { dict in
    Member(
        id: dict["id"] as? UUID ?? UUID(),
        name: dict["name"] as? String ?? "",
        colorTag: colorTag(from: dict["colorTag"] as? String),
        email: dict["email"] as? String ?? "",
        isMember: dict["isMember"] as? Bool ?? false,
        membershipAmount: dict["membershipAmount"] as? Double,
        hasProfileImage: dict["hasProfileImage"] as? Bool ?? false,
        profileImageName: dict["profileImageName"] as? String
    )
}

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
    
    // MARK: - Search Logic
    var nameMatches: [Member] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return members.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            return members.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
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
        for field in searchableFields where field.isEnabled {
            let minChars = (field is MembershipAmountSearchableField) ? 1 : 3
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < minChars { continue }
            let matches = members.filter { member in
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
                                MemberFieldResultRow(member: match.member, fieldName: fieldName, fieldValue: match.matchedString, searchText: searchText)
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
                    Button {
                        // to be coded
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
        .onChange(of: selectedMemberIDs) {
            if selectedMemberIDs.isEmpty {
                // Exiting selection mode
            }
        }
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

#if DEBUG
struct MemberListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MemberListView()
        }
    }
}
#endif 
