import SwiftUI

struct ChecklistCard: ExpandableCard {
    let id: UUID
    let title: String
    let date: Date
    let items: [ChecklistItem]
    let dueDate: Date?
    let image: String
    let isCompleted: Bool
    
    struct ChecklistItem: Identifiable {
        let id = UUID()
        let title: String
        var isCompleted: Bool
    }
    
    var type: CardType { .checklist }
    
    func expandedView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Due Date if available
                if let dueDate = dueDate {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Due: \(dueDate.formatted(date: .long, time: .shortened))")
                    }
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Checklist Items
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(items) { item in
                        HStack {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .secondary)
                            Text(item.title)
                                .strikethrough(item.isCompleted)
                                .foregroundColor(item.isCompleted ? .secondary : .primary)
                        }
                    }
                }
                
                // Progress
                let completedCount = items.filter { $0.isCompleted }.count
                let totalCount = items.count
                let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress")
                        .font(.headline)
                    
                    ProgressView(value: progress)
                        .tint(.green)
                    
                    Text("\(completedCount) of \(totalCount) completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Actions
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Label("Add Item", systemImage: "plus.circle")
                    }
                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }
            .padding()
        )
    }
}

// MARK: - Preview Provider
struct ChecklistCard_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistCard(
            id: UUID(),
            title: "Event Preparation",
            date: Date(),
            items: [
//                ChecklistItem(title: "Book venue", isCompleted: true),
//                ChecklistItem(title: "Send invitations", isCompleted: true),
//                ChecklistItem(title: "Order catering", isCompleted: false),
//                ChecklistItem(title: "Prepare presentation", isCompleted: false),
//                ChecklistItem(title: "Confirm guest list", isCompleted: false)
            ],
            dueDate: Date().addingTimeInterval(7 * 86400), // 7 days from now
            image: "Placeholder member profile 1",
            isCompleted: false
        )
        .expandedView()
    }
} 
