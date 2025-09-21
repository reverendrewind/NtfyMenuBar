//
//  IntentsBridge.swift
//  NtfyMenuBar
//
//  Created by Assistant on 2025-09-21.
//

import Foundation
import Intents

// MARK: - Intent Extensions for Shortcuts App

// This file provides the bridge between the auto-generated Intent classes
// and our Swift implementation

extension SendNtfyMessageIntent {

    /// Convenience initializer for creating the intent programmatically
    convenience init(message: String, topic: String, title: String? = nil, priority: Int = 3) {
        self.init()
        self.message = message
        self.topic = topic
        // Note: title and priority not available in current Intent Definition
    }
}

extension SnoozeNotificationsIntent {

    /// Convenience initializer for creating the intent programmatically
    convenience init(minutes: Int) {
        self.init()
        // Note: minutes parameter not available in current Intent Definition
    }
}

// MARK: - Shortcuts Donations

class ShortcutsDonator {

    /// Donate a send message shortcut after successfully sending a message
    static func donateSendMessage(message: String, topic: String, title: String? = nil) {
        let intent = SendNtfyMessageIntent(
            message: message,
            topic: topic,
            title: title,
            priority: 3
        )

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("❌ Failed to donate send message shortcut: \(error)")
            } else {
                print("✅ Donated send message shortcut for topic: \(topic)")
            }
        }
    }

    /// Donate a snooze shortcut after snoozing notifications
    static func donateSnooze(minutes: Int) {
        let intent = SnoozeNotificationsIntent(minutes: minutes)

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("❌ Failed to donate snooze shortcut: \(error)")
            } else {
                print("✅ Donated snooze shortcut for \(minutes) minutes")
            }
        }
    }
}