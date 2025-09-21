//
//  NtfyViewModel.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import Foundation
import Combine
import Intents

@MainActor
class NtfyViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var hasUnreadMessages = false
    @Published var messages: [NtfyMessage] = []
    @Published var settings: NtfySettings
    @Published var connectionError: String?
    @Published var isSnoozed = false
    @Published var snoozeTimeRemaining: TimeInterval?

    private var ntfyService: NtfyService?
    private var cancellables = Set<AnyCancellable>()
    private var snoozeTimer: Timer?

    // Expose service for UI access to connection quality
    var service: NtfyService {
        return ntfyService ?? NtfyService(settings: settings)
    }
    
    // Closure to open settings window (set by StatusBarController)
    var openSettingsAction: (() -> Void)?
    
    init() {
        self.settings = SettingsManager.loadSettings()
        setupService()
        setupSnoozeState()
        loadRecentArchivedMessages()

        // Autoconnect if server is configured and autoconnect is enabled
        if settings.isConfigured && settings.autoConnect {
            // Delay slightly to ensure UI is ready
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    print("🚀 Autoconnecting to configured server...")
                    connect()
                }
            }
        }
    }
    
    func connect() {
        guard settings.isConfigured else {
            connectionError = "Please configure server settings first"
            return
        }
        
        ntfyService?.connect()
    }
    
    func disconnect() {
        ntfyService?.disconnect()
    }
    
    func clearMessages() {
        messages.removeAll()
        hasUnreadMessages = false
        NotificationManager.shared.clearAllNotifications()
    }
    
    func updateSettings(_ newSettings: NtfySettings) {
        settings = newSettings
        SettingsManager.saveSettings(newSettings)
        setupService()
        
        if isConnected {
            disconnect()
            connect()
        }
    }
    
    private func setupService() {
        ntfyService = NtfyService(settings: settings)
        
        ntfyService?.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
        
        ntfyService?.$connectionError
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionError, on: self)
            .store(in: &cancellables)
        
        ntfyService?.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessages in
                guard let self = self else { return }

                // Merge new messages with existing ones, avoiding duplicates
                var allMessages = self.messages

                for newMessage in newMessages {
                    // Check if this message already exists
                    if !allMessages.contains(where: { $0.uniqueId == newMessage.uniqueId }) {
                        allMessages.insert(newMessage, at: 0)
                    }
                }

                // Limit to maxRecentMessages
                if allMessages.count > self.settings.maxRecentMessages {
                    allMessages = Array(allMessages.prefix(self.settings.maxRecentMessages))
                }

                self.messages = allMessages
                self.hasUnreadMessages = !allMessages.isEmpty
                print("📱 Merged messages: \(newMessages.count) new, \(allMessages.count) total")
            }
            .store(in: &cancellables)
    }

    // MARK: - Snooze Management

    private func setupSnoozeState() {
        // Initialize snooze state from settings
        isSnoozed = settings.isCurrentlySnoozed
        snoozeTimeRemaining = settings.snoozeTimeRemaining

        // Setup timer if snooze is active
        if settings.isCurrentlySnoozed {
            startSnoozeTimer()
        } else if settings.isSnoozed && !settings.isCurrentlySnoozed {
            // Snooze has expired, clear it
            clearSnooze()
        }
    }

    func snoozeNotifications(duration: SnoozeDuration, customDuration: TimeInterval? = nil) {
        let snoozeInterval: TimeInterval

        if duration == .custom, let customDuration = customDuration {
            snoozeInterval = customDuration
        } else {
            snoozeInterval = duration.timeInterval
        }

        let endTime = Date().addingTimeInterval(snoozeInterval)

        // Update settings
        settings.isSnoozed = true
        settings.snoozeEndTime = endTime
        updateSettings(settings)

        // Update published properties
        isSnoozed = true
        snoozeTimeRemaining = snoozeInterval

        // Start countdown timer
        startSnoozeTimer()

        // Donate shortcut for Siri
        let minutes = Int(snoozeInterval / 60)
        ShortcutsDonator.donateSnooze(minutes: minutes)

        print("🔕 Notifications snoozed for \(duration.displayName) until \(endTime)")
    }

    func clearSnooze() {
        // Update settings
        settings.isSnoozed = false
        settings.snoozeEndTime = nil
        updateSettings(settings)

        // Update published properties
        isSnoozed = false
        snoozeTimeRemaining = nil

        // Stop timer
        snoozeTimer?.invalidate()
        snoozeTimer = nil

        print("🔔 Snooze cleared - notifications enabled")
    }

    private func startSnoozeTimer() {
        snoozeTimer?.invalidate()

        snoozeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let remaining = self.settings.snoozeTimeRemaining, remaining > 0 {
                    self.snoozeTimeRemaining = remaining
                } else {
                    // Snooze has expired
                    self.clearSnooze()
                }
            }
        }
    }

    var snoozeStatusText: String {
        guard isSnoozed, let remaining = snoozeTimeRemaining else {
            return "Notifications enabled"
        }

        if remaining <= 0 {
            return "Snooze expiring..."
        }

        let totalMinutes = Int(round(remaining / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "Snoozed for \(hours)h \(minutes)m"
        } else {
            return "Snoozed for \(minutes)m"
        }
    }

    // MARK: - Message Archive Management

    private func loadRecentArchivedMessages() {
        Task {
            // Load recent archived messages (last 7 days) to populate the UI on startup
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            let recentMessages = await MessageArchive.shared.getArchivedMessages(since: weekAgo)

            await MainActor.run {
                // Only show the most recent messages up to maxRecentMessages, but avoid duplicates
                let uniqueMessages = recentMessages.reduce(into: [String: NtfyMessage]()) { dict, message in
                    dict[message.uniqueId] = message
                }.values.sorted { $0.date > $1.date }

                self.messages = Array(uniqueMessages.prefix(self.settings.maxRecentMessages))
                self.hasUnreadMessages = !self.messages.isEmpty
                print("📂 Loaded \(self.messages.count) recent archived messages (deduplicated)")
            }
        }
    }

    func loadAllArchivedMessages() async -> [NtfyMessage] {
        return await MessageArchive.shared.getAllArchivedMessages()
    }

    func getArchiveStatistics() async -> ArchiveStatistics {
        return await MessageArchive.shared.getArchiveStatistics()
    }

    func clearOldArchivedMessages(olderThan days: Int) {
        Task {
            let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
            await MessageArchive.shared.clearOldMessages(olderThan: cutoffDate)

            // Reload recent messages
            await MainActor.run {
                loadRecentArchivedMessages()
            }

            print("🗑️ Cleared archived messages older than \(days) days")
        }
    }

    func exportAllArchivedMessages() async -> [NtfyMessage] {
        return await MessageArchive.shared.getAllArchivedMessages()
    }
}