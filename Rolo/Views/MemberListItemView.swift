import SwiftUI
import UIKit


struct Member: Identifiable, Codable {
    let id: UUID
    let name: String
    let colorTag: ColorTag
    let email: String
    let isMember: Bool
    let membershipAmount: Double?
    let hasProfileImage: Bool
    let profileImageName: String?

    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1) ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
    
    init(
        id: UUID,
        name: String,
        colorTag: ColorTag,
        email: String,
        isMember: Bool,
        membershipAmount: Double?,
        hasProfileImage: Bool,
        profileImageName: String?
    ) {
        self.id = id
        self.name = name
        self.colorTag = colorTag
        self.email = email
        self.isMember = isMember
        self.membershipAmount = membershipAmount
        self.hasProfileImage = hasProfileImage
        self.profileImageName = profileImageName
    }
}

struct MemberListItemView: View {
    let member: Member
    var selected: Bool = false
    var onTap: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil
    @State private var isPressed: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ProfileFromInitials(name: member.name, size: 48, initials: member.initials)
                    .frame(width: 48, height: 48)
                    .aspectRatio(contentMode: .fill)
                
                Image(member.profileImageName ?? "Default Profile Pic icon")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .background(Circle().fill(Color(.sRGB, red: 0.06, green: 0.12, blue: 0.11, opacity: 1)))
                    .opacity(member.hasProfileImage ? 1 : 0)

                // Color tag overlay
                HStack() {
                    Circle()
                        .fill(member.colorTag.color)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white)
                .clipShape(Circle())
                .offset(x: 2, y: 2)
                .opacity(member.colorTag == .none ? 0 : 1)
                // Selected checkmark overlay (always present for layout stability)
                ZStack {
                    Circle()
                        .fill(GlobalTheme.brandPrimary)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(GlobalTheme.tertiaryGreen, lineWidth: 2)
                        )
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(GlobalTheme.highlightGreen)
                }
                .opacity(selected ? 1 : 0)
                .offset(x: 1, y: 1)
            }
            .frame(width: 48, height: 48)
            
            Text(member.name)
                .font(.system(size: 18))
                .foregroundColor(GlobalTheme.brandPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
            
            if member.isMember {
                HStack (spacing: 4) {
                    Image(systemName: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.system(size: 14))
                        .foregroundColor(GlobalTheme.highlightGreen)
                    Text("$\(String(format: "%.0f", member.membershipAmount!))")
                        .font(.footnote)
                        .foregroundColor(GlobalTheme.highlightGreen)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(GlobalTheme.highlightGreen.opacity(0.1))
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(
            selected ? GlobalTheme.tertiaryGreen : (isPressed ? GlobalTheme.roloLightGrey.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0.2, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onLongPress?()
        })
    }
}

//#if DEBUG
//struct MemberListItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        MemberListItemView(member: Member(
//            id: UUID(),
//            name: "James Robin",
//            color: Color(red: 0.83, green: 0.47, blue: 0.37),
//            colorName: "Red",
//            profileImage: nil
//        ))
//        .previewLayout(.sizeThatFits)
//    }
//}
//#endif

#Preview {
    MemberListView()
}





//MARK: slide in Search bar
// spacer to push the list and search bar beneath the overlay
//                Spacer()
//                    .frame(height: 60)
//                LazyVStack(spacing: 0) {
//                    GeometryReader { geo in
//                        Color.clear
//                            .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).minY)
//                            .frame(height: 0)
//                    }
//                    .frame(height: 0)
//                    if isSearchBarRevealed {
//                        CustomSearchBar(text: $searchText)
//                            .transition(.move(edge: .top).combined(with: .opacity))
//                            .padding(.bottom, 8)
//                    }
//                }
