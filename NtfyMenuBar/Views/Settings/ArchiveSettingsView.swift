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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Message Archive")
                    .font(.headline)

                Text("Messages are automatically archived for persistent storage and can be exported at any time.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Archive statistics
                if isLoadingArchiveStats {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading archive statistics...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let stats = archiveStatistics {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Archive Statistics")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Total Messages:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(stats.totalMessages)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }

                                HStack {
                                    Text("Archive Size:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(stats.formattedSize)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Date Range:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(stats.dateRange)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                HStack {
                                    Text("Archive Files:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(stats.archiveFilesCount)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)

                        // Top topics
                        if !stats.messagesByTopic.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Top Topics:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                let sortedTopics = stats.messagesByTopic.sorted { $0.value > $1.value }.prefix(8)
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 6) {
                                    ForEach(Array(sortedTopics), id: \.key) { topic, count in
                                        HStack {
                                            Text("• \(topic)")
                                                .font(.caption2)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Spacer()
                                            Text("\(count)")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }

                Button("Refresh Statistics") {
                    loadArchiveStatistics()
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingArchiveStats)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Browse Archived Messages")
                    .font(.headline)

                Text("View and search through your archived message history.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button(showingArchiveBrowser ? "Hide Archive Browser" : "Show Archive Browser") {
                        showingArchiveBrowser.toggle()
                        if showingArchiveBrowser && archivedMessages.isEmpty {
                            loadArchivedMessages()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if showingArchiveBrowser {
                        Button("Load Recent (7 days)") {
                            loadRecentArchivedMessages()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)

                        Button("Load All") {
                            loadArchivedMessages()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }

                    if showingArchiveBrowser && !archivedMessages.isEmpty {
                        Spacer()
                        Text("\(filteredArchivedMessages.count) of \(archivedMessages.count) messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if showingArchiveBrowser {
                    if isLoadingArchive {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading archived messages...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    } else if !archivedMessages.isEmpty {
                        VStack(spacing: 12) {
                            // Search and filter controls
                            HStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    TextField("Search messages...", text: $archiveSearchText)
                                        .textFieldStyle(.plain)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)

                                Picker("Topic", selection: $selectedArchiveTopic) {
                                    Text("All Topics").tag("All")
                                    ForEach(archiveTopics, id: \.self) { topic in
                                        Text(topic).tag(topic)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }

                            // Message list
                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(filteredArchivedMessages.prefix(100), id: \.uniqueId) { message in
                                        ArchiveMessageRowView(message: message)
                                    }

                                    if filteredArchivedMessages.count > 100 {
                                        Text("Showing first 100 messages. Use search to narrow results.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                            .frame(height: 300)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "archivebox")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No archived messages found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Export Messages")
                    .font(.headline)

                Text("Export your messages to CSV or JSON format for analysis or backup. Files are saved to the application's export folder.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Export location info
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    Text("Export location:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Show in Finder") {
                        revealExportsFolder()
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent messages (last 7 days)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 12) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button("Export as \(format.displayName)") {
                                exportRecentMessages(format: format)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("All archived messages")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 12) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button("Export all as \(format.displayName)") {
                                exportAllArchivedMessages(format: format)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Archive Management")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Clear old messages")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Remove archived messages older than the specified number of days.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Delete messages older than:")
                            .font(.caption)
                        Spacer()
                        Picker("Days", selection: $archiveClearDays) {
                            Text("7 days").tag(7)
                            Text("30 days").tag(30)
                            Text("90 days").tag(90)
                            Text("1 year").tag(365)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }

                    Button("Clear Old Messages") {
                        showingClearArchiveAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            if archiveStatistics == nil {
                loadArchiveStatistics()
            }
        }
        .alert("Clear Archive Messages", isPresented: $showingClearArchiveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearOldArchivedMessages()
            }
        } message: {
            Text("Are you sure you want to delete all archived messages older than \(archiveClearDays) days? This action cannot be undone.")
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
            print("✅ Successfully exported \(messageCount) messages to \(url.path)")

            // Show success notification
            let content = UNMutableNotificationContent()
            content.title = "Export Complete"
            content.body = "Exported \(messageCount) messages as \(format.displayName)"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "export_success",
                content: content,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to show export notification: \(error)")
                }
            }

            // Reveal in Finder
            NSWorkspace.shared.activateFileViewerSelecting([url])

        case .failure(let error):
            print("❌ Failed to export messages: \(error.localizedDescription)")

            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Export Failed"
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