//
//  NotificationManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
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
    
    func showNotification(for message: NtfyMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.displayTitle
        content.body = message.message ?? "No message"
        content.sound = .default
        content.categoryIdentifier = "ntfy"
        
        // Add topic as subtitle if different from title
        if message.topic != message.title {
            content.subtitle = "Topic: \(message.topic)"
        }
        
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
            // User tapped the notification
            print("📱 User tapped notification: \(userInfo)")
            // Could open the app or specific topic here
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("📱 User dismissed notification: \(userInfo)")
            
        default:
            break
        }
        
        completionHandler()
    }
}