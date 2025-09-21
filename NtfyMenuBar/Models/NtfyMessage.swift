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

enum SnoozeDuration: String, Codable, CaseIterable {
    case fiveMinutes = "5 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"
    case twoHours = "2 hours"
    case fourHours = "4 hours"
    case eightHours = "8 hours"
    case untilTomorrow = "Until tomorrow"
    case custom = "Custom"

    var displayName: String {
        return rawValue
    }

    var timeInterval: TimeInterval {
        switch self {
        case .fiveMinutes: return 5 * 60
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .fourHours: return 4 * 60 * 60
        case .eightHours: return 8 * 60 * 60
        case .untilTomorrow:
            let now = Date()
            let calendar = Calendar.current
            let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
            return tomorrow.timeIntervalSince(now)
        case .custom: return 0
        }
    }

    var systemImage: String {
        switch self {
        case .fiveMinutes, .fifteenMinutes, .thirtyMinutes: return "clock"
        case .oneHour, .twoHours: return "clock.circle"
        case .fourHours, .eightHours: return "clock.circle.fill"
        case .untilTomorrow: return "moon.zzz"
        case .custom: return "slider.horizontal.3"
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

    // Snooze settings
    var isSnoozed: Bool = false
    var snoozeEndTime: Date?
    var defaultSnoozeDuration: SnoozeDuration = .thirtyMinutes

    // Computed property to check if notifications are currently snoozed
    var isCurrentlySnoozed: Bool {
        guard isSnoozed, let endTime = snoozeEndTime else { return false }
        return Date() < endTime
    }

    // Time remaining in snooze
    var snoozeTimeRemaining: TimeInterval? {
        guard let endTime = snoozeEndTime, isCurrentlySnoozed else { return nil }
        return endTime.timeIntervalSince(Date())
    }

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
            name: "", // Empty name so displayName falls back to cleanURL
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

struct AccessToken: Codable, Identifiable, Equatable {
    var id = UUID()
    let token: String
    let label: String?
    let lastAccess: Int?
    let lastOrigin: String?
    let expires: Int?
    let created: Date

    var isExpired: Bool {
        guard let expires = expires else { return false }
        return Date().timeIntervalSince1970 > TimeInterval(expires)
    }

    var expirationDate: Date? {
        guard let expires = expires else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(expires))
    }

    var lastAccessDate: Date? {
        guard let lastAccess = lastAccess else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(lastAccess))
    }

    var displayLabel: String {
        return label?.isEmpty == false ? label! : "Unlabeled token"
    }

    var maskedToken: String {
        guard token.count > 8 else { return token }
        let prefix = String(token.prefix(8))
        let suffix = String(token.suffix(4))
        return "\(prefix)•••••••••••••••••••••••••••\(suffix)"
    }
}

enum TokenExpiration: String, CaseIterable, Codable {
    case never = "Never"
    case oneHour = "1 hour"
    case oneDay = "1 day"
    case oneWeek = "1 week"
    case oneMonth = "1 month"
    case threeMonths = "3 months"
    case oneYear = "1 year"

    var displayName: String {
        return rawValue
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .never: return nil
        case .oneHour: return 3600
        case .oneDay: return 86400
        case .oneWeek: return 604800
        case .oneMonth: return 2629746 // 30.44 days
        case .threeMonths: return 7889238 // 91.31 days
        case .oneYear: return 31557600 // 365.25 days
        }
    }
}