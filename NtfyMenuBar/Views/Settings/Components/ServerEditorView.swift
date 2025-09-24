//
//  ServerEditorView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI
import AppKit

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