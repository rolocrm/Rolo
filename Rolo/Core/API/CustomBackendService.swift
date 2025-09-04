//import Foundation
//import SwiftUI
//import Combine
//
//// MARK: - Custom Backend Configuration
//struct CustomBackendConfig {
//    static let baseURL = "https://api.yourdomain.com" // Change this to your actual domain
//    static let apiVersion = "v1"
//    
//    static var fullBaseURL: String {
//        "\(baseURL)/api/\(apiVersion)"
//    }
//}
//
//// MARK: - Custom Backend Errors
//enum CustomBackendError: Error, LocalizedError {
//    case invalidURL
//    case invalidResponse
//    case decodingError
//    case networkError(Error)
//    case serverError(String)
//    case notFound(String)
//    case unauthorized
//    case forbidden
//    case conflict(String)
//    case validationError([String])
//    case unknown(String)
//    
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL:
//            return "Invalid URL"
//        case .invalidResponse:
//            return "Invalid response from server"
//        case .decodingError:
//            return "Failed to decode response"
//        case .networkError(let error):
//            return "Network error: \(error.localizedDescription)"
//        case .serverError(let message):
//            return "Server error: \(message)"
//        case .notFound(let message):
//            return "Not found: \(message)"
//        case .unauthorized:
//            return "Unauthorized. Please sign in again."
//        case .forbidden:
//            return "Access denied"
//        case .conflict(let message):
//            return "Conflict: \(message)"
//        case .validationError(let errors):
//            return "Validation errors: \(errors.joined(separator: ", "))"
//        case .unknown(let message):
//            return message
//        }
//    }
//}
//
//// MARK: - Custom Backend Service
//class CustomBackendService: ObservableObject {
//    static let shared = CustomBackendService()
//    
//    private var cancellables = Set<AnyCancellable>()
//    private let session = URLSession.shared
//    
//    // JWT Token management
//    @Published var authToken: String?
//    @Published var isAuthenticated = false
//    
//    private init() {
//        // Load saved token
//        authToken = UserDefaults.standard.string(forKey: "auth_token")
//        isAuthenticated = authToken != nil
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func createRequest(endpoint: String, method: String, body: Data? = nil) -> URLRequest? {
//        guard let url = URL(string: "\(CustomBackendConfig.fullBaseURL)/\(endpoint)") else {
//            return nil
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = method
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        if let body = body {
//            request.httpBody = body
//        }
//        
//        // Add authorization header if token exists
//        if let token = authToken {
//            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        }
//        
//        return request
//    }
//    
//    private func handleResponse<T: Codable>(_ data: Data, _ response: URLResponse) throws -> T {
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw CustomBackendError.invalidResponse
//        }
//        
//        // Handle different HTTP status codes
//        switch httpResponse.statusCode {
//        case 200...299:
//            do {
//                let decoder = JSONDecoder()
//                decoder.dateDecodingStrategy = .iso8601
//                return try decoder.decode(T.self, from: data)
//            } catch {
//                throw CustomBackendError.decodingError
//            }
//        case 400:
//            // Try to parse validation errors
//            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
//                if let errors = errorResponse.errors {
//                    throw CustomBackendError.validationError(errors)
//                }
//            }
//            throw CustomBackendError.serverError("Bad request")
//        case 401:
//            // Clear token and set as unauthenticated
//            await MainActor.run {
//                self.clearAuthToken()
//            }
//            throw CustomBackendError.unauthorized
//        case 403:
//            throw CustomBackendError.forbidden
//        case 404:
//            throw CustomBackendError.notFound("Resource not found")
//        case 409:
//            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
//                throw CustomBackendError.conflict(errorResponse.error ?? "Conflict occurred")
//            }
//            throw CustomBackendError.conflict("Conflict occurred")
//        case 500...599:
//            throw CustomBackendError.serverError("Server error occurred")
//        default:
//            throw CustomBackendError.unknown("Unexpected status code: \(httpResponse.statusCode)")
//        }
//    }
//    
//    private func performRequest<T: Codable>(endpoint: String, method: String, body: Data? = nil) async throws -> T {
//        guard let request = createRequest(endpoint: endpoint, method: method, body: body) else {
//            throw CustomBackendError.invalidURL
//        }
//        
//        do {
//            let (data, response) = try await session.data(for: request)
//            return try handleResponse(data, response)
//        } catch {
//            if let customError = error as? CustomBackendError {
//                throw customError
//            }
//            throw CustomBackendError.networkError(error)
//        }
//    }
//    
//    // MARK: - Authentication Methods
//    
//    func signUp(email: String, password: String, firstName: String, lastName: String, phoneNumber: String?) async throws -> SignUpResponse {
//        let signUpData = SignUpRequest(
//            email: email,
//            password: password,
//            firstName: firstName,
//            lastName: lastName,
//            phoneNumber: phoneNumber
//        )
//        
//        let body = try JSONEncoder().encode(signUpData)
//        return try await performRequest(endpoint: "auth/signup", method: "POST", body: body)
//    }
//    
//    func signIn(email: String, password: String) async throws -> SignInResponse {
//        let signInData = SignInRequest(email: email, password: password)
//        let body = try JSONEncoder().encode(signInData)
//        
//        let response: SignInResponse = try await performRequest(endpoint: "auth/signin", method: "POST", body: body)
//        
//        // Save token and update authentication state
//        await MainActor.run {
//            self.authToken = response.token
//            self.isAuthenticated = true
//            UserDefaults.standard.set(response.token, forKey: "auth_token")
//        }
//        
//        return response
//    }
//    
//    func signOut() {
//        clearAuthToken()
//    }
//    
//    private func clearAuthToken() {
//        authToken = nil
//        isAuthenticated = false
//        UserDefaults.standard.removeObject(forKey: "auth_token")
//    }
//    
//    func refreshToken() async throws -> TokenRefreshResponse {
//        guard let token = authToken else {
//            throw CustomBackendError.unauthorized
//        }
//        
//        let refreshData = TokenRefreshRequest(token: token)
//        let body = try JSONEncoder().encode(refreshData)
//        
//        let response: TokenRefreshResponse = try await performRequest(endpoint: "auth/refresh", method: "POST", body: body)
//        
//        // Update token
//        await MainActor.run {
//            self.authToken = response.token
//            UserDefaults.standard.set(response.token, forKey: "auth_token")
//        }
//        
//        return response
//    }
//    
//    // MARK: - User Profile Methods
//    
//    func getUserProfile() async throws -> UserProfile {
//        return try await performRequest(endpoint: "users/profile", method: "GET")
//    }
//    
//    func updateUserProfile(firstName: String, lastName: String, phoneNumber: String?, avatarUrl: String?) async throws -> UserProfile {
//        let updateData = UserProfileUpdateRequest(
//            firstName: firstName,
//            lastName: lastName,
//            phoneNumber: phoneNumber,
//            avatarUrl: avatarUrl
//        )
//        
//        let body = try JSONEncoder().encode(updateData)
//        return try await performRequest(endpoint: "users/profile", method: "PUT", body: body)
//    }
//    
//    // MARK: - Community Methods
//    
//    func getCommunities() async throws -> [Community] {
//        return try await performRequest(endpoint: "communities", method: "GET")
//    }
//    
//    func getCommunity(id: String) async throws -> Community {
//        return try await performRequest(endpoint: "communities/\(id)", method: "GET")
//    }
//    
//    func createCommunity(request: CommunityCreationRequest) async throws -> Community {
//        let body = try JSONEncoder().encode(request)
//        return try await performRequest(endpoint: "communities", method: "POST", body: body)
//    }
//    
//    func updateCommunity(id: String, updates: [String: Any]) async throws -> Community {
//        let body = try JSONSerialization.data(withJSONObject: updates)
//        return try await performRequest(endpoint: "communities/\(id)", method: "PUT", body: body)
//    }
//    
//    func deleteCommunity(id: String) async throws {
//        let _: EmptyResponse = try await performRequest(endpoint: "communities/\(id)", method: "DELETE")
//    }
//    
//    // MARK: - Member Methods
//    
//    func getMembers(communityId: String) async throws -> [Member] {
//        return try await performRequest(endpoint: "communities/\(communityId)/members", method: "GET")
//    }
//    
//    func createMember(communityId: String, member: MemberCreationRequest) async throws -> Member {
//        let body = try JSONEncoder().encode(member)
//        return try await performRequest(endpoint: "communities/\(communityId)/members", method: "POST", body: body)
//    }
//    
//    func updateMember(communityId: String, memberId: String, updates: [String: Any]) async throws -> Member {
//        let body = try JSONSerialization.data(withJSONObject: updates)
//        return try await performRequest(endpoint: "communities/\(communityId)/members/\(memberId)", method: "PUT", body: body)
//    }
//    
//    func deleteMember(communityId: String, memberId: String) async throws {
//        let _: EmptyResponse = try await performRequest(endpoint: "communities/\(communityId)/members/\(memberId)", method: "DELETE")
//    }
//    
//    // MARK: - Subscription Methods
//    
//    func getSubscriptionPlans() async throws -> [SubscriptionPlan] {
//        return try await performRequest(endpoint: "subscriptions/plans", method: "GET")
//    }
//    
//    func getCommunitySubscription(communityId: String) async throws -> CommunitySubscription {
//        return try await performRequest(endpoint: "communities/\(communityId)/subscription", method: "GET")
//    }
//}
//
//// MARK: - Request/Response Models
//
//struct SignUpRequest: Codable {
//    let email: String
//    let password: String
//    let firstName: String
//    let lastName: String
//    let phoneNumber: String?
//}
//
//struct SignUpResponse: Codable {
//    let message: String
//    let userId: String
//}
//
//struct SignInRequest: Codable {
//    let email: String
//    let password: String
//}
//
//struct SignInResponse: Codable {
//    let user: AuthUser
//    let token: String
//    let expiresIn: String
//}
//
//struct TokenRefreshRequest: Codable {
//    let token: String
//}
//
//struct TokenRefreshResponse: Codable {
//    let token: String
//    let expiresIn: String
//}
//
//struct UserProfileUpdateRequest: Codable {
//    let firstName: String
//    let lastName: String
//    let phoneNumber: String?
//    let avatarUrl: String?
//}
//
//struct MemberCreationRequest: Codable {
//    let firstName: String
//    let lastName: String
//    let email: String?
//    let phoneNumber: String?
//    let address: String?
//    let city: String?
//    let state: String?
//    let zip: String?
//    let country: String?
//    let dateOfBirth: Date?
//    let notes: String?
//}
//
//struct EmptyResponse: Codable {}
//
//struct ErrorResponse: Codable {
//    let error: String?
//    let errors: [String]?
//}
//
//// MARK: - Extensions
//
//extension JSONDecoder {
//    static let iso8601: JSONDecoder = {
//        let decoder = JSONDecoder()
//        let formatter = ISO8601DateFormatter()
//        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
//        decoder.dateDecodingStrategy = .custom { decoder in
//            let container = try decoder.singleValueContainer()
//            let dateString = try container.decode(String.self)
//            
//            if let date = formatter.date(from: dateString) {
//                return date
//            }
//            
//            throw DecodingError.dataCorruptedError(
//                in: container,
//                debugDescription: "Cannot decode date string \(dateString)"
//            )
//        }
//        return decoder
//    }()
//}
