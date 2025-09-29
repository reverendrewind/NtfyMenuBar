//
//  SnoozeControlView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct SnoozeControlView: View {
    @EnvironmentObject var viewModel: NtfyViewModel

    var body: some View {
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
}