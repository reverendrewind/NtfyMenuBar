//
//  StatusBarController.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 20/09/2025.
//

import AppKit
import SwiftUI
import Combine

class StatusBarController: NSObject, ObservableObject, WindowManagerDelegate {
    private var statusItem: NSStatusItem?
    let viewModel: NtfyViewModel
    let themeManager: ThemeManager
    private var cancellables = Set<AnyCancellable>()

    // Services
    private var menuBuilder: MenuBuilder!
    private var windowManager: WindowManager!
    
    init(viewModel: NtfyViewModel, themeManager: ThemeManager) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        super.init()

        // Initialize services
        self.windowManager = WindowManager(viewModel: viewModel, themeManager: themeManager, delegate: self)
        self.menuBuilder = MenuBuilder(viewModel: viewModel, statusBarController: self)

        setupStatusItem()
        setupNotificationObservers()
        setupSnoozeObservers()

        // Set up settings action closure
        viewModel.openSettingsAction = { [weak self] in
            self?.openSettings()
        }

        // Initialize theme from settings
        themeManager.setTheme(viewModel.settings.appearanceMode)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Set the icon
            if let image = NSImage(named: StringConstants.Assets.menuBarIcon) {
                image.isTemplate = true // Enable template rendering for dark/light mode
                button.image = image
            }
            
            // Set up actions
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenDashboardFromNotification),
            name: .openDashboardFromNotification,
            object: nil
        )
    }

    private func setupSnoozeObservers() {
        // Observe snooze state changes
        viewModel.$isSnoozed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
            .store(in: &cancellables)
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }

        // Set the appropriate icon based on snooze state
        if viewModel.isSnoozed {
            // Use custom snooze icon (grayed-out ntfy bell with slash/ZZZ)
            if let image = NSImage(named: StringConstants.Assets.menuBarIconSnooze) {
                image.isTemplate = true
                button.image = image
                button.toolTip = "Notifications snoozed - \(viewModel.snoozeStatusText)"
            }
        } else {
            // Use normal ntfy bell icon
            if let image = NSImage(named: StringConstants.Assets.menuBarIcon) {
                image.isTemplate = true
                button.image = image
                button.toolTip = "ntfy Notifications"
            }
        }
    }
    
    @objc private func handleOpenDashboardFromNotification() {
        // Open dashboard when triggered from notification action
        openDashboard()
    }
    
    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click - show menu
            showMenu()
        } else {
            // Left click - open dashboard
            openDashboard()
        }
    }
    
    private func openDashboard() {
        guard let button = statusItem?.button else { return }
        windowManager.toggleDashboard(nearStatusButton: button)
    }
    
    
    private func showMenu() {
        let menu = menuBuilder.buildContextMenu()
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc func openDashboardFromMenu() {
        openDashboard()
    }
    
    @objc func openSettings() {
        windowManager.openSettings()
    }
    
    @objc func toggleConnection() {
        if viewModel.isConnected {
            viewModel.disconnect()
        } else {
            viewModel.connect()
        }
    }
    
    @objc func clearMessages() {
        viewModel.clearMessages()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc func snoozeNotifications(_ sender: NSMenuItem) {
        guard let duration = sender.representedObject as? SnoozeDuration else { return }
        viewModel.snoozeNotifications(duration: duration)
    }

    @objc func clearSnooze() {
        viewModel.clearSnooze()
    }
    
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}