# Rolo App - Community Management

Rolo is a community management app designed to help administrators manage members, events, donations, and tasks.

## Supabase Integration

This project uses Supabase as a backend. Follow these steps to set up:

### 1. Add Supabase Swift Package

In Xcode:
1. Go to File > Add Packages
2. Enter the repository URL: `https://github.com/supabase-community/supabase-swift`
3. Select version: "Up to Next Major (1.0.0)"
4. Click Add Package

### 2. Configuration Settings

The app is configured to work with a Supabase project. The configuration is stored in:
```swift
Core/API/SupabaseConfig.swift
```

This file contains:
- Project URL
- Anonymous API Key

### 3. Database Schema

The database schema includes:

- **Communities**: Groups that contain members
- **Users**: App users with roles (admin, limited_admin, viewer)
- **CommunityUsers**: Links users to communities with roles 
- **Members**: Individual members within a community
- **Donations**: Donation records linked to members
- **Tasks**: Tasks that can be assigned to users

### 4. Model Integration

The app includes integration models that map between Supabase database entities and app models:

- `MemberDB` <-> `AgendaTask`
- `CardTypeDB` <-> `CardType`

### 5. API Services

The app provides services for interacting with Supabase:

- `SupabaseService.swift`: Handles API calls to Supabase
- `SupabaseIntegration.swift`: Helps convert between app and database models

## Development

To continue development:

1. Complete the Swift Package Manager integration
2. Implement the update methods in SupabaseService for full CRUD operations
3. Add authentication flow with Supabase Auth
4. Implement offline caching with Combine

## Project Structure

- **Core/API**: Contains all Supabase integration files
- **cardTypes**: Contains different card type implementations
- **Assets**: Contains image assets and resources 