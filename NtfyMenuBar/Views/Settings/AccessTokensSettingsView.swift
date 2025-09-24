//
//  AccessTokensSettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI
import AppKit

struct AccessTokensSettingsView: View {
    // Required bindings from parent
    @Binding var serverURL: String
    @Binding var authMethod: AuthenticationMethod
    @Binding var username: String
    @Binding var password: String
    @Binding var accessToken: String
    @Binding var accessTokens: [AccessToken]
    @Binding var newTokenLabel: String
    @Binding var newTokenExpiration: TokenExpiration
    @Binding var isGeneratingToken: Bool
    @Binding var generatedToken: String?
    @Binding var tokenError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Generate access tokens")
                    .font(.headline)

                Text("Access tokens allow applications to authenticate without using your password. Each token provides full account access except password changes and account deletion.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Token label (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("App or service name", text: $newTokenLabel)
                        .textFieldStyle(.roundedBorder)

                    Text("Expiration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $newTokenExpiration) {
                        ForEach(TokenExpiration.allCases, id: \.self) { expiration in
                            Text(expiration.displayName).tag(expiration)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Button("Generate token") {
                            generateNewToken()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isGeneratingToken || !canGenerateToken)

                        if isGeneratingToken {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    if let error = tokenError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            // Generated token display
            if let token = generatedToken {
                VStack(alignment: .leading, spacing: 12) {
                    Text("New token generated")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text("⚠️ Copy this token now - you won't be able to see it again!")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)

                    HStack {
                        Text(token)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                            .textSelection(.enabled)

                        Button("Copy") {
                            copyToClipboard(token)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button("Dismiss") {
                        generatedToken = nil
                        newTokenLabel = ""
                        newTokenExpiration = .never
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }

            // Existing tokens list
            VStack(alignment: .leading, spacing: 12) {
                Text("Existing tokens")
                    .font(.headline)

                if accessTokens.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "key.slash")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No access tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Generate your first token above to get started")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 8) {
                        ForEach(accessTokens) { token in
                            AccessTokenRowView(
                                token: token,
                                onCopy: { copyToClipboard($0) },
                                onRevoke: { revokeToken($0) }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private computed properties

    private var canGenerateToken: Bool {
        return !serverURL.isEmpty &&
               ((authMethod == .basicAuth && !username.isEmpty) ||
                (authMethod == .accessToken && !accessToken.isEmpty))
    }

    // MARK: - Private methods

    private func generateNewToken() {
        guard !isGeneratingToken else { return }

        isGeneratingToken = true
        tokenError = nil

        Task {
            do {
                let token = try await TokenManager.shared.generateToken(
                    serverURL: serverURL,
                    authMethod: authMethod,
                    username: username,
                    password: password,
                    accessToken: accessToken,
                    label: newTokenLabel.isEmpty ? nil : newTokenLabel,
                    expiration: newTokenExpiration
                )

                await MainActor.run {
                    self.generatedToken = token.token
                    self.accessTokens.append(token)
                    self.isGeneratingToken = false
                }
            } catch {
                await MainActor.run {
                    self.tokenError = error.localizedDescription
                    self.isGeneratingToken = false
                }
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func revokeToken(_ token: AccessToken) {
        // Note: This only removes the token from local storage.
        // For server-side revocation, implement DELETE to /v1/access-tokens/{token_id}
        accessTokens.removeAll { $0.id == token.id }
    }
}