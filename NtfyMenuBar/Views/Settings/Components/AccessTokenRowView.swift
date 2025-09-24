//
//  AccessTokenRowView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct AccessTokenRowView: View {
    let token: AccessToken
    let onCopy: (String) -> Void
    let onRevoke: (AccessToken) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(token.displayLabel)
                        .font(.body)
                        .fontWeight(.medium)

                    if token.isExpired {
                        Text("EXPIRED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }

                Text(token.maskedToken)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    if let lastAccessDate = token.lastAccessDate {
                        Text("Last used: \(lastAccessDate, formatter: dateFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never used")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let expirationDate = token.expirationDate {
                        Text("Expires: \(expirationDate, formatter: dateFormatter)")
                            .font(.caption2)
                            .foregroundColor(token.isExpired ? .red : .secondary)
                    } else {
                        Text("Never expires")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Button("Copy") {
                    onCopy(token.token)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(token.isExpired)

                Button("Revoke") {
                    onRevoke(token)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(token.isExpired ? Color.red.opacity(0.05) : Color.secondary.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(token.isExpired ? Color.red.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}