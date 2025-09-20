//
//  NtfyMenuBarApp.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Initialize status bar controller here where we have proper app lifecycle
        let viewModel = NtfyViewModel()
        statusBarController = StatusBarController(viewModel: viewModel)
    }
}

@main
struct NtfyMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            if let viewModel = appDelegate.statusBarController?.viewModel {
                SettingsView()
                    .environmentObject(viewModel)
            } else {
                SettingsView()
                    .environmentObject(NtfyViewModel())
            }
        }
    }
}
