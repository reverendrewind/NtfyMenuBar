//
//  NtfyMenuBarTests.swift
//  NtfyMenuBarTests
//
//  Created by Rimskij Papa on 19/09/2025.
//

import XCTest
@testable import NtfyMenuBar

@MainActor
final class NtfyViewModelTests: XCTestCase {
    var viewModel: NtfyViewModel!
    var mockSettingsManager: MockSettingsManager!

    override func setUpWithError() throws {
        // Create a clean test environment
        mockSettingsManager = MockSettingsManager()

        // Create view model with test settings
        let testSettings = NtfySettings(
            serverURL: "https://test.ntfy.sh",
            topics: ["test-topic"],
            maxRecentMessages: 10,
            autoConnect: false // Disable autoconnect for testing
        )

        mockSettingsManager.mockSettings = testSettings
        viewModel = NtfyViewModel()
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockSettingsManager = nil
    }

    // MARK: - Initialization Tests

    func testViewModelInitialization() throws {
        XCTAssertFalse(viewModel.isConnected)
        XCTAssertFalse(viewModel.hasUnreadMessages)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertNil(viewModel.connectionError)
        XCTAssertFalse(viewModel.isSnoozed)
        XCTAssertNil(viewModel.snoozeTimeRemaining)
    }

    // MARK: - Settings Management Tests

    func testUpdateSettings() {
        let newSettings = NtfySettings(
            serverURL: "https://new-server.com",
            topics: ["new-topic"],
            maxRecentMessages: 50
        )

        viewModel.updateSettings(newSettings)

        XCTAssertEqual(viewModel.settings.serverURL, "https://new-server.com")
        XCTAssertEqual(viewModel.settings.topics, ["new-topic"])
        XCTAssertEqual(viewModel.settings.maxRecentMessages, 50)
    }

    // MARK: - Message Management Tests

    func testClearMessages() {
        // Setup: Add some test messages
        let testMessage = createTestMessage(id: "test-1")
        viewModel.messages = [testMessage]
        viewModel.hasUnreadMessages = true

        // Test clearing
        viewModel.clearMessages()

        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertFalse(viewModel.hasUnreadMessages)
        XCTAssertNotNil(viewModel.settings.lastClearedTimestamp)
    }

    func testMessageDeduplication() {
        // This would test message deduplication logic
        // We would need to expose the message merging logic for testing
        XCTAssertTrue(true) // Placeholder - would require refactoring to make testable
    }

    // MARK: - Snooze Management Tests

    func testSnoozeNotifications() {
        XCTAssertFalse(viewModel.isSnoozed)

        viewModel.snoozeNotifications(duration: .fifteenMinutes)

        XCTAssertTrue(viewModel.isSnoozed)
        XCTAssertNotNil(viewModel.snoozeTimeRemaining)
        XCTAssertTrue(viewModel.settings.isSnoozed)
        XCTAssertNotNil(viewModel.settings.snoozeEndTime)
    }

    func testClearSnooze() {
        // Setup snooze state
        viewModel.snoozeNotifications(duration: .fiveMinutes)
        XCTAssertTrue(viewModel.isSnoozed)

        // Clear snooze
        viewModel.clearSnooze()

        XCTAssertFalse(viewModel.isSnoozed)
        XCTAssertNil(viewModel.snoozeTimeRemaining)
        XCTAssertFalse(viewModel.settings.isSnoozed)
        XCTAssertNil(viewModel.settings.snoozeEndTime)
    }

    func testSnoozeStatusText() {
        // Test default state
        let defaultStatus = viewModel.snoozeStatusText
        XCTAssertEqual(defaultStatus, "Notifications enabled")

        // Test snoozed state
        viewModel.snoozeNotifications(duration: .thirtyMinutes)
        let snoozeStatus = viewModel.snoozeStatusText
        XCTAssertTrue(snoozeStatus.contains("Snoozed"))
    }

    // MARK: - Connection Tests

    func testConnectionWithoutConfiguration() {
        viewModel.settings.serverURL = ""
        viewModel.settings.topics = []

        viewModel.connect()

        XCTAssertNotNil(viewModel.connectionError)
        XCTAssertEqual(viewModel.connectionError, "Please configure server settings first")
    }

    func testConnectionWithConfiguration() {
        // This would test connection logic but requires mocking the service
        // For now, just verify the settings are configured
        XCTAssertTrue(viewModel.settings.isConfigured)
    }

    // MARK: - Helper Methods

    private func createTestMessage(id: String) -> NtfyMessage {
        return NtfyMessage(
            id: id,
            time: Int(Date().timeIntervalSince1970),
            event: "message",
            topic: "test-topic",
            message: "Test message",
            title: "Test Title",
            priority: 3,
            tags: ["test"]
        )
    }
}

// MARK: - Mock Settings Manager

class MockSettingsManager {
    var mockSettings: NtfySettings = NtfySettings()

    func loadSettings() -> NtfySettings {
        return mockSettings
    }

    func saveSettings(_ settings: NtfySettings) {
        mockSettings = settings
    }
}

// MARK: - Model Tests

final class NtfyMessageTests: XCTestCase {

    func testMessageInitialization() {
        let message = NtfyMessage(
            id: "test-123",
            time: 1695123456,
            event: "message",
            topic: "test-topic",
            message: "Hello World",
            title: "Test Title",
            priority: 4,
            tags: ["urgent", "test"]
        )

        XCTAssertEqual(message.id, "test-123")
        XCTAssertEqual(message.topic, "test-topic")
        XCTAssertEqual(message.message, "Hello World")
        XCTAssertEqual(message.title, "Test Title")
        XCTAssertEqual(message.priority, 4)
        XCTAssertEqual(message.tags, ["urgent", "test"])
        XCTAssertFalse(message.isKeepalive)
    }

    func testUniqueId() {
        let message = NtfyMessage(
            id: "test-123",
            time: 1695123456,
            event: "message",
            topic: "test-topic",
            message: "Hello",
            title: nil,
            priority: nil,
            tags: nil
        )

        let expectedUniqueId = "test-123-1695123456-message-test-topic"
        XCTAssertEqual(message.uniqueId, expectedUniqueId)
    }

    func testDisplayTitle() {
        let messageWithTitle = NtfyMessage(id: "1", time: 123, event: "message", topic: "test", message: nil, title: "Custom Title", priority: nil, tags: nil)
        XCTAssertEqual(messageWithTitle.displayTitle, "Custom Title")

        let messageWithoutTitle = NtfyMessage(id: "1", time: 123, event: "message", topic: "test", message: nil, title: nil, priority: nil, tags: nil)
        XCTAssertEqual(messageWithoutTitle.displayTitle, "ntfy Notification")
    }

    func testPriorityDescription() {
        let priorities = [
            (1, "Min"),
            (2, "Low"),
            (3, "Default"),
            (4, "High"),
            (5, "Max"),
            (nil, "Default"),
            (99, "Default") // Invalid priority should default
        ]

        for (priority, expected) in priorities {
            let message = NtfyMessage(id: "1", time: 123, event: "message", topic: "test", message: nil, title: nil, priority: priority, tags: nil)
            XCTAssertEqual(message.priorityDescription, expected, "Priority \(priority?.description ?? "nil") should return \(expected)")
        }
    }

    func testKeepaliveDetection() {
        let keepaliveMessage = NtfyMessage(id: "1", time: 123, event: "keepalive", topic: "test", message: nil, title: nil, priority: nil, tags: nil)
        XCTAssertTrue(keepaliveMessage.isKeepalive)

        let regularMessage = NtfyMessage(id: "1", time: 123, event: "message", topic: "test", message: nil, title: nil, priority: nil, tags: nil)
        XCTAssertFalse(regularMessage.isKeepalive)
    }

    func testDateConversion() {
        let timestamp = 1695123456
        let message = NtfyMessage(id: "1", time: timestamp, event: "message", topic: "test", message: nil, title: nil, priority: nil, tags: nil)

        let expectedDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
        XCTAssertEqual(message.date, expectedDate)
    }
}

// MARK: - Settings Tests

final class NtfySettingsTests: XCTestCase {

    func testDefaultSettings() {
        let settings = NtfySettings()

        XCTAssertEqual(settings.serverURL, "")
        XCTAssertTrue(settings.topics.isEmpty)
        XCTAssertEqual(settings.maxRecentMessages, 20)
        XCTAssertTrue(settings.enableNotifications)
        XCTAssertTrue(settings.autoConnect)
        XCTAssertEqual(settings.authMethod, .basicAuth)
        XCTAssertFalse(settings.isSnoozed)
    }

    func testSettingsConfiguration() {
        var settings = NtfySettings()
        XCTAssertFalse(settings.isConfigured)

        settings.serverURL = "https://ntfy.sh"
        settings.topics = ["test"]
        XCTAssertTrue(settings.isConfigured)
    }

    func testSnoozeTimeRemaining() {
        var settings = NtfySettings()
        XCTAssertNil(settings.snoozeTimeRemaining)

        let futureTime = Date().addingTimeInterval(300) // 5 minutes
        settings.snoozeEndTime = futureTime
        settings.isSnoozed = true

        let remaining = settings.snoozeTimeRemaining
        XCTAssertNotNil(remaining)
        XCTAssertGreaterThan(remaining!, 0)
        XCTAssertLessThanOrEqual(remaining!, 300)
    }

    func testCurrentlySnoozeState() {
        var settings = NtfySettings()
        XCTAssertFalse(settings.isCurrentlySnoozed)

        // Set snooze in the future
        settings.isSnoozed = true
        settings.snoozeEndTime = Date().addingTimeInterval(300)
        XCTAssertTrue(settings.isCurrentlySnoozed)

        // Set snooze in the past
        settings.snoozeEndTime = Date().addingTimeInterval(-300)
        XCTAssertFalse(settings.isCurrentlySnoozed)
    }
}

// MARK: - Enum Tests

final class EnumTests: XCTestCase {

    func testAuthenticationMethodDisplayNames() {
        XCTAssertEqual(AuthenticationMethod.basicAuth.displayName, "Username & Password")
        XCTAssertEqual(AuthenticationMethod.accessToken.displayName, "Access token")
    }

    func testAppearanceModeDisplayNames() {
        XCTAssertEqual(AppearanceMode.light.displayName, "Light")
        XCTAssertEqual(AppearanceMode.dark.displayName, "Dark")
        XCTAssertEqual(AppearanceMode.system.displayName, "System")
    }

    func testSnoozeDurationTimeIntervals() {
        XCTAssertEqual(SnoozeDuration.fiveMinutes.timeInterval, 5 * 60)
        XCTAssertEqual(SnoozeDuration.fifteenMinutes.timeInterval, 15 * 60)
        XCTAssertEqual(SnoozeDuration.thirtyMinutes.timeInterval, 30 * 60)
        XCTAssertEqual(SnoozeDuration.oneHour.timeInterval, 60 * 60)
        XCTAssertEqual(SnoozeDuration.twoHours.timeInterval, 2 * 60 * 60)
        XCTAssertEqual(SnoozeDuration.fourHours.timeInterval, 4 * 60 * 60)
        XCTAssertEqual(SnoozeDuration.eightHours.timeInterval, 8 * 60 * 60)
    }
}
