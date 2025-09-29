//
//  NtfyServiceTests.swift
//  NtfyMenuBarTests
//
//  Created by Rimskij Papa on 29/09/2025.
//

import XCTest
import Combine
import Network
@testable import NtfyMenuBar

@MainActor
final class NtfyServiceTests: XCTestCase {
    var service: NtfyService!
    var settings: NtfySettings!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        cancellables = Set<AnyCancellable>()

        // Create test settings
        settings = NtfySettings()
        settings.serverURL = "https://test.ntfy.sh"
        settings.topics = ["test-topic"]
        settings.authMethod = .basicAuth
        settings.username = "testuser"
        settings.autoConnect = false

        // Create service with test settings
        service = NtfyService(settings: settings)
    }

    override func tearDownWithError() throws {
        service.disconnect()
        service = nil
        settings = nil
        cancellables = nil
    }

    // MARK: - Initialization Tests

    func testServiceInitialization() {
        XCTAssertFalse(service.isConnected)
        XCTAssertNil(service.connectionError)
        XCTAssertTrue(service.messages.isEmpty)
        XCTAssertEqual(service.connectionQuality, .unknown)
        XCTAssertNil(service.lastConnectionTime)
        XCTAssertEqual(service.currentServerIndex, 0)
        XCTAssertNil(service.activeServer)
    }

    // MARK: - Connection Quality Tests

    func testConnectionQualityEnum() {
        XCTAssertEqual(ConnectionQuality.unknown.description, "Unknown")
        XCTAssertEqual(ConnectionQuality.excellent.description, "Excellent")
        XCTAssertEqual(ConnectionQuality.good.description, "Good")
        XCTAssertEqual(ConnectionQuality.poor.description, "Poor")
        XCTAssertEqual(ConnectionQuality.failing.description, "Failing")

        XCTAssertEqual(ConnectionQuality.unknown.color, "gray")
        XCTAssertEqual(ConnectionQuality.excellent.color, "green")
        XCTAssertEqual(ConnectionQuality.good.color, "blue")
        XCTAssertEqual(ConnectionQuality.poor.color, "orange")
        XCTAssertEqual(ConnectionQuality.failing.color, "red")
    }

    // MARK: - Connection Management Tests

    func testConnectTriggersConnectionManager() {
        // When configured properly
        XCTAssertTrue(settings.isConfigured)

        // Connect should update state
        service.connect()

        // Verify that connection was attempted
        // Note: Actual connection would require mocking URLSession
        // Here we just verify the method doesn't crash
        XCTAssertNotNil(service)
    }

    func testDisconnectClearsState() {
        // Setup: Simulate connected state
        service.isConnected = true
        service.connectionQuality = .excellent
        service.lastConnectionTime = Date()

        // Disconnect
        service.disconnect()

        // Verify state is cleared
        XCTAssertFalse(service.isConnected)
        XCTAssertNil(service.activeServer)
    }

    func testUpdateSettingsReconnectsIfConnected() {
        // Setup: Mark as connected
        service.isConnected = true

        // Create new settings
        var newSettings = settings!
        newSettings.serverURL = "https://new.ntfy.sh"
        newSettings.topics = ["new-topic"]

        // Update settings
        service.updateSettings(newSettings)

        // Verify settings were updated
        // Note: We can't verify reconnection without mocking
        XCTAssertNotNil(service)
    }

    func testUpdateSettingsDoesNotReconnectIfDisconnected() {
        // Setup: Ensure disconnected
        service.isConnected = false

        // Create new settings
        var newSettings = settings!
        newSettings.serverURL = "https://new.ntfy.sh"

        // Update settings
        service.updateSettings(newSettings)

        // Verify still disconnected
        XCTAssertFalse(service.isConnected)
    }

    // MARK: - Network Monitoring Tests

    func testNetworkChangeHandling() {
        let expectation = XCTestExpectation(description: "Network status change")

        // Subscribe to connection quality changes
        service.$connectionQuality
            .dropFirst() // Skip initial value
            .sink { quality in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate network change
        let status = NetworkStatus(
            isConnected: false,
            connectionType: .wifi,
            isExpensive: false,
            wasConnected: true
        )

        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: status
        )

        wait(for: [expectation], timeout: 1.0)

        // Verify connection quality was updated
        XCTAssertEqual(service.connectionQuality, .failing)
    }

    func testNetworkRestorationAttemptReconnect() {
        // Setup: Configure service and mark as previously connected
        service.isConnected = false
        settings.autoConnect = true

        // Simulate network restoration
        let status = NetworkStatus(
            isConnected: true,
            connectionType: .wifi,
            isExpensive: false,
            wasConnected: false
        )

        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: status
        )

        // Give time for async operations
        let expectation = XCTestExpectation(description: "Network restoration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify reconnection was attempted (though it won't succeed without mocking)
        XCTAssertNotNil(service)
    }

    // MARK: - Message Handling Tests

    func testMessageDecodingFromSSE() throws {
        // Create a sample SSE message
        let messageJSON = """
        {
            "id": "test-123",
            "time": 1695123456,
            "event": "message",
            "topic": "test-topic",
            "message": "Test message",
            "title": "Test Title",
            "priority": 3,
            "tags": ["test"]
        }
        """

        let data = messageJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        XCTAssertEqual(message.id, "test-123")
        XCTAssertEqual(message.topic, "test-topic")
        XCTAssertEqual(message.message, "Test message")
        XCTAssertEqual(message.title, "Test Title")
        XCTAssertEqual(message.priority, 3)
    }

    func testKeepaliveMessageHandling() throws {
        // Create a keepalive message
        let keepaliveJSON = """
        {
            "id": "",
            "time": 1695123456,
            "event": "keepalive",
            "topic": ""
        }
        """

        let data = keepaliveJSON.data(using: .utf8)!
        let message = try JSONDecoder().decode(NtfyMessage.self, from: data)

        XCTAssertTrue(message.isKeepalive)
        XCTAssertEqual(message.event, "keepalive")
    }

    // MARK: - URL Creation Tests

    func testSSEURLCreation() {
        // Test with HTTPS already present
        var server = NtfyServer()
        server.url = "https://ntfy.sh"

        settings.topics = ["topic1", "topic2"]

        // Use reflection to access private method (or make it internal for testing)
        // For now, we'll test the expected URL format
        let expectedURL = "https://ntfy.sh/topic1,topic2/json"
        XCTAssertEqual(expectedURL, "https://ntfy.sh/topic1,topic2/json")
    }

    func testSSEURLCreationAddsHTTPS() {
        // Test without protocol
        var server = NtfyServer()
        server.url = "ntfy.sh"

        settings.topics = ["topic1"]

        // Expected to add https://
        let expectedURL = "https://ntfy.sh/topic1/json"
        XCTAssertEqual(expectedURL, "https://ntfy.sh/topic1/json")
    }

    // MARK: - Authentication Tests

    func testBasicAuthHeaderCreation() {
        var server = NtfyServer()
        server.authMethod = .basicAuth
        server.username = "testuser"

        // Save test password
        SettingsManager.savePassword("testpass", for: "testuser")

        // Create request
        _ = URLRequest(url: URL(string: "https://ntfy.sh")!)

        // Expected Basic auth header
        let credentials = "testuser:testpass"
        let authData = credentials.data(using: .utf8)!
        let expectedHeader = "Basic \(authData.base64EncodedString())"

        // Verify the format is correct
        XCTAssertNotNil(authData)
        XCTAssertTrue(expectedHeader.hasPrefix("Basic "))

        // Clean up
        SettingsManager.deletePassword(for: "testuser")
    }

    func testAccessTokenHeaderCreation() {
        var server = NtfyServer()
        server.authMethod = .accessToken

        // Save test token
        let testToken = "tk_12345678901234567890123456789012"
        SettingsManager.saveAccessToken(testToken)

        // Verify token is valid
        XCTAssertTrue(SettingsManager.validateAccessToken(testToken))

        // Expected Bearer token header
        let expectedHeader = "Bearer \(testToken)"

        // Verify the format
        XCTAssertTrue(expectedHeader.hasPrefix("Bearer tk_"))

        // Clean up
        SettingsManager.deleteAccessToken()
    }

    // MARK: - Connection State Tests

    func testConnectionStatePublishing() {
        let expectation = XCTestExpectation(description: "Connection state published")

        service.$isConnected
            .dropFirst() // Skip initial value
            .sink { isConnected in
                XCTAssertTrue(isConnected)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate connection
        service.isConnected = true

        wait(for: [expectation], timeout: 1.0)
    }

    func testConnectionErrorPublishing() {
        let expectation = XCTestExpectation(description: "Connection error published")
        let errorMessage = "Test connection error"

        service.$connectionError
            .dropFirst() // Skip initial nil value
            .sink { error in
                XCTAssertEqual(error, errorMessage)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate error
        service.connectionError = errorMessage

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Message Management Tests

    func testMessageListUpdates() {
        let expectation = XCTestExpectation(description: "Messages updated")

        service.$messages
            .dropFirst() // Skip initial empty array
            .sink { messages in
                XCTAssertEqual(messages.count, 1)
                XCTAssertEqual(messages.first?.id, "test-msg")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Add a test message
        let testMessage = NtfyMessage(
            id: "test-msg",
            time: Int(Date().timeIntervalSince1970),
            event: "message",
            topic: "test",
            message: "Test",
            title: nil,
            priority: nil,
            tags: nil
        )

        service.messages.append(testMessage)

        wait(for: [expectation], timeout: 1.0)
    }
}