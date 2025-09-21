//
//  ScriptCommands.swift
//  NtfyMenuBar
//
//  Created by Assistant on 2025-09-21.
//

import Foundation
import Cocoa

// MARK: - Send Message Command

@objc(SendMessageScriptCommand)
class SendMessageScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let message = directParameter as? String else {
            scriptErrorNumber = -50
            scriptErrorString = "Message text is required"
            return false
        }

        guard let topic = arguments?["topic"] as? String else {
            scriptErrorNumber = -50
            scriptErrorString = "Topic is required"
            return false
        }

        let title = arguments?["title"] as? String
        let priority = arguments?["priority"] as? Int ?? 3
        let tags = arguments?["tags"] as? String

        // Send message through the app
        Task { @MainActor in
            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
            guard let viewModel = appDelegate.statusBarController?.viewModel else { return }

            // Create URL for the topic
            let serverURL = viewModel.settings.serverURL
            guard !serverURL.isEmpty else {
                scriptErrorNumber = -51
                scriptErrorString = "Server not configured"
                return
            }

            let urlString = "\(serverURL)/\(topic)"
            guard let url = URL(string: urlString) else {
                scriptErrorNumber = -51
                scriptErrorString = "Invalid server URL"
                return
            }

            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = message.data(using: .utf8)

            // Add headers
            if let title = title {
                request.setValue(title, forHTTPHeaderField: "Title")
            }
            request.setValue(String(priority), forHTTPHeaderField: "Priority")
            if let tags = tags {
                request.setValue(tags, forHTTPHeaderField: "Tags")
            }

            // Add authentication
            if !viewModel.settings.username.isEmpty,
               let password = SettingsManager.loadPassword(for: viewModel.settings.username) {
                let credentials = "\(viewModel.settings.username):\(password)"
                if let credData = credentials.data(using: .utf8) {
                    let base64Credentials = credData.base64EncodedString()
                    request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
                }
            } else if let token = SettingsManager.loadAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            // Send request
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    print("📤 AppleScript: Message sent successfully")
                } else {
                    scriptErrorNumber = -52
                    scriptErrorString = "Failed to send message"
                }
            } catch {
                scriptErrorNumber = -52
                scriptErrorString = "Network error: \(error.localizedDescription)"
            }
        }

        return true
    }
}

// MARK: - Get Messages Command

@objc(GetMessagesScriptCommand)
class GetMessagesScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let topic = arguments?["topic"] as? String
        let limit = arguments?["limit"] as? Int ?? 20

        guard let appDelegate = NSApp.delegate as? AppDelegate else {
            scriptErrorNumber = -50
            scriptErrorString = "Application not available"
            return []
        }

        guard let viewModel = appDelegate.statusBarController?.viewModel else {
            scriptErrorNumber = -50
            scriptErrorString = "View model not available"
            return []
        }

        var messages = viewModel.messages

        // Filter by topic if specified
        if let topic = topic {
            messages = messages.filter { $0.topic == topic }
        }

        // Limit results
        messages = Array(messages.prefix(limit))

        // Convert to scriptable messages
        return messages.map { ScriptableMessage(from: $0) }
    }
}

// MARK: - Connection Commands

@objc(ConnectScriptCommand)
class ConnectScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        Task { @MainActor in
            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
            guard let viewModel = appDelegate.statusBarController?.viewModel else { return }

            viewModel.connect()
        }
        return true
    }
}

@objc(DisconnectScriptCommand)
class DisconnectScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        Task { @MainActor in
            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
            guard let viewModel = appDelegate.statusBarController?.viewModel else { return }

            viewModel.disconnect()
        }
        return true
    }
}

// MARK: - Snooze Commands

@objc(SnoozeScriptCommand)
class SnoozeScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let minutes = arguments?["minutes"] as? Int else {
            scriptErrorNumber = -50
            scriptErrorString = "Duration in minutes is required"
            return nil
        }

        Task { @MainActor in
            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
            guard let viewModel = appDelegate.statusBarController?.viewModel else { return }

            let duration = TimeInterval(minutes * 60)
            viewModel.snoozeNotifications(duration: .custom, customDuration: duration)
        }
        return true
    }
}

@objc(UnsnoozeScriptCommand)
class UnsnoozeScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        Task { @MainActor in
            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
            guard let viewModel = appDelegate.statusBarController?.viewModel else { return }

            viewModel.clearSnooze()
        }
        return true
    }
}

// MARK: - Clear Messages Command

@objc(ClearMessagesScriptCommand)
class ClearMessagesScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        Task { @MainActor in
            guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
            guard let viewModel = appDelegate.statusBarController?.viewModel else { return }

            viewModel.clearMessages()
        }
        return true
    }
}