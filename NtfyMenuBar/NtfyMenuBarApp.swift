//
//  NtfyMenuBarApp.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var themeManager: ThemeManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure app stays out of dock - force accessory policy
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Initialize status bar controller here where we have proper app lifecycle
        let viewModel = NtfyViewModel()
        let themeManager = ThemeManager()
        self.themeManager = themeManager
        statusBarController = StatusBarController(viewModel: viewModel, themeManager: themeManager)
        
        // Additional check - hide from dock completely
        if NSApplication.shared.activationPolicy() != .accessory {
            print("⚠️ Activation policy not accessory, forcing...")
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Set activation policy as early as possible
        NSApplication.shared.setActivationPolicy(.accessory)
        print("🔧 Set activation policy to accessory in willFinishLaunching")
    }
}

@main
struct NtfyMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            if let viewModel = appDelegate.statusBarController?.viewModel,
               let themeManager = appDelegate.themeManager {
                SettingsView()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            } else {
                SettingsView()
                    .environmentObject(NtfyViewModel())
                    .environmentObject(ThemeManager())
            }
        }
    }
}
