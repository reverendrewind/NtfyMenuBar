//
//  NtfyMenuBarApp.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI

@main
struct NtfyMenuBarApp: App {
    @StateObject private var viewModel = NtfyViewModel()
    @State private var showingMainWindow = false
    
    var body: some Scene {
        MenuBarExtra("ntfy", systemImage: "bell") {
            Button("Open Dashboard") {
                openDashboard()
            }
            
            Divider()
            
            Button("Settings...") {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
            
            Divider()
            
            if viewModel.isConnected {
                Button("Disconnect") {
                    viewModel.disconnect()
                }
            } else {
                Button("Connect") {
                    viewModel.connect()
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        
        WindowGroup("ntfy Dashboard") {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    showingMainWindow = true
                }
                .onDisappear {
                    showingMainWindow = false
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .keyboardShortcut("d", modifiers: [.command])
        
        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
    
    private func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Try to bring existing window to front, or create new one
        if let window = NSApp.windows.first(where: { $0.title == "ntfy Dashboard" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Create new window if none exists
            let contentView = ContentView().environmentObject(viewModel)
            let hostingController = NSHostingController(rootView: contentView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "ntfy Dashboard"
            window.contentViewController = hostingController
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
}
