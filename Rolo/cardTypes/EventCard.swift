import SwiftUI

struct EventCard: ExpandableCard {
    let id: UUID
    let title: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let location: String
    let description: String
    let attendees: [String]
    let image: String
    let isCompleted: Bool
    
    var type: CardType { .event }
    
    func expandedView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Time and Location
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                        Text("\(startTime.formatted(date: .omitted, time: .shortened)) - \(endTime.formatted(date: .omitted, time: .shortened))")
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle")
                        Text(location)
                    }
                }
                .foregroundColor(.secondary)
                
                Divider()
                
                // Description
                Text(description)
                    .font(.body)
                    .lineSpacing(4)
                
                // Attendees
                if !attendees.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attendees")
                            .font(.headline)
                        
                        ForEach(attendees, id: \.self) { attendee in
                            HStack {
                                Image(systemName: "person.circle")
                                Text(attendee)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Actions
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Label("Add to Calendar", systemImage: "calendar.badge.plus")
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
struct EventCard_Previews: PreviewProvider {
    static var previews: some View {
        EventCard(
            id: UUID(),
            title: "Board Meeting",
            date: Date(),
            startTime: Date().addingTimeInterval(3600), // 1 hour from now
            endTime: Date().addingTimeInterval(7200),   // 2 hours from now
            location: "Main Conference Room",
            description: "Quarterly board meeting to discuss upcoming projects and budget allocation.",
            attendees: ["John Smith", "Sarah Johnson", "Michael Brown", "Emily Davis"],
            image: "Placeholder member profile 1",
            isCompleted: false
        )
        .expandedView()
    }
} 
