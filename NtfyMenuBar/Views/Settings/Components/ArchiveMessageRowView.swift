//
//  ArchiveMessageRowView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct ArchiveMessageRowView: View {
    let message: NtfyMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority and timestamp column
            VStack(alignment: .leading, spacing: 2) {
                Text(priorityEmoji)
                    .font(.caption)

                Text(message.date, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 60, alignment: .leading)

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.topic)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)

                    if let title = message.title, !title.isEmpty {
                        Text(title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(message.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let messageText = message.message, !messageText.isEmpty {
                    Text(messageText)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                if let tags = message.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(3)
                        }
                        if tags.count > 3 {
                            Text("+\(tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.clear)
        .cornerRadius(6)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.2))
                .offset(y: 20),
            alignment: .bottom
        )
    }

    private var priorityEmoji: String {
        switch message.priority ?? 3 {
        case 5: return "🔴"
        case 4: return "🟠"
        case 3: return "🟡"
        case 2: return "🔵"
        case 1: return "⚪"
        default: return "🟡"
        }
    }
}