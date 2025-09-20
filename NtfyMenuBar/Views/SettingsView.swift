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

                    Text("Topics")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Topic list
                    if !topics.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                                HStack {
                                    Text(topic)
                                        .font(.body)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(6)

                                    Spacer()

                                    Button("Remove") {
                                        topics.remove(at: index)
                                    }
                                    .buttonStyle(.borderless)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                        }
                    }

                    // Add new topic
                    HStack {
                        TextField("Add topic (e.g., my-topic)", text: $newTopic)
                            .textFieldStyle(.roundedBorder)

                        Button("Add") {
                            addTopic()
                        }
                        .buttonStyle(.bordered)
                        .disabled(newTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if topics.isEmpty {
                        Text("Add at least one topic to receive notifications")
                            .font(.caption)
                            .foregroundColor(.orange)
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
        let trimmedTopic = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty, !topics.contains(trimmedTopic) else { return }

        topics.append(trimmedTopic)
        newTopic = ""
    }

    private func loadCurrentSettings() {
        let settings = SettingsManager.loadSettings()
        serverURL = settings.serverURL
        topics = settings.topics
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