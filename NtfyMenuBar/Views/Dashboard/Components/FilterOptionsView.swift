//
//  FilterOptionsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct FilterOptionsView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @Binding var searchText: String
    @Binding var selectedPriorities: Set<Int>
    @Binding var selectedTopics: Set<String>

    @State private var groupingMode: GroupingMode = .none
    @State private var collapsedSections: Set<String> = []

    private let filteringService = MessageFilteringService()

    var body: some View {
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

    private var availableTopics: [String] {
        return filteringService.getAvailableTopics(from: viewModel.messages)
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
    }
}