import Foundation
import SwiftUI


// MARK: Agenda data
public struct AgendaTask: Identifiable {
    public let id: UUID = UUID()
    public var name: String
    public var taskDescription: String
    public var contentBody: String?
    public var subject: String?
    public var image: String
    public let phone: String?
    public let email: String?
    public var priority: Bool
    public var type: CardType
    public var triggerDate: Date
    public let actionDate: Date?
    public var completed: Bool = false
    public var hidden: Bool? = nil
    public var isSelected: Bool = false
    public var isDeleted: Bool = false
    public var isCompleting: Bool = false
    public var shouldRemove: Bool = false
    public var isPinned: Bool = false
    public var isSkipped: Bool = false
    public var actionCompletedOn: Date? = nil
    
    // Computed property to determine if we should use a placeholder
    public var shouldUsePlaceholder: Bool {
        image == "ProfileFromIcon" || image == "ProfileFromInitials" || !image.hasPrefix("Placeholder member profile")
    }
    
    // Computed property to get initials from name
    public var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1) ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
    
    // Computed property to get the profile image view
    public var profileImage: some View {
        if !shouldUsePlaceholder {
            return AnyView(Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill))
        } else if image == "ProfileFromIcon" {
            return AnyView(ProfileFromIcon(size: 48)
                .frame(width: 48, height: 48)
                .aspectRatio(contentMode: .fill))
        } else {
            return AnyView(ProfileFromInitials(name: name, size: 48, initials: initials)
                .frame(width: 48, height: 48)
                .aspectRatio(contentMode: .fill))
        }
    }
    
    public init(name: String, taskDescription: String, contentBody: String? = nil, subject: String? = nil, image: String, phone: String? = nil, email: String? = nil, priority: Bool, type: CardType, triggerDate: Date, actionDate: Date? = nil, completed: Bool = false, hidden: Bool? = nil, isPinned: Bool = false, isSkipped: Bool = false, actionCompletedOn: Date? = nil) {
        self.name = name
        self.taskDescription = taskDescription
        self.contentBody = contentBody
        self.subject = subject
        self.image = image
        self.phone = phone
        self.email = email
        self.priority = priority
        self.type = type
        self.triggerDate = triggerDate
        self.actionDate = actionDate
        self.completed = completed
        self.hidden = hidden
        self.isPinned = isPinned
        self.isSkipped = isSkipped
        self.actionCompletedOn = actionCompletedOn
    }
}

extension AgendaTask {
    public static let placeholderAgendaTasks: [AgendaTask] = {
        // Use Broomfield data for agenda tasks
        return BroomfieldDataLoader.shared.getBroomfieldAgendaTasks()
    }()
    
    // Keep the original placeholder tasks as backup
    public static let originalPlaceholderAgendaTasks: [AgendaTask] = {
        let calendar = Calendar.current
        let today = Date()
        
        // Helper function to create date relative to today
        func createDate(daysFromToday: Int) -> Date {
            return calendar.date(byAdding: .day, value: daysFromToday, to: today) ?? today
        }
        
        return [
            // --- Today & Near Future --- 
            AgendaTask(
                name: "James H.",
                taskDescription: "Follow up: 6 months check-in",
                contentBody: "Hi James,\n\nHope you're doing well! Just checking in as it's been about 6 months since we last properly connected. How have things been?\n\nBest regards,\n[Your Name]",
                subject: "Checking In",
                image: "Placeholder member profile 1", 
                phone: "+1 (555) 123-4567",
                email: "james.h@email.com",
                priority: false,
                type: .email,
                triggerDate: today,
                actionDate: today.addingTimeInterval(5 * 86400)
            ),
            AgendaTask(
                name: "Michael R.",
                taskDescription: "Call: Follow up on donation",
                image: "Placeholder member profile 4", 
                phone: "+1 (555) 345-6789",
                email: "michael.r@email.com",
                priority: true, 
                type: .payment,
                triggerDate: today,
                actionDate: today
            ),
            // Additional Today Tasks
            AgendaTask(
                name: "Rachel G.",
                taskDescription: "Urgent: Review Shabbat dinner menu",
                image: "ProfileFromIcon",
                phone: "+1 (555) 111-2233",
                email: "rachel.g@email.com",
                priority: true,
                type: .reminder,
                triggerDate: today,
                actionDate: today,
                isPinned: true
            ),
            AgendaTask(
                name: "Youth Group Meeting",
                taskDescription: "Finalize activities schedule",
                image: "ProfileFromIcon",
                priority: true,
                type: .event,
                triggerDate: today,
                actionDate: today.addingTimeInterval(2 * 3600)
            ),
            AgendaTask(
                name: "Donation Campaign",
                taskDescription: "Send thank you notes to recent donors",
                image: "ProfileFromInitials",
                priority: false,
                type: .payment,
                triggerDate: today,
                actionDate: today.addingTimeInterval(4 * 3600)
            ),
            AgendaTask(
                name: "Newsletter Draft",
                taskDescription: "Review monthly newsletter content",
                image: "ProfileFromInitials",
                priority: true,
                type: .reminder,
                triggerDate: today,
                actionDate: today.addingTimeInterval(6 * 3600)
            ),
            AgendaTask(
                name: "Building Maintenance",
                taskDescription: "Schedule HVAC inspection",
                image: "ProfileFromInitials",
                phone: "+1 (555) 999-8877",
                priority: false,
                type: .reminder,
                triggerDate: today,
                actionDate: today.addingTimeInterval(8 * 3600)
            ),

            // --- Overdue Example --- 
            AgendaTask(
                name: "Gala Dinner RSVP",
                taskDescription: "Reminder: Gala Dinner RSVPs overdue",
                image: "Placeholder member profile 2", 
                priority: false, 
                type: .event,
                triggerDate: today.addingTimeInterval(-3 * 86400),
                actionDate: createDate(daysFromToday: -1)
            ),
            
            // --- Upcoming Week --- 
            AgendaTask(
                name: "Sarah H.",
                taskDescription: "Send Birthday Text",
                contentBody: "Happy Birthday, Sarah! 🎉 Hope you have a wonderful day filled with joy and celebration!",
                image: "Placeholder member profile 3", 
                phone: "+1 (555) 234-5678",
                email: "sarah.h@email.com",
                priority: false, 
                type: .text,
                triggerDate: createDate(daysFromToday: 6),
                actionDate: createDate(daysFromToday: 7)
            ),
            // Additional Week Tasks
            AgendaTask(
                name: "Fundraising Committee",
                taskDescription: "Weekly progress review meeting",
                image: "ProfileFromIcon",
                priority: true,
                type: .event,
                triggerDate: createDate(daysFromToday: 3),
                actionDate: createDate(daysFromToday: 3),
                isPinned: true
            ),
            AgendaTask(
                name: "Security System",
                taskDescription: "Annual security system review",
                image: "ProfileFromIcon",
                priority: true,
                type: .reminder,
                triggerDate: createDate(daysFromToday: 4),
                actionDate: createDate(daysFromToday: 4)
            ),
            AgendaTask(
                name: "Community Outreach",
                taskDescription: "Follow up with new families",
                image: "ProfileFromInitials",
                priority: false,
                type: .email,
                triggerDate: createDate(daysFromToday: 5),
                actionDate: createDate(daysFromToday: 5)
            ),
            AgendaTask(
                name: "Kitchen Inspection",
                taskDescription: "Schedule kosher kitchen inspection",
                image: "ProfileFromInitials",
                priority: true,
                type: .reminder,
                triggerDate: createDate(daysFromToday: 6),
                actionDate: createDate(daysFromToday: 6)
            ),
            AgendaTask(
                name: "Volunteer Program",
                taskDescription: "Review volunteer applications",
                image: "ProfileFromInitials",
                priority: false,
                type: .reminder,
                triggerDate: createDate(daysFromToday: 7),
                actionDate: createDate(daysFromToday: 7)
            ),
            
            // --- Upcoming Month --- 
            AgendaTask(
                name: "Board Meeting",
                taskDescription: "Prep for Board Meeting",
                image: "Placeholder member profile 5", 
                priority: true,
                type: .event,
                triggerDate: createDate(daysFromToday: 20),
                actionDate: createDate(daysFromToday: 21)
            ),
            AgendaTask(
                name: "Elena T.",
                taskDescription: "Reminder: Elena T.'s Birthday Approaching",
                image: "Placeholder member profile 6", 
                priority: false, 
                type: .reminder,
                triggerDate: createDate(daysFromToday: 25),
                actionDate: createDate(daysFromToday: 26)
            ),
            // Additional Month Tasks
            AgendaTask(
                name: "Holiday Planning",
                taskDescription: "Start planning for upcoming holidays",
                image: "ProfileFromIcon",
                priority: true,
                type: .event,
                triggerDate: createDate(daysFromToday: 15),
                actionDate: createDate(daysFromToday: 15),
                isPinned: true
            ),
            AgendaTask(
                name: "Membership Drive",
                taskDescription: "Review membership renewal strategy",
                image: "ProfileFromInitials",
                priority: true,
                type: .reminder,
                triggerDate: createDate(daysFromToday: 18),
                actionDate: createDate(daysFromToday: 18)
            ),
            AgendaTask(
                name: "Budget Review",
                taskDescription: "Quarterly budget review meeting",
                image: "ProfileFromInitials",
                priority: true,
                type: .event,
                triggerDate: createDate(daysFromToday: 22),
                actionDate: createDate(daysFromToday: 22)
            ),
            AgendaTask(
                name: "Education Program",
                taskDescription: "Plan next semester's classes",
                image: "ProfileFromInitials",
                priority: false,
                type: .reminder,
                triggerDate: createDate(daysFromToday: 27),
                actionDate: createDate(daysFromToday: 27)
            ),
            AgendaTask(
                name: "Facility Updates",
                taskDescription: "Review renovation proposals",
                image: "ProfileFromInitials",
                priority: true,
                type: .reminder,
                triggerDate: createDate(daysFromToday: 29),
                actionDate: createDate(daysFromToday: 29)
            ),

            // --- Beyond Month View --- 
            AgendaTask(
                name: "Jonathan D.",
                taskDescription: "Reconnect: Haven't spoken since High Holidays",
                contentBody: "Hi Jonathan, Hope you're having a great week! It feels like a while since the High Holidays, wanted to reach out and see how you're doing.",
                image: "Placeholder member profile 7", 
                priority: true, 
                type: .text,
                triggerDate: createDate(daysFromToday: 35),
                actionDate: createDate(daysFromToday: 36)
            ),
            AgendaTask(
                name: "Annual Picnic",
                taskDescription: "Event Planning: Finalize picnic vendors",
                image: "Placeholder member profile 8", 
                priority: false, 
                type: .event,
                triggerDate: createDate(daysFromToday: 45),
                actionDate: createDate(daysFromToday: 46)
            ),
            
            // --- Completed/Skipped Examples (Might show if filter is off) ---
            AgendaTask(
                name: "Rebecca F.",
                taskDescription: "Birthday Follow-up (Past)",
                image: "Placeholder member profile 9", 
                priority: false, 
                type: .reminder,
                triggerDate: createDate(daysFromToday: -28),
                actionDate: createDate(daysFromToday: -27),
                completed: true,
                actionCompletedOn: createDate(daysFromToday: -27)
            ),
            AgendaTask(
                name: "David K.",
                taskDescription: "Send Thank You Note (Skipped)",
                image: "Placeholder member profile 10", 
                priority: true, 
                type: .payment,
                triggerDate: createDate(daysFromToday: -30),
                actionDate: createDate(daysFromToday: -29),
                isSkipped: true,
                actionCompletedOn: createDate(daysFromToday: -29)
            )
        ]
    }()
} 


// MARK: Member Data

let placeholderMembersData: [[String: Any?]] = [
    ["id": UUID(), "name": "David Cohen", "colorTag": "none", "email": "david.cohen@email.com", "isMember": true, "membershipAmount": 54.0, "hasProfileImage": true, "profileImageName": "Placeholder member profile 1"],
    ["id": UUID(), "name": "Rachel Levi", "colorTag": "blue", "email": "rachel.levi@email.com", "isMember": false, "membershipAmount": nil, "hasProfileImage": true, "profileImageName": "Placeholder member profile 2"],
    ["id": UUID(), "name": "Moshe Goldstein", "colorTag": "green", "email": "moshe.goldstein@email.com", "isMember": true, "membershipAmount": 100.0, "hasProfileImage": true, "profileImageName": "Placeholder member profile 3"],
    ["id": UUID(), "name": "Esther Mizrahi", "colorTag": "yellow", "email": "estherandavi.mizrahi@email.com", "isMember": false, "membershipAmount": nil, "hasProfileImage": true, "profileImageName": "Placeholder member profile 4"],
    ["id": UUID(), "name": "Yosef Ben-Ami", "colorTag": "none", "email": "yosef.benami@email.com", "isMember": true, "membershipAmount": 36.0, "hasProfileImage": false, "profileImageName": "Default Profile Pic icon"],
    ["id": UUID(), "name": "Shira Abramson", "colorTag": "red", "email": "shira.abramson@email.com", "isMember": false, "membershipAmount": nil, "hasProfileImage": false, "profileImageName": "Default Profile Pic icon"],
    ["id": UUID(), "name": "Avi Rosenberg", "colorTag": "none", "email": "avi.rosenberg@email.com", "isMember": false, "membershipAmount": nil, "hasProfileImage": true, "profileImageName": "Placeholder member profile 5"],
    ["id": UUID(), "name": "Leah Katz", "colorTag": "green", "email": "leah.katz@email.com", "isMember": true, "membershipAmount": 72.0, "hasProfileImage": true, "profileImageName": "Placeholder member profile 6"],
    ["id": UUID(), "name": "Noam Shapiro", "colorTag": "none", "email": "noam.shapiro@email.com", "isMember": false, "membershipAmount": nil, "hasProfileImage": false, "profileImageName": "Default Profile Pic icon"],
    ["id": UUID(), "name": "Miriam Azulay", "colorTag": "purple", "email": "miriam.azulay@email.com", "isMember": false, "membershipAmount": nil, "hasProfileImage": true, "profileImageName": "Placeholder member profile 7"]
    // ... (add the rest of your members here, using the same pattern) ...
]

