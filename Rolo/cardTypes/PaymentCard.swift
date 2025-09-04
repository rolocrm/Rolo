import SwiftUI

struct PaymentCard: ExpandableCard {
    let id: UUID
    let title: String
    let date: Date
    let amount: Decimal
    let recipient: String
    let status: Status
    let notes: String
    let image: String
    let isCompleted: Bool
    
    enum Status: String {
        case pending, completed, failed
    }
    
    var type: CardType { .payment }
    
    func expandedView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Amount and Recipient
                VStack(alignment: .leading, spacing: 8) {
                    Text(amount.formatted(.currency(code: "USD")))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "person.fill")
                        Text(recipient)
                            .font(.headline)
                    }
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Status
                HStack {
                    Image(systemName: statusIcon)
                    Text(status.rawValue.capitalized)
                }
                .foregroundColor(statusColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
                
                // Notes
                Text(notes)
                    .font(.body)
                    .lineSpacing(4)
                
                // Actions
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Label("View Receipt", systemImage: "doc.text")
                    }
                    Button(action: {}) {
                        Label("Contact Support", systemImage: "questionmark.circle")
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }
            .padding()
        )
    }
    
    private var statusIcon: String {
        switch status {
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Preview Provider
struct PaymentCard_Previews: PreviewProvider {
    static var previews: some View {
        PaymentCard(
            id: UUID(),
            title: "Donation Payment",
            date: Date(),
            amount: 100.00,
            recipient: "Yorkville Jewish Centre",
            status: .completed,
            notes: "Monthly donation for synagogue maintenance and community programs.",
            image: "Placeholder member profile 1",
            isCompleted: true
        )
        .expandedView()
    }
} 
