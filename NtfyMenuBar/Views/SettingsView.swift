//
//  SettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI

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
    @State private var selectedTab: SettingsTab = .connection

    enum SettingsTab: String, CaseIterable {
        case connection = "Connection"
        case preferences = "Preferences"

        var systemImage: String {
            switch self {
            case .connection: return "network"
            case .preferences: return "gearshape"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Tab Selection
                Picker("Settings Tab", selection: $selectedTab) {
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
        .frame(width: 550, height: 650)
        .background(Color.theme.windowBackground)
        .onAppear {
            loadCurrentSettings()
        }
    }

    // MARK: - Tab Views

    private var connectionSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Server Configuration")
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
                                TextField("Add topics (comma-separated)", text: $newTopic)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 200)
                                    .onSubmit {
                                        addTopic()
                                    }
                                    .onChange(of: newTopic) { _ in
                                        // Clear error when user types
                                        if !topicValidationError.isEmpty && !topicValidationError.contains("Added") {
                                            topicValidationError = ""
                                        }
                                        // Auto-lowercase but preserve commas and spaces around them
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
                                Text("Example: alerts, news or alerts,news,updates")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Tip: Add multiple topics with commas (e.g., topic1,topic2)")
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

                Picker("Authentication Method", selection: $authMethod) {
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
                            Text("Access Token")
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

                Toggle("Enable Notifications", isOn: $enableNotifications)

                Toggle("Auto-connect at Launch", isOn: $autoConnect)
                    .help("Automatically connect to the server when the app starts")

                HStack {
                    Text("Recent Messages: \(maxRecentMessages)")
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

        // Split by comma and process each topic
        let topicList = input.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
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
            appearanceMode: appearanceMode
        )
        settings.topics = topics

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