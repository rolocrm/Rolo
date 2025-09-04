# 🚀 Migration Guide: Supabase → Custom Node.js Backend

This guide will help you migrate from Supabase to a custom Node.js + Express + PostgreSQL backend deployed on AWS.

## 📋 Overview

The migration involves:
1. **Backend**: Replacing Supabase with a custom Node.js backend
2. **Database**: Moving from Supabase PostgreSQL to AWS RDS PostgreSQL
3. **Authentication**: Replacing Supabase Auth with JWT-based authentication
4. **Deployment**: Moving from Supabase to AWS ECS + RDS + ALB
5. **iOS App**: Updating the app to use the new backend APIs

## 🏗️ Architecture

### Before (Supabase)
```
iOS App → Supabase (Auth + Database + Real-time)
```

### After (Custom Backend)
```
iOS App → AWS ALB → ECS Fargate → Node.js Backend → RDS PostgreSQL
```

## 🚀 Quick Start

### 1. Set Up Local Development Environment

```bash
# Clone the backend
cd backend

# Install dependencies
npm install

# Copy environment file
cp env.example .env

# Edit .env with your configuration
nano .env

# Start with Docker Compose
docker-compose up -d

# Run database migrations
npm run migrate
```

### 2. Test the Backend

```bash
# Check health endpoint
curl http://localhost:3000/health

# Test signup
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+1234567890"
  }'
```

## 🔧 Configuration

### Environment Variables

```bash
# Server
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=rolo_db
DB_USER=rolo_user
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=7d

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_S3_BUCKET=rolo-assets

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

## 🗄️ Database Schema

The new database schema mirrors your current Supabase structure:

- **users**: User accounts with authentication
- **user_profiles**: Extended user information
- **communities**: Community organizations
- **collaborators**: User-community relationships with roles
- **members**: Community members
- **subscription_plans**: Available subscription tiers
- **community_subscriptions**: Active subscriptions
- **cards**: Different types of cards (text, email, event, etc.)
- **audit_logs**: Complete audit trail of all actions

### Key Differences from Supabase

1. **Authentication**: Custom JWT implementation instead of Supabase Auth
2. **Real-time**: WebSocket support can be added if needed
3. **Storage**: AWS S3 integration for file uploads
4. **Functions**: Custom business logic in Express routes
5. **Policies**: Application-level authorization instead of RLS

## 🔐 Authentication Flow

### Sign Up
1. User submits signup form
2. Backend creates user record with hashed password
3. Verification email sent
4. User clicks verification link
5. Account activated

### Sign In
1. User submits credentials
2. Backend verifies password hash
3. JWT token generated and returned
4. Token stored in iOS app
5. Token included in subsequent requests

### Token Management
- Tokens expire after 7 days (configurable)
- Refresh endpoint for extending sessions
- Automatic token clearing on 401 responses

## 🚀 AWS Deployment

### 1. Prerequisites

- AWS CLI configured
- Domain name with SSL certificate
- AWS account with appropriate permissions

### 2. Deploy Infrastructure

```bash
# Create CloudFormation stack
aws cloudformation create-stack \
  --stack-name rolo-backend \
  --template-body file://aws-deployment.yml \
  --parameters \
    ParameterKey=Environment,ParameterValue=production \
    ParameterKey=DomainName,ParameterValue=api.yourdomain.com \
    ParameterKey=CertificateArn,ParameterValue=arn:aws:acm:... \
    ParameterKey=DatabasePassword,ParameterValue=your_secure_password \
    ParameterKey=JWTSecret,ParameterValue=your_jwt_secret

# Wait for stack creation
aws cloudformation wait stack-create-complete --stack-name rolo-backend
```

### 3. Deploy Application

```bash
# Build and push Docker image
docker build -t rolo-backend .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com
docker tag rolo-backend:latest $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/rolo-backend:latest
docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/rolo-backend:latest

# Update ECS service
aws ecs update-service --cluster production-rolo-cluster --service production-rolo-service --force-new-deployment
```

## 📱 iOS App Updates

### 1. Replace Supabase Dependencies

Remove from `Package.swift`:
```swift
.package(url: "https://github.com/supabase-community/supabase-swift", from: "1.0.0")
```

### 2. Update Service Usage

Replace `SupabaseService` with `CustomBackendService`:

```swift
// Before (Supabase)
import Supabase
let supabase = SupabaseClient(...)

// After (Custom Backend)
import Foundation
let backendService = CustomBackendService.shared
```

### 3. Update Authentication

```swift
// Before
try await supabase.auth.signUp(email: email, password: password)

// After
try await CustomBackendService.shared.signUp(
    email: email, 
    password: password, 
    firstName: firstName, 
    lastName: lastName, 
    phoneNumber: phoneNumber
)
```

### 4. Update API Calls

```swift
// Before
let communities: [Community] = try await supabaseService.performRequest(
    endpoint: "communities"
)

// After
let communities: [Community] = try await CustomBackendService.shared.getCommunities()
```

## 🔄 Migration Steps

### Phase 1: Development & Testing
1. Set up local development environment
2. Test all API endpoints
3. Verify database schema and data integrity
4. Test authentication flow

### Phase 2: iOS App Updates
1. Create new `CustomBackendService`
2. Update all views to use new service
3. Test authentication and data flow
4. Remove Supabase dependencies

### Phase 3: Production Deployment
1. Deploy AWS infrastructure
2. Set up production database
3. Deploy backend application
4. Update iOS app configuration

### Phase 4: Data Migration
1. Export data from Supabase
2. Transform data to match new schema
3. Import data to new database
4. Verify data integrity

### Phase 5: Go Live
1. Update iOS app to production backend
2. Monitor application performance
3. Verify all functionality works
4. Decommission Supabase

## 🧪 Testing

### API Testing

```bash
# Test authentication
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "SecurePass123"}'

# Test protected endpoint
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/api/communities
```

### iOS App Testing

1. Test signup/signin flow
2. Test community creation and management
3. Test member management
4. Test subscription features
5. Test offline functionality

## 📊 Monitoring & Logging

### CloudWatch Logs
- Application logs in `/ecs/production-rolo`
- Database logs in RDS console
- Load balancer access logs

### Health Checks
- `/health` endpoint for load balancer
- Database connection monitoring
- Application performance metrics

### Error Tracking
- Comprehensive error logging
- Audit trail for all actions
- Performance monitoring

## 🔒 Security Features

### Authentication
- JWT tokens with configurable expiration
- Password hashing with bcrypt
- Email verification required
- Password reset functionality

### Authorization
- Role-based access control
- Community-level permissions
- Resource ownership validation

### Data Protection
- HTTPS everywhere
- Database encryption at rest
- Secure environment variables
- Input validation and sanitization

## 🚀 Performance Optimizations

### Database
- Proper indexing on all tables
- Connection pooling
- Query optimization
- Regular maintenance

### Application
- Response caching
- Rate limiting
- Efficient data serialization
- Background job processing

### Infrastructure
- Auto-scaling ECS tasks
- CDN for static assets
- Load balancer health checks
- Multi-AZ database deployment

## 🆘 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check security group rules
   - Verify database endpoint
   - Check credentials

2. **Authentication Errors**
   - Verify JWT secret
   - Check token expiration
   - Validate user permissions

3. **CORS Issues**
   - Update CORS configuration
   - Check frontend domain
   - Verify preflight requests

### Debug Commands

```bash
# Check database connection
npm run migrate

# Test email configuration
node -e "require('./src/services/emailService').testEmailConfig()"

# View application logs
docker-compose logs backend

# Check database status
docker-compose exec postgres psql -U rolo_user -d rolo_db -c "SELECT version();"
```

## 📚 Additional Resources

- [Express.js Documentation](https://expressjs.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [JWT.io](https://jwt.io/) for token debugging

## 🎯 Next Steps

After successful migration:

1. **Add Real-time Features**: Implement WebSocket support for live updates
2. **Advanced Analytics**: Add comprehensive reporting and analytics
3. **Mobile Push Notifications**: Integrate with APNS/FCM
4. **Advanced Caching**: Implement Redis for better performance
5. **API Documentation**: Generate OpenAPI/Swagger documentation
6. **Testing Suite**: Add comprehensive unit and integration tests

## 📞 Support

For migration assistance:
1. Review this guide thoroughly
2. Test in development environment first
3. Check logs for detailed error information
4. Verify all configuration parameters
5. Test each feature incrementally

---

**Happy Migrating! 🚀**

This custom backend will give you full control over your data, better performance, and the flexibility to scale as your community grows.
