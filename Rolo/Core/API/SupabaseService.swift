import Foundation
import Combine
import Supabase

enum SupabaseError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case serverError(String)
    case notFound(String)
    case unknown(String)
    case authError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .unknown(let message):
            return message
        case .authError(let message):
            return message
        }
    }
}

class SupabaseService {
    static let shared = SupabaseService()
    
    private init() {}
    
    private let baseURL = SupabaseConfig.projectURL
    private let apiKey = SupabaseConfig.anonKey
    
    // Create a decoder that can handle the ISO8601 date format from Supabase
    private lazy var decoder: JSONDecoder = {
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
    }()
    
    // MARK: - Helper Methods
    
    private func createRequest(endpoint: String, method: String) async -> URLRequest? {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(endpoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        // Try to get the user's session token for authenticated requests
        do {
            let session = try await supabase.auth.session
            request.addValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            print("🔍 Debug: Using user session token for authentication")
        } catch {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            print("🔍 Debug: Error getting session, using anon key: \(error)")
        }
        
        return request
    }
    
    private func createAuthRequest(endpoint: String, method: String) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        return request
    }
    
    // MARK: - Async/Await Methods for Auth Service
    
    func performRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        
        let isAuthEndpoint = endpoint.starts(with: "/auth/")
        
        var request: URLRequest
        if isAuthEndpoint {
            guard let authRequest = createAuthRequest(endpoint: endpoint, method: method) else {
                throw SupabaseError.invalidURL
            }
            request = authRequest
        } else {
            guard let restRequest = await createRequest(endpoint: endpoint, method: method) else {
                throw SupabaseError.invalidURL
            }
            request = restRequest
        }
        
        // Add custom headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Debug authentication headers
        print("🔍 Debug: Authorization header: \(request.value(forHTTPHeaderField: "Authorization") ?? "None")")
        print("🔍 Debug: API key header: \(request.value(forHTTPHeaderField: "apikey") ?? "None")")
        
        // Decode and inspect JWT token
        if let authHeader = request.value(forHTTPHeaderField: "Authorization"),
           authHeader.hasPrefix("Bearer ") {
            let token = String(authHeader.dropFirst(7))
            print("🔍 Debug: JWT Token: \(token)")
            
            // Try to decode JWT payload (base64 part)
            let parts = token.components(separatedBy: ".")
            if parts.count >= 2 {
                let payload = parts[1]
                if let data = Data(base64Encoded: payload + String(repeating: "=", count: (4 - payload.count % 4) % 4)),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("🔍 Debug: JWT Payload: \(json)")
                    if let sub = json["sub"] as? String {
                        print("🔍 Debug: JWT sub (user_id): \(sub)")
                    }
                    if let role = json["role"] as? String {
                        print("🔍 Debug: JWT role: \(role)")
                    }
                }
            }
        }
        
        // Add body if provided
        if let body = body {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body)
                request.httpBody = jsonData
            } catch {
                print("❌ SupabaseService: JSON serialization error: \(error)")
                throw SupabaseError.networkError(error)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            print("🔍 Debug: Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 400 {
                // Try to parse error response
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorDict["message"] as? String {
                    print("❌ SupabaseService: Server error: \(message)")
                    throw SupabaseError.authError(message)
                } else {
                    print("❌ SupabaseService: HTTP error: \(httpResponse.statusCode)")
                    throw SupabaseError.serverError(httpResponse.statusCode.description)
                }
            }
            
            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                print("❌ SupabaseService: Decoding error: \(error)")
                throw SupabaseError.decodingError
            }
            
        } catch let error as SupabaseError {
            throw error
        } catch {
            print("❌ SupabaseService: Network error: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Generic Request Methods (Original Combine-based)
    
    func fetch<T: Decodable>(_ type: T.Type, from endpoint: String) async throws -> T {
        guard let request = await createRequest(endpoint: endpoint, method: "GET") else {
            throw SupabaseError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode >= 400 {
            throw SupabaseError.serverError(httpResponse.statusCode.description)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SupabaseError.decodingError
        }
    }
} 
