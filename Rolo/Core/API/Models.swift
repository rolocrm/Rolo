import Foundation
import SwiftUI

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable, Equatable {
    let userId: UUID
    let firstName: String
    let lastName: String
    let phoneNumber: String?
    let avatarUrl: String?
    let completedProfile: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case avatarUrl = "avatar_url"
        case completedProfile = "completed_profile"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var id: UUID { userId }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - Community Model
struct Community: Identifiable, Codable {
    let id: UUID
    let handle: String
    let name: String
    let email: String
    let phoneNumber: String
    let taxId: String?
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let logoUrl: String?
    let createdBy: UUID?
    let createdAt: Date?
    let updatedAt: Date?
    
    // Subscription-related fields
    let ownerId: UUID?
    let currentPlanId: UUID?
    let subscriptionStatus: SubscriptionStatus?
    let hasPaymentMethod: Bool?
    let teamMemberCount: Int?
    let viewerCount: Int?
    let maxTeamMembers: Int?
    let maxViewers: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, handle, name, email, address, city, state, zip, country
        case phoneNumber = "phone_number"
        case taxId = "tax_id"
        case logoUrl = "logo_url"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        
        // Subscription-related coding keys
        case ownerId = "owner_id"
        case currentPlanId = "current_plan_id"
        case subscriptionStatus = "subscription_status"
        case hasPaymentMethod = "has_payment_method"
        case teamMemberCount = "team_member_count"
        case viewerCount = "viewer_count"
        case maxTeamMembers = "max_team_members"
        case maxViewers = "max_viewers"
    }
}

// MARK: - User Role Enum
enum UserRole: String, Codable, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case limitedAdmin = "limited_admin"
    case viewer = "viewer"
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .limitedAdmin: return "Limited Admin"
        case .viewer: return "Viewer"
        }
    }
}

// MARK: - Collaborator Status Enum
enum CollaboratorStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

// MARK: - Collaborator Model
struct Collaborator: Identifiable, Codable {
    let id: UUID
    let userId: UUID?
    let communityId: UUID?
    let role: UserRole
    let status: CollaboratorStatus
    let invitedBy: UUID?
    let joinedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, role, status
        case userId = "user_id"
        case communityId = "community_id"
        case invitedBy = "invited_by"
        case joinedAt = "joined_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Invite Status Enum
enum InviteStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Invite Model
struct Invite: Identifiable, Codable {
    let id: UUID
    let email: String
    let communityId: UUID?
    let role: UserRole
    let token: String
    let status: InviteStatus
    let invitedBy: UUID?
    let createdAt: Date?
    let acceptedAt: Date?
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, email, role, token, status
        case communityId = "community_id"
        case invitedBy = "invited_by"
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
        case expiresAt = "expires_at"
    }
}

// MARK: - Collaborator Creation Request
struct CollaboratorRequest: Codable {
    let fullName: String
    let email: String
    let role: UserRole
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case email, role
    }
}

// MARK: - Community Creation Request
struct CommunityCreationRequest: Codable {
    let handle: String
    let name: String
    let email: String
    let phoneNumber: String
    let taxId: String?
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let logoUrl: String?
    let collaborators: [CollaboratorRequest]
    
    enum CodingKeys: String, CodingKey {
        case handle, name, email, address, city, state, zip, country, collaborators
        case phoneNumber = "phone_number"
        case taxId = "tax_id"
        case logoUrl = "logo_url"
    }
}

// MARK: - Auth Response Model
struct AuthResponse: Codable {
    let user: AuthUser?
    let session: Session?
}

struct AuthUser: Codable {
    let id: UUID
    let email: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case createdAt = "created_at"
    }
}

struct Session: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
} 

// MARK: - Subscription Plan Model
struct SubscriptionPlan: Identifiable, Codable {
    let id: UUID
    let name: String
    let displayName: String
    let description: String?
    let priceMonthly: Decimal
    let priceYearly: Decimal
    let maxTeamMembers: Int
    let maxViewers: Int
    let features: [String: Any]
    let isActive: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case displayName = "display_name"
        case priceMonthly = "price_monthly"
        case priceYearly = "price_yearly"
        case maxTeamMembers = "max_team_members"
        case maxViewers = "max_viewers"
        case features
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom coding for features since [String: Any] isn't Codable by default
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        priceMonthly = try container.decode(Decimal.self, forKey: .priceMonthly)
        priceYearly = try container.decode(Decimal.self, forKey: .priceYearly)
        maxTeamMembers = try container.decode(Int.self, forKey: .maxTeamMembers)
        maxViewers = try container.decode(Int.self, forKey: .maxViewers)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        
        // Decode features as [String: Any]
        if let featuresData = try container.decodeIfPresent(Data.self, forKey: .features) {
            if let featuresDict = try JSONSerialization.jsonObject(with: featuresData) as? [String: Any] {
                features = featuresDict
            } else {
                features = [:]
            }
        } else {
            features = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(priceMonthly, forKey: .priceMonthly)
        try container.encode(priceYearly, forKey: .priceYearly)
        try container.encode(maxTeamMembers, forKey: .maxTeamMembers)
        try container.encode(maxViewers, forKey: .maxViewers)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        
        // Encode features as Data
        if let featuresData = try? JSONSerialization.data(withJSONObject: features) {
            try container.encode(featuresData, forKey: .features)
        }
    }
    
    // Convenience initializer for creating plans in code
    init(id: UUID, name: String, displayName: String, description: String?, priceMonthly: Decimal, priceYearly: Decimal, maxTeamMembers: Int, maxViewers: Int, features: [String: Any], isActive: Bool, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.description = description
        self.priceMonthly = priceMonthly
        self.priceYearly = priceYearly
        self.maxTeamMembers = maxTeamMembers
        self.maxViewers = maxViewers
        self.features = features
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Community Subscription Model
struct CommunitySubscription: Identifiable, Codable {
    let id: UUID
    let communityId: UUID
    let planId: UUID
    let status: SubscriptionStatus
    let billingCycle: BillingCycle
    let currentPeriodStart: Date
    let currentPeriodEnd: Date
    let cancelAtPeriodEnd: Bool
    let canceledAt: Date?
    let stripeSubscriptionId: String?
    let stripeCustomerId: String?
    let paymentMethodId: String?
    let hasPaymentMethod: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case communityId = "community_id"
        case planId = "plan_id"
        case status, billingCycle = "billing_cycle"
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case canceledAt = "canceled_at"
        case stripeSubscriptionId = "stripe_subscription_id"
        case stripeCustomerId = "stripe_customer_id"
        case paymentMethodId = "payment_method_id"
        case hasPaymentMethod = "has_payment_method"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Subscription Status Enum
enum SubscriptionStatus: String, Codable, CaseIterable {
    case active = "active"
    case canceled = "canceled"
    case pastDue = "past_due"
    case unpaid = "unpaid"
    case trialing = "trialing"
    case free = "free"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .canceled: return "Canceled"
        case .pastDue: return "Past Due"
        case .unpaid: return "Unpaid"
        case .trialing: return "Trialing"
        case .free: return "Free"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .active, .trialing: return true
        case .canceled, .pastDue, .unpaid, .free: return false
        }
    }
}

// MARK: - Billing Cycle Enum
enum BillingCycle: String, Codable, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Subscription Info Model
struct SubscriptionInfo: Codable {
    let communityId: UUID
    let communityName: String
    let communityHandle: String
    let ownerId: UUID?
    let subscriptionStatus: SubscriptionStatus
    let hasPaymentMethod: Bool
    let teamMemberCount: Int
    let viewerCount: Int
    let maxTeamMembers: Int
    let maxViewers: Int
    let planId: UUID?
    let planName: String?
    let planDisplayName: String?
    let priceMonthly: Decimal?
    let priceYearly: Decimal?
    let planFeatures: [String: Bool]?
    let subscriptionId: UUID?
    let billingCycle: BillingCycle?
    let currentPeriodStart: Date?
    let currentPeriodEnd: Date?
    let cancelAtPeriodEnd: Bool?
    let stripeSubscriptionId: String?
    let stripeCustomerId: String?
    let teamMemberUsagePercent: Double
    let viewerUsagePercent: Double
    let teamLimitExceeded: Bool
    let viewerLimitExceeded: Bool
    
    enum CodingKeys: String, CodingKey {
        case communityId = "community_id"
        case communityName = "community_name"
        case communityHandle = "community_handle"
        case ownerId = "owner_id"
        case subscriptionStatus = "subscription_status"
        case hasPaymentMethod = "has_payment_method"
        case teamMemberCount = "team_member_count"
        case viewerCount = "viewer_count"
        case maxTeamMembers = "max_team_members"
        case maxViewers = "max_viewers"
        case planId = "plan_id"
        case planName = "plan_name"
        case planDisplayName = "plan_display_name"
        case priceMonthly = "price_monthly"
        case priceYearly = "price_yearly"
        case planFeatures = "plan_features"
        case subscriptionId = "subscription_id"
        case billingCycle = "billing_cycle"
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case stripeSubscriptionId = "stripe_subscription_id"
        case stripeCustomerId = "stripe_customer_id"
        case teamMemberUsagePercent = "team_member_usage_percent"
        case viewerUsagePercent = "viewer_usage_percent"
        case teamLimitExceeded = "team_limit_exceeded"
        case viewerLimitExceeded = "viewer_limit_exceeded"
    }
}

// MARK: - Subscription Usage Model
struct SubscriptionUsage: Codable {
    let communityId: UUID
    let teamMemberCount: Int
    let viewerCount: Int
    let maxTeamMembers: Int
    let maxViewers: Int
    let teamUsagePercent: Double
    let viewerUsagePercent: Double
    let teamLimitExceeded: Bool
    let viewerLimitExceeded: Bool
    let subscriptionStatus: SubscriptionStatus
    let planName: String?
    let planDisplayName: String?
    
    enum CodingKeys: String, CodingKey {
        case communityId = "community_id"
        case teamMemberCount = "team_member_count"
        case viewerCount = "viewer_count"
        case maxTeamMembers = "max_team_members"
        case maxViewers = "max_viewers"
        case teamUsagePercent = "team_usage_percent"
        case viewerUsagePercent = "viewer_usage_percent"
        case teamLimitExceeded = "team_limit_exceeded"
        case viewerLimitExceeded = "viewer_limit_exceeded"
        case subscriptionStatus = "subscription_status"
        case planName = "plan_name"
        case planDisplayName = "plan_display_name"
    }
}

// MARK: - MemberList Model
struct MemberList: Identifiable, Codable, Equatable {
    let id: UUID
    let communityId: UUID
    let name: String
    let description: String?
    let color: String
    let emoji: String?
    let isDefault: Bool
    let createdBy: UUID
    let createdAt: Date?
    let updatedAt: Date?
    let memberCount: Int? // Computed field for member count
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, color, emoji
        case communityId = "community_id"
        case isDefault = "is_default"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case memberCount = "member_count"
    }
    
    // Computed property for SwiftUI Color
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }
    
    // Display name with emoji if available
    var displayName: String {
        if let emoji = emoji, !emoji.isEmpty {
            return "\(emoji) \(name)"
        }
        return name
    }
}

// MARK: - Member List Junction Model (Junction table)
struct MemberListJunction: Identifiable, Codable {
    let id: UUID
    let memberId: UUID
    let listId: UUID
    let addedBy: UUID
    let addedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case memberId = "member_id"
        case listId = "list_id"
        case addedBy = "added_by"
        case addedAt = "added_at"
    }
}

// MARK: - List Creation Request
struct ListCreationRequest: Codable {
    let name: String
    let description: String?
    let color: String
    let emoji: String?
    
    enum CodingKeys: String, CodingKey {
        case name, description, color, emoji
    }
}

// MARK: - List Update Request
struct ListUpdateRequest: Codable {
    let name: String?
    let description: String?
    let color: String?
    let emoji: String?
    
    enum CodingKeys: String, CodingKey {
        case name, description, color, emoji
    }
}

// MARK: - Add Members to List Request
struct AddMembersToListRequest: Codable {
    let memberIds: [UUID]
    let listId: UUID
    
    enum CodingKeys: String, CodingKey {
        case memberIds = "member_ids"
        case listId = "list_id"
    }
}

// MARK: - Remove Members from List Request
struct RemoveMembersFromListRequest: Codable {
    let memberIds: [UUID]
    let listId: UUID
    
    enum CodingKeys: String, CodingKey {
        case memberIds = "member_ids"
        case listId = "list_id"
    }
}

// MARK: - API Member Model (for backend responses)
struct APIMember: Identifiable, Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String?
    let phoneNumber: String?
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let dateOfBirth: Date?
    let membershipDate: Date?
    let status: String?
    let notes: String?
    let addedToListAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phoneNumber = "phone_number"
        case address, city, state, zip, country
        case dateOfBirth = "date_of_birth"
        case membershipDate = "membership_date"
        case status, notes
        case addedToListAt = "added_at"
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - List with Members Model
struct ListWithMembers: Identifiable, Codable {
    let list: MemberList
    let members: [APIMember]
    
    var id: UUID { list.id }
    var name: String { list.name }
    var displayName: String { list.displayName }
    var memberCount: Int { members.count }
}
