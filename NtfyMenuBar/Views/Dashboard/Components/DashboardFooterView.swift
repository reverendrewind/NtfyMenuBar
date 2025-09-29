//
//  DashboardFooterView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct DashboardFooterView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @Binding var searchText: String
    @Binding var selectedPriorities: Set<Int>
    @Binding var selectedTopics: Set<String>
    @Binding var showFilterOptions: Bool

    private let filteringService = MessageFilteringService()

    var body: some View {
        HStack {
            Button("Settings") {
                Logger.shared.info("📱 Settings button pressed")
                viewModel.openSettingsAction?()
            }
            .keyboardShortcut(",", modifiers: .command)

            Spacer()

            if !viewModel.messages.isEmpty {
                if hasActiveFilters {
                    Button("Clear filters") {
                        clearAllFilters()
                    }
                    .keyboardShortcut(.escape)
                }

                Button("Clear") {
                    viewModel.clearMessages()
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }

            Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                Logger.shared.info("🔗 Connect button pressed, connected: \(viewModel.isConnected)")
                if viewModel.isConnected {
                    viewModel.disconnect()
                } else {
                    viewModel.connect()
                }
            }
            .keyboardShortcut("d", modifiers: .command)
        }
        .buttonStyle(.borderless)
        .font(.caption)
    }

    private var hasActiveFilters: Bool {
        return filteringService.hasActiveFilters(
            searchText: searchText,
            selectedPriorities: selectedPriorities,
            selectedTopics: selectedTopics
        )
    }

    private func clearAllFilters() {
        searchText = ""
        selectedPriorities.removeAll()
        selectedTopics.removeAll()
        showFilterOptions = false
    }
}