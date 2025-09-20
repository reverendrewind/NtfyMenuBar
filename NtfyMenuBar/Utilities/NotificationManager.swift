//
//  NotificationManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import Foundation
import UserNotifications

extension Notification.Name {
    static let openDashboardFromNotification = Notification.Name("openDashboardFromNotification")
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
        requestPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                } else if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("⚠️ Notification permission denied")
                }
            }
        }
    }
    
    func showNotification(for message: NtfyMessage, settings: NtfySettings = SettingsManager.loadSettings()) {
        let content = UNMutableNotificationContent()
        
        // Enhanced branding with ntfy prefix and priority indicators
        let priorityEmoji = getPriorityEmoji(for: message.priority)
        let brandedTitle = "ntfy: \(priorityEmoji)\(message.displayTitle)"
        content.title = brandedTitle
        
        // Rich body content with metadata
        let messageBody = message.message ?? "No message"
        let formattedBody = formatNotificationBody(message: messageBody, priority: message.priority, tags: message.tags)
        content.body = formattedBody
        
        // Enhanced subtitle with server context
        content.subtitle = formatNotificationSubtitle(for: message)
        
        // Enhanced sound selection based on user preferences
        content.sound = getSoundForMessage(message, settings: settings)
        
        // Set notification category for interactive actions
        content.categoryIdentifier = "NTFY_MESSAGE"
        
        // Set badge based on priority
        if let priority = message.priority {
            content.badge = NSNumber(value: priority)
        }
        
        // Add user info for potential actions
        content.userInfo = [
            "messageId": message.id,
            "topic": message.topic,
            "timestamp": message.time
        ]
        
        // Add priority-based styling
        if let priority = message.priority, priority >= 4 {
            content.sound = .defaultCritical
        }
        
        let request = UNNotificationRequest(
            identifier: message.id,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show notification: \(error)")
            } else {
                print("📱 Notification shown: \(message.displayTitle)")
            }
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func clearNotification(withId id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification - open dashboard
            print("📱 User tapped notification: \(userInfo)")
            openDashboard()
            
        case "OPEN_DASHBOARD":
            // User pressed "Open dashboard" button
            print("📱 User requested dashboard: \(userInfo)")
            openDashboard()
            
        case "MARK_READ":
            // User pressed "Mark read" button
            print("📱 User marked as read: \(userInfo)")
            if let messageId = userInfo["messageId"] as? String {
                clearNotification(withId: messageId)
            }
            
        case "DISMISS":
            // User pressed "Dismiss" button
            print("📱 User dismissed: \(userInfo)")
            if let messageId = userInfo["messageId"] as? String {
                clearNotification(withId: messageId)
            }
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("📱 User dismissed notification: \(userInfo)")
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func openDashboard() {
        // Post notification that dashboard should open
        // This will be caught by StatusBarController
        NotificationCenter.default.post(name: .openDashboardFromNotification, object: nil)
    }
    
    // MARK: - Enhanced Notification Content
    
    private func setupNotificationCategories() {
        // Create actions for interactive notifications
        let openDashboardAction = UNNotificationAction(
            identifier: "OPEN_DASHBOARD",
            title: "Open dashboard",
            options: [.foreground]
        )
        
        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ",
            title: "Mark read",
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        
        // Create category with actions
        let messageCategory = UNNotificationCategory(
            identifier: "NTFY_MESSAGE",
            actions: [openDashboardAction, markReadAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([messageCategory])
    }
    
    private func getPriorityEmoji(for priority: Int?) -> String {
        guard let priority = priority else { return "📢 " }
        
        switch priority {
        case 5: return "🔴 " // Max/Urgent
        case 4: return "🟠 " // High
        case 3: return "🟡 " // Default
        case 2: return "🔵 " // Low
        case 1: return "⚪ " // Min
        default: return "📢 "
        }
    }
    
    private func formatNotificationBody(message: String, priority: Int?, tags: [String]?) -> String {
        var components: [String] = []
        
        // Add the main message (truncated smartly)
        let truncatedMessage = smartTruncate(message, maxLength: 150)
        components.append(truncatedMessage)
        
        // Add priority info if significant
        if let priority = priority, priority >= 4 {
            components.append("⚠️ Priority: \(priority)")
        }
        
        // Add tags if present
        if let tags = tags, !tags.isEmpty {
            let tagString = tags.prefix(3).joined(separator: ", ")
            let tagSuffix = tags.count > 3 ? " +\(tags.count - 3)" : ""
            components.append("🏷️ Tags: \(tagString)\(tagSuffix)")
        }
        
        // Add timestamp for context
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        components.append("🕐 \(timeFormatter.string(from: Date()))")
        
        return components.joined(separator: "\n")
    }
    
    private func formatNotificationSubtitle(for message: NtfyMessage) -> String {
        var subtitleComponents: [String] = []
        
        // Add topic if different from title
        if message.topic != message.title {
            subtitleComponents.append("📂 \(message.topic)")
        }
        
        // Add server context (extract from URL if available)
        // This could be enhanced to show actual server name
        subtitleComponents.append("🌐 ntfy")
        
        return subtitleComponents.joined(separator: " • ")
    }
    
    private func getSoundForMessage(_ message: NtfyMessage, settings: NtfySettings) -> UNNotificationSound {
        let priority = message.priority ?? 3

        // Use critical sound for high priority if enabled
        if settings.customSoundForHighPriority && priority >= 4 {
            return .defaultCritical
        }

        // Use custom sound from settings
        if let soundFileName = settings.notificationSound.fileName {
            return UNNotificationSound(named: UNNotificationSoundName(soundFileName))
        }

        return .default
    }

    private func getSoundForPriority(_ priority: Int?) -> UNNotificationSound {
        guard let priority = priority else { return .default }

        switch priority {
        case 5: return .defaultCritical // Max/Urgent
        case 4: return .defaultCritical // High
        case 3: return .default         // Default
        case 2: return .default         // Low
        case 1: return .default         // Min
        default: return .default
        }
    }
    
    private func smartTruncate(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        
        // Try to truncate at word boundaries
        let truncated = String(text.prefix(maxLength))
        if let lastSpaceIndex = truncated.lastIndex(of: " ") {
            let wordBoundaryTruncated = String(truncated[..<lastSpaceIndex])
            if wordBoundaryTruncated.count >= maxLength * 3/4 { // At least 75% of desired length
                return wordBoundaryTruncated + "..."
            }
        }
        
        // Fallback to character truncation
        return String(text.prefix(maxLength - 3)) + "..."
    }
}