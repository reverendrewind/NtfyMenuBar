//
//  StatusBarController.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 20/09/2025.
//

import AppKit
import SwiftUI
import Combine

// Custom window class that can become key even when borderless
class DashboardWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

class StatusBarController: NSObject, ObservableObject, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    let viewModel: NtfyViewModel
    private var dashboardPopover: NSPopover?
    private var settingsWindow: NSWindow?
    
    init(viewModel: NtfyViewModel) {
        self.viewModel = viewModel
        super.init()
        setupStatusItem()
        setupNotificationObservers()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Set the icon
            if let image = NSImage(named: "MenuBarIcon") {
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
        if let popover = dashboardPopover, popover.isShown {
            // Popover is shown, close it (toggle behavior)
            popover.close()
        } else {
            // Create popover if it doesn't exist
            if dashboardPopover == nil {
                let popover = NSPopover()
                popover.contentSize = NSSize(width: 350, height: 500)
                popover.behavior = .transient // Close when clicking outside
                popover.appearance = NSAppearance(named: .aqua)
                
                let contentView = ContentView().environmentObject(viewModel)
                let hostingController = NSHostingController(rootView: contentView)
                popover.contentViewController = hostingController
                
                dashboardPopover = popover
            }
            
            // Show popover relative to status item button
            if let button = statusItem?.button {
                dashboardPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        // Dashboard item
        let dashboardItem = NSMenuItem(title: "Open Dashboard", action: #selector(openDashboardFromMenu), keyEquivalent: "")
        dashboardItem.target = self
        menu.addItem(dashboardItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Recent Messages Section
        if viewModel.messages.isEmpty {
            let noMessagesItem = NSMenuItem(title: "No recent messages", action: nil, keyEquivalent: "")
            noMessagesItem.isEnabled = false
            menu.addItem(noMessagesItem)
        } else {
            // Add header
            let recentHeader = NSMenuItem(title: "Recent Messages", action: nil, keyEquivalent: "")
            recentHeader.isEnabled = false
            let headerFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            recentHeader.attributedTitle = NSAttributedString(string: "Recent Messages", attributes: [
                .font: headerFont,
                .foregroundColor: NSColor.secondaryLabelColor
            ])
            menu.addItem(recentHeader)
            
            // Show up to 5 recent messages
            let recentMessages = Array(viewModel.messages.prefix(5))
            for message in recentMessages {
                let messageItem = createMessageMenuItem(for: message)
                menu.addItem(messageItem)
            }
            
            if viewModel.messages.count > 5 {
                let moreItem = NSMenuItem(title: "... and \(viewModel.messages.count - 5) more", action: #selector(openDashboardFromMenu), keyEquivalent: "")
                moreItem.target = self
                let italicFont = NSFont.systemFont(ofSize: NSFont.systemFontSize - 1, weight: .regular)
                let italicDescriptor = italicFont.fontDescriptor.withSymbolicTraits(.italic)
                let finalFont = NSFont(descriptor: italicDescriptor, size: NSFont.systemFontSize - 1) ?? italicFont
                moreItem.attributedTitle = NSAttributedString(string: "... and \(viewModel.messages.count - 5) more", attributes: [
                    .font: finalFont,
                    .foregroundColor: NSColor.secondaryLabelColor
                ])
                menu.addItem(moreItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings item
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Connection toggle
        let connectionItem = NSMenuItem(
            title: viewModel.isConnected ? "Disconnect" : "Connect",
            action: #selector(toggleConnection),
            keyEquivalent: ""
        )
        connectionItem.target = self
        menu.addItem(connectionItem)
        
        // Clear messages
        let clearItem = NSMenuItem(title: "Clear Messages", action: #selector(clearMessages), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func openDashboardFromMenu() {
        openDashboard()
    }
    
    @objc private func openSettings() {
        if let window = settingsWindow, window.isVisible {
            // Settings window exists and is visible, bring to front
            window.orderFront(nil)
            window.makeKeyAndOrderFront(nil)
        } else {
            // Calculate position below menu bar (centered)
            guard let screen = NSScreen.main else { return }
            let screenFrame = screen.frame
            let windowSize = CGSize(width: 500, height: 550)
            
            // Calculate X position (centered)
            let initialX = (screenFrame.width - windowSize.width) / 2
            
            // Position just below menu bar at TOP of screen
            // screenFrame.maxY is the top of the screen
            let menuBarHeight: CGFloat = 25
            let gap: CGFloat = 10
            let initialY = screenFrame.maxY - menuBarHeight - windowSize.height - gap
            
            // Create new settings window with correct initial position
            let settingsView = SettingsView().environmentObject(viewModel)
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: initialX, y: initialY, width: windowSize.width, height: windowSize.height),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.contentViewController = hostingController
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.isRestorable = false
            window.tabbingMode = .disallowed
            // Make window appear on all spaces/desktops
            window.collectionBehavior = [.moveToActiveSpace, .transient]
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            
            // Keep reference to window
            settingsWindow = window
        }
    }
    
    @objc private func toggleConnection() {
        if viewModel.isConnected {
            viewModel.disconnect()
        } else {
            viewModel.connect()
        }
    }
    
    @objc private func clearMessages() {
        viewModel.clearMessages()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Window Positioning
    
    private func positionWindowNearMenuBar(_ window: NSWindow) {
        // Disable window restoration and tiling
        window.isRestorable = false
        window.tabbingMode = .disallowed
        
        guard let screen = NSScreen.main else { 
            window.center()
            return 
        }
        
        // Force window to be shown first so it has correct dimensions
        window.makeKeyAndOrderFront(nil)
        
        // Small delay to ensure window is fully displayed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            
            // Position in upper-right corner with margins
            let margin: CGFloat = 30
            let upperRightX = screenFrame.origin.x + screenFrame.size.width - windowFrame.size.width - margin
            let upperRightY = screenFrame.origin.y + screenFrame.size.height - windowFrame.size.height - margin
            
            // Use setFrame with display:true to force positioning
            let upperRightFrame = NSRect(
                x: upperRightX,
                y: upperRightY,
                width: windowFrame.size.width,
                height: windowFrame.size.height
            )
            
            window.setFrame(upperRightFrame, display: true, animate: false)
        }
    }
    
    // MARK: - Message Menu Items
    
    private func createMessageMenuItem(for message: NtfyMessage) -> NSMenuItem {
        // Create title with truncation
        let title = message.displayTitle
        let messageText = message.message ?? "No message"
        let truncatedMessage = messageText.count > 50 ? String(messageText.prefix(47)) + "..." : messageText
        
        // Format time
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let timeString = formatter.localizedString(for: message.date, relativeTo: Date())
        
        // Create menu item text
        let menuTitle = "\(title): \(truncatedMessage) (\(timeString))"
        
        let menuItem = NSMenuItem(title: menuTitle, action: #selector(openDashboardFromMenu), keyEquivalent: "")
        menuItem.target = self
        
        // Style the menu item
        let regularFont = NSFont.systemFont(ofSize: NSFont.systemFontSize - 1)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: regularFont,
            .foregroundColor: NSColor.labelColor
        ]
        
        let attributedTitle = NSMutableAttributedString(string: menuTitle, attributes: attributes)
        
        // Make title bold
        if let titleRange = menuTitle.range(of: title) {
            let nsRange = NSRange(titleRange, in: menuTitle)
            attributedTitle.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize - 1), range: nsRange)
        }
        
        // Make time secondary color
        if let timeRange = menuTitle.range(of: "(\(timeString))") {
            let nsRange = NSRange(timeRange, in: menuTitle)
            attributedTitle.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: nsRange)
        }
        
        menuItem.attributedTitle = attributedTitle
        
        return menuItem
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        print("Window will close")
        if let window = notification.object as? NSWindow {
            window.delegate = nil
            
            // Only handle settings window now - dashboard is a popover
            if window === settingsWindow {
                settingsWindow = nil
            }
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Only handle settings window now, popover handles itself
        // Popover automatically closes when clicking outside due to .transient behavior
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}