//
//  WindowManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import AppKit
import SwiftUI

// Custom window class that can become key even when borderless
class DashboardWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

class WindowManager: NSObject, NSWindowDelegate {
    private weak var viewModel: NtfyViewModel?
    private weak var themeManager: ThemeManager?
    private weak var delegate: WindowManagerDelegate?

    private var dashboardWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var globalEventMonitor: Any?

    init(viewModel: NtfyViewModel, themeManager: ThemeManager, delegate: WindowManagerDelegate) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.delegate = delegate
        super.init()
    }

    // MARK: - Dashboard Window Management

    func toggleDashboard(nearStatusButton button: NSButton) {
        if let window = dashboardWindow, window.isVisible {
            closeDashboard()
        } else {
            openDashboard(nearStatusButton: button)
        }
    }

    func openDashboard(nearStatusButton button: NSButton) {
        guard let viewModel = viewModel, let themeManager = themeManager else { return }

        let windowSize = CGSize(width: UIConstants.Dashboard.width, height: UIConstants.Dashboard.height)

        // Calculate position relative to status button
        let position = calculateDashboardPosition(button: button, windowSize: windowSize)

        Logger.shared.debug("📍 Button screen rect: \(button.window!.convertToScreen(button.frame))")
        Logger.shared.debug("📍 Window position: x=\(position.x), y=\(position.y)")

        // Create dashboard window
        let window = DashboardWindow(
            contentRect: NSRect(x: position.x, y: position.y, width: windowSize.width, height: windowSize.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configureDashboardWindow(window, themeManager: themeManager)

        // Add content
        let contentView = ContentView()
            .environmentObject(viewModel)
            .environmentObject(themeManager)
        let hostingController = NSHostingController(rootView: contentView)
        window.contentViewController = hostingController
        window.delegate = self

        window.makeKeyAndOrderFront(nil)
        dashboardWindow = window

        setupGlobalEventMonitor()
    }

    func closeDashboard() {
        dashboardWindow?.close()
    }

    // MARK: - Settings Window Management

    func openSettings() {
        guard let viewModel = viewModel, let themeManager = themeManager else { return }

        if let window = settingsWindow, window.isVisible {
            window.orderFront(nil)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let position = calculateSettingsPosition()
        let windowSize = CGSize(width: UIConstants.Settings.width, height: UIConstants.Settings.height)

        // Create settings view
        let settingsView = SettingsView()
            .environmentObject(viewModel)
            .environmentObject(themeManager)
        let hostingController = NSHostingController(rootView: settingsView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: position.x, y: position.y, width: windowSize.width, height: windowSize.height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        configureSettingsWindow(window, hostingController: hostingController)
        settingsWindow = window
    }

    // MARK: - Window Configuration

    private func configureDashboardWindow(_ window: NSWindow, themeManager: ThemeManager) {
        window.backgroundColor = themeManager.isDarkMode ?
            NSColor.windowBackgroundColor : NSColor.controlBackgroundColor
        window.appearance = themeManager.isDarkMode ?
            NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        window.isOpaque = true
        window.hasShadow = true
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace, .stationary]
    }

    private func configureSettingsWindow(_ window: NSWindow, hostingController: NSHostingController<some View>) {
        // Show app name in title bar
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "NtfyMenuBar"
        window.title = appName
        window.subtitle = "Settings"

        // Force title visibility with TabView
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible

        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.isRestorable = false
        window.tabbingMode = .disallowed
        window.collectionBehavior = [.moveToActiveSpace, .transient]
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Window Positioning

    private func calculateDashboardPosition(button: NSButton, windowSize: CGSize) -> CGPoint {
        let buttonFrame = button.frame
        guard let buttonWindow = button.window else {
            return CGPoint(x: 0, y: 0)
        }

        let buttonScreenRect = buttonWindow.convertToScreen(buttonFrame)

        // Center window below button with overflow protection
        let buttonCenterX = buttonScreenRect.midX
        let windowX = max(0, min(buttonCenterX - windowSize.width / 2,
                               buttonWindow.screen!.frame.maxX - windowSize.width))
        let windowY = buttonScreenRect.minY - windowSize.height - UIConstants.Dashboard.buttonGap

        return CGPoint(x: windowX, y: windowY)
    }

    private func calculateSettingsPosition() -> CGPoint {
        guard let screen = NSScreen.main else {
            return CGPoint(x: 100, y: 100)
        }

        let screenFrame = screen.frame
        let windowSize = CGSize(width: UIConstants.Settings.width, height: UIConstants.Settings.height)

        // Calculate X position (centered)
        let initialX = (screenFrame.width - windowSize.width) / 2

        // Position just below menu bar at TOP of screen
        let initialY = screenFrame.maxY - UIConstants.Settings.menuBarHeight -
                      windowSize.height - UIConstants.Settings.topGap

        return CGPoint(x: initialX, y: initialY)
    }

    // MARK: - Global Event Monitoring

    private func setupGlobalEventMonitor() {
        removeGlobalEventMonitor()

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleGlobalMouseEvent(event)
        }
    }

    private func removeGlobalEventMonitor() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }

    private func handleGlobalMouseEvent(_ event: NSEvent) {
        guard let window = dashboardWindow, window.isVisible else { return }

        // Get the click location in screen coordinates
        let windowLocation = NSEvent.mouseLocation

        // Check if click is outside the dashboard window
        if !window.frame.contains(windowLocation) {
            DispatchQueue.main.async {
                window.close()
            }
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        print("Window will close")

        guard let window = notification.object as? NSWindow else { return }
        window.delegate = nil

        // Determine which window is closing and clear the reference
        if window === dashboardWindow {
            dashboardWindow = nil
            removeGlobalEventMonitor()
        } else if window === settingsWindow {
            settingsWindow = nil
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        // Close dashboard when it loses focus (click outside)
        if let window = notification.object as? NSWindow,
           window === dashboardWindow {
            window.close()
        }
    }

    deinit {
        removeGlobalEventMonitor()
    }
}

// MARK: - WindowManagerDelegate Protocol

protocol WindowManagerDelegate: AnyObject {
    // Add any delegate methods needed for communication back to StatusBarController
}