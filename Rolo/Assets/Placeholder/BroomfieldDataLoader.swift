import Foundation
import SwiftUI

// MARK: - Broomfield Data Models
struct BroomfieldMember: Codable {
    let id: String
    let name: String
    let firstName: String?
    let lastName: String?
    let middleName: String?
    let nickname: String?
    let email: String?
    let phone: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let occupation: String?
    let jewishMemberName: String?
    let motherHebrewName: String?
    let fatherHebrewName: String?
    let aliyaName: String?
    let tribe: String?
    let gender: String?
    let dateOfBirth: String?
    let birthdayPreference: String?
    let memberSince: String?
    let instagram: String?
    let tiktok: String?
    let linkedin: String?
    let facebook: String?
    let webLinks: String?
    let maritalStatus: String?
    let hasChildren: String?
    let householdMembers: String?
    let colorTag: String
    let isMember: Bool
    let membershipAmount: Double?
    let monthlyMembership: String?
    let collectionDay: String?
    let membershipEnds: String?
    let pastDonations: String?
    let paymentMethod: String?
    let metAt: String?
    let occasion: String?
    let eventDate: String?
    let hebrewDate: String?
    let note: String?
    let notes: String?
    let tags: String?
    let apartmentNumber: String?
    let isJewish: String?
    let potentialDuplicate: String?
    let hasProfileImage: Bool
    let profileImageName: String
}

struct BroomfieldList: Codable {
    let id: String
    let name: String
    let description: String
    let color: String
    let emoji: String?
    let memberCount: Int
}

struct BroomfieldData: Codable {
    let members: [BroomfieldMember]
    let lists: [BroomfieldList]
    let listAssignments: [String: [String]]
}

// MARK: - Data Loader
class BroomfieldDataLoader {
    static let shared = BroomfieldDataLoader()
    
    private var cachedData: BroomfieldData?
    
    private init() {}
    
    func loadBroomfieldData() -> BroomfieldData? {
        if let cachedData = cachedData {
            return cachedData
        }
        
        guard let url = Bundle.main.url(forResource: "Rolo - broomfield", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load Broomfield JSON file")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let broomfieldData = try decoder.decode(BroomfieldData.self, from: data)
            cachedData = broomfieldData
            return broomfieldData
        } catch {
            print("Failed to decode Broomfield data: \(error)")
            return nil
        }
    }
    
    func getBroomfieldMembers() -> [Member] {
        guard let data = loadBroomfieldData() else {
            return []
        }
        
        return data.members.map { broomfieldMember in
            Member(
                id: UUID(uuidString: broomfieldMember.id) ?? UUID(),
                name: broomfieldMember.name,
                colorTag: colorTag(from: broomfieldMember.colorTag),
                email: broomfieldMember.email ?? "",
                isMember: broomfieldMember.isMember,
                membershipAmount: broomfieldMember.membershipAmount,
                hasProfileImage: broomfieldMember.hasProfileImage,
                profileImageName: broomfieldMember.profileImageName
            )
        }
    }
    
    func getBroomfieldLists() -> [MemberList] {
        guard let data = loadBroomfieldData() else {
            return []
        }
        
        return data.lists.map { broomfieldList in
            MemberList(
                id: UUID(uuidString: broomfieldList.id) ?? UUID(),
                communityId: UUID(), // Default community ID
                name: broomfieldList.name,
                description: broomfieldList.description,
                color: broomfieldList.color,
                emoji: broomfieldList.emoji,
                isDefault: false,
                createdBy: UUID(), // Default creator ID
                createdAt: Date(),
                updatedAt: Date(),
                memberCount: broomfieldList.memberCount
            )
        }
    }
    
    func getListAssignments() -> [String: [String]] {
        guard let data = loadBroomfieldData() else {
            return [:]
        }
        
        return data.listAssignments
    }
    
    func getBroomfieldAgendaTasks() -> [AgendaTask] {
        guard let data = loadBroomfieldData() else {
            return []
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Helper function to create date relative to today
        func createDate(daysFromToday: Int) -> Date {
            return calendar.date(byAdding: .day, value: daysFromToday, to: today) ?? today
        }
        
        // Get some sample members for agenda tasks
        let sampleMembers = Array(data.members.prefix(20))
        
        var agendaTasks: [AgendaTask] = []
        
        // Create some agenda tasks using Broomfield members
        for (index, member) in sampleMembers.enumerated() {
            let taskTypes: [CardType] = [.email, .text, .payment, .reminder, .event]
            let taskType = taskTypes[index % taskTypes.count]
            
            let taskDescriptions = [
                "Follow up: 6 months check-in",
                "Call: Follow up on donation",
                "Send Birthday Text",
                "Review Shabbat dinner menu",
                "Weekly progress review meeting",
                "Annual security system review",
                "Follow up with new families",
                "Schedule kosher kitchen inspection",
                "Review volunteer applications",
                "Prep for Board Meeting"
            ]
            
            let contentBodies = [
                "Hi \(member.name),\n\nHope you're doing well! Just checking in as it's been about 6 months since we last properly connected. How have things been?\n\nBest regards,\n[Your Name]",
                "Happy Birthday, \(member.name)! 🎉 Hope you have a wonderful day filled with joy and celebration!",
                "Hi \(member.name), Hope you're having a great week! It feels like a while since the High Holidays, wanted to reach out and see how you're doing."
            ]
            
            let agendaTask = AgendaTask(
                name: member.name,
                taskDescription: taskDescriptions[index % taskDescriptions.count],
                contentBody: contentBodies[index % contentBodies.count],
                subject: "Checking In",
                image: member.hasProfileImage ? member.profileImageName : "Default Profile Pic icon",
                phone: member.phone,
                email: member.email,
                priority: index % 3 == 0, // Every third task is priority
                type: taskType,
                triggerDate: createDate(daysFromToday: index - 5), // Spread across past and future
                actionDate: createDate(daysFromToday: index - 4),
                completed: index % 5 == 0, // Every fifth task is completed
                isPinned: index % 7 == 0 // Every seventh task is pinned
            )
            
            agendaTasks.append(agendaTask)
        }
        
        return agendaTasks
    }
}
//
//// Helper function to convert string to ColorTag
//private func colorTag(from string: String?) -> ColorTag {
//    guard let string = string else { return .none }
//    return ColorTag(rawValue: string) ?? .none
//}
