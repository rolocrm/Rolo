import SwiftUI

struct TextCard: ExpandableCard {
    let id: UUID
    let title: String
    let date: Date
    let contentBody: String
    let taskDescription: String
    let image: String
    let priority: Bool
    let isCompleted: Bool
    
    var type: CardType { .text }
    
    func expandedView() -> AnyView {
        AnyView(TextCardExpandedView(card: self))
    }
}

struct TextCardExpandedView: View {
    let card: TextCard

    @State private var isEditing = false
    @State private var editedMessage: String

    init(card: TextCard) {
        self.card = card
        _editedMessage = State(initialValue: card.contentBody)
    }

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

            // Content
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
            VStack(alignment: .leading, spacing: 12) {
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

                    // Text Content
                    Text(editedMessage)
                        .font(.system(size: 14))
                        .foregroundColor(GlobalTheme.roloLight)
                        .lineSpacing(4)
                        .padding(12)
                        .onTapGesture {
                            isEditing = true
                        }
                }
                .padding(8)
                .background(GlobalTheme.secondaryGreen)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20
                    )
                )
                .onTapGesture {
                    isEditing = true
                }

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
            }
            .cornerRadius(12)
        }
        .padding(.bottom, 24)
        .sheet(isPresented: $isEditing) {
            EditCardView(
                title: "Reach out",
                description: "Sent out after a 6 month period of time that you haven't been in contact with a member.",
                editTemplate: true,
                text: $editedMessage,
                isEditing: $isEditing,
                onEditTemplate: {
                    // Handle edit template action
                }
            )
        }
    }
}

// MARK: - Preview Provider
struct TextCard_Previews: PreviewProvider {
    static var previews: some View {
        
        TextCardExpandedView(
            card: TextCard(
                id: UUID(),
                title: "Sarah H.",
                date: Date(),
                contentBody: "Happy Birthday, Sarah! 🎉 Hope you have a wonderful day filled with joy and celebration!",
                taskDescription: "Send Birthday Text",
                image: "Placeholder member profile 3",
                priority: false,
                isCompleted: false
            )
        )
    }
}
