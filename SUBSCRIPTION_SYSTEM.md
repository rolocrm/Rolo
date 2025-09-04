# Rolo Subscription System

## Overview

The Rolo subscription system is designed to provide tiered access to community management features based on subscription plans. The system supports:

- **Multiple subscription tiers** with different feature sets and limits
- **Team member management** with role-based access control
- **Automatic limit enforcement** based on subscription plans
- **Payment integration** with Stripe
- **Usage tracking and analytics**

## Database Schema

### Core Tables

#### 1. `subscription_plans`
Stores available subscription plans and their features.

```sql
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,                    -- 'free', 'starter', 'professional', 'enterprise'
    display_name TEXT NOT NULL,                   -- 'Free', 'Starter', 'Professional', 'Enterprise'
    description TEXT,
    price_monthly DECIMAL(10,2) NOT NULL,         -- Monthly price
    price_yearly DECIMAL(10,2) NOT NULL,          -- Yearly price
    max_team_members INTEGER NOT NULL DEFAULT 1,  -- -1 for unlimited
    max_viewers INTEGER NOT NULL DEFAULT 3,       -- -1 for unlimited
    features JSONB NOT NULL DEFAULT '{}',         -- Feature flags
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 2. `community_subscriptions`
Tracks active subscriptions for each community.

```sql
CREATE TABLE community_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status TEXT NOT NULL DEFAULT 'active',        -- 'active', 'canceled', 'past_due', 'unpaid', 'trialing'
    billing_cycle TEXT NOT NULL DEFAULT 'monthly', -- 'monthly', 'yearly'
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT false,
    canceled_at TIMESTAMPTZ,
    stripe_subscription_id TEXT,                  -- Stripe subscription ID
    stripe_customer_id TEXT,                      -- Stripe customer ID
    payment_method_id TEXT,                       -- Stripe payment method ID
    has_payment_method BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 3. Updated `communities` table
Enhanced with subscription-related fields.

```sql
-- New columns added to communities table
ALTER TABLE communities ADD COLUMN owner_id UUID REFERENCES auth.users(id);
ALTER TABLE communities ADD COLUMN current_plan_id UUID REFERENCES subscription_plans(id);
ALTER TABLE communities ADD COLUMN subscription_status TEXT DEFAULT 'free';
ALTER TABLE communities ADD COLUMN has_payment_method BOOLEAN DEFAULT false;
ALTER TABLE communities ADD COLUMN team_member_count INTEGER DEFAULT 1;
ALTER TABLE communities ADD COLUMN viewer_count INTEGER DEFAULT 0;
ALTER TABLE communities ADD COLUMN max_team_members INTEGER DEFAULT 1;
ALTER TABLE communities ADD COLUMN max_viewers INTEGER DEFAULT 3;
```

### Views

#### `subscription_info`
Provides a comprehensive view of subscription data for easy querying.

```sql
CREATE VIEW subscription_info AS
SELECT 
    c.id as community_id,
    c.name as community_name,
    c.handle as community_handle,
    c.owner_id,
    c.subscription_status,
    c.has_payment_method,
    c.team_member_count,
    c.viewer_count,
    c.max_team_members,
    c.max_viewers,
    sp.id as plan_id,
    sp.name as plan_name,
    sp.display_name as plan_display_name,
    sp.price_monthly,
    sp.price_yearly,
    sp.features as plan_features,
    cs.id as subscription_id,
    cs.billing_cycle,
    cs.current_period_start,
    cs.current_period_end,
    cs.cancel_at_period_end,
    cs.stripe_subscription_id,
    cs.stripe_customer_id,
    -- Usage percentages
    CASE 
        WHEN c.max_team_members = -1 THEN 0
        ELSE ROUND((c.team_member_count::DECIMAL / c.max_team_members::DECIMAL) * 100, 2)
    END as team_member_usage_percent,
    CASE 
        WHEN c.max_viewers = -1 THEN 0
        ELSE ROUND((c.viewer_count::DECIMAL / c.max_viewers::DECIMAL) * 100, 2)
    END as viewer_usage_percent,
    -- Limit exceeded flags
    (c.team_member_count > c.max_team_members AND c.max_team_members != -1) as team_limit_exceeded,
    (c.viewer_count > c.max_viewers AND c.max_viewers != -1) as viewer_limit_exceeded
FROM communities c
LEFT JOIN subscription_plans sp ON c.current_plan_id = sp.id
LEFT JOIN community_subscriptions cs ON c.id = cs.community_id AND cs.status = 'active';
```

## Subscription Plans

### Default Plans

1. **Free Plan**
   - Price: $0/month, $0/year
   - Team Members: 1 (owner only)
   - Viewers: 3
   - Features: Basic management, member tracking, basic analytics

2. **Starter Plan**
   - Price: $9.99/month, $99.99/year
   - Team Members: 3
   - Viewers: 10
   - Features: All Free features + team collaboration, custom branding

3. **Professional Plan**
   - Price: $29.99/month, $299.99/year
   - Team Members: 10
   - Viewers: 50
   - Features: All Starter features + advanced permissions, API access, priority support

4. **Enterprise Plan**
   - Price: $99.99/month, $999.99/year
   - Team Members: Unlimited (-1)
   - Viewers: Unlimited (-1)
   - Features: All Professional features + white label, custom integrations, dedicated support

## Role-Based Access Control

### User Roles

1. **Owner** - Community creator with full access
2. **Admin** - Full administrative access
3. **Limited Admin** - Restricted administrative access
4. **Viewer** - Read-only access

### Role Inheritance

- Team members (owner, admin, limited_admin) inherit the subscription benefits
- Viewers are counted separately and have their own limits
- Only the community owner pays for the subscription

## Automatic Enforcement

### Database Triggers

1. **Team Member Limit Enforcement**
   - Prevents adding team members beyond plan limits
   - Enforces viewer limits separately
   - Provides clear error messages when limits are exceeded

2. **Usage Tracking**
   - Automatically updates team member and viewer counts
   - Maintains real-time usage statistics
   - Triggers when collaborators are added/removed

3. **Subscription Sync**
   - Keeps community subscription status in sync
   - Updates plan limits automatically
   - Maintains payment method status

### Functions

#### `change_subscription_plan(community_id, plan_name, billing_cycle)`
- Changes subscription plan for a community
- Handles upgrades and downgrades
- Manages free plan conversion
- Returns success/failure status

#### `get_subscription_usage(community_id)`
- Returns current usage statistics
- Includes usage percentages
- Flags when limits are exceeded
- Provides plan information

## Swift Integration

### Models

The system includes comprehensive Swift models:

- `SubscriptionPlan` - Plan details and pricing
- `CommunitySubscription` - Active subscription data
- `SubscriptionInfo` - Comprehensive subscription view
- `SubscriptionUsage` - Usage statistics
- `SubscriptionStatus` - Status enumeration
- `BillingCycle` - Billing cycle enumeration

### SubscriptionService

The `SubscriptionService` class provides:

- Plan management (fetch, change, create)
- Usage tracking and analytics
- Team member limit checking
- Payment method management
- Billing integration with Stripe

## Usage Examples

### Check if user can add team member

```swift
let canAdd = try await subscriptionService.canAddTeamMember(
    communityId: communityId, 
    role: .admin
)
```

### Get subscription usage

```swift
let usage = try await subscriptionService.getSubscriptionUsage(
    communityId: communityId
)
print("Team usage: \(usage.teamUsagePercent)%")
print("Viewer usage: \(usage.viewerUsagePercent)%")
```

### Change subscription plan

```swift
let result = try await subscriptionService.changeSubscriptionPlan(
    communityId: communityId,
    planName: "professional",
    billingCycle: .monthly
)
```

### Get available roles based on plan

```swift
let availableRoles = try await subscriptionService.getAvailableRoles(
    communityId: communityId
)
```

## Security and RLS Policies

### Row Level Security

- All subscription tables have RLS enabled
- Only community owners can manage their subscriptions
- Community members can view subscription information
- Subscription plans are publicly readable

### Authentication

- All operations require authenticated users
- UUID comparisons use case-insensitive matching
- JWT token format is properly handled

## Payment Integration

### Stripe Integration

The system is designed to integrate with Stripe:

- Stores Stripe subscription and customer IDs
- Handles webhook updates for subscription changes
- Manages payment method status
- Supports subscription lifecycle events

### Webhook Handling

```swift
// Update subscription from Stripe webhook
let updatedSubscription = try await subscriptionService.updateSubscriptionFromWebhook(
    subscriptionId: subscriptionId,
    stripeData: webhookData
)
```

## Monitoring and Analytics

### Usage Tracking

- Real-time team member and viewer counts
- Usage percentage calculations
- Limit exceeded notifications
- Historical usage data

### Recommendations

The system provides automatic recommendations:

- Upgrade suggestions when approaching limits
- Payment method reminders
- Plan optimization suggestions

## Migration and Setup

### Initial Setup

1. Run all migration files in order
2. Default plans are automatically created
3. Existing communities are set to free plan
4. Owner relationships are established

### Data Migration

```sql
-- Update existing communities
UPDATE communities 
SET owner_id = created_by 
WHERE owner_id IS NULL AND created_by IS NOT NULL;

-- Set default plan
UPDATE communities 
SET 
    current_plan_id = (SELECT id FROM subscription_plans WHERE name = 'free'),
    subscription_status = 'free',
    max_team_members = (SELECT max_team_members FROM subscription_plans WHERE name = 'free'),
    max_viewers = (SELECT max_viewers FROM subscription_plans WHERE name = 'free')
WHERE current_plan_id IS NULL;
```

## Best Practices

### Performance

- Use indexes on frequently queried columns
- Leverage the `subscription_info` view for complex queries
- Cache subscription data when appropriate

### Security

- Always validate user permissions before operations
- Use RLS policies for data access control
- Validate subscription limits before adding team members

### Maintenance

- Monitor usage patterns and adjust plans accordingly
- Regular cleanup of expired subscriptions
- Backup subscription data regularly

## Future Enhancements

### Planned Features

1. **Usage-based billing** - Pay per team member
2. **Custom plans** - Tailored subscription packages
3. **Bulk operations** - Manage multiple communities
4. **Advanced analytics** - Detailed usage reports
5. **Trial periods** - Free trial for new plans
6. **Promotional codes** - Discount and trial codes

### Scalability Considerations

- Database partitioning for large subscription tables
- Caching layer for frequently accessed data
- Background jobs for usage calculations
- API rate limiting for subscription operations 