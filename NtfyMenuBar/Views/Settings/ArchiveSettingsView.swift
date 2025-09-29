//
//  ArchiveSettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI
import UserNotifications
import AppKit

struct ArchiveSettingsView: View {
    @EnvironmentObject var viewModel: NtfyViewModel

    // Required bindings from parent
    @Binding var archiveStatistics: ArchiveStatistics?
    @Binding var isLoadingArchiveStats: Bool
    @Binding var showingClearArchiveAlert: Bool
    @Binding var archiveClearDays: Int
    @Binding var archivedMessages: [NtfyMessage]
    @Binding var isLoadingArchive: Bool
    @Binding var showingArchiveBrowser: Bool
    @Binding var archiveSearchText: String
    @Binding var selectedArchiveTopic: String

    // Collapsible section states
    @State private var statisticsExpanded = true
    @State private var browseExpanded = false
    @State private var exportExpanded = false
    @State private var managementExpanded = false

    // Export options
    @State private var exportScope: ExportScope = .recent
    @State private var exportFormat: ExportFormat = .json

    enum ExportScope: String, CaseIterable {
        case recent = "Last 7 days"
        case all = "All messages"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Statistics Section
            DisclosureGroup(isExpanded: $statisticsExpanded) {
                statisticsContent
                    .padding(.top, 8)
            } label: {
                Label("Archive statistics", systemImage: "chart.bar.fill")
                    .font(.headline)
            }

            Divider()

            // Browse Section
            DisclosureGroup(isExpanded: $browseExpanded) {
                browseContent
                    .padding(.top, 8)
            } label: {
                Label("Browse messages", systemImage: "magnifyingglass")
                    .font(.headline)
            }

            Divider()

            // Export Section
            DisclosureGroup(isExpanded: $exportExpanded) {
                exportContent
                    .padding(.top, 8)
            } label: {
                Label("Export messages", systemImage: "square.and.arrow.up")
                    .font(.headline)
            }

            Divider()

            // Management Section
            DisclosureGroup(isExpanded: $managementExpanded) {
                managementContent
                    .padding(.top, 8)
            } label: {
                Label("Archive management", systemImage: "trash")
                    .font(.headline)
            }
        }
        .onAppear {
            if archiveStatistics == nil {
                loadArchiveStatistics()
            }
        }
        .alert("Clear archive messages", isPresented: $showingClearArchiveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearOldArchivedMessages()
            }
        } message: {
            Text("Are you sure you want to delete all archived messages older than \(archiveClearDays) days? This action cannot be undone.")
        }
    }

    // MARK: - Statistics Content

    private var statisticsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoadingArchiveStats {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading statistics...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let stats = archiveStatistics {
                // Compact 2x2 grid for main stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    statItem(label: "Messages", value: "\(stats.totalMessages)")
                    statItem(label: "Size", value: stats.formattedSize)
                    statItem(label: "Date Range", value: stats.dateRange)
                    statItem(label: "Files", value: "\(stats.archiveFilesCount)")
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)

                // Compact top topics display
                if !stats.messagesByTopic.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top topics:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        let topTopics = stats.messagesByTopic.sorted { $0.value > $1.value }.prefix(4)
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 4) {
                            ForEach(Array(topTopics), id: \.key) { topic, count in
                                HStack {
                                    Text("\(topic)")
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(4)
                            }
                        }

                        if stats.messagesByTopic.count > 4 {
                            Text("+\(stats.messagesByTopic.count - 4) more topics")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No statistics available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Refresh") {
                loadArchiveStatistics()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isLoadingArchiveStats)
        }
    }

    private func statItem(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    // MARK: - Browse Content

    private var browseContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Search and filter controls - split into multiple rows if needed
            VStack(spacing: 8) {
                // First row: Search and Topic picker
                HStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        TextField("Search...", text: $archiveSearchText)
                            .textFieldStyle(.plain)
                            .font(.caption)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                    .frame(minWidth: 120)

                    Picker("", selection: $selectedArchiveTopic) {
                        Text("All topics").tag("All")
                        ForEach(archiveTopics, id: \.self) { topic in
                            Text(topic).tag(topic)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 100)
                    .controlSize(.small)

                    Spacer()

                    if !archivedMessages.isEmpty {
                        Text("\(filteredArchivedMessages.count) messages")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Second row: Load buttons (only when no messages loaded)
                if archivedMessages.isEmpty {
                    HStack(spacing: 8) {
                        Button("Load recent (7 days)") {
                            loadRecentArchivedMessages()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("Load all messages") {
                            loadArchivedMessages()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Spacer()
                    }
                }
            }

            // Message list (only if loaded)
            if isLoadingArchive {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading messages...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else if !archivedMessages.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredArchivedMessages.prefix(50), id: \.uniqueId) { message in
                            ArchiveMessageRowView(message: message)
                        }

                        if filteredArchivedMessages.count > 50 {
                            Text("Showing first 50 of \(filteredArchivedMessages.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .frame(height: 180)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(6)
            }
        }
    }

    // MARK: - Export Content

    private var exportContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Export controls split into two rows for better layout
            VStack(spacing: 8) {
                // First row: Selection controls
                HStack(spacing: 8) {
                    Text("Export:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Scope", selection: $exportScope) {
                        ForEach(ExportScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 100)
                    .controlSize(.small)

                    Text("as")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 70)
                    .controlSize(.small)

                    Spacer()
                }

                // Second row: Action buttons
                HStack(spacing: 8) {
                    Button("Export now") {
                        performExport()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Show exports folder") {
                        revealExportsFolder()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()
                }
            }
        }
    }

    // MARK: - Management Content

    private var managementContent: some View {
        HStack {
            Text("Clear messages older than:")
                .font(.caption)

            Picker("", selection: $archiveClearDays) {
                Text("7 days").tag(7)
                Text("30 days").tag(30)
                Text("90 days").tag(90)
                Text("1 year").tag(365)
            }
            .pickerStyle(.menu)
            .frame(width: 90)
            .controlSize(.small)

            Button("Clear") {
                showingClearArchiveAlert = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.red)

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private var archiveTopics: [String] {
        let allTopics = Set(archivedMessages.map { $0.topic })
        return Array(allTopics).sorted()
    }

    private var filteredArchivedMessages: [NtfyMessage] {
        var messages = archivedMessages

        // Apply search filter
        if !archiveSearchText.isEmpty {
            let searchLower = archiveSearchText.lowercased()
            messages = messages.filter { message in
                (message.message?.lowercased().contains(searchLower) ?? false) ||
                (message.title?.lowercased().contains(searchLower) ?? false) ||
                message.topic.lowercased().contains(searchLower) ||
                (message.tags?.joined(separator: " ").lowercased().contains(searchLower) ?? false)
            }
        }

        // Apply topic filter
        if selectedArchiveTopic != "All" {
            messages = messages.filter { $0.topic == selectedArchiveTopic }
        }

        return messages
    }

    private func performExport() {
        switch exportScope {
        case .recent:
            exportRecentMessages(format: exportFormat)
        case .all:
            exportAllArchivedMessages(format: exportFormat)
        }
    }

    private func loadArchiveStatistics() {
        isLoadingArchiveStats = true
        Task {
            let stats = await viewModel.getArchiveStatistics()
            await MainActor.run {
                self.archiveStatistics = stats
                self.isLoadingArchiveStats = false
            }
        }
    }

    private func loadArchivedMessages() {
        isLoadingArchive = true
        Task {
            let messages = await viewModel.loadAllArchivedMessages()
            await MainActor.run {
                self.archivedMessages = messages
                self.isLoadingArchive = false
            }
        }
    }

    private func loadRecentArchivedMessages() {
        isLoadingArchive = true
        Task {
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            let recentMessages = await MessageArchive.shared.getArchivedMessages(since: weekAgo)
            await MainActor.run {
                self.archivedMessages = recentMessages
                self.isLoadingArchive = false
            }
        }
    }

    private func clearOldArchivedMessages() {
        viewModel.clearOldArchivedMessages(olderThan: archiveClearDays)
        // Refresh statistics after clearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadArchiveStatistics()
        }
    }

    private func exportRecentMessages(format: ExportFormat) {
        Task {
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            let recentMessages = await MessageArchive.shared.getArchivedMessages(since: weekAgo)

            await MainActor.run {
                ExportManager.shared.exportMessages(
                    recentMessages,
                    format: format,
                    scope: .all
                ) { result in
                    DispatchQueue.main.async {
                        handleExportResult(result, messageCount: recentMessages.count, format: format)
                    }
                }
            }
        }
    }

    private func exportAllArchivedMessages(format: ExportFormat) {
        Task {
            let allMessages = await viewModel.loadAllArchivedMessages()

            await MainActor.run {
                ExportManager.shared.exportMessages(
                    allMessages,
                    format: format,
                    scope: .all
                ) { result in
                    DispatchQueue.main.async {
                        handleExportResult(result, messageCount: allMessages.count, format: format)
                    }
                }
            }
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>, messageCount: Int, format: ExportFormat) {
        switch result {
        case .success(let url):
            // Show success notification
            let content = UNMutableNotificationContent()
            content.title = "Export complete"
            content.body = "Exported \(messageCount) messages as \(format.displayName)"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "export_success",
                content: content,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request)

            // Reveal in Finder
            NSWorkspace.shared.activateFileViewerSelecting([url])

        case .failure(let error):
            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Export failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func revealExportsFolder() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let exportDirectory = appSupportURL.appendingPathComponent("NtfyMenuBar/Exports")

        // Create exports directory if it doesn't exist
        try? fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        // Reveal in Finder
        NSWorkspace.shared.activateFileViewerSelecting([exportDirectory])
    }
}