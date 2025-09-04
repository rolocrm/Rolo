import Foundation
import Supabase

class SubscriptionService: ObservableObject {
    private let supabaseService: SupabaseService
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Subscription Plans
    
    /// Fetch all available subscription plans
    func getSubscriptionPlans() async throws -> [SubscriptionPlan] {
        let plans: [SubscriptionPlan] = try await supabaseService.performRequest(
            endpoint: "subscription_plans?is_active=eq.true&order=price_monthly.asc"
        )
        return plans
    }
    
    /// Get a specific subscription plan by name
    func getSubscriptionPlan(name: String) async throws -> SubscriptionPlan? {
        let plans: [SubscriptionPlan] = try await supabaseService.performRequest(
            endpoint: "subscription_plans?name=eq.\(name)&is_active=eq.true"
        )
        return plans.first
    }
    
    // MARK: - Community Subscriptions
    
    /// Get subscription information for a community
    func getCommunitySubscriptionInfo(communityId: UUID) async throws -> SubscriptionInfo? {
        let subscriptions: [SubscriptionInfo] = try await supabaseService.performRequest(
            endpoint: "subscription_info?community_id=eq.\(communityId.uuidString)"
        )
        return subscriptions.first
    }
    
    /// Get subscription usage statistics for a community
    func getSubscriptionUsage(communityId: UUID) async throws -> SubscriptionUsage {
        // For now, we'll create a mock response since the function doesn't exist yet
        // In a real implementation, you would call the database function
        let mockUsage = SubscriptionUsage(
            communityId: communityId,
            teamMemberCount: 1,
            viewerCount: 0,
            maxTeamMembers: 1,
            maxViewers: 3,
            teamUsagePercent: 100.0,
            viewerUsagePercent: 0.0,
            teamLimitExceeded: false,
            viewerLimitExceeded: false,
            subscriptionStatus: .free,
            planName: "free",
            planDisplayName: "Free"
        )
        return mockUsage
    }
    
    /// Change subscription plan for a community
    func changeSubscriptionPlan(
        communityId: UUID,
        planName: String,
        billingCycle: BillingCycle = .monthly
    ) async throws -> [String: Any] {
        // For now, we'll create a mock response
        // In a real implementation, you would call the database function
        return [
            "success": true,
            "message": "Successfully changed subscription plan",
            "plan_name": planName,
            "billing_cycle": billingCycle.rawValue
        ]
    }
    
    /// Create a new subscription for a community
    func createSubscription(
        communityId: UUID,
        planId: UUID,
        billingCycle: BillingCycle = .monthly,
        stripeSubscriptionId: String? = nil,
        stripeCustomerId: String? = nil
    ) async throws -> CommunitySubscription {
        let subscriptionData: [String: Any] = [
            "community_id": communityId.uuidString,
            "plan_id": planId.uuidString,
            "status": "active",
            "billing_cycle": billingCycle.rawValue,
            "current_period_start": ISO8601DateFormatter().string(from: Date()),
            "current_period_end": ISO8601DateFormatter().string(from: Date().addingTimeInterval(billingCycle == .yearly ? 365 * 24 * 60 * 60 : 30 * 24 * 60 * 60)),
            "stripe_subscription_id": stripeSubscriptionId as Any,
            "stripe_customer_id": stripeCustomerId as Any
        ]
        
        let subscriptions: [CommunitySubscription] = try await supabaseService.performRequest(
            endpoint: "community_subscriptions",
            method: "POST",
            body: subscriptionData,
            headers: ["Prefer": "return=representation"]
        )
        
        guard let subscription = subscriptions.first else {
            throw SupabaseError.serverError("No subscription returned from creation")
        }
        
        return subscription
    }
    
    /// Update subscription payment method
    func updatePaymentMethod(
        subscriptionId: UUID,
        paymentMethodId: String,
        hasPaymentMethod: Bool = true
    ) async throws -> CommunitySubscription {
        let updateData: [String: Any] = [
            "payment_method_id": paymentMethodId,
            "has_payment_method": hasPaymentMethod
        ]
        
        let subscriptions: [CommunitySubscription] = try await supabaseService.performRequest(
            endpoint: "community_subscriptions?id=eq.\(subscriptionId.uuidString)",
            method: "PATCH",
            body: updateData,
            headers: ["Prefer": "return=representation"]
        )
        
        guard let subscription = subscriptions.first else {
            throw SupabaseError.serverError("No subscription returned from update")
        }
        
        return subscription
    }
    
    /// Cancel subscription at period end
    func cancelSubscription(subscriptionId: UUID) async throws -> CommunitySubscription {
        let updateData: [String: Any] = [
            "cancel_at_period_end": true,
            "canceled_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let subscriptions: [CommunitySubscription] = try await supabaseService.performRequest(
            endpoint: "community_subscriptions?id=eq.\(subscriptionId.uuidString)",
            method: "PATCH",
            body: updateData,
            headers: ["Prefer": "return=representation"]
        )
        
        guard let subscription = subscriptions.first else {
            throw SupabaseError.serverError("No subscription returned from update")
        }
        
        return subscription
    }
    
    /// Reactivate a canceled subscription
    func reactivateSubscription(subscriptionId: UUID) async throws -> CommunitySubscription {
        let updateData: [String: Any] = [
            "cancel_at_period_end": false
        ]
        
        let subscriptions: [CommunitySubscription] = try await supabaseService.performRequest(
            endpoint: "community_subscriptions?id=eq.\(subscriptionId.uuidString)",
            method: "PATCH",
            body: updateData,
            headers: ["Prefer": "return=representation"]
        )
        
        guard let subscription = subscriptions.first else {
            throw SupabaseError.serverError("No subscription returned from update")
        }
        
        return subscription
    }
    
    // MARK: - Team Member Management
    
    /// Check if adding a team member would exceed limits
    func canAddTeamMember(communityId: UUID, role: UserRole) async throws -> Bool {
        let usage = try await getSubscriptionUsage(communityId: communityId)
        
        switch role {
        case .owner, .admin, .limitedAdmin:
            return usage.maxTeamMembers == -1 || usage.teamMemberCount < usage.maxTeamMembers
        case .viewer:
            return usage.maxViewers == -1 || usage.viewerCount < usage.maxViewers
        }
    }
    
    /// Get available roles based on subscription plan
    func getAvailableRoles(communityId: UUID) async throws -> [UserRole] {
        let usage = try await getSubscriptionUsage(communityId: communityId)
        
        var availableRoles: [UserRole] = [.viewer]
        
        // Check if we can add team members (admin roles)
        if usage.maxTeamMembers == -1 || usage.teamMemberCount < usage.maxTeamMembers {
            availableRoles.append(contentsOf: [.limitedAdmin, .admin])
        }
        
        return availableRoles
    }
    
    // MARK: - Billing Integration
    
    /// Update subscription with Stripe webhook data
    func updateSubscriptionFromWebhook(
        subscriptionId: UUID,
        stripeData: [String: Any]
    ) async throws -> CommunitySubscription {
        var updateData: [String: Any] = [:]
        
        // Map Stripe webhook data to our fields
        if let status = stripeData["status"] as? String {
            updateData["status"] = status
        }
        
        if let currentPeriodStart = stripeData["current_period_start"] as? Int {
            updateData["current_period_start"] = ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: TimeInterval(currentPeriodStart)))
        }
        
        if let currentPeriodEnd = stripeData["current_period_end"] as? Int {
            updateData["current_period_end"] = ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: TimeInterval(currentPeriodEnd)))
        }
        
        if let cancelAtPeriodEnd = stripeData["cancel_at_period_end"] as? Bool {
            updateData["cancel_at_period_end"] = cancelAtPeriodEnd
        }
        
        let subscriptions: [CommunitySubscription] = try await supabaseService.performRequest(
            endpoint: "community_subscriptions?id=eq.\(subscriptionId.uuidString)",
            method: "PATCH",
            body: updateData,
            headers: ["Prefer": "return=representation"]
        )
        
        guard let subscription = subscriptions.first else {
            throw SupabaseError.serverError("No subscription returned from update")
        }
        
        return subscription
    }
    
    // MARK: - Analytics
    
    /// Get subscription analytics for a community
    func getSubscriptionAnalytics(communityId: UUID) async throws -> [String: Any] {
        let usage = try await getSubscriptionUsage(communityId: communityId)
        let subscriptionInfo = try await getCommunitySubscriptionInfo(communityId: communityId)
        
        return [
            "usage": usage,
            "subscription_info": subscriptionInfo as Any,
            "limits": [
                "team_members": [
                    "current": usage.teamMemberCount,
                    "max": usage.maxTeamMembers,
                    "usage_percent": usage.teamUsagePercent,
                    "exceeded": usage.teamLimitExceeded
                ],
                "viewers": [
                    "current": usage.viewerCount,
                    "max": usage.maxViewers,
                    "usage_percent": usage.viewerUsagePercent,
                    "exceeded": usage.viewerLimitExceeded
                ]
            ],
            "recommendations": generateRecommendations(usage: usage, subscriptionInfo: subscriptionInfo)
        ]
    }
    
    // MARK: - Helper Methods
    
    private func generateRecommendations(usage: SubscriptionUsage, subscriptionInfo: SubscriptionInfo?) -> [String] {
        var recommendations: [String] = []
        
        if usage.teamLimitExceeded {
            recommendations.append("Upgrade your plan to add more team members")
        }
        
        if usage.viewerLimitExceeded {
            recommendations.append("Upgrade your plan to add more viewers")
        }
        
        if usage.teamUsagePercent > 80 {
            recommendations.append("Consider upgrading to accommodate more team members")
        }
        
        if usage.viewerUsagePercent > 80 {
            recommendations.append("Consider upgrading to accommodate more viewers")
        }
        
        if subscriptionInfo?.hasPaymentMethod == false && subscriptionInfo?.subscriptionStatus != .free {
            recommendations.append("Add a payment method to ensure uninterrupted service")
        }
        
        return recommendations
    }
} 