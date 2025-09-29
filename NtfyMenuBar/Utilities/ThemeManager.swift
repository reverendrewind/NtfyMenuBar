//
//  ThemeManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 20/09/2025.
//

import SwiftUI
import AppKit
import Combine

@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppearanceMode = .system
    @Published var isDarkMode: Bool = false
    
    private var appearanceTimer: Timer?
    
    init() {
        setupSystemAppearanceObserver()
        updateTheme()
    }
    
    deinit {
        // Ensure timer is properly cleaned up
        appearanceTimer?.invalidate()
        appearanceTimer = nil
    }
    
    func setTheme(_ theme: AppearanceMode) {
        currentTheme = theme
        updateTheme()
    }
    
    private func setupSystemAppearanceObserver() {
        // Invalidate any existing timer first
        appearanceTimer?.invalidate()
        appearanceTimer = nil

        // Monitor for system appearance changes using a timer approach
        // since NSApplication.didChangeEffectiveAppearanceNotification doesn't exist
        appearanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                // If self is deallocated, invalidate the timer
                timer.invalidate()
                return
            }

            Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.updateTheme()
            }
        }
    }
    
    private func updateTheme() {
        switch currentTheme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            isDarkMode = isSystemInDarkMode()
        }
    }
    
    private func isSystemInDarkMode() -> Bool {
        let appearance = NSApp.effectiveAppearance
        _ = NSAppearance(named: .aqua)
        _ = NSAppearance(named: .darkAqua)
        
        return appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
}

// MARK: - Theme Colors
extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    // Background colors
    var windowBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }
    
    var cardBackground: Color {
        Color.secondary.opacity(0.1)
    }
    
    var headerBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }
    
    // Text colors
    var primaryText: Color {
        Color(NSColor.labelColor)
    }
    
    var secondaryText: Color {
        Color(NSColor.secondaryLabelColor)
    }
    
    var accentText: Color {
        Color(NSColor.controlAccentColor)
    }
    
    // UI element colors
    var borderColor: Color {
        Color(NSColor.separatorColor)
    }
    
    var separatorColor: Color {
        Color(NSColor.separatorColor)
    }
    
    var buttonBackground: Color {
        Color(NSColor.controlColor)
    }
}
