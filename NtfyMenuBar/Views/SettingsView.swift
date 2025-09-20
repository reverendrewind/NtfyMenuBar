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
    @State private var topic: String = ""
    @State private var authMethod: AuthenticationMethod = .basicAuth
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var accessToken: String = ""
    @State private var enableNotifications: Bool = true
    @State private var maxRecentMessages: Int = 20
    @State private var autoConnect: Bool = true
    @State private var appearanceMode: AppearanceMode = .system
    @State private var selectedTab: SettingsTab = .connection
    @State private var showingUserManagement = false

    enum SettingsTab: String, CaseIterable {
        case connection = "Connection"
        case preferences = "Preferences"
        case userManagement = "User Management"

        var systemImage: String {
            switch self {
            case .connection: return "network"
            case .preferences: return "gearshape"
            case .userManagement: return "person.2"
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
                    case .userManagement:
                        userManagementView
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

                if selectedTab != .userManagement {
                    Button("Save") {
                        saveSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValidConfiguration)
                }
            }
            .padding(20)
            .padding(.top, 0)
        }
        .frame(width: 550, height: 650)
        .background(Color.theme.windowBackground)
        .onAppear {
            loadCurrentSettings()
        }
        .sheet(isPresented: $showingUserManagement) {
            UserManagementView(settings: viewModel.settings)
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

                    Text("Topic")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("my-topic", text: $topic)
                        .textFieldStyle(.roundedBorder)
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

    private var userManagementView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("User Management")
                    .font(.headline)

                Text("Manage users on your ntfy server. Requires admin permissions.")
                    .font(.body)
                    .foregroundColor(.secondary)

                if viewModel.settings.isConfigured {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(.blue)
                            Text("Available Features")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "plus.circle", title: "Create Users", description: "Add new users with custom roles")
                            FeatureRow(icon: "person.badge.minus", title: "Delete Users", description: "Remove users from the server")
                            FeatureRow(icon: "crown", title: "Role Management", description: "Assign admin or user roles")
                            FeatureRow(icon: "key", title: "Password Management", description: "Reset user passwords")
                        }

                        Button("Open User Manager") {
                            showingUserManagement = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Server Not Configured")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }

                        Text("Configure your server connection in the Connection tab first.")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Button("Go to Connection Settings") {
                            selectedTab = .connection
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Coming Soon")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "chart.bar", title: "Server Statistics", description: "View server metrics and usage")
                    FeatureRow(icon: "lock.shield", title: "Access Control", description: "Manage topic permissions")
                }
            }
        }
    }

    // MARK: - Private Methods

    private var isValidConfiguration: Bool {
        guard !serverURL.isEmpty && !topic.isEmpty else { return false }

        switch authMethod {
        case .basicAuth:
            return !username.isEmpty
        case .accessToken:
            return SettingsManager.validateAccessToken(accessToken)
        }
    }

    private func loadCurrentSettings() {
        let settings = SettingsManager.loadSettings()
        serverURL = settings.serverURL
        topic = settings.topic
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
        let settings = NtfySettings(
            serverURL: serverURL,
            topic: topic,
            authMethod: authMethod,
            username: username,
            enableNotifications: enableNotifications,
            maxRecentMessages: maxRecentMessages,
            autoConnect: autoConnect,
            appearanceMode: appearanceMode
        )

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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
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