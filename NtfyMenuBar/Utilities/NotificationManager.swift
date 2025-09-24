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
        // Check if notifications should be blocked (snooze or DND)
        if settings.shouldBlockNotifications {
            let reason = settings.isCurrentlySnoozed ? "snooze mode" : "Do Not Disturb schedule"
            print("🔕 Notification skipped due to \(reason): \(message.displayTitle)")
            return
        }

        let content = UNMutableNotificationContent()
        
        // Enhanced branding with ntfy prefix and priority indicators
        let priorityEmoji = getPriorityEmoji(for: message.priority)
        let brandedTitle = "\(StringConstants.NotificationContent.ntfyPrefix) \(priorityEmoji)\(message.displayTitle)"
        content.title = brandedTitle
        
        // Rich body content with metadata
        let messageBody = message.message ?? StringConstants.NotificationContent.noMessage
        let formattedBody = formatNotificationBody(message: messageBody, priority: message.priority, tags: message.tags)
        content.body = formattedBody
        
        // Enhanced subtitle with server context
        content.subtitle = formatNotificationSubtitle(for: message)
        
        // Enhanced sound selection based on user preferences
        content.sound = getSoundForMessage(message, settings: settings)
        
        // Set notification category for interactive actions
        content.categoryIdentifier = StringConstants.NotificationCategories.ntfyMessage
        
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
            
        case StringConstants.NotificationActions.openDashboard:
            // User pressed "Open dashboard" button
            print("📱 User requested dashboard: \(userInfo)")
            openDashboard()
            
        case StringConstants.NotificationActions.markRead:
            // User pressed "Mark read" button
            print("📱 User marked as read: \(userInfo)")
            if let messageId = userInfo["messageId"] as? String {
                clearNotification(withId: messageId)
            }
            
        case StringConstants.NotificationActions.dismiss:
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
            identifier: StringConstants.NotificationActions.openDashboard,
            title: StringConstants.MenuItems.openDashboard,
            options: [.foreground]
        )
        
        let markReadAction = UNNotificationAction(
            identifier: StringConstants.NotificationActions.markRead,
            title: StringConstants.NotificationActions.markReadTitle,
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: StringConstants.NotificationActions.dismiss,
            title: StringConstants.NotificationActions.dismissTitle,
            options: [.destructive]
        )
        
        // Create category with actions
        let messageCategory = UNNotificationCategory(
            identifier: StringConstants.NotificationCategories.ntfyMessage,
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
        let truncatedMessage = smartTruncate(message, maxLength: AppConfig.Notifications.maxMessageLength)
        components.append(truncatedMessage)
        
        // Add priority info if significant
        if let priority = priority, priority >= 4 {
            components.append("⚠️ Priority: \(priority)")
        }
        
        // Add tags if present
        if let tags = tags, !tags.isEmpty {
            let tagString = tags.prefix(AppConfig.Notifications.maxTagsToShow).joined(separator: ", ")
            let tagSuffix = tags.count > AppConfig.Notifications.maxTagsToShow ? " +\(tags.count - AppConfig.Notifications.maxTagsToShow)" : ""
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
            return UNNotificationSound(named: UNNotificationSoundName("\(soundFileName).aiff"))
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
            if wordBoundaryTruncated.count >= Int(Double(maxLength) * AppConfig.Notifications.smartTruncateThreshold) { // At least 75% of desired length
                return wordBoundaryTruncated + AppConfig.Notifications.truncationSuffix
            }
        }
        
        // Fallback to character truncation
        return String(text.prefix(maxLength - AppConfig.Notifications.truncationSuffix.count)) + AppConfig.Notifications.truncationSuffix
    }
}