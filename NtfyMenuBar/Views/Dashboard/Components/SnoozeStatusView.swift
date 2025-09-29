//
//  SnoozeStatusView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct SnoozeStatusView: View {
    @EnvironmentObject var viewModel: NtfyViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 10))
                .foregroundColor(.orange)

            Text(viewModel.snoozeStatusText)
                .font(.caption2)
                .foregroundColor(.orange)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
}