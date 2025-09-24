//
//  SettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI
import UserNotifications
import AppKit

struct SettingsView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var serverURL: String = ""
    @State private var topics: [String] = []
    @State private var newTopic: String = ""
    @State private var topicValidationError: String = ""
    @State private var authMethod: AuthenticationMethod = .basicAuth
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var accessToken: String = ""
    @State private var enableNotifications: Bool = true
    @State private var maxRecentMessages: Int = 20
    @State private var autoConnect: Bool = true
    @State private var appearanceMode: AppearanceMode = .system
    @State private var notificationSound: NotificationSound = .default
    @State private var customSoundForHighPriority: Bool = true
    @State private var selectedTab: SettingsTab = .connection
    @State private var fallbackServers: [NtfyServer] = []
    @State private var enableFallbackServers: Bool = false
    @State private var fallbackRetryDelay: Double = 30.0
    @State private var editingServer: NtfyServer?
    @State private var showingServerEditor: Bool = false

    // Access token management state
    @State private var accessTokens: [AccessToken] = []
    @State private var newTokenLabel: String = ""
    @State private var newTokenExpiration: TokenExpiration = .never
    @State private var isGeneratingToken: Bool = false
    @State private var generatedToken: String?
    @State private var tokenError: String?

    // Do Not Disturb scheduling state
    @State private var isDNDScheduleEnabled: Bool = false
    @State private var dndStartTime: Date = Date()
    @State private var dndEndTime: Date = Date()
    @State private var dndDaysOfWeek: Set<Int> = Set([1, 2, 3, 4, 5, 6, 7])

    // Archive management state
    @State private var archiveStatistics: ArchiveStatistics?
    @State private var isLoadingArchiveStats: Bool = false
    @State private var showingClearArchiveAlert: Bool = false
    @State private var archiveClearDays: Int = 30

    // Archive browser state
    @State private var archivedMessages: [NtfyMessage] = []
    @State private var isLoadingArchive: Bool = false
    @State private var showingArchiveBrowser: Bool = false
    @State private var archiveSearchText: String = ""
    @State private var selectedArchiveTopic: String = "All"

    enum SettingsTab: String, CaseIterable {
        case connection = "Connection"
        case tokens = "Access tokens"
        case fallbacks = "Fallback servers"
        case dnd = "Do Not Disturb"
        case archive = "Message Archive"
        case preferences = "Preferences"

        var systemImage: String {
            switch self {
            case .connection: return "network"
            case .tokens: return "key.fill"
            case .fallbacks: return "server.rack"
            case .dnd: return "moon.zzz"
            case .archive: return "archivebox"
            case .preferences: return "gearshape"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                // Tab Selection
                Picker("", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.systemImage)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(20)
            .padding(.bottom, 0)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .connection:
                        connectionSettingsView
                    case .tokens:
                        accessTokensView
                    case .fallbacks:
                        fallbackServersView
                    case .dnd:
                        dndSettingsView
                    case .archive:
                        archiveSettingsView
                    case .preferences:
                        preferencesSettingsView
                    }
                }
                .padding(20)
                .padding(.top, 0)
            }

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidConfiguration)
            }
            .padding(20)
            .padding(.top, 0)
        }
        .frame(width: UIConstants.Settings.width, height: UIConstants.Settings.height)
        .background(Color.theme.windowBackground)
        .onAppear {
            loadCurrentSettings()
        }
    }

    // MARK: - Tab Views

    private var connectionSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Server configuration")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Server URL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("https://ntfy.sh", text: $serverURL)
                        .textFieldStyle(.roundedBorder)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topics")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Compact horizontal scrolling topic chips
                        if !topics.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                                        HStack(spacing: 4) {
                                            Text(topic)
                                                .font(.caption)
                                                .foregroundColor(.blue)

                                            Button(action: {
                                                topics.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary.opacity(0.7))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .frame(maxHeight: 30)
                        }

                        // Compact add topic field
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                TextField("Add topics", text: $newTopic)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 200)
                                    .onSubmit {
                                        addTopic()
                                    }
                                    .onChange(of: newTopic) {
                                        // Clear error when user types
                                        if !topicValidationError.isEmpty && !topicValidationError.contains("Added") {
                                            topicValidationError = ""
                                        }
                                        // Auto-lowercase but preserve separators (commas and spaces)
                                        newTopic = newTopic.lowercased()
                                    }

                                Button(action: addTopic) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                .disabled(newTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            // Validation error or help text
                            if !topicValidationError.isEmpty {
                                HStack(spacing: 3) {
                                    Image(systemName: topicValidationError.contains("Added") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                    Text(topicValidationError)
                                        .font(.caption2)
                                }
                                .foregroundColor(topicValidationError.contains("Added") ? .green : .red)
                            } else if topics.isEmpty {
                                Text("Examples: 'alerts news' or 'alerts,news' or just 'alerts'")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Tip: Separate with spaces or commas (topic1 topic2)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Authentication")
                    .font(.headline)

                Picker("", selection: $authMethod) {
                    ForEach(AuthenticationMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .pickerStyle(.segmented)

                Group {
                    if authMethod == .basicAuth {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)

                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)

                            Text("Leave empty for public servers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Access token")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("tk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", text: $accessToken)
                                .textFieldStyle(.roundedBorder)

                            Text("32-character token starting with 'tk_'")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var preferencesSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notifications")
                    .font(.headline)

                Toggle("Enable notifications", isOn: $enableNotifications)

                Toggle("Auto-connect at launch", isOn: $autoConnect)
                    .help("Automatically connect to the server when the app starts")

                HStack {
                    Text("Recent messages: \(maxRecentMessages)")
                    Spacer()
                    Stepper("", value: $maxRecentMessages, in: 5...100, step: 5)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance")
                    .font(.headline)

                Picker("Appearance", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Notification sounds")
                    .font(.headline)

                Picker("Sound", selection: $notificationSound) {
                    ForEach(NotificationSound.allCases, id: \.self) { sound in
                        Text(sound.displayName).tag(sound)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Use critical sound for high priority messages", isOn: $customSoundForHighPriority)
                    .help("Play critical alert sound for priority 4 and 5 messages")

                if notificationSound != .default {
                    Button("Test sound") {
                        testNotificationSound()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var fallbackServersView: some View {
        FallbackServersSettingsView(
            fallbackServers: $fallbackServers,
            enableFallbackServers: $enableFallbackServers,
            fallbackRetryDelay: $fallbackRetryDelay,
            editingServer: $editingServer,
            showingServerEditor: $showingServerEditor
        )
    }

    private var dndSettingsView: some View {
        DNDSettingsView(
            isDNDScheduleEnabled: $isDNDScheduleEnabled,
            dndStartTime: $dndStartTime,
            dndEndTime: $dndEndTime,
            dndDaysOfWeek: $dndDaysOfWeek
        )
        .environmentObject(viewModel)
    }

    private var accessTokensView: some View {
        AccessTokensSettingsView(
            serverURL: $serverURL,
            authMethod: $authMethod,
            username: $username,
            password: $password,
            accessToken: $accessToken,
            accessTokens: $accessTokens,
            newTokenLabel: $newTokenLabel,
            newTokenExpiration: $newTokenExpiration,
            isGeneratingToken: $isGeneratingToken,
            generatedToken: $generatedToken,
            tokenError: $tokenError
        )
    }

    private var archiveSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Message Archive")
                    .font(.headline)

                Text("Messages are automatically archived for persistent storage and can be exported at any time.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Archive statistics
                if isLoadingArchiveStats {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading archive statistics...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let stats = archiveStatistics {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Archive Statistics")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Total Messages:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(stats.totalMessages)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }

                                HStack {
                                    Text("Archive Size:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(stats.formattedSize)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Date Range:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(stats.dateRange)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                HStack {
                                    Text("Archive Files:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(stats.archiveFilesCount)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)

                        // Top topics
                        if !stats.messagesByTopic.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Top Topics:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                let sortedTopics = stats.messagesByTopic.sorted { $0.value > $1.value }.prefix(8)
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 6) {
                                    ForEach(Array(sortedTopics), id: \.key) { topic, count in
                                        HStack {
                                            Text("• \(topic)")
                                                .font(.caption2)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Spacer()
                                            Text("\(count)")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }

                Button("Refresh Statistics") {
                    loadArchiveStatistics()
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingArchiveStats)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Browse Archived Messages")
                    .font(.headline)

                Text("View and search through your archived message history.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button(showingArchiveBrowser ? "Hide Archive Browser" : "Show Archive Browser") {
                        showingArchiveBrowser.toggle()
                        if showingArchiveBrowser && archivedMessages.isEmpty {
                            loadArchivedMessages()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if showingArchiveBrowser {
                        Button("Load Recent (7 days)") {
                            loadRecentArchivedMessages()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)

                        Button("Load All") {
                            loadArchivedMessages()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }

                    if showingArchiveBrowser && !archivedMessages.isEmpty {
                        Spacer()
                        Text("\(filteredArchivedMessages.count) of \(archivedMessages.count) messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if showingArchiveBrowser {
                    if isLoadingArchive {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading archived messages...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    } else if !archivedMessages.isEmpty {
                        VStack(spacing: 12) {
                            // Search and filter controls
                            HStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    TextField("Search messages...", text: $archiveSearchText)
                                        .textFieldStyle(.plain)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)

                                Picker("Topic", selection: $selectedArchiveTopic) {
                                    Text("All Topics").tag("All")
                                    ForEach(archiveTopics, id: \.self) { topic in
                                        Text(topic).tag(topic)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }

                            // Message list
                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(filteredArchivedMessages.prefix(100), id: \.uniqueId) { message in
                                        ArchiveMessageRowView(message: message)
                                    }

                                    if filteredArchivedMessages.count > 100 {
                                        Text("Showing first 100 messages. Use search to narrow results.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                            .frame(height: 300)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "archivebox")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No archived messages found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Export Messages")
                    .font(.headline)

                Text("Export your messages to CSV or JSON format for analysis or backup. Files are saved to the application's export folder.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Export location info
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    Text("Export location:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Show in Finder") {
                        revealExportsFolder()
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent messages (last 7 days)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 12) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button("Export as \(format.displayName)") {
                                exportRecentMessages(format: format)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("All archived messages")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 12) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button("Export all as \(format.displayName)") {
                                exportAllArchivedMessages(format: format)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Archive Management")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Clear old messages")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Remove archived messages older than the specified number of days.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Delete messages older than:")
                            .font(.caption)
                        Spacer()
                        Picker("Days", selection: $archiveClearDays) {
                            Text("7 days").tag(7)
                            Text("30 days").tag(30)
                            Text("90 days").tag(90)
                            Text("1 year").tag(365)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }

                    Button("Clear Old Messages") {
                        showingClearArchiveAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            if archiveStatistics == nil {
                loadArchiveStatistics()
            }
        }
        .alert("Clear Archive Messages", isPresented: $showingClearArchiveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearOldArchivedMessages()
            }
        } message: {
            Text("Are you sure you want to delete all archived messages older than \(archiveClearDays) days? This action cannot be undone.")
        }
    }

    // MARK: - Private Methods

    private var isValidConfiguration: Bool {
        guard !serverURL.isEmpty && !topics.isEmpty else { return false }

        switch authMethod {
        case .basicAuth:
            return !username.isEmpty
        case .accessToken:
            return SettingsManager.validateAccessToken(accessToken)
        }
    }


    private func addTopic() {
        let input = newTopic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Clear any previous error
        topicValidationError = ""

        // Check if empty
        guard !input.isEmpty else {
            topicValidationError = "Topic cannot be empty"
            return
        }

        // Determine separator: if contains comma, use comma; otherwise use space
        let topicList: [String]
        if input.contains(",") {
            // Comma-separated (e.g., "topic1,topic2" or "topic1, topic2")
            topicList = input.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if input.contains(" ") {
            // Space-separated (e.g., "topic1 topic2 topic3")
            topicList = input.split(separator: " ").map {
                String($0).trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }
        } else {
            // Single topic
            topicList = [input]
        }

        var addedTopics: [String] = []
        var invalidTopics: [String] = []
        var duplicateTopics: [String] = []

        let validPattern = "^[a-z0-9_-]+$"
        let regex = try? NSRegularExpression(pattern: validPattern)

        for topicName in topicList {
            // Skip empty entries (from extra commas)
            guard !topicName.isEmpty else { continue }

            // Check length
            guard topicName.count <= 64 else {
                invalidTopics.append("\(topicName) (too long)")
                continue
            }

            // Validate format
            let range = NSRange(location: 0, length: topicName.utf16.count)
            guard regex?.firstMatch(in: topicName, options: [], range: range) != nil else {
                invalidTopics.append(topicName)
                continue
            }

            // Check for duplicates
            if topics.contains(topicName) {
                duplicateTopics.append(topicName)
                continue
            }

            topics.append(topicName)
            addedTopics.append(topicName)
        }

        // Provide feedback
        if !invalidTopics.isEmpty {
            topicValidationError = "Invalid: \(invalidTopics.joined(separator: ", "))"
        } else if !duplicateTopics.isEmpty && addedTopics.isEmpty {
            topicValidationError = "Already added: \(duplicateTopics.joined(separator: ", "))"
        } else if !addedTopics.isEmpty {
            // Successfully added some topics
            newTopic = ""
            topicValidationError = ""

            // Show brief success feedback if some were skipped
            if !duplicateTopics.isEmpty {
                topicValidationError = "Added \(addedTopics.count) topic(s), skipped duplicates"
                // Clear this message after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.topicValidationError = ""
                }
            }
        }

        // Clear input only if something was successfully added
        if !addedTopics.isEmpty {
            newTopic = ""
        }
    }

    private func loadCurrentSettings() {
        let settings = SettingsManager.loadSettings()
        serverURL = settings.serverURL

        // Filter and validate loaded topics
        topics = settings.topics.compactMap { topic in
            let cleaned = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let validPattern = "^[a-z0-9_-]+$"
            let regex = try? NSRegularExpression(pattern: validPattern)
            let range = NSRange(location: 0, length: cleaned.utf16.count)

            if !cleaned.isEmpty &&
               cleaned.count <= 64 &&
               regex?.firstMatch(in: cleaned, options: [], range: range) != nil {
                return cleaned
            }
            return nil
        }

        authMethod = settings.authMethod
        username = settings.username
        enableNotifications = settings.enableNotifications
        maxRecentMessages = settings.maxRecentMessages
        autoConnect = settings.autoConnect
        appearanceMode = settings.appearanceMode
        notificationSound = settings.notificationSound
        customSoundForHighPriority = settings.customSoundForHighPriority
        fallbackServers = settings.fallbackServers
        enableFallbackServers = settings.enableFallbackServers
        fallbackRetryDelay = settings.fallbackRetryDelay

        // Load DND settings
        isDNDScheduleEnabled = settings.isDNDScheduleEnabled
        dndStartTime = settings.dndStartTime
        dndEndTime = settings.dndEndTime
        dndDaysOfWeek = settings.dndDaysOfWeek

        if !username.isEmpty {
            password = SettingsManager.loadPassword(for: username) ?? ""
        }

        accessToken = SettingsManager.loadAccessToken() ?? ""
    }

    private func saveSettings() {
        var settings = NtfySettings(
            serverURL: serverURL,
            authMethod: authMethod,
            username: username,
            enableNotifications: enableNotifications,
            maxRecentMessages: maxRecentMessages,
            autoConnect: autoConnect,
            appearanceMode: appearanceMode,
            notificationSound: notificationSound,
            customSoundForHighPriority: customSoundForHighPriority,
            enableFallbackServers: enableFallbackServers,
            fallbackRetryDelay: fallbackRetryDelay
        )
        settings.topics = topics
        settings.fallbackServers = fallbackServers

        // Save DND settings
        settings.isDNDScheduleEnabled = isDNDScheduleEnabled
        settings.dndStartTime = dndStartTime
        settings.dndEndTime = dndEndTime
        settings.dndDaysOfWeek = dndDaysOfWeek

        SettingsManager.saveSettings(settings)

        // Save authentication credentials based on method
        switch authMethod {
        case .basicAuth:
            if !password.isEmpty && !username.isEmpty {
                SettingsManager.savePassword(password, for: username)
            }
            // Clear any existing token
            SettingsManager.deleteAccessToken()
        case .accessToken:
            if !accessToken.isEmpty {
                SettingsManager.saveAccessToken(accessToken)
            }
            // Clear any existing password
            if !username.isEmpty {
                SettingsManager.deletePassword(for: username)
            }
        }

        viewModel.updateSettings(settings)
        themeManager.setTheme(appearanceMode)
        dismiss()
    }

    private func testNotificationSound() {
        let content = UNMutableNotificationContent()
        content.title = "ntfy Sound Test"
        content.body = "Testing notification sound: \(notificationSound.displayName)"

        // Use the selected sound
        if let soundFileName = notificationSound.fileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundFileName))
        } else {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "sound_test",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to test sound: \(error)")
            } else {
                print("🔊 Testing sound: \(notificationSound.displayName)")
            }
        }
    }

    private func loadArchiveStatistics() {
        isLoadingArchiveStats = true
        Task {
            let stats = await viewModel.getArchiveStatistics()
            await MainActor.run {
                self.archiveStatistics = stats
                self.isLoadingArchiveStats = false
            }
        }
    }


    private func loadArchivedMessages() {
        isLoadingArchive = true
        Task {
            let messages = await viewModel.loadAllArchivedMessages()
            await MainActor.run {
                self.archivedMessages = messages
                self.isLoadingArchive = false
            }
        }
    }

    private func loadRecentArchivedMessages() {
        isLoadingArchive = true
        Task {
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            let recentMessages = await MessageArchive.shared.getArchivedMessages(since: weekAgo)
            await MainActor.run {
                self.archivedMessages = recentMessages
                self.isLoadingArchive = false
            }
        }
    }

    private var archiveTopics: [String] {
        let allTopics = Set(archivedMessages.map { $0.topic })
        return Array(allTopics).sorted()
    }

    private var filteredArchivedMessages: [NtfyMessage] {
        var messages = archivedMessages

        // Apply search filter
        if !archiveSearchText.isEmpty {
            let searchLower = archiveSearchText.lowercased()
            messages = messages.filter { message in
                (message.message?.lowercased().contains(searchLower) ?? false) ||
                (message.title?.lowercased().contains(searchLower) ?? false) ||
                message.topic.lowercased().contains(searchLower) ||
                (message.tags?.joined(separator: " ").lowercased().contains(searchLower) ?? false)
            }
        }

        // Apply topic filter
        if selectedArchiveTopic != "All" {
            messages = messages.filter { $0.topic == selectedArchiveTopic }
        }

        return messages
    }

    private func clearOldArchivedMessages() {
        viewModel.clearOldArchivedMessages(olderThan: archiveClearDays)
        // Refresh statistics after clearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadArchiveStatistics()
        }
    }

    private func exportRecentMessages(format: ExportFormat) {
        Task {
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            let recentMessages = await MessageArchive.shared.getArchivedMessages(since: weekAgo)

            await MainActor.run {
                ExportManager.shared.exportMessages(
                    recentMessages,
                    format: format,
                    scope: .all
                ) { result in
                    DispatchQueue.main.async {
                        handleExportResult(result, messageCount: recentMessages.count, format: format)
                    }
                }
            }
        }
    }

    private func exportAllArchivedMessages(format: ExportFormat) {
        Task {
            let allMessages = await viewModel.loadAllArchivedMessages()

            await MainActor.run {
                ExportManager.shared.exportMessages(
                    allMessages,
                    format: format,
                    scope: .all
                ) { result in
                    DispatchQueue.main.async {
                        handleExportResult(result, messageCount: allMessages.count, format: format)
                    }
                }
            }
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>, messageCount: Int, format: ExportFormat) {
        switch result {
        case .success(let url):
            print("✅ Successfully exported \(messageCount) messages to \(url.path)")

            // Show success notification
            let content = UNMutableNotificationContent()
            content.title = "Export Complete"
            content.body = "Exported \(messageCount) messages as \(format.displayName)"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "export_success",
                content: content,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to show export notification: \(error)")
                }
            }

            // Reveal in Finder
            NSWorkspace.shared.activateFileViewerSelecting([url])

        case .failure(let error):
            print("❌ Failed to export messages: \(error.localizedDescription)")

            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func revealExportsFolder() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let exportDirectory = appSupportURL.appendingPathComponent("NtfyMenuBar/Exports")

        // Create exports directory if it doesn't exist
        try? fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        // Reveal in Finder
        NSWorkspace.shared.activateFileViewerSelecting([exportDirectory])
    }
}

struct ArchiveMessageRowView: View {
    let message: NtfyMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority and timestamp column
            VStack(alignment: .leading, spacing: 2) {
                Text(priorityEmoji)
                    .font(.caption)

                Text(message.date, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 60, alignment: .leading)

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.topic)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)

                    if let title = message.title, !title.isEmpty {
                        Text(title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(message.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let messageText = message.message, !messageText.isEmpty {
                    Text(messageText)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                if let tags = message.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(3)
                        }
                        if tags.count > 3 {
                            Text("+\(tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.clear)
        .cornerRadius(6)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.2))
                .offset(y: 20),
            alignment: .bottom
        )
    }

    private var priorityEmoji: String {
        switch message.priority ?? 3 {
        case 5: return "🔴"
        case 4: return "🟠"
        case 3: return "🟡"
        case 2: return "🔵"
        case 1: return "⚪"
        default: return "🟡"
        }
    }
}



struct ServerEditorView: View {
    @Binding var server: NtfyServer?
    @Binding var isPresented: Bool
    let onSave: (NtfyServer?) -> Void

    @State private var url: String = ""
    @State private var name: String = ""
    @State private var authMethod: AuthenticationMethod = .basicAuth
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var accessToken: String = ""

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text(server?.url.isEmpty == false ? "Edit server" : "Add server")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.top, 4)

            // Content
            VStack(alignment: .leading, spacing: 20) {
                // Server details section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Server details")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("https://ntfy.sh", text: $url)
                            .textFieldStyle(.roundedBorder)
                        Text("e.g., https://ntfy.sh or https://ntfy.example.com")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display name (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("My server", text: $name)
                            .textFieldStyle(.roundedBorder)
                        Text("Custom name for this server")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Authentication section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Authentication")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("", selection: $authMethod) {
                        ForEach(AuthenticationMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    if authMethod == .basicAuth {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("username", text: $username)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                SecureField("password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Text("Leave empty for public servers")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Access token")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("tk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", text: $accessToken)
                                .textFieldStyle(.roundedBorder)
                            Text("32-character token starting with 'tk_'")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    saveServer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty)
            }
            .padding(.bottom, 4)
        }
        .padding(24)
        .frame(width: 480, height: 580)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .onAppear {
            loadServerData()
        }
    }

    private func loadServerData() {
        guard let server = server else { return }
        url = server.url
        name = server.name
        authMethod = server.authMethod
        username = server.username

        // Load credentials
        if !username.isEmpty {
            password = SettingsManager.loadPassword(for: username) ?? ""
        }
        accessToken = SettingsManager.loadAccessToken() ?? ""
    }

    private func saveServer() {
        guard var serverToSave = server else {
            // Create new server
            let newServer = NtfyServer(
                url: url,
                name: name,
                authMethod: authMethod,
                username: username,
                isEnabled: true
            )
            onSave(newServer)
            isPresented = false
            return
        }

        // Update existing server
        serverToSave.url = url
        serverToSave.name = name
        serverToSave.authMethod = authMethod
        serverToSave.username = username

        // Save credentials
        switch authMethod {
        case .basicAuth:
            if !password.isEmpty && !username.isEmpty {
                SettingsManager.savePassword(password, for: username)
            }
        case .accessToken:
            if !accessToken.isEmpty {
                SettingsManager.saveAccessToken(accessToken)
            }
        }

        onSave(serverToSave)
        isPresented = false
    }
}


extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}