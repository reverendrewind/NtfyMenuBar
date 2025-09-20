//
//  NtfyUser.swift
//  NtfyMenuBar
//
//  Created by Claude on 20/09/2025.
//

import Foundation

struct NtfyUser: Codable, Identifiable, Equatable {
    let username: String
    let role: String
    let grants: [NtfyGrant]?

    var id: String { username }

    var displayRole: String {
        switch role.lowercased() {
        case "admin":
            return "Admin"
        case "user":
            return "User"
        case "anonymous":
            return "Anonymous"
        default:
            return role.capitalized
        }
    }

    var roleColor: String {
        switch role.lowercased() {
        case "admin":
            return "red"
        case "user":
            return "blue"
        case "anonymous":
            return "gray"
        default:
            return "secondary"
        }
    }

    var isAdmin: Bool {
        role.lowercased() == "admin"
    }

    var isSystemUser: Bool {
        username == "*"
    }

    var topicCount: Int {
        grants?.count ?? 0
    }

    var hasWildcardAccess: Bool {
        grants?.contains { $0.topic == "*" } ?? false
    }
}

struct NtfyGrant: Codable, Equatable {
    let topic: String
    let read: Bool?
    let write: Bool?

    var permissions: String {
        let canRead = read ?? false
        let canWrite = write ?? false

        switch (canRead, canWrite) {
        case (true, true):
            return "Read/Write"
        case (true, false):
            return "Read Only"
        case (false, true):
            return "Write Only"
        default:
            return "No Access"
        }
    }

    var permissionIcon: String {
        let canRead = read ?? false
        let canWrite = write ?? false

        switch (canRead, canWrite) {
        case (true, true):
            return "pencil"
        case (true, false):
            return "eye"
        case (false, true):
            return "square.and.pencil"
        default:
            return "xmark"
        }
    }
}

// MARK: - API Request/Response Models

struct CreateUserRequest: Codable {
    let username: String
    let password: String
    let role: String?

    init(username: String, password: String, role: UserRole = .user) {
        self.username = username
        self.password = password
        self.role = role.rawValue
    }
}

struct ChangePasswordRequest: Codable {
    let password: String
}

struct ChangeRoleRequest: Codable {
    let role: String

    init(role: UserRole) {
        self.role = role.rawValue
    }
}

enum UserRole: String, CaseIterable, Codable {
    case admin = "admin"
    case user = "user"

    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .user:
            return "User"
        }
    }

    var description: String {
        switch self {
        case .admin:
            return "Full server access and user management"
        case .user:
            return "Standard user with topic access"
        }
    }

    var systemImage: String {
        switch self {
        case .admin:
            return "crown"
        case .user:
            return "person"
        }
    }
}

// MARK: - User Management Errors

enum UserManagementError: LocalizedError {
    case invalidUsername
    case userAlreadyExists
    case userNotFound
    case insufficientPermissions
    case invalidPassword
    case cannotDeleteSelf
    case cannotModifySystemUser
    case serverError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Invalid username. Use only letters, numbers, dashes, and underscores."
        case .userAlreadyExists:
            return "A user with this username already exists."
        case .userNotFound:
            return "The specified user was not found."
        case .insufficientPermissions:
            return "You don't have permission to perform this operation."
        case .invalidPassword:
            return "Password must be at least 8 characters long."
        case .cannotDeleteSelf:
            return "You cannot delete your own user account."
        case .cannotModifySystemUser:
            return "Cannot modify the system anonymous user."
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}