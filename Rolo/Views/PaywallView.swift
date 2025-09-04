import SwiftUI

struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan?
    @State private var selectedBillingCycle: BillingCycle = .monthly
    @State private var showingPaymentSheet = false
    @State private var showingTrialAlert = false
    
    // Sample plans for immediate display
    private let samplePlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: UUID(),
            name: "free",
            displayName: "Free",
            description: "Perfect for small communities",
            priceMonthly: 0.00,
            priceYearly: 0.00,
            maxTeamMembers: 0,
            maxViewers: 0,
            features: [
                "max_members": 100,
                "birthday_reminders": false,
                "donation_links": false,
                "email_templates": false,
                "agenda_opened": false,
                "dedicated_support": false
            ],
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        SubscriptionPlan(
            id: UUID(),
            name: "pro",
            displayName: "Pro",
            description: "Advanced features for growing communities",
            priceMonthly: 350.00,
            priceYearly: 280.00,
            maxTeamMembers: 2,
            maxViewers: 0,
            features: [
                "max_members": 250,
                "birthday_reminders": true,
                "donation_links": true,
                "email_templates": true,
                "trial_days": 30,
                "email_limit": 100,
                "agenda_opened": false,
                "dedicated_support": false
            ],
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        SubscriptionPlan(
            id: UUID(),
            name: "scale",
            displayName: "Scale",
            description: "Built for large communities",
            priceMonthly: 999.00,
            priceYearly: 799.00,
            maxTeamMembers: 10,
            maxViewers: 0,
            features: [
                "max_members": 1500,
                "birthday_reminders": true,
                "donation_links": true,
                "email_templates": true,
                "email_limit": 1000,
                "agenda_opened": true,
                "dedicated_support": false
            ],
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        ),
        SubscriptionPlan(
            id: UUID(),
            name: "enterprise",
            displayName: "Enterprise",
            description: "Custom solutions for enterprise",
            priceMonthly: 0.00,
            priceYearly: 0.00,
            maxTeamMembers: -1,
            maxViewers: 0,
            features: [
                "max_members": -1,
                "birthday_reminders": true,
                "donation_links": true,
                "email_templates": true,
                "email_limit": -1,
                "agenda_opened": true,
                "dedicated_support": true
            ],
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        )
    ]
    
    // MARK: - Initialization
    init() {
        // Default initializer
    }
    
    // Convenience initializer for quick access
    init(preselectedPlan: SubscriptionPlan? = nil) {
        self._selectedPlan = State(initialValue: preselectedPlan)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 20) {
                        // Icon
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding(.top, 20)
                        
                        // Title
                        VStack(spacing: 8) {
                            Text("Unlock Your Community's Full Potential")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("Choose the perfect plan for your community's growth")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        
                        // Current Usage
                        if let usage = viewModel.currentUsage {
                            currentUsageCard(usage: usage)
                        }
                    }
                    .padding(.bottom, 30)
                    
                    // Plans Section
                    VStack(spacing: 20) {
                        // Billing Toggle
                        HStack {
                            Text("Billing Cycle")
                                .font(.headline)
                            
                            Spacer()
                            
                            Picker("Billing Cycle", selection: $selectedBillingCycle) {
                                Text("Monthly").tag(BillingCycle.monthly)
                                Text("Yearly").tag(BillingCycle.yearly)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 200)
                        }
                        .padding(.horizontal, 20)
                        
                        // Plans Stack
                        VStack(spacing: 12) {
                            ForEach(samplePlans) { plan in
                                PlanCardView(
                                    plan: plan,
                                    billingCycle: selectedBillingCycle,
                                    isSelected: selectedPlan?.id == plan.id,
                                    isComingSoon: plan.name == "scale" || plan.name == "enterprise"
                                ) {
                                    if plan.name == "scale" || plan.name == "enterprise" {
                                        // Show coming soon alert
                                    } else {
                                        selectedPlan = plan
                                        if plan.name == "pro" {
                                            showingTrialAlert = true
                                        } else {
                                            showingPaymentSheet = true
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Call to Action Text
                        if let selectedPlan = selectedPlan, selectedPlan.name == "pro" {
                            VStack(spacing: 8) {
                                Text("Get started with a ")
                                    .font(.title3)
                                    .foregroundColor(.primary) +
                                Text("30-day free trial")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue) +
                                Text(" on \(selectedPlan.displayName)")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Main Action Button
                    VStack(spacing: 16) {
                        Button(action: {
                            if let selectedPlan = selectedPlan {
                                if selectedPlan.name == "pro" {
                                    showingTrialAlert = true
                                } else {
                                    showingPaymentSheet = true
                                }
                            }
                        }) {
                            Text(buttonText)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    selectedPlan != nil ? Color.blue : Color.gray
                                )
                                .cornerRadius(12)
                        }
                        .disabled(selectedPlan == nil)
                        .padding(.horizontal, 20)
                        
                        Button(action: {
                            // Show all plans or additional info
                        }) {
                            Text("VIEW ALL PLANS")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        Text("Cancel anytime in the App Store")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentSheetView(
                plan: selectedPlan,
                billingCycle: selectedBillingCycle,
                onSuccess: { success in
                    showingPaymentSheet = false
                    if success {
                        dismiss()
                    }
                }
            )
        }
        .alert("30-Day Free Trial", isPresented: $showingTrialAlert) {
            Button("Start Trial") {
                showingPaymentSheet = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Start your 30-day free trial of Pro plan. No charges until trial ends.")
        }
    }
    
    private func currentUsageCard(usage: SubscriptionUsage) -> some View {
        VStack(spacing: 12) {
            Text("Current Usage")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 30) {
                VStack {
                    Text("\(usage.teamMemberCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Team Members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(usage.maxTeamMembers == -1 ? "∞" : "\(usage.maxTeamMembers)")")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Max Allowed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if usage.teamLimitExceeded {
                Text("⚠️ Upgrade to add more team members")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    private var buttonText: String {
        guard let selectedPlan = selectedPlan else {
            return "Select a Plan"
        }
        
        if selectedPlan.name == "pro" {
            return "START MY FREE TRIAL"
        } else if selectedPlan.name == "free" {
            return "CONTINUE WITH FREE"
        } else {
            return "START SUBSCRIPTION"
        }
    }
}

// MARK: - Plan Card View
struct PlanCardView: View {
    let plan: SubscriptionPlan
    let billingCycle: BillingCycle
    let isSelected: Bool
    let isComingSoon: Bool
    let onTap: () -> Void
    
    private var price: Decimal {
        billingCycle == .monthly ? plan.priceMonthly : plan.priceYearly
    }
    
    private var savingsText: String? {
        if billingCycle == .yearly && plan.priceYearly < plan.priceMonthly * 12 {
            let savings = (plan.priceMonthly * 12 - plan.priceYearly) / (plan.priceMonthly * 12) * 100
            return "Save \(NSDecimalNumber(decimal: savings).intValue)%"
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with selection indicator
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Popular badge
                    if plan.name == "pro" {
                        Text("MOST POPULAR")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    
                    Text(plan.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if let description = plan.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            // Price
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    Text("\(NSDecimalNumber(decimal: price).intValue)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(billingCycle == .monthly ? "/month" : "/month")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                
                if billingCycle == .yearly {
                    Text("billed annually")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                if let savings = savingsText {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // Key Features (simplified for card view)
            VStack(spacing: 6) {
                if let maxMembers = plan.features["max_members"] as? Int {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .blue)
                        Text("Up to \(maxMembers == -1 ? "∞" : "\(maxMembers)") members")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .primary)
                        Spacer()
                    }
                }
                
                if plan.maxTeamMembers > 0 {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .blue)
                        Text("\(plan.maxTeamMembers == -1 ? "∞" : "\(plan.maxTeamMembers)") team members")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .primary)
                        Spacer()
                    }
                }
                
                if (plan.features["birthday_reminders"] as? Bool) == true {
                    HStack {
                        Image(systemName: "gift.fill")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .blue)
                        Text("Birthday reminders")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .primary)
                        Spacer()
                    }
                }
            }
            
            // Trial Badge
            if plan.features["trial_days"] as? Int == 30 {
                Text("30-Day Free Trial")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(
            isSelected ? 
                .gray : .purple)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? Color.clear : Color.gray.opacity(0.3),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Feature Item View
struct FeatureItemView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Feature Row View
struct FeatureRowView: View {
    let feature: Feature
    let plans: [SubscriptionPlan]
    
    var body: some View {
        HStack {
            // Feature name
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let description = feature.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Plan availability
            HStack(spacing: 16) {
                ForEach(plans) { plan in
                    VStack {
                        if feature.isAvailable(in: plan) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        
                        if let value = feature.getValue(in: plan) {
                            Text(value)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        
        if feature != Feature.allCases.last {
            Divider()
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - FAQ Item View
struct FAQItemView: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Feature Enum
enum Feature: CaseIterable {
    case members
    case teamMembers
    case birthdayReminders
    case donationLinks
    case emailTemplates
    case agendaOpened
    case dedicatedSupport
    
    var displayName: String {
        switch self {
        case .members: return "Community Members"
        case .teamMembers: return "Team Members"
        case .birthdayReminders: return "Birthday Reminders"
        case .donationLinks: return "Donation Links"
        case .emailTemplates: return "Email Templates"
        case .agendaOpened: return "Agenda Opened"
        case .dedicatedSupport: return "Dedicated Support"
        }
    }
    
    var description: String? {
        switch self {
        case .members: return "Maximum number of members you can add"
        case .teamMembers: return "Collaborators with admin access"
        case .birthdayReminders: return "Automatic birthday notifications"
        case .donationLinks: return "Connected donation request links"
        case .emailTemplates: return "Monthly email sending limit"
        case .agendaOpened: return "Full agenda management features"
        case .dedicatedSupport: return "Priority customer support"
        }
    }
    
    func isAvailable(in plan: SubscriptionPlan) -> Bool {
        switch self {
        case .members:
            return plan.features["max_members"] as? Int != nil
        case .teamMembers:
            return plan.maxTeamMembers > 0
        case .birthdayReminders:
            return (plan.features["birthday_reminders"] as? Bool) == true
        case .donationLinks:
            return (plan.features["donation_links"] as? Bool) == true
        case .emailTemplates:
            return (plan.features["email_templates"] as? Bool) == true
        case .agendaOpened:
            return (plan.features["agenda_opened"] as? Bool) == true
        case .dedicatedSupport:
            return (plan.features["dedicated_support"] as? Bool) == true
        }
    }
    
    func getValue(in plan: SubscriptionPlan) -> String? {
        switch self {
        case .members:
            if let maxMembers = plan.features["max_members"] as? Int {
                return maxMembers == -1 ? "∞" : "\(maxMembers)"
            }
        case .teamMembers:
            return plan.maxTeamMembers > 0 ? "\(plan.maxTeamMembers)" : nil
        case .emailTemplates:
            if let emailLimit = plan.features["email_limit"] as? Int {
                return emailLimit == -1 ? "∞" : "\(emailLimit)"
            }
        default:
            return nil
        }
        return nil
    }
}

// MARK: - Payment Sheet View
struct PaymentSheetView: View {
    let plan: SubscriptionPlan?
    let billingCycle: BillingCycle
    let onSuccess: (Bool) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var buttonText: String {
        if isLoading {
            return "Processing..."
        } else if plan?.features["trial_days"] as? Int == 30 {
            return "Start Trial"
        } else {
            return "Start Subscription"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let plan = plan {
                    // Plan Summary
                    VStack(spacing: 16) {
                        Text("Complete Your Purchase")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 8) {
                            Text(plan.displayName)
                                .font(.headline)
                            
                            HStack {
                                Text("$\(NSDecimalNumber(decimal: billingCycle == .monthly ? plan.priceMonthly : plan.priceYearly).intValue)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text(billingCycle == .monthly ? "/month" : "/month")
                                    .foregroundColor(.secondary)
                            }
                            
                            if billingCycle == .yearly {
                                Text("billed annually")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if plan.features["trial_days"] as? Int == 30 {
                                Text("30-Day Free Trial")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                }
                
                // Payment Form Placeholder
                VStack(spacing: 16) {
                    Text("Payment Information")
                        .font(.headline)
                    
                    // This would be replaced with actual payment form
                    VStack(spacing: 12) {
                        TextField("Card Number", text: .constant(""))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            TextField("MM/YY", text: .constant(""))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("CVC", text: .constant(""))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        TextField("Billing Address", text: .constant(""))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                // Purchase Button
                Button(action: processPayment) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(buttonText)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
            }
            .padding()
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func processPayment() {
        isLoading = true
        errorMessage = nil
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            onSuccess(true)
        }
    }
}

// MARK: - View Model
class PaywallViewModel: ObservableObject {
    @Published var plans: [SubscriptionPlan] = []
    @Published var currentUsage: SubscriptionUsage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let subscriptionService: SubscriptionService
    
    init() {
        self.subscriptionService = SubscriptionService(supabaseService: SupabaseService.shared)
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        Task {
            do {
                async let plansTask = subscriptionService.getSubscriptionPlans()
                async let usageTask = subscriptionService.getSubscriptionUsage(communityId: getCurrentCommunityId())
                
                let (plans, usage) = try await (plansTask, usageTask)
                
                await MainActor.run {
                    self.plans = plans
                    self.currentUsage = usage
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getCurrentCommunityId() -> UUID {
        // This would get the current community ID from your app state
        // For now, returning a placeholder
        return UUID()
    }
}

#Preview("PaywallView") {
    PaywallView()
}

// MARK: - Plan Card Preview
struct PlanCardPreview: View {
    @State private var selectedBillingCycle: BillingCycle = .monthly
    @State private var selectedPlan: SubscriptionPlan?
    
    private let samplePlan = SubscriptionPlan(
        id: UUID(),
        name: "pro",
        displayName: "Pro",
        description: "Advanced features for growing communities",
        priceMonthly: 350.00,
        priceYearly: 280.00,
        maxTeamMembers: 2,
        maxViewers: 0,
        features: [
            "max_members": 250,
            "birthday_reminders": true,
            "donation_links": true,
            "email_templates": true,
            "trial_days": 30,
            "email_limit": 100
        ],
        isActive: true,
        createdAt: nil,
        updatedAt: nil
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Plan Card Preview")
                .font(.title)
                .fontWeight(.bold)
            
            // Billing Toggle
            Picker("Billing Cycle", selection: $selectedBillingCycle) {
                Text("Monthly").tag(BillingCycle.monthly)
                Text("Yearly").tag(BillingCycle.yearly)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
            
            // Plan Card
            PlanCardView(
                plan: samplePlan,
                billingCycle: selectedBillingCycle,
                isSelected: selectedPlan?.id == samplePlan.id,
                isComingSoon: false
            ) {
                selectedPlan = selectedPlan?.id == samplePlan.id ? nil : samplePlan
            }
            .padding(.horizontal, 20)
            
            Text("Tap the card to select/deselect")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview("Plan Card Only") {
    PlanCardPreview()
}

#Preview("Original Paywall") {
    PaywallView()
} 
