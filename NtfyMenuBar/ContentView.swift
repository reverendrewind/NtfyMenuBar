//
//  ContentView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI

enum PriorityFilter: String, CaseIterable {
    case all = "All"
    case min = "Min (1)"
    case low = "Low (2)"
    case normal = "Normal (3)"
    case high = "High (4)"
    case max = "Max (5)"

    var priorityValue: Int? {
        switch self {
        case .all: return nil
        case .min: return 1
        case .low: return 2
        case .normal: return 3
        case .high: return 4
        case .max: return 5
        }
    }

    var displayName: String {
        return rawValue
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    // Filtering and search state
    @State private var searchText: String = ""
    @State private var selectedPriorityFilter: PriorityFilter = .all
    @State private var selectedTopicFilter: String = "All topics"
    @State private var showFilterOptions: Bool = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            Divider()
            
            if viewModel.messages.isEmpty {
                emptyStateView
            } else if hasActiveFilters {
                searchAndFilterView
            } else {
                messagesView
            }
            
            Divider()
            
            footerView
        }
        .padding()
        .frame(width: 320, height: 300)
        .background(Color.theme.windowBackground)
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
    
    private var headerView: some View {
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

                connectionStatusView
            }

            // Search and filter bar (only show if there are messages)
            if !viewModel.messages.isEmpty {
                searchAndFilterBar
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
    
    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.isConnected {
                    Text(viewModel.service.connectionQuality.description)
                        .font(.caption2)
                        .foregroundColor(connectionQualityColor)
                }
            }
        }
    }
    
    private var statusColor: Color {
        if viewModel.isConnected {
            return .green
        } else if !viewModel.settings.isConfigured {
            return .orange
        } else {
            return .red
        }
    }
    
    private var statusText: String {
        if viewModel.isConnected {
            return "Connected"
        } else if !viewModel.settings.isConfigured {
            return "Not configured"
        } else if viewModel.connectionError != nil {
            return "Error"
        } else {
            return "Disconnected"
        }
    }

    private var connectionQualityColor: Color {
        switch viewModel.service.connectionQuality {
        case .unknown: return .gray
        case .excellent: return .green
        case .good: return .blue
        case .poor: return .orange
        case .failing: return .red
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.slash")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No notifications yet")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var searchAndFilterBar: some View {
        HStack(spacing: 8) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                TextField("Search messages...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)

            // Filter button
            Button {
                showFilterOptions.toggle()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 12))
                    if hasActiveFilters {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    }
                }
                .foregroundColor(hasActiveFilters ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showFilterOptions) {
                filterOptionsView
            }
        }
    }

    private var filterOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter messages")
                .font(.headline)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Priority", selection: $selectedPriorityFilter) {
                    ForEach(PriorityFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Topic")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Topic", selection: $selectedTopicFilter) {
                    Text("All topics").tag("All topics")
                    ForEach(availableTopics, id: \.self) { topic in
                        Text(topic).tag(topic)
                    }
                }
                .pickerStyle(.menu)
            }

            Button("Clear filters") {
                clearAllFilters()
            }
            .buttonStyle(.bordered)
            .disabled(!hasActiveFilters)
        }
        .padding()
        .frame(width: 200)
    }

    private var messagesView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(filteredMessages, id: \.uniqueId) { message in
                    MessageRowView(message: message)
                }
            }
        }
        .frame(maxHeight: 200)
    }

    private var searchAndFilterView: some View {
        VStack(spacing: 8) {
            if filteredMessages.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("No messages match your search")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Clear search") {
                        searchText = ""
                        clearAllFilters()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredMessages, id: \.uniqueId) { message in
                            MessageRowView(message: message)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }
    
    private var footerView: some View {
        HStack {
            Button("Settings") {
                print("📱 Settings button pressed")
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
                print("🔗 Connect button pressed, connected: \(viewModel.isConnected)")
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

    // MARK: - Filtering Logic

    private var filteredMessages: [NtfyMessage] {
        var messages = viewModel.messages

        // Apply search filter
        if !searchText.isEmpty {
            messages = messages.filter { message in
                let searchLower = searchText.lowercased()
                return (message.message?.lowercased().contains(searchLower) ?? false) ||
                       (message.title?.lowercased().contains(searchLower) ?? false) ||
                       message.topic.lowercased().contains(searchLower) ||
                       (message.tags?.joined(separator: " ").lowercased().contains(searchLower) ?? false)
            }
        }

        // Apply priority filter
        if let priorityValue = selectedPriorityFilter.priorityValue {
            messages = messages.filter { message in
                (message.priority ?? 3) == priorityValue
            }
        }

        // Apply topic filter
        if selectedTopicFilter != "All topics" {
            messages = messages.filter { message in
                message.topic == selectedTopicFilter
            }
        }

        return messages
    }

    private var availableTopics: [String] {
        let allTopics = Set(viewModel.messages.map { $0.topic })
        return Array(allTopics).sorted()
    }

    private var hasActiveFilters: Bool {
        return !searchText.isEmpty ||
               selectedPriorityFilter != .all ||
               selectedTopicFilter != "All topics"
    }

    private func clearAllFilters() {
        searchText = ""
        selectedPriorityFilter = .all
        selectedTopicFilter = "All topics"
        showFilterOptions = false
    }
}

#Preview {
    ContentView()
        .environmentObject(NtfyViewModel())
}
