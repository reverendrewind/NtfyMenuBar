//
//  UIConstants.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import Foundation
import CoreGraphics

struct UIConstants {

    // MARK: - Dashboard Window
    struct Dashboard {
        static let width: CGFloat = 320
        static let height: CGFloat = 300
        static let buttonGap: CGFloat = 5
        static let screenMargin: CGFloat = 20
    }

    // MARK: - Settings Window
    struct Settings {
        static let width: CGFloat = 700
        static let height: CGFloat = 750
        static let fallbackWidth: CGFloat = 700
        static let fallbackHeight: CGFloat = 650
        static let menuBarHeight: CGFloat = 25
        static let topGap: CGFloat = 10
    }

    // MARK: - Menu Bar
    struct MenuBar {
        static let fallbackMargin: CGFloat = 30
        static let recentMessagesLimit = 5
    }

    // MARK: - Spacing and Layout
    struct Layout {
        static let smallSpacing: CGFloat = 5
        static let mediumSpacing: CGFloat = 10
        static let largeSpacing: CGFloat = 20
        static let extraLargeSpacing: CGFloat = 30

        // Animation durations
        static let fastAnimation: Double = 0.2
        static let standardAnimation: Double = 0.3
        static let slowAnimation: Double = 0.5
    }

    // MARK: - Content Sizing
    struct Content {
        static let maxMessagePreviewLength = 50
        static let messageListMaxHeight: CGFloat = 400
        static let settingsRowHeight: CGFloat = 44
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }

    // MARK: - Shadow
    struct Shadow {
        static let radius: CGFloat = 10
        static let opacity: Float = 0.1
        static let offsetY: CGFloat = 2
    }
}