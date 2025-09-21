//
//  ExportManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 21/09/2025.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        }
    }

    var displayName: String {
        return rawValue
    }

    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        }
    }
}

enum ExportScope: String, CaseIterable {
    case all = "All messages"
    case filtered = "Filtered messages"
    case selected = "Selected messages"

    var displayName: String {
        return rawValue
    }
}

class ExportManager {
    static let shared = ExportManager()

    private init() {}

    func exportMessages(
        _ messages: [NtfyMessage],
        format: ExportFormat,
        scope: ExportScope,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Show save panel
        let savePanel = NSSavePanel()
        savePanel.title = "Export \(scope.displayName) as \(format.displayName)"
        savePanel.allowedContentTypes = [.init(filenameExtension: format.fileExtension)!]
        savePanel.nameFieldStringValue = generateFilename(for: format, scope: scope)
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else {
                completion(.failure(ExportError.userCancelled))
                return
            }

            do {
                let exportData = try self.generateExportData(messages: messages, format: format)
                try exportData.write(to: url, atomically: true, encoding: .utf8)
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func generateFilename(for format: ExportFormat, scope: ExportScope) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())

        let scopePrefix = scope == .all ? "all" : scope == .filtered ? "filtered" : "selected"
        return "ntfy_messages_\(scopePrefix)_\(timestamp).\(format.fileExtension)"
    }

    private func generateExportData(messages: [NtfyMessage], format: ExportFormat) throws -> String {
        switch format {
        case .csv:
            return try generateCSV(messages: messages)
        case .json:
            return try generateJSON(messages: messages)
        }
    }

    private func generateCSV(messages: [NtfyMessage]) throws -> String {
        var csvContent = "ID,Timestamp,Date,Topic,Title,Message,Priority,Priority Description,Tags,Event\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        for message in messages.sorted(by: { $0.date > $1.date }) {
            let fields = [
                escapeCSVField(message.id),
                String(message.time),
                escapeCSVField(dateFormatter.string(from: message.date)),
                escapeCSVField(message.topic),
                escapeCSVField(message.title ?? ""),
                escapeCSVField(message.message ?? ""),
                String(message.priority ?? 3),
                escapeCSVField(message.priorityDescription),
                escapeCSVField(message.tags?.joined(separator: "; ") ?? ""),
                escapeCSVField(message.event)
            ]

            csvContent += fields.joined(separator: ",") + "\n"
        }

        return csvContent
    }

    private func generateJSON(messages: [NtfyMessage]) throws -> String {
        let sortedMessages = messages.sorted(by: { $0.date > $1.date })

        let exportData = ExportData(
            exportDate: Date(),
            format: "ntfy-menubar-export",
            version: "1.0",
            messageCount: sortedMessages.count,
            messages: sortedMessages.map { message in
                ExportMessage(
                    id: message.id,
                    timestamp: message.time,
                    date: message.date,
                    topic: message.topic,
                    title: message.title,
                    message: message.message,
                    priority: message.priority,
                    priorityDescription: message.priorityDescription,
                    tags: message.tags,
                    event: message.event
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(exportData)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }

        return jsonString
    }

    private func escapeCSVField(_ field: String) -> String {
        // Escape quotes and wrap in quotes if field contains comma, quote, or newline
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        return field
    }
}

// MARK: - Export Data Models

struct ExportData: Codable {
    let exportDate: Date
    let format: String
    let version: String
    let messageCount: Int
    let messages: [ExportMessage]
}

struct ExportMessage: Codable {
    let id: String
    let timestamp: Int
    let date: Date
    let topic: String
    let title: String?
    let message: String?
    let priority: Int?
    let priorityDescription: String
    let tags: [String]?
    let event: String
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case userCancelled
    case encodingFailed
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Export was cancelled by user"
        case .encodingFailed:
            return "Failed to encode export data"
        case .writeFailed:
            return "Failed to write export file"
        }
    }
}