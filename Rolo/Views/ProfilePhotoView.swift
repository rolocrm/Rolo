import SwiftUI

struct ProfileFromInitials: View {
    let name: String
    let size: CGFloat
    let initials: String?
    
    init(name: String, size: CGFloat, initials: String? = nil) {
        self.name = name
        self.size = size
        self.initials = initials
    }
    
    private var displayInitials: String {
        if let initials = initials {
            return initials
        }
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1) ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(GlobalTheme.secondaryGreen)
            
            Text(displayInitials)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(GlobalTheme.highlightGreen)
        }
        .frame(width: size, height: size)
    }
}

struct ProfileFromIcon: View {
    let size: CGFloat
    
    var body: some View {
            Image("Default Profile Pic icon")
                .resizable()
                .aspectRatio(contentMode: .fill)
//                .frame(width: size * 0.6, height: size * 0.6)
        .frame(width: size, height: size)
    }
}

// Preview provider for development
struct ProfilePhotoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Group {
                Text("Profile From Initials")
                    .font(.headline)
                ProfileFromInitials(name: "James Hamilton", size: 100)
                ProfileFromInitials(name: "Sarah", size: 60)
                ProfileFromInitials(name: "David K.", size: 40)
                ProfileFromInitials(name: "", size: 80, initials: "AB")
            }
            
            Divider().padding(.vertical)
            
            Group {
                Text("Profile From Icon")
                    .font(.headline)
                ProfileFromIcon(size: 100)
                ProfileFromIcon(size: 60)
                ProfileFromIcon(size: 40)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
