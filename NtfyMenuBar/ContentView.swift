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
            headerView
            
            Divider()
            
            if viewModel.messages.isEmpty {
                emptyStateView
            } else if filteringService.hasActiveFilters(searchText: searchText, selectedPriorities: selectedPriorities, selectedTopics: selectedTopics) {
                searchAndFilterView
            } else {
                messagesView
            }
            
            Divider()
            
            footerView
        }
        .padding()
        .frame(width: UIConstants.Dashboard.width, height: UIConstants.Dashboard.height)
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

                HStack(spacing: 8) {
                    // Snooze button and status
                    snoozeControlView

                    connectionStatusView
                }
            }

            // Snooze status bar (only show if snoozed)
            if viewModel.isSnoozed {
                snoozeStatusView
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
            Text("Filter & group messages")
                .font(.headline)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Grouping")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Grouping", selection: $groupingMode) {
                    ForEach(GroupingMode.allCases, id: \.self) { mode in
                        Label(mode.displayName, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Menu {
                    // Select/Deselect all
                    Button(action: {
                        let allPriorities = Set([1, 2, 3, 4, 5])
                        if selectedPriorities == allPriorities {
                            selectedPriorities.removeAll()
                        } else {
                            selectedPriorities = allPriorities
                        }
                    }) {
                        HStack {
                            let allPriorities = Set([1, 2, 3, 4, 5])
                            Image(systemName: selectedPriorities == allPriorities ? "checkmark" : selectedPriorities.isEmpty ? "" : "minus")
                            Text("All priorities")
                        }
                    }

                    Divider()

                    // Individual priority checkboxes (in descending order)
                    ForEach([5, 4, 3, 2, 1], id: \.self) { priority in
                        Button(action: {
                            if selectedPriorities.contains(priority) {
                                selectedPriorities.remove(priority)
                            } else {
                                selectedPriorities.insert(priority)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedPriorities.contains(priority) ? "checkmark" : "")
                                    .frame(width: 12)
                                Text(filteringService.priorityDisplayName(for: priority))
                                Spacer()
                                let count = filteringService.getMessageCount(for: priority, in: viewModel.messages)
                                Text("(\(count))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } label: {
                    HStack {
                        if selectedPriorities.isEmpty {
                            Text("All priorities")
                                .font(.caption)
                        } else if selectedPriorities.count == 1 {
                            Text(filteringService.priorityDisplayName(for: selectedPriorities.first!))
                                .font(.caption)
                        } else {
                            Text("\(selectedPriorities.count) priorities selected")
                                .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Topic")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Menu {
                    // Select/Deselect all
                    Button(action: {
                        if selectedTopics.count == availableTopics.count {
                            selectedTopics.removeAll()
                        } else {
                            selectedTopics = Set(availableTopics)
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedTopics.count == availableTopics.count ? "checkmark" : selectedTopics.isEmpty ? "" : "minus")
                            Text("All topics")
                        }
                    }

                    Divider()

                    // Individual topic checkboxes
                    ForEach(availableTopics, id: \.self) { topic in
                        Button(action: {
                            if selectedTopics.contains(topic) {
                                selectedTopics.remove(topic)
                            } else {
                                selectedTopics.insert(topic)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedTopics.contains(topic) ? "checkmark" : "")
                                    .frame(width: 12)
                                Text(topic)
                                Spacer()
                                let count = filteringService.getMessageCount(for: topic, in: viewModel.messages)
                                Text("(\(count))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } label: {
                    HStack {
                        if selectedTopics.isEmpty {
                            Text("All topics")
                                .font(.caption)
                        } else if selectedTopics.count == 1 {
                            Text(selectedTopics.first!)
                                .font(.caption)
                        } else {
                            Text("\(selectedTopics.count) topics selected")
                                .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                Button("Clear filters") {
                    clearAllFilters()
                }
                .buttonStyle(.bordered)
                .disabled(!hasActiveFilters)

                if groupingMode != .none && !collapsedSections.isEmpty {
                    Button("Expand all") {
                        collapsedSections.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .frame(width: 220)
    }

    private var messagesView: some View {
        ScrollView {
            if groupingMode == .none {
                // Ungrouped view
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredMessages, id: \.uniqueId) { message in
                        MessageRowView(message: message)
                    }
                }
            } else {
                // Grouped view
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messageGroups, id: \.key) { group in
                        MessageGroupView(
                            title: group.key,
                            messages: group.value,
                            isCollapsed: collapsedSections.contains(group.key),
                            groupingMode: groupingMode,
                            onToggle: {
                                toggleSection(group.key)
                            }
                        )
                    }
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
                    if groupingMode == .none {
                        // Ungrouped view
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(filteredMessages, id: \.uniqueId) { message in
                                MessageRowView(message: message)
                            }
                        }
                    } else {
                        // Grouped view
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(messageGroups, id: \.key) { group in
                                MessageGroupView(
                                    title: group.key,
                                    messages: group.value,
                                    isCollapsed: collapsedSections.contains(group.key),
                                    groupingMode: groupingMode,
                                    onToggle: {
                                        toggleSection(group.key)
                                    }
                                )
                            }
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
        return filteringService.filterMessages(
            viewModel.messages,
            searchText: searchText,
            selectedPriorities: selectedPriorities,
            selectedTopics: selectedTopics
        )
    }

    private var availableTopics: [String] {
        return filteringService.getAvailableTopics(from: viewModel.messages)
    }

    private var messageGroups: [MessageGroup] {
        return filteringService.groupMessages(filteredMessages, by: groupingMode)
    }

    private func toggleSection(_ section: String) {
        if collapsedSections.contains(section) {
            collapsedSections.remove(section)
        } else {
            collapsedSections.insert(section)
        }
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


    // MARK: - Snooze Controls

    private var snoozeControlView: some View {
        Group {
            if viewModel.isSnoozed {
                // Show unsnooze button when snoozed
                Button(action: {
                    viewModel.clearSnooze()
                }) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .help("Clear snooze")
            } else {
                // Show snooze menu when not snoozed
                Menu {
                    ForEach(SnoozeDuration.allCases.filter { $0 != .custom }, id: \.self) { duration in
                        Button(action: {
                            viewModel.snoozeNotifications(duration: duration)
                        }) {
                            Label(duration.displayName, systemImage: duration.systemImage)
                        }
                    }

                } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Snooze notifications")
            }
        }
    }

    private var snoozeStatusView: some View {
        HStack(spacing: 6) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 10))
                .foregroundColor(.orange)

            Text(viewModel.snoozeStatusText)
                .font(.caption2)
                .foregroundColor(.orange)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
}

struct MessageGroupView: View {
    let title: String
    let messages: [NtfyMessage]
    let isCollapsed: Bool
    let groupingMode: GroupingMode
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Group header
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Image(systemName: groupIcon)
                        .font(.system(size: 11))
                        .foregroundColor(groupColor)

                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    // Message count badge
                    Text("\(messages.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(6)

                    // Priority indicator for priority grouping
                    if groupingMode == .byPriority {
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 6, height: 6)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(6)
            .hoverEffect()

            // Messages (if not collapsed)
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(messages, id: \.uniqueId) { message in
                        MessageRowView(message: message)
                            .padding(.leading, 12)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
    }

    private var groupIcon: String {
        switch groupingMode {
        case .byTopic:
            return "folder.fill"
        case .byPriority:
            return "flag.fill"
        case .none:
            return "list.bullet"
        }
    }

    private var groupColor: Color {
        switch groupingMode {
        case .byTopic:
            return .blue
        case .byPriority:
            return priorityColor
        case .none:
            return .secondary
        }
    }

    private var priorityColor: Color {
        switch title {
        case "Max":
            return .red
        case "High":
            return .orange
        case "Default":
            return .yellow
        case "Low":
            return .blue
        case "Min":
            return .gray
        default:
            return .secondary
        }
    }
}

// Helper extension for hover effect
extension View {
    func hoverEffect() -> some View {
        self.onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NtfyViewModel())
}
