//
//  IntentHandler.swift
//  NtfyMenuBar
//
//  Created by Assistant on 2025-09-21.
//

import Intents
import Foundation
import AppKit

class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is SendNtfyMessageIntent:
            return SendNtfyMessageIntentHandler()
        case is SnoozeNotificationsIntent:
            return SnoozeNotificationsIntentHandler()
        default:
            fatalError("Unhandled intent type: \(intent)")
        }
    }
}

// MARK: - Send Message Intent Handler

class SendNtfyMessageIntentHandler: NSObject, SendNtfyMessageIntentHandling {

    func handle(intent: SendNtfyMessageIntent, completion: @escaping (SendNtfyMessageIntentResponse) -> Void) {
        guard let message = intent.message,
              let topic = intent.topic else {
            completion(SendNtfyMessageIntentResponse(code: .failure, userActivity: nil))
            return
        }

        Task {
            do {
                // Get settings
                let settings = SettingsManager.loadSettings()
                guard !settings.serverURL.isEmpty else {
                    completion(SendNtfyMessageIntentResponse(code: .failure, userActivity: nil))
                    return
                }

                // Create URL
                let urlString = "\(settings.serverURL)/\(topic)"
                guard let url = URL(string: urlString) else {
                    completion(SendNtfyMessageIntentResponse(code: .failure, userActivity: nil))
                    return
                }

                // Create request
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.httpBody = message.data(using: .utf8)

                // Add optional parameters - using defaults since not in generated intent
                request.setValue("Notification", forHTTPHeaderField: "Title")
                request.setValue("3", forHTTPHeaderField: "Priority")

                // Add authentication
                if settings.authMethod == .basicAuth && !settings.username.isEmpty,
                   let password = SettingsManager.loadPassword(for: settings.username) {
                    let credentials = "\(settings.username):\(password)"
                    if let credData = credentials.data(using: .utf8) {
                        let base64Credentials = credData.base64EncodedString()
                        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
                    }
                } else if settings.authMethod == .accessToken,
                          let token = SettingsManager.loadAccessToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                // Send request
                let (_, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    let successResponse = SendNtfyMessageIntentResponse.success(topic: topic)
                    completion(successResponse)
                } else {
                    completion(SendNtfyMessageIntentResponse(code: .failure, userActivity: nil))
                }
            } catch {
                print("❌ Failed to send message via Shortcuts: \(error)")
                completion(SendNtfyMessageIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }

    func resolveTopic(for intent: SendNtfyMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let topic = intent.topic, !topic.isEmpty {
            completion(INStringResolutionResult.success(with: topic))
        } else {
            // Use default topic from settings if not specified
            let settings = SettingsManager.loadSettings()
            if let defaultTopic = settings.topics.first {
                completion(INStringResolutionResult.success(with: defaultTopic))
            } else {
                completion(INStringResolutionResult.needsValue())
            }
        }
    }

    func resolveMessage(for intent: SendNtfyMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let message = intent.message, !message.isEmpty {
            completion(INStringResolutionResult.success(with: message))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }
}

// MARK: - Snooze Notifications Intent Handler

class SnoozeNotificationsIntentHandler: NSObject, SnoozeNotificationsIntentHandling {

    func handle(intent: SnoozeNotificationsIntent, completion: @escaping (SnoozeNotificationsIntentResponse) -> Void) {
        let minutes = 30 // Default since parameter not generated yet

        Task { @MainActor in
            // Access the running app if available
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
               let viewModel = appDelegate.statusBarController?.viewModel {
                // If app is running, use the view model
                let duration = TimeInterval(minutes * 60)
                viewModel.snoozeNotifications(duration: .custom, customDuration: duration)

                let response = SnoozeNotificationsIntentResponse.success(minutes: NSNumber(value: minutes))
                completion(response)
            } else {
                // If app is not running, update settings directly
                var settings = SettingsManager.loadSettings()
                settings.isSnoozed = true
                settings.snoozeEndTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
                SettingsManager.saveSettings(settings)

                let response = SnoozeNotificationsIntentResponse.success(minutes: NSNumber(value: minutes))
                completion(response)
            }
        }
    }

    func resolveMinutes(for intent: SnoozeNotificationsIntent, with completion: @escaping (SnoozeNotificationsMinutesResolutionResult) -> Void) {
        let minutes = 30 // Default since parameter not generated yet
        completion(SnoozeNotificationsMinutesResolutionResult.success(with: minutes))
    }
}