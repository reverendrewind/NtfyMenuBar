//
//  ContentView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @State private var showingSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            Divider()
            
            if viewModel.messages.isEmpty {
                emptyStateView
            } else {
                messagesView
            }
            
            Divider()
            
            footerView
        }
        .padding()
        .frame(width: 280)
        .fixedSize()
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("ntfy Notifications")
                .font(.headline)
            
            Spacer()
            
            connectionStatusView
        }
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.isConnected ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(viewModel.isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.slash")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No notifications yet")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(viewModel.messages) { message in
                    MessageRowView(message: message)
                }
            }
        }
        .frame(maxHeight: 200)
    }
    
    private var footerView: some View {
        HStack {
            Button("Settings") {
                print("📱 Settings button pressed")
                showingSettings = true
            }
            
            Spacer()
            
            if !viewModel.messages.isEmpty {
                Button("Clear") {
                    viewModel.clearMessages()
                }
            }
            
            Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                print("🔗 Connect button pressed, connected: \(viewModel.isConnected)")
                if viewModel.isConnected {
                    viewModel.disconnect()
                } else {
                    viewModel.connect()
                }
            }
        }
        .buttonStyle(.borderless)
        .font(.caption)
    }
}

#Preview {
    ContentView()
        .environmentObject(NtfyViewModel())
}
