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
            VStack(alignment: .leading, spacing: 2) {
                Text(serverDisplayName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if !viewModel.settings.topic.isEmpty {
                    Text(viewModel.settings.topic)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer()
            
            connectionStatusView
        }
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
