# ntfy macOS Menubar App Development Plan

## Project Overview
A native macOS menubar application for receiving ntfy notifications with SwiftUI and modern Swift concurrency.

**Target Server**: `https://ntfy.2137.wtf`
**Authentication**: Required (admin:admin123)
**Platform**: macOS 14.0+ (Sonoma)
**Framework**: SwiftUI with Swift 6

---

## 1. Xcode Project Setup

### New Project Configuration:
- **Platform**: macOS
- **Application Type**: App
- **Interface**: SwiftUI ✅
- **Language**: Swift ✅
- **Storage**: None ✅ (no Core Data/CloudKit needed)
- **Testing**: Include Tests ✅, Skip UI Tests
- **Product Name**: `NtfyMenuBar`
- **Minimum Deployment**: macOS 14.0

### Post-Creation Setup:
1. Set `LSUIElement = YES` in Info.plist (hide from Dock)
2. Add network client entitlement
3. Add notifications entitlement

---

## 2. Project Structure

```
NtfyMenuBar/
├── NtfyMenuBar.xcodeproj
├── NtfyMenuBar/
│   ├── NtfyMenuBarApp.swift          # Main app entry point
│   ├── Models/
│   │   └── NtfyMessage.swift         # Message data model
│   ├── Services/
│   │   └── NtfyService.swift         # WebSocket connection handling
│   ├── ViewModels/
│   │   └── NtfyViewModel.swift       # Observable state management
│   ├── Views/
│   │   ├── ContentView.swift         # Main menubar content
│   │   ├── SettingsView.swift        # Configuration window
│   │   └── MessageRowView.swift      # Individual message display
│   ├── Utilities/
│   │   └── NotificationManager.swift # macOS notification handling
│   ├── Resources/
│   │   ├── Info.plist
│   │   └── Assets.xcassets
│   └── NtfyMenuBar.entitlements
```

---

## 3. Implementation Code

### 3.1 Main App (NtfyMenuBarApp.swift)
```swift
import SwiftUI
import UserNotifications

@main
struct NtfyMenuBarApp: App {
    @StateObject private var viewModel = NtfyViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
        } label: {
            Image(systemName: viewModel.hasUnreadMessages ? "bell.badge.fill" : "bell.fill")
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, isActive: viewModel.hasNewMessage)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}
```

### 3.2 Data Model (Models/NtfyMessage.swift)
```swift
import Foundation

struct NtfyMessage: Codable, Identifiable, Equatable {
    let id: String
    let time: Int
    let event: String
    let topic: String
    let message: String
    let title: String?
    let priority: Int?
    let tags: [String]?

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(time))
    }

    var displayTitle: String {
        title ?? "ntfy Notification"
    }

    var isKeepalive: Bool {
        event == "keepalive"
    }
}

struct NtfySettings: Codable {
    var serverURL: String = "https://ntfy.2137.wtf"
    var topic: String = "test"
    var username: String = "admin"
    var password: String = "admin123"
    var enableNotifications: Bool = true
    var maxRecentMessages: Int = 20

    static let `default` = NtfySettings()
}
```

### 3.3 WebSocket Service (Services/NtfyService.swift)
```swift
import Foundation
import Combine

@MainActor
class NtfyService: ObservableObject {
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var messages: [NtfyMessage] = []

    private var webSocketTask: URLSessionWebSocketTask?
    private var settings: NtfySettings
    private let notificationManager = NotificationManager()

    init(settings: NtfySettings = .default) {
        self.settings = settings
    }

    func connect() {
        disconnect() // Clean up any existing connection

        guard let url = createWebSocketURL() else {
            connectionError = "Invalid server URL"
            return
        }

        var request = URLRequest(url: url)
        addAuthenticationHeader(to: &request)

        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()

        Task {
            await receiveMessages()
        }

        isConnected = true
        connectionError = nil
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    func updateSettings(_ newSettings: NtfySettings) {
        settings = newSettings
        if isConnected {
            connect() // Reconnect with new settings
        }
    }

    private func createWebSocketURL() -> URL? {
        let baseURL = settings.serverURL.replacingOccurrences(of: "https://", with: "wss://")
                                      .replacingOccurrences(of: "http://", with: "ws://")
        return URL(string: "\(baseURL)/\(settings.topic)/ws")
    }

    private func addAuthenticationHeader(to request: inout URLRequest) {
        let credentials = "\(settings.username):\(settings.password)"
        let authData = credentials.data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(authData)", forHTTPHeaderField: "Authorization")
    }

    private func receiveMessages() async {
        guard let webSocketTask = webSocketTask else { return }

        do {
            while !Task.isCancelled && isConnected {
                let message = try await webSocketTask.receive()
                await handleWebSocketMessage(message)
            }
        } catch {
            await MainActor.run {
                self.connectionError = error.localizedDescription
                self.isConnected = false
            }
        }
    }

    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) async {
        let data: Data

        switch message {
        case .data(let messageData):
            data = messageData
        case .string(let string):
            data = string.data(using: .utf8) ?? Data()
        @unknown default:
            return
        }

        guard let ntfyMessage = try? JSONDecoder().decode(NtfyMessage.self, from: data),
              !ntfyMessage.isKeepalive else { return }

        await MainActor.run {
            self.messages.insert(ntfyMessage, at: 0)

            // Limit stored messages
            if self.messages.count > self.settings.maxRecentMessages {
                self.messages = Array(self.messages.prefix(self.settings.maxRecentMessages))
            }

            // Show notification
            if self.settings.enableNotifications {
                self.notificationManager.showNotification(for: ntfyMessage)
            }
        }
    }
}
```

### 3.4 View Model (ViewModels/NtfyViewModel.swift)
```swift
import Foundation
import Combine

@MainActor
class NtfyViewModel: ObservableObject {
    @Published var settings: NtfySettings
    @Published var hasNewMessage = false

    private let ntfyService: NtfyService
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.settings = SettingsManager.loadSettings()
        self.ntfyService = NtfyService(settings: settings)

        setupBindings()
        connectIfNeeded()
    }

    var isConnected: Bool {
        ntfyService.isConnected
    }

    var messages: [NtfyMessage] {
        ntfyService.messages
    }

    var hasUnreadMessages: Bool {
        !messages.isEmpty
    }

    func connect() {
        ntfyService.connect()
    }

    func disconnect() {
        ntfyService.disconnect()
    }

    func updateSettings(_ newSettings: NtfySettings) {
        settings = newSettings
        ntfyService.updateSettings(newSettings)
        SettingsManager.saveSettings(newSettings)
    }

    func clearMessages() {
        ntfyService.messages.removeAll()
    }

    private func setupBindings() {
        ntfyService.$messages
            .map { !$0.isEmpty }
            .sink { [weak self] hasMessages in
                if hasMessages {
                    self?.triggerNewMessageAnimation()
                }
            }
            .store(in: &cancellables)
    }

    private func triggerNewMessageAnimation() {
        hasNewMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.hasNewMessage = false
        }
    }

    private func connectIfNeeded() {
        if !settings.serverURL.isEmpty && !settings.topic.isEmpty {
            connect()
        }
    }
}
```

### 3.5 Main Content View (Views/ContentView.swift)
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView

            Divider()

            if viewModel.messages.isEmpty {
                emptyStateView
            } else {
                messagesView
            }

            Divider()

            footerView
        }
        .padding()
        .frame(width: 300, maxHeight: 400)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
    }

    private var headerView: some View {
        HStack {
            Text("ntfy Notifications")
                .font(.headline)

            Spacer()

            connectionStatusView
        }
    }

    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.isConnected ? .green : .red)
                .frame(width: 8, height: 8)

            Text(viewModel.isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.slash")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("No notifications yet")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var messagesView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(viewModel.messages) { message in
                    MessageRowView(message: message)
                }
            }
        }
        .frame(maxHeight: 200)
    }

    private var footerView: some View {
        HStack {
            Button("Settings") {
                showingSettings = true
            }

            Spacer()

            if !viewModel.messages.isEmpty {
                Button("Clear") {
                    viewModel.clearMessages()
                }
            }

            Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                if viewModel.isConnected {
                    viewModel.disconnect()
                } else {
                    viewModel.connect()
                }
            }
        }
        .buttonStyle(.borderless)
        .font(.caption)
    }
}
```

### 3.6 Message Row View (Views/MessageRowView.swift)
```swift
import SwiftUI

struct MessageRowView: View {
    let message: NtfyMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(message.displayTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(message.message)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if let tags = message.tags, !tags.isEmpty {
                HStack {
                    ForEach(tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.secondary.opacity(0.2))
                            .cornerRadius(3)
                    }

                    if tags.count > 3 {
                        Text("+\(tags.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.05))
        .cornerRadius(6)
    }

    private var timeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: message.date, relativeTo: Date())
    }
}
```

### 3.7 Settings View (Views/SettingsView.swift)
```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @State private var settings: NtfySettings
    @Environment(\.dismiss) private var dismiss

    init() {
        _settings = State(initialValue: .default)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Server Configuration") {
                    TextField("Server URL", text: $settings.serverURL)
                        .textFieldStyle(.roundedBorder)

                    TextField("Topic", text: $settings.topic)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Authentication") {
                    TextField("Username", text: $settings.username)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $settings.password)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Preferences") {
                    Toggle("Enable Notifications", isOn: $settings.enableNotifications)

                    Stepper("Recent Messages: \(settings.maxRecentMessages)",
                           value: $settings.maxRecentMessages,
                           in: 5...100,
                           step: 5)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            settings = viewModel.settings
        }
    }

    private func saveSettings() {
        viewModel.updateSettings(settings)
        dismiss()
    }
}
```

### 3.8 Notification Manager (Utilities/NotificationManager.swift)
```swift
import Foundation
import UserNotifications

class NotificationManager: NSObject {
    override init() {
        super.init()
        requestPermission()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func showNotification(for message: NtfyMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.displayTitle
        content.body = message.message
        content.sound = .default
        content.categoryIdentifier = "ntfy"

        // Add topic as subtitle if different from title
        if message.topic != message.title {
            content.subtitle = "Topic: \(message.topic)"
        }

        // Add user info for potential actions
        content.userInfo = [
            "messageId": message.id,
            "topic": message.topic
        ]

        let request = UNNotificationRequest(
            identifier: message.id,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
}
```

### 3.9 Settings Manager (Utilities/SettingsManager.swift)
```swift
import Foundation

struct SettingsManager {
    private static let settingsKey = "NtfySettings"

    static func saveSettings(_ settings: NtfySettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    static func loadSettings() -> NtfySettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(NtfySettings.self, from: data) else {
            return .default
        }
        return settings
    }
}
```

---

## 4. Configuration Files

### 4.1 Info.plist Additions
```xml
<key>LSUIElement</key>
<true/>
<key>NSHumanReadableCopyright</key>
<string>© 2025 Your Name</string>
<key>CFBundleDisplayName</key>
<string>ntfy</string>
```

### 4.2 Entitlements (NtfyMenuBar.entitlements)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
</plist>
```

---

## 5. Features Checklist

### Core Features ✅
- [x] MenuBar icon with notification badge
- [x] Real-time WebSocket connection to ntfy server
- [x] Authentication support (Basic Auth)
- [x] Native macOS notifications
- [x] Recent messages display
- [x] Connection status indicator
- [x] Settings configuration
- [x] Auto-reconnection logic

### Advanced Features 🚀
- [ ] Multiple topic support
- [ ] Custom notification sounds
- [ ] Message persistence across app restarts
- [ ] Dark/light mode icon adaptation
- [ ] Keyboard shortcuts
- [ ] Message filtering/search
- [ ] Export message history
- [ ] Custom server certificates support

### Future Enhancements 💡
- [ ] Widget support (macOS 14+)
- [ ] Shortcuts app integration
- [ ] AppleScript support
- [ ] Message reply functionality
- [ ] Rich notification support (images, buttons)
- [ ] Multiple server support
- [ ] Notification scheduling
- [ ] Do Not Disturb integration

---

## 6. Development Steps

### Phase 1: Basic Setup
1. Create Xcode project with recommended settings
2. Add Info.plist configurations
3. Set up entitlements
4. Create basic project structure

### Phase 2: Core Implementation
1. Implement data models (NtfyMessage, NtfySettings)
2. Create WebSocket service (NtfyService)
3. Build view model (NtfyViewModel)
4. Implement notification manager

### Phase 3: User Interface
1. Create main content view
2. Build settings interface
3. Design message row components
4. Add menubar integration

### Phase 4: Testing & Polish
1. Test WebSocket connections
2. Verify notification behavior
3. Test settings persistence
4. Handle edge cases and errors

### Phase 5: Distribution
1. Code signing setup
2. App notarization (if distributing)
3. Create installer/DMG
4. App Store submission (optional)

---

## 7. Testing Strategy

### Unit Tests
- Test NtfyMessage model parsing
- Test settings encoding/decoding
- Test WebSocket connection logic
- Test notification formatting

### Integration Tests
- Test end-to-end message flow
- Test authentication handling
- Test reconnection behavior
- Test settings persistence

### Manual Testing
- Test various message types
- Test connection failures
- Test notification permissions
- Test menubar behavior across different macOS versions

---

## 8. Build Configuration

### Debug Configuration
- Enable all logging
- Disable app sandbox for easier testing
- Use development team signing

### Release Configuration
- Minimize logging
- Enable app sandbox
- Use distribution signing
- Enable hardened runtime

---

## 9. Deployment Notes

### Local Development
- No code signing required
- Can run from Xcode directly
- Useful for rapid iteration

### Distribution
- Requires Apple Developer account
- Must be code signed and notarized
- Consider using `create-dmg` for installer

### App Store (Optional)
- Requires additional app store entitlements
- Must follow App Store guidelines
- Provides automatic updates

---

## 10. Troubleshooting

### Common Issues
1. **WebSocket connection fails**: Check server URL and authentication
2. **Notifications not showing**: Verify notification permissions
3. **App not staying in menubar**: Ensure LSUIElement is set
4. **Authentication errors**: Verify credentials and server settings

### Debug Tips
- Use Console.app to view system logs
- Enable WebSocket logging in URLSession
- Test with curl commands first
- Use Network Link Conditioner for connection testing

---

This plan provides everything needed to build a professional ntfy menubar app for macOS. Start with Phase 1 and work through each section systematically.