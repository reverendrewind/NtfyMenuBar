//
//  AppConfig.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import Foundation

struct AppConfig {

    // MARK: - Network Configuration
    struct Network {
        static let maxReconnectAttempts = 3
        static let timeoutInterval: TimeInterval = 15.0
        static let keepaliveInterval: TimeInterval = 25.0
        static let maxBackoffDelay: TimeInterval = 15.0
        static let baseBackoffDelay: TimeInterval = 2.0

        // Connection retry configuration
        static let retryDelay: TimeInterval = 1.0
        static let connectionHealthCheckInterval: TimeInterval = 30.0
    }

    // MARK: - Notification Configuration
    struct Notifications {
        static let maxMessageLength = 150
        static let maxTagsToShow = 3
        static let maxTitleLength = 100
        static let smartTruncateThreshold = 0.75 // 75% of desired length
        static let truncationSuffix = "..."

        // Notification timing
        static let dismissDelay: TimeInterval = 5.0
        static let soundFadeDelay: TimeInterval = 0.5
    }

    // MARK: - Message Management
    struct Messages {
        static let defaultMaxRecentMessages = 20
        static let minRecentMessages = 5
        static let maxRecentMessages = 100
        static let archiveRetentionDays = 30

        // Cache configuration
        static let cacheValidityInterval: TimeInterval = 300 // 5 minutes
        static let maxMessagesPerFile = 1000
        static let maxArchiveFiles = 10
    }

    // MARK: - Snooze Configuration
    struct Snooze {
        static let timerUpdateInterval: TimeInterval = 1.0
        static let defaultSnoozeDuration: TimeInterval = 1800 // 30 minutes

        // Predefined durations (in minutes)
        static let shortSnooze: TimeInterval = 5 * 60    // 5 minutes
        static let mediumSnooze: TimeInterval = 30 * 60  // 30 minutes
        static let longSnooze: TimeInterval = 120 * 60   // 2 hours
        static let workdaySnooze: TimeInterval = 480 * 60 // 8 hours
    }

    // MARK: - Performance Configuration
    struct Performance {
        static let maxConcurrentConnections = 3
        static let memoryWarningThreshold = 0.8 // 80% of available memory
        static let backgroundTaskTimeout: TimeInterval = 30.0
        static let uiUpdateThrottleInterval: TimeInterval = 0.1 // 100ms
    }

    // MARK: - Validation Rules
    struct Validation {
        static let maxTopicLength = 64
        static let maxServerUrlLength = 255
        static let minPasswordLength = 1
        static let maxUsernameLength = 50
        static let maxTokenLength = 64
        static let minTokenLength = 32

        // URL validation patterns
        static let httpUrlPattern = #"^https?://.*"#
        static let topicPattern = #"^[a-zA-Z0-9_-]+$"#
    }

    // MARK: - Security Configuration
    struct Security {
        static let keychainService = "net.raczej.NtfyMenuBar"
        static let tokenPrefix = "tk_"
        static let maxLoginAttempts = 3
        static let lockoutDuration: TimeInterval = 300 // 5 minutes
    }

    // MARK: - Debug Configuration
    struct Debug {
        static let enableVerboseLogging = false
        static let enableNetworkLogging = false
        static let maxLogLines = 1000
        static let logRotationSize = 10_485_760 // 10MB
    }
}