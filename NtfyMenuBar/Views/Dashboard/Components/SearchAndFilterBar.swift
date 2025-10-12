//
//  SearchAndFilterBar.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct SearchAndFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedPriorities: Set<Int>
    @Binding var selectedTopics: Set<String>
    @Binding var showFilterOptions: Bool
    @FocusState.Binding var isSearchFocused: Bool

    private let filteringService = MessageFilteringService()

    var body: some View {
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
                    .accessibilityLabel("Search messages")
                    .accessibilityHint("Type to filter messages by title or content")

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
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
                            .accessibilityHidden(true)
                    }
                }
                .foregroundColor(hasActiveFilters ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(hasActiveFilters ? "Filters (active)" : "Filters")
            .accessibilityHint("Opens filter options for priorities and topics")
            .popover(isPresented: $showFilterOptions) {
                FilterOptionsView(
                    searchText: $searchText,
                    selectedPriorities: $selectedPriorities,
                    selectedTopics: $selectedTopics
                )
            }
        }
    }

    private var hasActiveFilters: Bool {
        return filteringService.hasActiveFilters(
            searchText: searchText,
            selectedPriorities: selectedPriorities,
            selectedTopics: selectedTopics
        )
    }
}