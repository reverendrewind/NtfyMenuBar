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

    // Unique identifier for SwiftUI ForEach - combines original ID with timestamp
    var uniqueId: String {
        return "\(id)-\(time)-\(topic)"
    }
    
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
            return "Access token"
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

enum NotificationSound: String, Codable, CaseIterable {
    case `default` = "default"
    case basso = "Basso"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case glass = "Glass"
    case hero = "Hero"
    case morse = "Morse"
    case ping = "Ping"
    case pop = "Pop"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case tink = "Tink"

    var displayName: String {
        switch self {
        case .default:
            return "Default"
        default:
            return rawValue
        }
    }

    var fileName: String? {
        switch self {
        case .default:
            return nil // Uses system default
        default:
            return rawValue
        }
    }
}

struct NtfyServer: Codable, Equatable, Identifiable {
    var id = UUID()
    var url: String = ""
    var name: String = ""
    var authMethod: AuthenticationMethod = .basicAuth
    var username: String = ""
    var isEnabled: Bool = true

    var displayName: String {
        return name.isEmpty ? cleanURL : name
    }

    var cleanURL: String {
        var serverURL = url

        // Remove protocol prefix for cleaner display
        if serverURL.hasPrefix("https://") {
            serverURL = String(serverURL.dropFirst(8))
        } else if serverURL.hasPrefix("http://") {
            serverURL = String(serverURL.dropFirst(7))
        }

        // Remove trailing slashes
        while serverURL.hasSuffix("/") {
            serverURL = String(serverURL.dropLast())
        }

        return serverURL.isEmpty ? "Not configured" : serverURL
    }

    var isConfigured: Bool {
        guard !url.isEmpty else { return false }

        switch authMethod {
        case .basicAuth:
            return !username.isEmpty || url.contains("ntfy.sh") // Public servers don't need auth
        case .accessToken:
            return true // Token validation happens in Keychain retrieval
        }
    }
}

struct NtfySettings: Codable, Equatable {
    var serverURL: String = ""
    var fallbackServers: [NtfyServer] = []
    var topics: [String] = []
    var authMethod: AuthenticationMethod = .basicAuth
    var username: String = ""
    var enableNotifications: Bool = true
    var maxRecentMessages: Int = 20
    var autoConnect: Bool = true
    var appearanceMode: AppearanceMode = .system
    var notificationSound: NotificationSound = .default
    var customSoundForHighPriority: Bool = true
    var enableFallbackServers: Bool = false
    var fallbackRetryDelay: Double = 30.0 // seconds

    // Legacy single topic support for migration
    var topic: String {
        get { topics.first ?? "" }
        set {
            if !newValue.isEmpty {
                topics = [newValue]
            }
        }
    }

    // Get primary server as NtfyServer object
    var primaryServer: NtfyServer {
        return NtfyServer(
            url: serverURL,
            name: "Primary server",
            authMethod: authMethod,
            username: username,
            isEnabled: true
        )
    }

    // Get all configured servers (primary + enabled fallbacks)
    var allServers: [NtfyServer] {
        var servers = [primaryServer]
        if enableFallbackServers {
            servers.append(contentsOf: fallbackServers.filter { $0.isEnabled && $0.isConfigured })
        }
        return servers
    }

    // Password and token stored separately in Keychain for security
    var isConfigured: Bool {
        guard !serverURL.isEmpty && !topics.isEmpty else { return false }

        switch authMethod {
        case .basicAuth:
            return !username.isEmpty || serverURL.contains("ntfy.sh") // Public servers don't need auth
        case .accessToken:
            return true // Token validation happens in Keychain retrieval
        }
    }

    static let `default` = NtfySettings()
}