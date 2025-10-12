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
            // Tabs with native macOS tab bar
            TabView(selection: $selectedTab) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ConnectionSettingsView(
                            serverURL: $serverURL,
                            topics: $topics,
                            authMethod: $authMethod,
                            username: $username,
                            password: $password,
                            accessToken: $accessToken,
                            autoConnect: $autoConnect
                        )
                    }
                    .padding(20)
                }
                .tabItem {
                    Label("Connection", systemImage: "network")
                }
                .tag(SettingsTab.connection)
                .accessibilityLabel("Connection tab")
                .accessibilityHint("Switch to connection settings")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
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
                    .padding(20)
                }
                .tabItem {
                    Label("Access tokens", systemImage: "key.fill")
                }
                .tag(SettingsTab.tokens)
                .accessibilityLabel("Access tokens tab")
                .accessibilityHint("Switch to access tokens settings")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        FallbackServersSettingsView(
                            fallbackServers: $fallbackServers,
                            enableFallbackServers: $enableFallbackServers,
                            fallbackRetryDelay: $fallbackRetryDelay,
                            editingServer: $editingServer,
                            showingServerEditor: $showingServerEditor
                        )
                    }
                    .padding(20)
                }
                .tabItem {
                    Label("Fallback servers", systemImage: "server.rack")
                }
                .tag(SettingsTab.fallbacks)
                .accessibilityLabel("Fallback servers tab")
                .accessibilityHint("Switch to fallback servers settings")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        DNDSettingsView(
                            isDNDScheduleEnabled: $isDNDScheduleEnabled,
                            dndStartTime: $dndStartTime,
                            dndEndTime: $dndEndTime,
                            dndDaysOfWeek: $dndDaysOfWeek
                        )
                        .environmentObject(viewModel)
                    }
                    .padding(20)
                }
                .tabItem {
                    Label("Do Not Disturb", systemImage: "moon.zzz")
                }
                .tag(SettingsTab.dnd)
                .accessibilityLabel("Do Not Disturb tab")
                .accessibilityHint("Switch to Do Not Disturb settings")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ArchiveSettingsView(
                            archiveStatistics: $archiveStatistics,
                            isLoadingArchiveStats: $isLoadingArchiveStats,
                            showingClearArchiveAlert: $showingClearArchiveAlert,
                            archiveClearDays: $archiveClearDays,
                            archivedMessages: $archivedMessages,
                            isLoadingArchive: $isLoadingArchive,
                            showingArchiveBrowser: $showingArchiveBrowser,
                            archiveSearchText: $archiveSearchText,
                            selectedArchiveTopic: $selectedArchiveTopic
                        )
                        .environmentObject(viewModel)
                    }
                    .padding(20)
                }
                .tabItem {
                    Label("Message Archive", systemImage: "archivebox")
                }
                .tag(SettingsTab.archive)
                .accessibilityLabel("Message Archive tab")
                .accessibilityHint("Switch to message archive settings")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PreferencesSettingsView(
                            enableNotifications: $enableNotifications,
                            maxRecentMessages: $maxRecentMessages,
                            appearanceMode: $appearanceMode,
                            notificationSound: $notificationSound,
                            customSoundForHighPriority: $customSoundForHighPriority
                        )
                    }
                    .padding(20)
                }
                .tabItem {
                    Label("Preferences", systemImage: "gearshape")
                }
                .tag(SettingsTab.preferences)
                .accessibilityLabel("Preferences tab")
                .accessibilityHint("Switch to preferences settings")
            }

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidConfiguration)
            }
            .padding(20)
            .padding(.top, 0)
            .accessibilityElement(children: .contain)
        }
        .frame(width: UIConstants.Settings.width, height: UIConstants.Settings.height)
        .background(Color.theme.windowBackground)
        .onAppear {
            loadCurrentSettings()
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



    private func loadCurrentSettings() {
        Logger.shared.info("⚙️ Loading current settings")
        let settings = SettingsManager.loadSettings()
        Logger.shared.info("⚙️ Loaded settings: serverURL=\(settings.serverURL), topics=\(settings.topics), authMethod=\(settings.authMethod)")
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