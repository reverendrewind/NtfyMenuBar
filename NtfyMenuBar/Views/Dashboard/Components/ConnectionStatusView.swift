//
//  ConnectionStatusView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct ConnectionStatusView: View {
    @EnvironmentObject var viewModel: NtfyViewModel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.isConnected {
                    Text(viewModel.service.connectionQuality.description)
                        .font(.caption2)
                        .foregroundColor(connectionQualityColor)
                }
            }
        }
    }

    private var statusColor: Color {
        if viewModel.isConnected {
            return .green
        } else if !viewModel.settings.isConfigured {
            return .orange
        } else {
            return .red
        }
    }

    private var statusText: String {
        let isConfigured = viewModel.settings.isConfigured
        Logger.shared.debug("📊 ConnectionStatusView: isConnected=\(viewModel.isConnected), isConfigured=\(isConfigured)")

        if viewModel.isConnected {
            return "Connected"
        } else if !isConfigured {
            Logger.shared.debug("📊 ConnectionStatusView: Returning 'Not configured' because isConfigured=\(isConfigured)")
            return "Not configured"
        } else if viewModel.connectionError != nil {
            return "Error"
        } else {
            return "Disconnected"
        }
    }

    private var connectionQualityColor: Color {
        switch viewModel.service.connectionQuality {
        case .unknown: return .gray
        case .excellent: return .green
        case .good: return .blue
        case .poor: return .orange
        case .failing: return .red
        }
    }
}