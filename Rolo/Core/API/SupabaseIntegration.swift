import Foundation
import SwiftUI
import Combine

/// This class handles the integration between the app's existing model and the Supabase backend
class SupabaseIntegration {
    static let shared = SupabaseIntegration()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - JSON Decoders and Encoders
    
    /// Creates a JSONDecoder configured for Supabase's date format
    func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
        return decoder
    }
    
    /// Creates a JSONEncoder configured for Supabase's date format
    func createEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(dateFormatter.string(from: date))
        }
        return encoder
    }
    
    // MARK: - Onboarding Support
    
    /// Checks if the user has completed onboarding
    func hasCompletedOnboarding(userId: UUID, completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                let userProfiles: [UserProfile] = try await SupabaseService.shared.performRequest(
                    endpoint: "user_profiles?user_id=eq.\(userId.uuidString.lowercased())"
                )
                
                if let profile = userProfiles.first, profile.completedProfile {
                    // Check if user has community access
                    let collaborators: [Collaborator] = try await SupabaseService.shared.performRequest(
                        endpoint: "collaborators?user_id=eq.\(userId.uuidString.lowercased())&status=eq.approved"
                    )
                    
                    completion(.success(!collaborators.isEmpty))
                } else {
                    completion(.success(false))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Initializes the app with data from Supabase for authenticated users
    func initializeApp(completion: @escaping (Result<Bool, Error>) -> Void) {
        // For the onboarding flow, we'll check if user has completed setup
        // This is a placeholder for future expansion when we add more features
        completion(.success(true))
    }
    
    // MARK: - Utility Methods
    
    /// Generic fetch method for onboarding data
    func fetch<T: Codable>(_ type: T.Type, from endpoint: String) async throws -> [T] {
        return try await SupabaseService.shared.fetch([T].self, from: endpoint)
    }
} 
