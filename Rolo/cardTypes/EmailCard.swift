import SwiftUI

struct EmailCard: ExpandableCard {
    let id: UUID
    let title: String
    let date: Date
    let sender: String
    let subject: String
    let contentBody: String
    let taskDescription: String
    let image: String
    let priority: Bool
    let isCompleted: Bool
    
    var type: CardType { .email }
    
    func expandedView() -> AnyView {
        AnyView(EmailCardExpandedView(card: self))
    }
}

struct EmailCardExpandedView: View {
    let card: EmailCard
    
    @State private var isEditing = false
    // TODO: add edit functionality to the email.
//    @State private var editedSubject: String
//    @State private var editedBodyContent: String
    
    var body: some View {
        VStack(alignment: .leading) {
            // Priority Badge
            if card.priority {
                HStack(spacing: 3) {
                    Text("Priority")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GlobalTheme.roloRed)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(GlobalTheme.roloRed.opacity(0.15))
                .cornerRadius(40)
            }
            
            // Display taskDescription above the box
            Text(card.taskDescription)
                .font(.system(size: 16))
                .foregroundColor(GlobalTheme.roloLight)
                .lineSpacing(4)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)

            Divider()
                .background(GlobalTheme.roloLight.opacity(0.1))
                .padding(.vertical, 8)
            
            // Automated Task Section
            VStack (alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(GlobalTheme.roloLight.opacity(0.6))
                        Text("Automated WhatsApp set for Mon, Feb 16.")
                            .font(.system(size: 12))
                            .foregroundColor(GlobalTheme.roloLight.opacity(0.6))
                        Text("Review")
                            .font(.system(size: 12))
                            .foregroundColor(GlobalTheme.roloLight.opacity(0.6))
                            .underline()
                            .onTapGesture {
                                isEditing = true
                            }
                    }
                    .padding(12)
                    
                    Divider()
                        .background(GlobalTheme.roloLight.opacity(0.1))
                    
                    // Email Content
                    VStack(alignment: .leading, spacing: 24) {
                        Text(card.subject)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.white)
                            .padding(.top, 12)
                        
                        Text(card.contentBody)
                            .font(.system(size: 14))
                            .foregroundColor(Color.white)
                            .lineSpacing(4)
                    }
                    .padding(12)
                }
                .padding(8)
                .background(GlobalTheme.secondaryGreen)
                .cornerRadius(20)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Spacer()
                    RoloPillButton(
                        title: "Skip",
                        backgroundColor: GlobalTheme.secondaryGreen,
                        foregroundColor: GlobalTheme.highlightGreen,
                        action: {}
                    )
                    
                    RoloPillButton(
                        title: "Send now",
                        backgroundColor: GlobalTheme.secondaryGreen,
                        foregroundColor: GlobalTheme.highlightGreen,
                        action: {}
                    )
                }
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Preview Provider
struct EmailCard_Previews: PreviewProvider {
    static var previews: some View {
        EmailCard(
            id: UUID(),
            title: "James H.",
            date: Date(),
            sender: "Meir D.",
            subject: "Checking In",
            contentBody: "Hi James,\n\nHope you're doing well! Just checking in as it's been about 6 months since we last properly connected. How have things been?\n\nBest regards,\n[Your Name]",
            taskDescription: "Follow up: 6 months check-in",
            image: "Placeholder member profile 1",
            priority: false,
            isCompleted: false
        )
        .expandedView()
    }
} 
