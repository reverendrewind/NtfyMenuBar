//
//  AppDelegate+Scripting.swift
//  NtfyMenuBar
//
//  Created by Assistant on 2025-09-21.
//

import Foundation
import Cocoa

// MARK: - AppleScript Support

extension AppDelegate {

    // MARK: - Scriptable Properties

    @objc var scriptingIsConnected: Bool {
        return statusBarController?.viewModel.isConnected ?? false
    }

    @objc var scriptingServerURL: String {
        return statusBarController?.viewModel.settings.serverURL ?? ""
    }

    @objc var scriptingCurrentTopics: String {
        return statusBarController?.viewModel.settings.topics.joined(separator: ", ") ?? ""
    }

    @objc var scriptingMessageCount: Int {
        return statusBarController?.viewModel.messages.count ?? 0
    }

    @objc var scriptingIsSnoozed: Bool {
        get {
            return statusBarController?.viewModel.isSnoozed ?? false
        }
        set {
            Task { @MainActor in
                guard let viewModel = statusBarController?.viewModel else { return }

                if newValue {
                    // Snooze for default duration
                    viewModel.snoozeNotifications(duration: viewModel.settings.defaultSnoozeDuration)
                } else {
                    viewModel.clearSnooze()
                }
            }
        }
    }

    @objc var scriptingMessages: [ScriptableMessage] {
        guard let messages = statusBarController?.viewModel.messages else { return [] }
        return messages.map { ScriptableMessage(from: $0) }
    }

    // MARK: - AppleScript Support Methods

    func application(_ sender: NSApplication, delegateHandlesKey key: String) -> Bool {
        let scriptableKeys = [
            "scriptingIsConnected",
            "scriptingServerURL",
            "scriptingCurrentTopics",
            "scriptingMessageCount",
            "scriptingIsSnoozed",
            "scriptingMessages"
        ]
        return scriptableKeys.contains(key)
    }
}