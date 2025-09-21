//
//  MessageArchive.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 21/09/2025.
//

import Foundation

class MessageArchive {
    static let shared = MessageArchive()

    private let fileManager = FileManager.default
    private let archiveDirectory: URL
    private let currentArchiveFile: URL
    private let maxMessagesPerFile = 1000
    private let maxArchiveFiles = 10

    // Cache for recent messages to avoid frequent file I/O
    private var cachedMessages: [NtfyMessage] = []
    private var cacheLastUpdated: Date = Date.distantPast
    private let cacheValidityInterval: TimeInterval = 300 // 5 minutes

    private init() {
        // Create archive directory in Application Support
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        archiveDirectory = appSupportURL.appendingPathComponent("NtfyMenuBar/MessageArchive")
        currentArchiveFile = archiveDirectory.appendingPathComponent("current.json")

        createArchiveDirectoryIfNeeded()
    }

    private func createArchiveDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
            print("📂 Archive directory created/verified at: \(archiveDirectory.path)")
        } catch {
            print("❌ Failed to create archive directory: \(error)")
            print("❌ Archive directory path: \(archiveDirectory.path)")
        }
    }

    // MARK: - Public Interface

    func archiveMessage(_ message: NtfyMessage) {
        Task {
            await saveMessageToArchive(message)
        }
    }

    func archiveMessages(_ messages: [NtfyMessage]) {
        Task {
            for message in messages {
                await saveMessageToArchive(message)
            }
        }
    }

    func getAllArchivedMessages() async -> [NtfyMessage] {
        // Check cache first
        if Date().timeIntervalSince(cacheLastUpdated) < cacheValidityInterval {
            print("📂 Using cached messages: \(cachedMessages.count) messages")
            return cachedMessages
        }

        print("📂 Loading all archived messages from files...")
        var allMessages: [NtfyMessage] = []

        // Load from current file
        let currentMessages = await loadMessagesFromFile(currentArchiveFile)
        print("📂 Loaded \(currentMessages.count) messages from current archive file")
        allMessages.append(contentsOf: currentMessages)

        // Load from rotated archive files
        let archiveFiles = getArchiveFiles()
        print("📂 Found \(archiveFiles.count) rotated archive files")
        for file in archiveFiles {
            let fileMessages = await loadMessagesFromFile(file)
            print("📂 Loaded \(fileMessages.count) messages from \(file.lastPathComponent)")
            allMessages.append(contentsOf: fileMessages)
        }

        // Sort by date (newest first) and remove duplicates
        let uniqueMessages = Dictionary(grouping: allMessages) { $0.id }
            .compactMapValues { $0.first }
            .values
            .sorted { $0.date > $1.date }

        // Update cache
        cachedMessages = Array(uniqueMessages)
        cacheLastUpdated = Date()

        print("📂 Total unique archived messages: \(cachedMessages.count)")
        return cachedMessages
    }

    func getArchivedMessages(since date: Date) async -> [NtfyMessage] {
        let allMessages = await getAllArchivedMessages()
        return allMessages.filter { $0.date >= date }
    }

    func getArchivedMessages(for topic: String) async -> [NtfyMessage] {
        let allMessages = await getAllArchivedMessages()
        return allMessages.filter { $0.topic == topic }
    }

    func getArchivedMessagesCount() async -> Int {
        return await getAllArchivedMessages().count
    }

    func clearOldMessages(olderThan date: Date) async {
        let allMessages = await getAllArchivedMessages()
        let recentMessages = allMessages.filter { $0.date >= date }

        // Clear all archive files and save only recent messages
        await clearAllArchiveFiles()

        for message in recentMessages {
            await saveMessageToArchive(message)
        }

        // Invalidate cache
        cacheLastUpdated = Date.distantPast
    }

    func getArchiveStatistics() async -> ArchiveStatistics {
        let messages = await getAllArchivedMessages()
        print("📊 Archive statistics: found \(messages.count) total messages")

        let totalCount = messages.count
        let topicCounts = Dictionary(grouping: messages) { $0.topic }
            .mapValues { $0.count }
        let priorityCounts = Dictionary(grouping: messages) { $0.priority ?? 3 }
            .mapValues { $0.count }

        let oldestMessage = messages.last?.date
        let newestMessage = messages.first?.date

        let archiveFiles = getArchiveFiles()
        let totalSize: Int = archiveFiles.reduce(0) { (total: Int, file: URL) -> Int in
            let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + fileSize
        }

        return ArchiveStatistics(
            totalMessages: totalCount,
            messagesByTopic: topicCounts,
            messagesByPriority: priorityCounts,
            oldestMessageDate: oldestMessage,
            newestMessageDate: newestMessage,
            archiveFilesCount: archiveFiles.count + 1, // +1 for current file
            totalSizeBytes: totalSize
        )
    }

    // MARK: - Private Implementation

    private func saveMessageToArchive(_ message: NtfyMessage) async {
        print("📥 Attempting to archive message: \(message.id) - \(message.displayTitle)")

        // Check if message already exists to avoid duplicates
        let existingMessages = await loadMessagesFromFile(currentArchiveFile)
        if existingMessages.contains(where: { $0.id == message.id }) {
            print("📥 Message \(message.id) already archived, skipping")
            return
        }

        var messages = existingMessages
        messages.insert(message, at: 0) // Insert at beginning (newest first)

        print("📥 Archiving message \(message.id), total messages in current file: \(messages.count)")

        // Check if we need to rotate the archive
        if messages.count > maxMessagesPerFile {
            print("📥 Rotating archive file (>= \(maxMessagesPerFile) messages)")
            await rotateArchive(messages: messages)
        } else {
            await saveMessagesToFile(messages, to: currentArchiveFile)
        }

        // Invalidate cache
        cacheLastUpdated = Date.distantPast
        print("📥 Successfully archived message \(message.id)")
    }

    private func rotateArchive(messages: [NtfyMessage]) async {
        let timestamp = DateFormatter.archiveTimestamp.string(from: Date())
        let rotatedFile = archiveDirectory.appendingPathComponent("archive_\(timestamp).json")

        // Save older messages to rotated file
        let olderMessages = Array(messages.dropFirst(maxMessagesPerFile / 2))
        await saveMessagesToFile(olderMessages, to: rotatedFile)

        // Keep recent messages in current file
        let recentMessages = Array(messages.prefix(maxMessagesPerFile / 2))
        await saveMessagesToFile(recentMessages, to: currentArchiveFile)

        // Clean up old archive files if we have too many
        await cleanupOldArchiveFiles()
    }

    private func cleanupOldArchiveFiles() async {
        let archiveFiles = getArchiveFiles()
        if archiveFiles.count > maxArchiveFiles {
            let filesToDelete = archiveFiles.suffix(archiveFiles.count - maxArchiveFiles)
            for file in filesToDelete {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    private func loadMessagesFromFile(_ url: URL) async -> [NtfyMessage] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let archivedData = try decoder.decode(ArchivedMessageContainer.self, from: data)
            return archivedData.messages
        } catch {
            print("❌ Failed to load messages from \(url.lastPathComponent): \(error)")
            return []
        }
    }

    private func saveMessagesToFile(_ messages: [NtfyMessage], to url: URL) async {
        do {
            let container = ArchivedMessageContainer(
                version: "1.0",
                createdAt: Date(),
                messageCount: messages.count,
                messages: messages
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted]

            let data = try encoder.encode(container)
            try data.write(to: url)
            print("💾 Successfully saved \(messages.count) messages to \(url.lastPathComponent)")
        } catch {
            print("❌ Failed to save messages to \(url.lastPathComponent): \(error)")
        }
    }

    private func getArchiveFiles() -> [URL] {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: archiveDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            return contents
                .filter { $0.lastPathComponent.hasPrefix("archive_") && $0.pathExtension == "json" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2 // Newest first
                }
        } catch {
            print("❌ Failed to get archive files: \(error)")
            return []
        }
    }

    private func clearAllArchiveFiles() async {
        do {
            let contents = try fileManager.contentsOfDirectory(at: archiveDirectory, includingPropertiesForKeys: nil)
            for file in contents {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("❌ Failed to clear archive files: \(error)")
        }
    }
}

// MARK: - Data Models

struct ArchivedMessageContainer: Codable {
    let version: String
    let createdAt: Date
    let messageCount: Int
    let messages: [NtfyMessage]
}

struct ArchiveStatistics {
    let totalMessages: Int
    let messagesByTopic: [String: Int]
    let messagesByPriority: [Int: Int]
    let oldestMessageDate: Date?
    let newestMessageDate: Date?
    let archiveFilesCount: Int
    let totalSizeBytes: Int

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalSizeBytes), countStyle: .file)
    }

    var dateRange: String {
        guard let oldest = oldestMessageDate, let newest = newestMessageDate else {
            return "No messages"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return "\(formatter.string(from: oldest)) - \(formatter.string(from: newest))"
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let archiveTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}