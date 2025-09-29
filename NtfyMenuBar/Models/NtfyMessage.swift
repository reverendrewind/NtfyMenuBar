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

    // Unique identifier for SwiftUI ForEach - combines original ID with timestamp and event
    var uniqueId: String {
        return "\(id)-\(time)-\(event)-\(topic)"
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

enum AuthenticationMethod: String, CaseIterable {
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

extension AuthenticationMethod: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as string first (new format)
        if let stringValue = try? container.decode(String.self) {
            if let method = AuthenticationMethod(rawValue: stringValue) {
                self = method
                return
            }
        }

        // Fall back to integer decoding (old format)
        if let intValue = try? container.decode(Int.self) {
            switch intValue {
            case 0:
                self = .basicAuth
            case 1:
                self = .accessToken
            default:
                self = .basicAuth // Default fallback
            }
            return
        }

        // If neither works, default to basicAuth
        self = .basicAuth
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
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

    // Message clearing settings
    var lastClearedTimestamp: Date?

    // Do Not Disturb scheduling settings
    var isDNDScheduleEnabled: Bool = false
    var dndStartTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    var dndEndTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var dndDaysOfWeek: Set<Int> = Set([1, 2, 3, 4, 5, 6, 7]) // Sunday = 1, Monday = 2, etc.

    // Custom decoder for backwards compatibility - encoder uses automatic synthesis
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode all fields with defaults for backwards compatibility
        serverURL = try container.decodeIfPresent(String.self, forKey: .serverURL) ?? ""
        topics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []
        authMethod = try container.decodeIfPresent(AuthenticationMethod.self, forKey: .authMethod) ?? .basicAuth
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        fallbackServers = try container.decodeIfPresent([NtfyServer].self, forKey: .fallbackServers) ?? []
        enableNotifications = try container.decodeIfPresent(Bool.self, forKey: .enableNotifications) ?? true
        maxRecentMessages = try container.decodeIfPresent(Int.self, forKey: .maxRecentMessages) ?? 20
        autoConnect = try container.decodeIfPresent(Bool.self, forKey: .autoConnect) ?? true
        appearanceMode = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearanceMode) ?? .system
        notificationSound = try container.decodeIfPresent(NotificationSound.self, forKey: .notificationSound) ?? .default
        customSoundForHighPriority = try container.decodeIfPresent(Bool.self, forKey: .customSoundForHighPriority) ?? true
        enableFallbackServers = try container.decodeIfPresent(Bool.self, forKey: .enableFallbackServers) ?? false
        fallbackRetryDelay = try container.decodeIfPresent(Double.self, forKey: .fallbackRetryDelay) ?? 30.0
        isSnoozed = try container.decodeIfPresent(Bool.self, forKey: .isSnoozed) ?? false
        snoozeEndTime = try container.decodeIfPresent(Date.self, forKey: .snoozeEndTime)
        defaultSnoozeDuration = try container.decodeIfPresent(SnoozeDuration.self, forKey: .defaultSnoozeDuration) ?? .thirtyMinutes
        lastClearedTimestamp = try container.decodeIfPresent(Date.self, forKey: .lastClearedTimestamp)
        isDNDScheduleEnabled = try container.decodeIfPresent(Bool.self, forKey: .isDNDScheduleEnabled) ?? false
        dndStartTime = try container.decodeIfPresent(Date.self, forKey: .dndStartTime) ?? (Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date())
        dndEndTime = try container.decodeIfPresent(Date.self, forKey: .dndEndTime) ?? (Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date())
        dndDaysOfWeek = try container.decodeIfPresent(Set<Int>.self, forKey: .dndDaysOfWeek) ?? Set([1, 2, 3, 4, 5, 6, 7])
    }

    private enum CodingKeys: String, CodingKey {
        case serverURL, topics, authMethod, username, fallbackServers
        case enableNotifications, maxRecentMessages, autoConnect
        case appearanceMode, notificationSound, customSoundForHighPriority
        case enableFallbackServers, fallbackRetryDelay
        case isSnoozed, snoozeEndTime, defaultSnoozeDuration
        case lastClearedTimestamp
        case isDNDScheduleEnabled, dndStartTime, dndEndTime, dndDaysOfWeek
    }

    // Default init
    init() {}

    // Public memberwise initializer for programmatic construction
    init(serverURL: String = "",
         fallbackServers: [NtfyServer] = [],
         topics: [String] = [],
         authMethod: AuthenticationMethod = .basicAuth,
         username: String = "",
         enableNotifications: Bool = true,
         maxRecentMessages: Int = 20,
         autoConnect: Bool = true,
         appearanceMode: AppearanceMode = .system,
         notificationSound: NotificationSound = .default,
         customSoundForHighPriority: Bool = true,
         enableFallbackServers: Bool = false,
         fallbackRetryDelay: Double = 30.0,
         isSnoozed: Bool = false,
         snoozeEndTime: Date? = nil,
         defaultSnoozeDuration: SnoozeDuration = .thirtyMinutes,
         lastClearedTimestamp: Date? = nil,
         isDNDScheduleEnabled: Bool = false,
         dndStartTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
         dndEndTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
         dndDaysOfWeek: Set<Int> = Set([1, 2, 3, 4, 5, 6, 7])) {
        self.serverURL = serverURL
        self.fallbackServers = fallbackServers
        self.topics = topics
        self.authMethod = authMethod
        self.username = username
        self.enableNotifications = enableNotifications
        self.maxRecentMessages = maxRecentMessages
        self.autoConnect = autoConnect
        self.appearanceMode = appearanceMode
        self.notificationSound = notificationSound
        self.customSoundForHighPriority = customSoundForHighPriority
        self.enableFallbackServers = enableFallbackServers
        self.fallbackRetryDelay = fallbackRetryDelay
        self.isSnoozed = isSnoozed
        self.snoozeEndTime = snoozeEndTime
        self.defaultSnoozeDuration = defaultSnoozeDuration
        self.lastClearedTimestamp = lastClearedTimestamp
        self.isDNDScheduleEnabled = isDNDScheduleEnabled
        self.dndStartTime = dndStartTime
        self.dndEndTime = dndEndTime
        self.dndDaysOfWeek = dndDaysOfWeek
    }

    // Computed property to check if notifications are currently snoozed
    var isCurrentlySnoozed: Bool {
        guard isSnoozed, let endTime = snoozeEndTime else { return false }
        return Date() < endTime
    }

    // Computed property to check if we're currently in Do Not Disturb time
    var isCurrentlyInDND: Bool {
        guard isDNDScheduleEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)

        // Check if today is enabled for DND
        guard dndDaysOfWeek.contains(currentWeekday) else { return false }

        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.dateComponents([.hour, .minute], from: dndStartTime)
        let endTime = calendar.dateComponents([.hour, .minute], from: dndEndTime)

        guard let currentHour = currentTime.hour,
              let currentMinute = currentTime.minute,
              let startHour = startTime.hour,
              let startMinute = startTime.minute,
              let endHour = endTime.hour,
              let endMinute = endTime.minute else { return false }

        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        // Handle overnight DND (e.g., 22:00 to 08:00)
        if startMinutes > endMinutes {
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        } else {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
    }

    // Check if notifications should be blocked (either snoozed or in DND)
    var shouldBlockNotifications: Bool {
        return isCurrentlySnoozed || isCurrentlyInDND
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
        let serverNotEmpty = !serverURL.isEmpty
        let topicsNotEmpty = !topics.isEmpty
        let usernameNotEmpty = !username.isEmpty
        let isPublicServer = serverURL.contains("ntfy.sh")

        Logger.shared.debug("🔧 isConfigured check: serverURL='\(serverURL)', topics=\(topics), username='\(username)', authMethod=\(authMethod)")
        Logger.shared.debug("🔧 serverNotEmpty=\(serverNotEmpty), topicsNotEmpty=\(topicsNotEmpty), usernameNotEmpty=\(usernameNotEmpty), isPublicServer=\(isPublicServer)")

        guard serverNotEmpty && topicsNotEmpty else {
            Logger.shared.debug("🔧 isConfigured=false (missing server or topics)")
            return false
        }

        switch authMethod {
        case .basicAuth:
            let result = usernameNotEmpty || isPublicServer
            Logger.shared.debug("🔧 basicAuth: usernameNotEmpty=\(usernameNotEmpty) || isPublicServer=\(isPublicServer) = \(result)")
            return result
        case .accessToken:
            Logger.shared.debug("🔧 accessToken: returning true")
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