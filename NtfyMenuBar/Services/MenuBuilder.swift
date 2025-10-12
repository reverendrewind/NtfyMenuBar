//
//  MenuBuilder.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import AppKit
import Foundation

class MenuBuilder {
    private weak var viewModel: NtfyViewModel?
    private weak var statusBarController: StatusBarController?

    init(viewModel: NtfyViewModel, statusBarController: StatusBarController) {
        self.viewModel = viewModel
        self.statusBarController = statusBarController
    }

    func buildContextMenu() -> NSMenu {
        let menu = NSMenu()

        addDashboardSection(to: menu)
        menu.addItem(NSMenuItem.separator())

        addRecentMessagesSection(to: menu)
        menu.addItem(NSMenuItem.separator())

        addSnoozeSection(to: menu)
        menu.addItem(NSMenuItem.separator())

        addSettingsSection(to: menu)
        menu.addItem(NSMenuItem.separator())

        addConnectionSection(to: menu)
        addClearSection(to: menu)
        menu.addItem(NSMenuItem.separator())

        addQuitSection(to: menu)

        return menu
    }

    // MARK: - Menu Sections

    private func addDashboardSection(to menu: NSMenu) {
        let dashboardItem = NSMenuItem(
            title: StringConstants.MenuItems.openDashboard,
            action: #selector(StatusBarController.openDashboardFromMenu),
            keyEquivalent: ""
        )
        dashboardItem.target = statusBarController
        menu.addItem(dashboardItem)
    }

    private func addRecentMessagesSection(to menu: NSMenu) {
        guard let viewModel = viewModel else { return }

        if viewModel.messages.isEmpty {
            let noMessagesItem = NSMenuItem(
                title: StringConstants.MenuItems.noRecentMessages,
                action: nil,
                keyEquivalent: ""
            )
            noMessagesItem.isEnabled = false
            menu.addItem(noMessagesItem)
        } else {
            addRecentMessagesHeader(to: menu)
            addRecentMessageItems(to: menu, messages: viewModel.messages)
        }
    }

    private func addRecentMessagesHeader(to menu: NSMenu) {
        let recentHeader = NSMenuItem(
            title: StringConstants.MenuItems.recentMessages,
            action: nil,
            keyEquivalent: ""
        )
        recentHeader.isEnabled = false

        let headerFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        recentHeader.attributedTitle = NSAttributedString(
            string: StringConstants.MenuItems.recentMessages,
            attributes: [
                .font: headerFont,
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        menu.addItem(recentHeader)
    }

    private func addRecentMessageItems(to menu: NSMenu, messages: [NtfyMessage]) {
        let recentMessages = Array(messages.prefix(UIConstants.MenuBar.recentMessagesLimit))

        for message in recentMessages {
            let messageItem = createMessageMenuItem(for: message)
            menu.addItem(messageItem)
        }

        if messages.count > UIConstants.MenuBar.recentMessagesLimit {
            let moreItem = createMoreMessagesItem(totalCount: messages.count)
            menu.addItem(moreItem)
        }
    }

    private func addSnoozeSection(to menu: NSMenu) {
        guard let viewModel = viewModel else { return }

        if viewModel.isSnoozed {
            addSnoozeStatusItems(to: menu)
        } else {
            addSnoozeSubmenu(to: menu)
        }
    }

    private func addSnoozeStatusItems(to menu: NSMenu) {
        guard let viewModel = viewModel else { return }

        let statusText = "Snoozed until \(viewModel.snoozeStatusText)"
        let snoozeStatusItem = NSMenuItem(
            title: statusText,
            action: nil,
            keyEquivalent: ""
        )
        snoozeStatusItem.isEnabled = false
        snoozeStatusItem.setAccessibilityLabel(statusText)
        menu.addItem(snoozeStatusItem)

        let clearSnoozeItem = NSMenuItem(
            title: StringConstants.MenuItems.clearSnooze,
            action: #selector(StatusBarController.clearSnooze),
            keyEquivalent: ""
        )
        clearSnoozeItem.target = statusBarController
        menu.addItem(clearSnoozeItem)
    }

    private func addSnoozeSubmenu(to menu: NSMenu) {
        let snoozeSubmenu = NSMenu()

        for duration in SnoozeDuration.allCases.filter({ $0 != .custom }) {
            let item = NSMenuItem(
                title: duration.displayName,
                action: #selector(StatusBarController.snoozeNotifications(_:)),
                keyEquivalent: ""
            )
            item.target = statusBarController
            item.representedObject = duration
            snoozeSubmenu.addItem(item)
        }

        let snoozeItem = NSMenuItem(
            title: StringConstants.MenuItems.snoozeNotifications,
            action: nil,
            keyEquivalent: ""
        )
        snoozeItem.submenu = snoozeSubmenu
        menu.addItem(snoozeItem)
    }

    private func addSettingsSection(to menu: NSMenu) {
        let settingsItem = NSMenuItem(
            title: StringConstants.MenuItems.settings,
            action: #selector(StatusBarController.openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = statusBarController
        menu.addItem(settingsItem)
    }

    private func addConnectionSection(to menu: NSMenu) {
        guard let viewModel = viewModel else { return }

        let connectionItem = NSMenuItem(
            title: viewModel.isConnected ? StringConstants.MenuItems.disconnect : StringConstants.MenuItems.connect,
            action: #selector(StatusBarController.toggleConnection),
            keyEquivalent: ""
        )
        connectionItem.target = statusBarController
        menu.addItem(connectionItem)
    }

    private func addClearSection(to menu: NSMenu) {
        let clearItem = NSMenuItem(
            title: StringConstants.MenuItems.clearMessages,
            action: #selector(StatusBarController.clearMessages),
            keyEquivalent: ""
        )
        clearItem.target = statusBarController
        menu.addItem(clearItem)
    }

    private func addQuitSection(to menu: NSMenu) {
        let quitItem = NSMenuItem(
            title: StringConstants.MenuItems.quit,
            action: #selector(StatusBarController.quit),
            keyEquivalent: "q"
        )
        quitItem.target = statusBarController
        menu.addItem(quitItem)
    }

    // MARK: - Message Menu Items

    private func createMessageMenuItem(for message: NtfyMessage) -> NSMenuItem {
        let title = message.displayTitle
        let messageText = message.message ?? StringConstants.NotificationContent.noMessage
        let truncatedMessage = messageText.count > UIConstants.Content.maxMessagePreviewLength ?
            String(messageText.prefix(UIConstants.Content.maxMessagePreviewLength - 3)) + "..." : messageText

        // Format time
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let timeString = formatter.localizedString(for: message.date, relativeTo: Date())

        // Create menu item text
        let menuTitle = "\(title): \(truncatedMessage) (\(timeString))"

        let menuItem = NSMenuItem(
            title: menuTitle,
            action: #selector(StatusBarController.openDashboardFromMenu),
            keyEquivalent: ""
        )
        menuItem.target = statusBarController

        // Style the menu item
        styleMessageMenuItem(menuItem, title: title, fullText: menuTitle, timeString: timeString)

        return menuItem
    }

    private func styleMessageMenuItem(_ menuItem: NSMenuItem, title: String, fullText: String, timeString: String) {
        let regularFont = NSFont.systemFont(ofSize: NSFont.systemFontSize - 1)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: regularFont,
            .foregroundColor: NSColor.labelColor
        ]

        let attributedTitle = NSMutableAttributedString(string: fullText, attributes: attributes)

        // Make title bold
        if let titleRange = fullText.range(of: title) {
            let nsRange = NSRange(titleRange, in: fullText)
            attributedTitle.addAttribute(
                .font,
                value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize - 1),
                range: nsRange
            )
        }

        // Make time secondary color
        if let timeRange = fullText.range(of: "(\(timeString))") {
            let nsRange = NSRange(timeRange, in: fullText)
            attributedTitle.addAttribute(
                .foregroundColor,
                value: NSColor.secondaryLabelColor,
                range: nsRange
            )
        }

        menuItem.attributedTitle = attributedTitle
    }

    private func createMoreMessagesItem(totalCount: Int) -> NSMenuItem {
        let remainingCount = totalCount - UIConstants.MenuBar.recentMessagesLimit
        let title = "... and \(remainingCount) more"

        let moreItem = NSMenuItem(
            title: title,
            action: #selector(StatusBarController.openDashboardFromMenu),
            keyEquivalent: ""
        )
        moreItem.target = statusBarController

        // Style with italic font
        let italicFont = NSFont.systemFont(ofSize: NSFont.systemFontSize - 1, weight: .regular)
        let italicDescriptor = italicFont.fontDescriptor.withSymbolicTraits(.italic)
        let finalFont = NSFont(descriptor: italicDescriptor, size: NSFont.systemFontSize - 1) ?? italicFont

        moreItem.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: finalFont,
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )

        return moreItem
    }
}