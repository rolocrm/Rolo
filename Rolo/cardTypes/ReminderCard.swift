import SwiftUI

struct ReminderCard: ExpandableCard {
    let id: UUID
    let title: String
    let date: Date
    let dueDate: Date
    let notes: String
    let priority: Priority
    let image: String
    let isCompleted: Bool
    
    enum Priority: String {
        case low, medium, high
    }
    
    var type: CardType { .reminder }
    
    func expandedView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Due Date
                HStack {
                    Image(systemName: "calendar")
                    Text("Due: \(dueDate.formatted(date: .long, time: .shortened))")
                }
                .foregroundColor(.secondary)
                
                Divider()
                
                // Notes
                Text(notes)
                    .font(.body)
                    .lineSpacing(4)
                
                // Priority
                HStack {
                    Image(systemName: priorityIcon)
                    Text(priority.rawValue.capitalized)
                }
                .foregroundColor(priorityColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(priorityColor.opacity(0.1))
                .cornerRadius(8)
                
                // Actions
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Label("Snooze", systemImage: "clock.arrow.circlepath")
                    }
                    Button(action: {}) {
                        Label("Complete", systemImage: "checkmark.circle")
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }
            .padding()
        )
    }
    
    private var priorityIcon: String {
        switch priority {
        case .low: return "arrow.down.circle"
        case .medium: return "arrow.right.circle"
        case .high: return "arrow.up.circle"
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Preview Provider
struct ReminderCard_Previews: PreviewProvider {
    static var previews: some View {
        ReminderCard(
            id: UUID(),
            title: "Follow up with client",
            date: Date(),
            dueDate: Date().addingTimeInterval(86400), // Tomorrow
            notes: "Call to discuss the new project requirements and timeline. Make sure to review the proposal before the call.",
            priority: .high,
            image: "Placeholder member profile 1",
            isCompleted: false
        )
        .expandedView()
    }
} 
