//
//  ConnectionSettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct ConnectionSettingsView: View {
    @EnvironmentObject var viewModel: NtfyViewModel

    // Bindings from parent SettingsView
    @Binding var serverURL: String
    @Binding var topics: [String]
    @Binding var authMethod: AuthenticationMethod
    @Binding var username: String
    @Binding var password: String
    @Binding var accessToken: String
    @Binding var autoConnect: Bool

    // Local UI state
    @State private var newTopic: String = ""
    @State private var topicValidationError: String = ""

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
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Server connection")
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

            // Existing topics displayed horizontally with wrapping
            if !topics.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(topics, id: \.self) { topic in
                        HStack(spacing: 4) {
                            Text(topic)
                                .font(.system(size: 12))

                            Button(action: {
                                removeTopic(topic)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove topic \(topic)")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
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

    // FlowLayout for horizontal wrapping display
    struct FlowLayout: Layout {
        var spacing: CGFloat = 8

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = FlowResult(
                in: proposal.replacingUnspecifiedDimensions().width,
                subviews: subviews,
                spacing: spacing
            )
            return result.size
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = FlowResult(
                in: bounds.width,
                subviews: subviews,
                spacing: spacing
            )
            for (index, subview) in subviews.enumerated() {
                subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                         y: result.positions[index].y + bounds.minY),
                            proposal: .unspecified)
            }
        }

        struct FlowResult {
            var size: CGSize = .zero
            var positions: [CGPoint] = []

            init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
                var currentX: CGFloat = 0
                var currentY: CGFloat = 0
                var lineHeight: CGFloat = 0
                var maxX: CGFloat = 0

                positions.reserveCapacity(subviews.count)

                for subview in subviews {
                    let size = subview.sizeThatFits(.unspecified)

                    if currentX + size.width > maxWidth && currentX > 0 {
                        currentX = 0
                        currentY += lineHeight + spacing
                        lineHeight = 0
                    }

                    positions.append(CGPoint(x: currentX, y: currentY))
                    lineHeight = max(lineHeight, size.height)
                    currentX += size.width + spacing
                    maxX = max(maxX, currentX - spacing)
                }

                self.size = CGSize(width: maxX, height: currentY + lineHeight)
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
            Text("Connection preferences")
                .font(.headline)

            // Connection status
            HStack {
                Text("Status:")
                    .fontWeight(.medium)
                Spacer()
                if viewModel.isConnected {
                    Label(StringConstants.StatusMessages.connected, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("Connection status: Connected")
                } else {
                    Label(StringConstants.StatusMessages.disconnected, systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .accessibilityLabel("Connection status: Disconnected")
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
        let isEmpty = trimmed.isEmpty
        let isValidLength = trimmed.count <= AppConfig.Validation.maxTopicLength
        let matchesPattern = trimmed.range(of: AppConfig.Validation.topicPattern, options: .regularExpression) != nil

        Logger.shared.info("🏷️ Validating topic '\(trimmed)':")
        Logger.shared.info("🏷️   - Length: \(trimmed.count) <= \(AppConfig.Validation.maxTopicLength): \(isValidLength)")
        Logger.shared.info("🏷️   - Pattern '\(AppConfig.Validation.topicPattern)' matches: \(matchesPattern)")
        Logger.shared.info("🏷️   - Not empty: \(!isEmpty)")

        return !isEmpty && isValidLength && matchesPattern
    }

    private func validateServerURL() {
        if !serverURL.isEmpty && !isValidURL(serverURL) {
            // URL validation feedback handled by UI
        }
    }

    private func addTopic() {
        let trimmed = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.shared.info("🏷️ Attempting to add topic(s): '\(trimmed)'")

        guard !trimmed.isEmpty else {
            Logger.shared.info("🏷️ Topic is empty, clearing error")
            topicValidationError = ""
            return
        }

        // Split by comma and/or space to support multiple topics
        let separators = CharacterSet(charactersIn: ", ")
        let potentialTopics = trimmed.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        Logger.shared.info("🏷️ Split input into potential topics: \(potentialTopics)")

        var addedTopics: [String] = []
        var failedTopics: [String] = []
        var duplicateTopics: [String] = []

        for topic in potentialTopics {
            let isValid = isValidTopic(topic)
            Logger.shared.info("🏷️ Topic validation result for '\(topic)': \(isValid)")

            if !isValid {
                failedTopics.append(topic)
                continue
            }

            if topics.contains(topic) {
                duplicateTopics.append(topic)
                continue
            }

            topics.append(topic)
            addedTopics.append(topic)
        }

        // Provide feedback about what happened
        if !addedTopics.isEmpty {
            Logger.shared.info("🏷️ Successfully added topics: \(addedTopics). Topics now: \(topics)")
            newTopic = ""
            topicValidationError = ""
        }

        if !failedTopics.isEmpty {
            topicValidationError = "Invalid topic(s): \(failedTopics.joined(separator: ", "))"
        } else if !duplicateTopics.isEmpty && addedTopics.isEmpty {
            topicValidationError = "Topic(s) already exist: \(duplicateTopics.joined(separator: ", "))"
        }
    }

    private func removeTopic(_ topic: String) {
        topics.removeAll { $0 == topic }
    }

}

#Preview {
    ConnectionSettingsView(
        serverURL: .constant("https://ntfy.sh"),
        topics: .constant(["test", "alerts"]),
        authMethod: .constant(.basicAuth),
        username: .constant("user"),
        password: .constant("pass"),
        accessToken: .constant(""),
        autoConnect: .constant(true)
    )
    .environmentObject(NtfyViewModel())
}