//
//  UserManagementService.swift
//  NtfyMenuBar
//
//  Created by Claude on 20/09/2025.
//

import Foundation
import Combine

@MainActor
class UserManagementService: ObservableObject {
    @Published var users: [NtfyUser] = []
    @Published var isLoading = false
    @Published var error: UserManagementError?

    private var settings: NtfySettings
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    init(settings: NtfySettings) {
        self.settings = settings
    }

    func updateSettings(_ newSettings: NtfySettings) {
        settings = newSettings
    }

    // MARK: - User Operations

    func loadUsers() async {
        isLoading = true
        error = nil

        do {
            let fetchedUsers = try await fetchUsers()
            users = fetchedUsers.sorted { $0.username < $1.username }
        } catch let userError as UserManagementError {
            error = userError
        } catch {
            self.error = .networkError(error)
        }

        isLoading = false
    }

    func createUser(username: String, password: String, role: UserRole) async throws {
        guard isValidUsername(username) else {
            throw UserManagementError.invalidUsername
        }

        guard isValidPassword(password) else {
            throw UserManagementError.invalidPassword
        }

        isLoading = true
        error = nil

        do {
            try await performCreateUser(username: username, password: password, role: role)
            await loadUsers() // Refresh the list
        } catch {
            isLoading = false
            throw error
        }

        isLoading = false
    }

    func deleteUser(_ user: NtfyUser) async throws {
        // Prevent deletion of system user and self
        if user.isSystemUser {
            throw UserManagementError.cannotModifySystemUser
        }

        if user.username == settings.username {
            throw UserManagementError.cannotDeleteSelf
        }

        isLoading = true
        error = nil

        do {
            try await performDeleteUser(username: user.username)
            users.removeAll { $0.username == user.username }
        } catch {
            isLoading = false
            throw error
        }

        isLoading = false
    }

    func changeUserRole(_ user: NtfyUser, to newRole: UserRole) async throws {
        if user.isSystemUser {
            throw UserManagementError.cannotModifySystemUser
        }

        isLoading = true
        error = nil

        do {
            try await performChangeRole(username: user.username, role: newRole)
            await loadUsers() // Refresh to get updated data
        } catch {
            isLoading = false
            throw error
        }

        isLoading = false
    }

    func changeUserPassword(_ user: NtfyUser, newPassword: String) async throws {
        guard isValidPassword(newPassword) else {
            throw UserManagementError.invalidPassword
        }

        if user.isSystemUser {
            throw UserManagementError.cannotModifySystemUser
        }

        isLoading = true
        error = nil

        do {
            try await performChangePassword(username: user.username, password: newPassword)
        } catch {
            isLoading = false
            throw error
        }

        isLoading = false
    }

    // MARK: - Private Implementation

    private func fetchUsers() async throws -> [NtfyUser] {
        guard let url = createUsersURL() else {
            throw UserManagementError.serverError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        addAuthenticationHeader(to: &request)

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserManagementError.serverError("Invalid response type")
            }

            try handleHTTPResponse(httpResponse)

            let users = try JSONDecoder().decode([NtfyUser].self, from: data)
            return users
        } catch let userError as UserManagementError {
            throw userError
        } catch {
            throw UserManagementError.networkError(error)
        }
    }

    private func performCreateUser(username: String, password: String, role: UserRole) async throws {
        guard let url = createUsersURL() else {
            throw UserManagementError.serverError("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthenticationHeader(to: &request)

        let createRequest = CreateUserRequest(username: username, password: password, role: role)

        do {
            request.httpBody = try JSONEncoder().encode(createRequest)

            let (_, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserManagementError.serverError("Invalid response type")
            }

            try handleHTTPResponse(httpResponse)
        } catch let userError as UserManagementError {
            throw userError
        } catch {
            throw UserManagementError.networkError(error)
        }
    }

    private func performDeleteUser(username: String) async throws {
        guard let url = createUserURL(for: username) else {
            throw UserManagementError.invalidUsername
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addAuthenticationHeader(to: &request)

        do {
            let (_, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserManagementError.serverError("Invalid response type")
            }

            try handleHTTPResponse(httpResponse)
        } catch let userError as UserManagementError {
            throw userError
        } catch {
            throw UserManagementError.networkError(error)
        }
    }

    private func performChangeRole(username: String, role: UserRole) async throws {
        guard let url = createUserRoleURL(for: username) else {
            throw UserManagementError.invalidUsername
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthenticationHeader(to: &request)

        let roleRequest = ChangeRoleRequest(role: role)

        do {
            request.httpBody = try JSONEncoder().encode(roleRequest)

            let (_, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserManagementError.serverError("Invalid response type")
            }

            try handleHTTPResponse(httpResponse)
        } catch let userError as UserManagementError {
            throw userError
        } catch {
            throw UserManagementError.networkError(error)
        }
    }

    private func performChangePassword(username: String, password: String) async throws {
        guard let url = createUserPasswordURL(for: username) else {
            throw UserManagementError.invalidUsername
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthenticationHeader(to: &request)

        let passwordRequest = ChangePasswordRequest(password: password)

        do {
            request.httpBody = try JSONEncoder().encode(passwordRequest)

            let (_, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserManagementError.serverError("Invalid response type")
            }

            try handleHTTPResponse(httpResponse)
        } catch let userError as UserManagementError {
            throw userError
        } catch {
            throw UserManagementError.networkError(error)
        }
    }

    // MARK: - URL Creation

    private func createUsersURL() -> URL? {
        var baseURL = settings.serverURL

        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            baseURL = "https://" + baseURL
        }

        let urlString = "\(baseURL)/v1/users"
        return URL(string: urlString)
    }

    private func createUserURL(for username: String) -> URL? {
        var baseURL = settings.serverURL

        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            baseURL = "https://" + baseURL
        }

        let urlString = "\(baseURL)/v1/users/\(username)"
        return URL(string: urlString)
    }

    private func createUserRoleURL(for username: String) -> URL? {
        var baseURL = settings.serverURL

        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            baseURL = "https://" + baseURL
        }

        let urlString = "\(baseURL)/v1/users/\(username)/role"
        return URL(string: urlString)
    }

    private func createUserPasswordURL(for username: String) -> URL? {
        var baseURL = settings.serverURL

        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            baseURL = "https://" + baseURL
        }

        let urlString = "\(baseURL)/v1/users/\(username)/password"
        return URL(string: urlString)
    }

    // MARK: - Authentication

    private func addAuthenticationHeader(to request: inout URLRequest) {
        switch settings.authMethod {
        case .basicAuth:
            guard !settings.username.isEmpty else { return }

            let password = SettingsManager.loadPassword(for: settings.username) ?? ""
            let credentials = "\(settings.username):\(password)"

            if let authData = credentials.data(using: .utf8) {
                let base64Credentials = authData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }

        case .accessToken:
            guard let token = SettingsManager.loadAccessToken(),
                  SettingsManager.validateAccessToken(token) else { return }

            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    // MARK: - Validation & Error Handling

    private func isValidUsername(_ username: String) -> Bool {
        let pattern = "^[a-zA-Z0-9_-]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: username.utf16.count)

        return !username.isEmpty &&
               username.count >= 3 &&
               username.count <= 32 &&
               regex?.firstMatch(in: username, options: [], range: range) != nil
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }

    private func handleHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return // Success
        case 400:
            throw UserManagementError.invalidUsername
        case 401, 403:
            throw UserManagementError.insufficientPermissions
        case 404:
            throw UserManagementError.userNotFound
        case 409:
            throw UserManagementError.userAlreadyExists
        default:
            throw UserManagementError.serverError("HTTP \(response.statusCode)")
        }
    }
}