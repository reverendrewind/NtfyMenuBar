//
//  StringConstants.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import Foundation

struct StringConstants {

    // MARK: - Asset Names
    struct Assets {
        static let menuBarIcon = "MenuBarIcon"
        static let menuBarIconSnooze = "MenuBarIconSnooze"
        static let appIcon = "AppIcon"
    }

    // MARK: - Notification Categories
    struct NotificationCategories {
        static let ntfyMessage = "NTFY_MESSAGE"
    }

    // MARK: - Notification Actions
    struct NotificationActions {
        static let openDashboard = "OPEN_DASHBOARD"
        static let markRead = "MARK_READ"
        static let dismiss = "DISMISS"
        static let markReadTitle = "Mark read"
        static let dismissTitle = "Dismiss"
    }

    // MARK: - Menu Items
    struct MenuItems {
        static let openDashboard = "Open Dashboard"
        static let settings = "Settings..."
        static let connect = "Connect"
        static let disconnect = "Disconnect"
        static let clearMessages = "Clear Messages"
        static let quit = "Quit"
        static let noRecentMessages = "No recent messages"
        static let recentMessages = "Recent Messages"
        static let snoozeNotifications = "Snooze Notifications"
        static let clearSnooze = "Clear Snooze"
    }

    // MARK: - Window Titles
    struct WindowTitles {
        static let settings = "Settings"
        static let dashboard = "Dashboard"
    }

    // MARK: - Notification Content
    struct NotificationContent {
        static let ntfyPrefix = "ntfy:"
        static let noMessage = "No message"
        static let priorityLabel = "Priority:"
        static let tagsLabel = "Tags:"
    }

    // MARK: - Settings Labels
    struct SettingsLabels {
        static let serverUrl = "Server URL"
        static let topic = "Topic"
        static let username = "Username"
        static let password = "Password"
        static let accessToken = "Access Token"
        static let enableNotifications = "Enable Notifications"
        static let autoConnect = "Auto Connect"
        static let maxRecentMessages = "Max Recent Messages"
        static let appearanceMode = "Appearance"
        static let notificationSound = "Notification Sound"
        static let customSoundForHighPriority = "Custom Sound for High Priority"
    }

    // MARK: - Settings Placeholders
    struct SettingsPlaceholders {
        static let serverUrlExample = "e.g., https://ntfy.sh or https://ntfy.example.com"
        static let topicExample = "e.g., my-notifications"
        static let usernamePlaceholder = "Username"
        static let passwordPlaceholder = "Password"
        static let tokenPlaceholder = "Access token (tk_...)"
    }

    // MARK: - Error Messages
    struct ErrorMessages {
        static let connectionFailed = "Connection failed"
        static let invalidUrl = "Invalid server URL"
        static let invalidTopic = "Invalid topic name"
        static let authenticationFailed = "Authentication failed"
        static let networkError = "Network error occurred"
        static let permissionDenied = "Notification permission denied"
        static let configurationError = "Please configure server settings first"
    }

    // MARK: - Status Messages
    struct StatusMessages {
        static let connected = "Connected"
        static let disconnected = "Disconnected"
        static let connecting = "Connecting..."
        static let reconnecting = "Reconnecting..."
        static let snoozed = "Snoozed"
        static let notificationsSnoozed = "Notifications snoozed"
        static let notificationsEnabled = "Notifications enabled"
    }

    // MARK: - Priority Labels
    struct PriorityLabels {
        static let minimal = "Minimal"
        static let low = "Low"
        static let normal = "Normal"
        static let high = "High"
        static let urgent = "Urgent"
    }

    // MARK: - Snooze Duration Labels
    struct SnoozeDurationLabels {
        static let fiveMinutes = "5 minutes"
        static let fifteenMinutes = "15 minutes"
        static let thirtyMinutes = "30 minutes"
        static let oneHour = "1 hour"
        static let twoHours = "2 hours"
        static let fourHours = "4 hours"
        static let eightHours = "8 hours"
        static let untilTomorrow = "Until tomorrow"
        static let custom = "Custom"
    }

    // MARK: - Authentication Methods
    struct AuthMethods {
        static let basicAuth = "Basic Authentication"
        static let bearerToken = "Bearer Token"
    }

    // MARK: - Appearance Modes
    struct AppearanceModes {
        static let light = "Light"
        static let dark = "Dark"
        static let system = "System"
    }

    // MARK: - Keychain Keys
    struct KeychainKeys {
        static let serverPassword = "server-password"
        static let serverUsername = "server-username"
        static let accessToken = "access-token"
    }

    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let ntfySettings = "ntfySettings"
        static let lastClearedTimestamp = "lastClearedTimestamp"
        static let snoozeEndTime = "snoozeEndTime"
        static let appearanceMode = "appearanceMode"
    }

    // MARK: - File Extensions
    struct FileExtensions {
        static let aiff = ".aiff"
        static let json = ".json"
        static let log = ".log"
    }

    // MARK: - URLs
    struct URLs {
        static let ntfyDocs = "https://ntfy.sh/docs"
        static let githubRepo = "https://github.com/reverendrewind/NtfyMenuBar"
    }
}