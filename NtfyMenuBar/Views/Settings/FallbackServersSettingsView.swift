//
//  FallbackServersSettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct FallbackServersSettingsView: View {
    // Required bindings from parent
    @Binding var fallbackServers: [NtfyServer]
    @Binding var enableFallbackServers: Bool
    @Binding var fallbackRetryDelay: Double
    @Binding var editingServer: NtfyServer?
    @Binding var showingServerEditor: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Configuration section
            VStack(alignment: .leading, spacing: 12) {
                Text("Fallback server configuration")
                    .font(.headline)

                Toggle("Enable fallback servers", isOn: $enableFallbackServers)
                    .help("Automatically try fallback servers when primary server fails")

                if enableFallbackServers {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Retry delay: \(Int(fallbackRetryDelay)) seconds")
                            Spacer()
                            Stepper("", value: $fallbackRetryDelay, in: 10...300, step: 10)
                        }
                        Text("Time to wait before retrying failed servers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Server management section
            if enableFallbackServers {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Configured servers")
                            .font(.headline)
                        Spacer()
                        Button("Add server") {
                            editingServer = NtfyServer()
                            showingServerEditor = true
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if fallbackServers.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "server.rack")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No fallback servers configured")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Add servers to provide automatic failover when the primary server is unavailable")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(fallbackServers.enumerated()), id: \.element.id) { index, server in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(server.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(server.cleanURL)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if !server.username.isEmpty {
                                            Text("User: \(server.username)")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }

                                    Spacer()

                                    VStack(spacing: 4) {
                                        Toggle("", isOn: Binding(
                                            get: { server.isEnabled },
                                            set: { newValue in
                                                fallbackServers[index].isEnabled = newValue
                                            }
                                        ))
                                        .help("Enable/disable this server")

                                        HStack(spacing: 4) {
                                            Button("Edit") {
                                                editingServer = server
                                                showingServerEditor = true
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)

                                            Button("Delete") {
                                                fallbackServers.remove(at: index)
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(server.isEnabled ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(server.isEnabled ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingServerEditor) {
            ServerEditorView(
                server: $editingServer,
                isPresented: $showingServerEditor
            ) { editedServer in
                if let editedServer = editedServer {
                    if let index = fallbackServers.firstIndex(where: { $0.id == editedServer.id }) {
                        fallbackServers[index] = editedServer
                    } else {
                        fallbackServers.append(editedServer)
                    }
                }
            }
        }
    }
}