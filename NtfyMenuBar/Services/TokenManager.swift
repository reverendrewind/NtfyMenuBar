//
//  TokenManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 20/01/2025.
//

import Foundation

enum TokenError: LocalizedError {
    case invalidServerURL
    case missingCredentials
    case authenticationFailed
    case networkError(Error)
    case invalidResponse
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Invalid server URL"
        case .missingCredentials:
            return "Missing authentication credentials"
        case .authenticationFailed:
            return "Authentication failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}

struct TokenResponse: Codable {
    let token: String
    let lastAccess: Int?
    let lastOrigin: String?
    let expires: Int?

    enum CodingKeys: String, CodingKey {
        case token
        case lastAccess = "last_access"
        case lastOrigin = "last_origin"
        case expires
    }
}

@MainActor
class TokenManager {
    static let shared = TokenManager()

    private init() {}

    func generateToken(
        serverURL: String,
        authMethod: AuthenticationMethod,
        username: String,
        password: String,
        accessToken: String,
        label: String?,
        expiration: TokenExpiration
    ) async throws -> AccessToken {

        // Validate server URL
        guard let url = createTokenURL(from: serverURL) else {
            throw TokenError.invalidServerURL
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authentication
        try addAuthenticationHeader(to: &request, authMethod: authMethod, username: username, password: password, accessToken: accessToken)

        // Create request body
        var requestBody: [String: Any] = [:]

        if let label = label, !label.isEmpty {
            requestBody["label"] = label
        }

        if let timeInterval = expiration.timeInterval {
            let expirationTime = Int(Date().timeIntervalSince1970 + timeInterval)
            requestBody["expires"] = expirationTime
        }

        // Add request body if not empty
        if !requestBody.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        }

        print("🔑 Generating token at: \(url)")
        print("🔑 Request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("🔑 Request body: \(requestBody)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TokenError.invalidResponse
            }

            print("🔑 HTTP Status: \(httpResponse.statusCode)")
            print("🔑 Response headers: \(httpResponse.allHeaderFields)")

            if let responseString = String(data: data, encoding: .utf8) {
                print("🔑 Response body: \(responseString)")
            }

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TokenError.serverError(httpResponse.statusCode, errorMessage)
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

            // Create AccessToken object
            let accessToken = AccessToken(
                token: tokenResponse.token,
                label: label,
                lastAccess: tokenResponse.lastAccess,
                lastOrigin: tokenResponse.lastOrigin,
                expires: tokenResponse.expires,
                created: Date()
            )

            print("✅ Token generated successfully: \(accessToken.maskedToken)")
            return accessToken

        } catch let error as TokenError {
            throw error
        } catch {
            throw TokenError.networkError(error)
        }
    }

    private func createTokenURL(from serverURL: String) -> URL? {
        var baseURL = serverURL

        // Ensure HTTP/HTTPS protocol
        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            baseURL = "https://" + baseURL
        }

        // Remove trailing slashes
        while baseURL.hasSuffix("/") {
            baseURL = String(baseURL.dropLast())
        }

        return URL(string: "\(baseURL)/v1/account/token")
    }

    private func addAuthenticationHeader(
        to request: inout URLRequest,
        authMethod: AuthenticationMethod,
        username: String,
        password: String,
        accessToken: String
    ) throws {
        switch authMethod {
        case .basicAuth:
            guard !username.isEmpty else {
                throw TokenError.missingCredentials
            }

            let credentials = "\(username):\(password)"
            guard let authData = credentials.data(using: .utf8) else {
                throw TokenError.authenticationFailed
            }

            let base64Credentials = authData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        case .accessToken:
            guard !accessToken.isEmpty else {
                throw TokenError.missingCredentials
            }

            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
    }
}