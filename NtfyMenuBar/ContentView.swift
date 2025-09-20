//
//  ContentView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @Environment(\.dismiss) private var dismiss
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
        .frame(width: 320, height: 300)
        .background(Color(NSColor.controlBackgroundColor))
        .onExitCommand {
            // Close on Escape key
            if let window = NSApplication.shared.keyWindow {
                window.close()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if viewModel.isConnected && !viewModel.settings.topic.isEmpty {
                    Text(viewModel.settings.topic)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else if !viewModel.isConnected && viewModel.settings.isConfigured {
                    Text("Not connected")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            connectionStatusView
        }
    }
    
    private var headerTitle: String {
        if !viewModel.isConnected {
            return "ntfy Notifications"
        }
        return serverDisplayName
    }
    
    private var serverDisplayName: String {
        var serverURL = viewModel.settings.serverURL
        
        // Remove protocol prefix for cleaner display
        if serverURL.hasPrefix("https://") {
            serverURL = String(serverURL.dropFirst(8))
        } else if serverURL.hasPrefix("http://") {
            serverURL = String(serverURL.dropFirst(7))
        }
        
        // Remove trailing slashes
        while serverURL.hasSuffix("/") {
            serverURL = String(serverURL.dropLast())
        }
        
        // Return cleaned URL or default
        return serverURL.isEmpty ? "Not Configured" : serverURL
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
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
        if viewModel.isConnected {
            return "Connected"
        } else if !viewModel.settings.isConfigured {
            return "Not Configured"
        } else if viewModel.connectionError != nil {
            return "Error"
        } else {
            return "Disconnected"
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
