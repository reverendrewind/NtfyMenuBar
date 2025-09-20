//
//  NtfyMessage.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import Foundation

struct NtfyMessage: Codable, Identifiable, Equatable {
    let id: String
    let time: Int
    let event: String
    let topic: String
    let message: String?
    let title: String?
    let priority: Int?
    let tags: [String]?
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(time))
    }
    
    var displayTitle: String {
        title ?? "ntfy Notification"
    }
    
    var isKeepalive: Bool {
        event == "keepalive"
    }
    
    var priorityDescription: String {
        switch priority {
        case 1: return "Min"
        case 2: return "Low"
        case 3: return "Default"
        case 4: return "High"
        case 5: return "Max"
        default: return "Default"
        }
    }
}

enum AuthenticationMethod: String, Codable, CaseIterable {
    case basicAuth = "basic"
    case accessToken = "token"
    
    var displayName: String {
        switch self {
        case .basicAuth:
            return "Username & Password"
        case .accessToken:
            return "Access Token"
        }
    }
}

enum AppearanceMode: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
}

struct NtfySettings: Codable {
    var serverURL: String = ""
    var topic: String = ""
    var authMethod: AuthenticationMethod = .basicAuth
    var username: String = ""
    var enableNotifications: Bool = true
    var maxRecentMessages: Int = 20
    var autoConnect: Bool = true
    var appearanceMode: AppearanceMode = .system
    
    // Password and token stored separately in Keychain for security
    var isConfigured: Bool {
        guard !serverURL.isEmpty && !topic.isEmpty else { return false }
        
        switch authMethod {
        case .basicAuth:
            return !username.isEmpty
        case .accessToken:
            return true // Token validation happens in Keychain retrieval
        }
    }
    
    static let `default` = NtfySettings()
}