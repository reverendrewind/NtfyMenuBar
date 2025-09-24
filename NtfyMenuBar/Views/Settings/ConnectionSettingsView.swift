//
//  ConnectionSettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct ConnectionSettingsView: View {
    @EnvironmentObject var viewModel: NtfyViewModel

    @State private var serverURL: String = ""
    @State private var topics: [String] = []
    @State private var newTopic: String = ""
    @State private var topicValidationError: String = ""
    @State private var authMethod: AuthenticationMethod = .basicAuth
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var accessToken: String = ""
    @State private var autoConnect: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                connectionSection
                topicsSection
                authenticationSection
                preferencesSection
            }
            .padding(20)
        }
        .onAppear {
            loadSettings()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(StringConstants.MenuItems.settings) {
                    saveSettings()
                }
                .disabled(!isFormValid)
            }
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Server Connection")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text(StringConstants.SettingsLabels.serverUrl)
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField(StringConstants.SettingsPlaceholders.serverUrlExample, text: $serverURL)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        validateServerURL()
                    }

                if !serverURL.isEmpty && !isValidURL(serverURL) {
                    Text(StringConstants.ErrorMessages.invalidUrl)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Toggle(StringConstants.SettingsLabels.autoConnect, isOn: $autoConnect)
                .toggleStyle(.switch)
        }
    }

    // MARK: - Topics Section

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topics")
                .font(.headline)

            // Existing topics
            ForEach(topics, id: \.self) { topic in
                HStack {
                    Text(topic)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)

                    Spacer()

                    Button(action: {
                        removeTopic(topic)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Add new topic
            HStack {
                TextField(StringConstants.SettingsPlaceholders.topicExample, text: $newTopic)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTopic()
                    }

                Button("Add") {
                    addTopic()
                }
                .disabled(newTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !topicValidationError.isEmpty {
                Text(topicValidationError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Authentication Section

    private var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Authentication")
                .font(.headline)

            Picker("Method", selection: $authMethod) {
                Text(StringConstants.AuthMethods.basicAuth).tag(AuthenticationMethod.basicAuth)
                Text(StringConstants.AuthMethods.accessToken).tag(AuthenticationMethod.accessToken)
            }
            .pickerStyle(.segmented)

            switch authMethod {
            case .basicAuth:
                basicAuthFields
            case .accessToken:
                tokenAuthFields
            }
        }
    }

    private var basicAuthFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(StringConstants.SettingsLabels.username)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField(StringConstants.SettingsPlaceholders.usernamePlaceholder, text: $username)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text(StringConstants.SettingsLabels.password)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    SecureField(StringConstants.SettingsPlaceholders.passwordPlaceholder, text: $password)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var tokenAuthFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(StringConstants.SettingsLabels.accessToken)
                .font(.subheadline)
                .fontWeight(.medium)

            TextField(StringConstants.SettingsPlaceholders.tokenPlaceholder, text: $accessToken)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Preferences")
                .font(.headline)

            // Connection status
            HStack {
                Text("Status:")
                    .fontWeight(.medium)
                Spacer()
                if viewModel.isConnected {
                    Label(StringConstants.StatusMessages.connected, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label(StringConstants.StatusMessages.disconnected, systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private var isFormValid: Bool {
        !serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidURL(serverURL) &&
        !topics.isEmpty &&
        (authMethod == .basicAuth ? (!username.isEmpty && !password.isEmpty) : !accessToken.isEmpty)
    }

    private func isValidURL(_ url: String) -> Bool {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: AppConfig.Validation.httpUrlPattern, options: .regularExpression) != nil
    }

    private func isValidTopic(_ topic: String) -> Bool {
        let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty &&
               trimmed.count <= AppConfig.Validation.maxTopicLength &&
               trimmed.range(of: AppConfig.Validation.topicPattern, options: .regularExpression) != nil
    }

    private func validateServerURL() {
        if !serverURL.isEmpty && !isValidURL(serverURL) {
            // URL validation feedback handled by UI
        }
    }

    private func addTopic() {
        let trimmed = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            topicValidationError = ""
            return
        }

        guard isValidTopic(trimmed) else {
            topicValidationError = StringConstants.ErrorMessages.invalidTopic
            return
        }

        guard !topics.contains(trimmed) else {
            topicValidationError = "Topic already exists"
            return
        }

        topics.append(trimmed)
        newTopic = ""
        topicValidationError = ""
    }

    private func removeTopic(_ topic: String) {
        topics.removeAll { $0 == topic }
    }

    private func loadSettings() {
        let settings = viewModel.settings
        serverURL = settings.serverURL
        topics = settings.topics
        authMethod = settings.authMethod
        username = settings.username
        password = SettingsManager.loadPassword(for: settings.username) ?? ""
        accessToken = SettingsManager.loadAccessToken() ?? ""
        autoConnect = settings.autoConnect
    }

    private func saveSettings() {
        var settings = viewModel.settings
        settings.serverURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.topics = topics
        settings.authMethod = authMethod
        settings.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !password.isEmpty {
            SettingsManager.savePassword(password, for: settings.username)
        }
        let trimmedToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedToken.isEmpty {
            SettingsManager.saveAccessToken(trimmedToken)
        }
        settings.autoConnect = autoConnect

        viewModel.updateSettings(settings)
    }
}

#Preview {
    ConnectionSettingsView()
        .environmentObject(NtfyViewModel())
}