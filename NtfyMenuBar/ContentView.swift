//
//  ContentView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    // Filtering service
    private let filteringService = MessageFilteringService()

    // Filtering and search state
    @State private var searchText: String = ""
    @State private var selectedPriorities: Set<Int> = []
    @State private var selectedTopics: Set<String> = []
    @State private var showFilterOptions: Bool = false
    @FocusState private var isSearchFocused: Bool

    // Grouping state
    @State private var groupingMode: GroupingMode = .none
    @State private var collapsedSections: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DashboardHeaderView(
                searchText: $searchText,
                selectedPriorities: $selectedPriorities,
                selectedTopics: $selectedTopics,
                showFilterOptions: $showFilterOptions,
                isSearchFocused: $isSearchFocused
            )

            Divider()

            if viewModel.messages.isEmpty {
                EmptyStateView()
            } else if filteringService.hasActiveFilters(searchText: searchText, selectedPriorities: selectedPriorities, selectedTopics: selectedTopics) {
                searchAndFilterView
            } else {
                messagesView
            }

            Divider()

            DashboardFooterView(
                searchText: $searchText,
                selectedPriorities: $selectedPriorities,
                selectedTopics: $selectedTopics,
                showFilterOptions: $showFilterOptions
            )
        }
        .padding()
        .frame(width: UIConstants.Dashboard.width, height: UIConstants.Dashboard.height)
        .background(Color.theme.windowBackground)
        .onChange(of: filteredMessages.count) { _ in
            announceFilterResults()
        }
        .onExitCommand {
            // Close on Escape key
            if let window = NSApplication.shared.keyWindow {
                window.close()
            }
        }
        .background(
            // Hidden button for Cmd+F search shortcut
            Button("") {
                isSearchFocused = true
            }
            .keyboardShortcut("f", modifiers: .command)
            .hidden()
        )
    }

    // MARK: - Remaining Views that need extraction

    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.messages, id: \.uniqueId) { message in
                    MessageRowView(message: message)
                        .padding(.horizontal, 2)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxHeight: .infinity)
    }

    private var searchAndFilterView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Clear filters button
            if hasActiveFilters {
                HStack {
                    Text("\(filteredMessages.count) of \(viewModel.messages.count) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityAddTraits(.updatesFrequently)

                    Spacer()

                    Button("Clear filters") {
                        clearAllFilters()
                    }
                    .font(.caption)
                    .accessibilityLabel("Clear all active filters")
                    .accessibilityHint("Removes search text and priority filters")
                }
                .padding(.bottom, 4)
            }

            // Filtered messages
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredMessages, id: \.uniqueId) { message in
                        MessageRowView(message: message)
                            .padding(.horizontal, 2)
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Helper Properties

    private var filteredMessages: [NtfyMessage] {
        return filteringService.filterMessages(
            viewModel.messages,
            searchText: searchText,
            selectedPriorities: selectedPriorities,
            selectedTopics: selectedTopics
        )
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

    private func announceFilterResults() {
        guard hasActiveFilters else { return }

        let announcement = "Showing \(filteredMessages.count) of \(viewModel.messages.count) messages"

        // Post accessibility announcement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApplication.shared.keyWindow {
                NSAccessibility.post(
                    element: window,
                    notification: .announcementRequested,
                    userInfo: [
                        .announcement: announcement,
                        .priority: NSAccessibilityPriorityLevel.medium
                    ]
                )
            }
        }
    }
}