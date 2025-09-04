const fs = require('fs');
const path = require('path');
const { query } = require('./connection');

const runMigrations = async () => {
  try {
    console.log('🚀 Starting database migrations...');

    // Read and execute schema.sql
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schemaSQL = fs.readFileSync(schemaPath, 'utf8');

    // Split SQL into individual statements
    const statements = schemaSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    console.log(`📝 Found ${statements.length} SQL statements to execute`);

    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.trim()) {
        try {
          console.log(`📋 Executing statement ${i + 1}/${statements.length}...`);
          await query(statement);
          console.log(`✅ Statement ${i + 1} executed successfully`);
        } catch (error) {
          // Skip if table/extension already exists
          if (error.code === '42P07' || error.code === '42710') {
            console.log(`⚠️  Statement ${i + 1} skipped (already exists): ${error.message}`);
          } else {
            console.error(`❌ Statement ${i + 1} failed:`, error.message);
            throw error;
          }
        }
      }
    }

    // Insert default subscription plans
    console.log('📦 Inserting default subscription plans...');
    await insertDefaultSubscriptionPlans();

    console.log('🎉 Database migrations completed successfully!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
};

const insertDefaultSubscriptionPlans = async () => {
  const plans = [
    {
      name: 'free',
      display_name: 'Free',
      description: 'Basic community management for small groups',
      price_monthly: 0.00,
      price_yearly: 0.00,
      max_team_members: 5,
      max_viewers: 10,
      features: JSON.stringify({
        basic_management: true,
        member_tracking: true,
        basic_reports: true
      })
    },
    {
      name: 'starter',
      display_name: 'Starter',
      description: 'Perfect for growing communities',
      price_monthly: 19.99,
      price_yearly: 199.99,
      max_team_members: 25,
      max_viewers: 100,
      features: JSON.stringify({
        basic_management: true,
        member_tracking: true,
        basic_reports: true,
        advanced_analytics: true,
        email_integration: true,
        custom_fields: true
      })
    },
    {
      name: 'professional',
      display_name: 'Professional',
      description: 'Advanced features for established communities',
      price_monthly: 49.99,
      price_yearly: 499.99,
      max_team_members: 100,
      max_viewers: 500,
      features: JSON.stringify({
        basic_management: true,
        member_tracking: true,
        basic_reports: true,
        advanced_analytics: true,
        email_integration: true,
        custom_fields: true,
        advanced_reporting: true,
        api_access: true,
        priority_support: true
      })
    },
    {
      name: 'enterprise',
      display_name: 'Enterprise',
      description: 'Full-featured solution for large organizations',
      price_monthly: 99.99,
      price_yearly: 999.99,
      max_team_members: -1, // Unlimited
      max_viewers: -1, // Unlimited
      features: JSON.stringify({
        basic_management: true,
        member_tracking: true,
        basic_reports: true,
        advanced_analytics: true,
        email_integration: true,
        custom_fields: true,
        advanced_reporting: true,
        api_access: true,
        priority_support: true,
        white_label: true,
        custom_integrations: true,
        dedicated_support: true
      })
    }
  ];

  for (const plan of plans) {
    try {
      await query(
        `INSERT INTO subscription_plans (
          name, display_name, description, price_monthly, price_yearly, 
          max_team_members, max_viewers, features
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        ON CONFLICT (name) DO UPDATE SET
          display_name = EXCLUDED.display_name,
          description = EXCLUDED.description,
          price_monthly = EXCLUDED.price_monthly,
          price_yearly = EXCLUDED.price_yearly,
          max_team_members = EXCLUDED.max_team_members,
          max_viewers = EXCLUDED.max_viewers,
          features = EXCLUDED.features,
          updated_at = NOW()`,
        [
          plan.name,
          plan.display_name,
          plan.description,
          plan.price_monthly,
          plan.price_yearly,
          plan.max_team_members,
          plan.max_viewers,
          plan.features
        ]
      );
      console.log(`✅ Subscription plan '${plan.name}' inserted/updated`);
    } catch (error) {
      console.error(`❌ Failed to insert plan '${plan.name}':`, error.message);
    }
  }
};

// Run migrations if this file is executed directly
if (require.main === module) {
  runMigrations();
}

module.exports = { runMigrations };
