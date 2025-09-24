//
//  MessageFilteringService.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import Foundation

enum GroupingMode: String, CaseIterable {
    case none = "None"
    case byTopic = "By topic"
    case byPriority = "By priority"

    var displayName: String {
        return rawValue
    }

    var systemImage: String {
        switch self {
        case .none: return "list.bullet"
        case .byTopic: return "folder"
        case .byPriority: return "flag"
        }
    }
}

struct MessageGroup {
    let key: String
    let value: [NtfyMessage]
}

class MessageFilteringService {

    // MARK: - Filtering Methods

    func filterMessages(_ messages: [NtfyMessage],
                       searchText: String,
                       selectedPriorities: Set<Int>,
                       selectedTopics: Set<String>) -> [NtfyMessage] {
        var filteredMessages = messages

        // Apply search filter
        if !searchText.isEmpty {
            filteredMessages = filteredMessages.filter { message in
                let searchLower = searchText.lowercased()
                return (message.message?.lowercased().contains(searchLower) ?? false) ||
                       (message.title?.lowercased().contains(searchLower) ?? false) ||
                       message.topic.lowercased().contains(searchLower) ||
                       (message.tags?.joined(separator: " ").lowercased().contains(searchLower) ?? false)
            }
        }

        // Apply priority filter (multi-selection)
        if !selectedPriorities.isEmpty {
            filteredMessages = filteredMessages.filter { message in
                selectedPriorities.contains(message.priority ?? 3)
            }
        }

        // Apply topic filter (multi-selection)
        if !selectedTopics.isEmpty {
            filteredMessages = filteredMessages.filter { message in
                selectedTopics.contains(message.topic)
            }
        }

        return filteredMessages
    }

    // MARK: - Grouping Methods

    func groupMessages(_ messages: [NtfyMessage], by groupingMode: GroupingMode) -> [MessageGroup] {
        switch groupingMode {
        case .none:
            return []
        case .byTopic:
            return groupMessagesByTopic(messages)
        case .byPriority:
            return groupMessagesByPriority(messages)
        }
    }

    private func groupMessagesByTopic(_ messages: [NtfyMessage]) -> [MessageGroup] {
        let grouped = Dictionary(grouping: messages) { $0.topic }
        return grouped.sorted { $0.key < $1.key }
            .map { MessageGroup(key: $0.key, value: $0.value.sorted { $0.date > $1.date }) }
    }

    private func groupMessagesByPriority(_ messages: [NtfyMessage]) -> [MessageGroup] {
        let grouped = Dictionary(grouping: messages) { message in
            message.priorityDescription
        }

        // Sort priority groups in descending order (Max to Min)
        let priorityOrder = ["Max", "High", "Default", "Low", "Min"]
        return grouped.sorted { first, second in
            let firstIndex = priorityOrder.firstIndex(of: first.key) ?? 999
            let secondIndex = priorityOrder.firstIndex(of: second.key) ?? 999
            return firstIndex < secondIndex
        }
        .map { MessageGroup(key: $0.key, value: $0.value.sorted { $0.date > $1.date }) }
    }

    // MARK: - Utility Methods

    func getAvailableTopics(from messages: [NtfyMessage]) -> [String] {
        let allTopics = Set(messages.map { $0.topic })
        return Array(allTopics).sorted()
    }

    func hasActiveFilters(searchText: String, selectedPriorities: Set<Int>, selectedTopics: Set<String>) -> Bool {
        return !searchText.isEmpty ||
               !selectedPriorities.isEmpty ||
               !selectedTopics.isEmpty
    }

    func priorityDisplayName(for priority: Int) -> String {
        switch priority {
        case 1: return "Min (1)"
        case 2: return "Low (2)"
        case 3: return "Normal (3)"
        case 4: return "High (4)"
        case 5: return "Max (5)"
        default: return "Normal (3)"
        }
    }

    func getMessageCount(for priority: Int, in messages: [NtfyMessage]) -> Int {
        return messages.filter { ($0.priority ?? 3) == priority }.count
    }

    func getMessageCount(for topic: String, in messages: [NtfyMessage]) -> Int {
        return messages.filter { $0.topic == topic }.count
    }
}