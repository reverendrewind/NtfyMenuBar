//
//  DashboardHeaderView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct DashboardHeaderView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @Binding var searchText: String
    @Binding var selectedPriorities: Set<Int>
    @Binding var selectedTopics: Set<String>
    @Binding var showFilterOptions: Bool
    @FocusState.Binding var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(headerTitle)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if viewModel.isConnected && !viewModel.settings.topics.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(viewModel.settings.topics.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    } else if !viewModel.isConnected && viewModel.settings.isConfigured {
                        Text("Not connected")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    // Snooze button and status
                    SnoozeControlView()

                    ConnectionStatusView()
                }
            }

            // Snooze status bar (only show if snoozed)
            if viewModel.isSnoozed {
                SnoozeStatusView()
            }

            // Search and filter bar (only show if there are messages)
            if !viewModel.messages.isEmpty {
                SearchAndFilterBar(
                    searchText: $searchText,
                    selectedPriorities: $selectedPriorities,
                    selectedTopics: $selectedTopics,
                    showFilterOptions: $showFilterOptions,
                    isSearchFocused: $isSearchFocused
                )
            }
        }
    }

    private var headerTitle: String {
        if !viewModel.isConnected {
            return "ntfy Notifications"
        }
        return serverDisplayName
    }

    private var serverDisplayName: String {
        // Show active server if connected and fallbacks are enabled, otherwise show primary
        if let activeServer = viewModel.service.activeServer, viewModel.isConnected {
            return activeServer.displayName
        }

        var serverURL = viewModel.settings.serverURL

        // Remove protocol prefix for cleaner display
        if serverURL.hasPrefix("https://") {
            serverURL = String(serverURL.dropFirst(8))
        } else if serverURL.hasPrefix("http://") {
            serverURL = String(serverURL.dropFirst(7))
        }

        // Remove trailing slashes
        while serverURL.hasSuffix("/") {
            serverURL = String(serverURL.dropLast())
        }

        // Return cleaned URL or default
        return serverURL.isEmpty ? "Not configured" : serverURL
    }
}