//
//  SettingsManagerTests.swift
//  NtfyMenuBarTests
//
//  Created by Rimskij Papa on 29/09/2025.
//

import XCTest
@testable import NtfyMenuBar

final class SettingsManagerTests: XCTestCase {

    // MARK: - Settings Persistence Tests

    func testSaveAndLoadSettings() {
        var testSettings = NtfySettings()
        testSettings.serverURL = "https://test.ntfy.sh"
        testSettings.topics = ["topic1", "topic2"]
        testSettings.maxRecentMessages = 30
        testSettings.enableNotifications = false
        testSettings.autoConnect = true
        testSettings.authMethod = .accessToken
        testSettings.username = "testuser"
        testSettings.isSnoozed = false
        testSettings.snoozeEndTime = nil
        testSettings.lastClearedTimestamp = Date()

        SettingsManager.saveSettings(testSettings)

        let loadedSettings = SettingsManager.loadSettings()

        XCTAssertEqual(loadedSettings.serverURL, testSettings.serverURL)
        XCTAssertEqual(loadedSettings.topics, testSettings.topics)
        XCTAssertEqual(loadedSettings.maxRecentMessages, testSettings.maxRecentMessages)
        XCTAssertEqual(loadedSettings.enableNotifications, testSettings.enableNotifications)
        XCTAssertEqual(loadedSettings.autoConnect, testSettings.autoConnect)
        XCTAssertEqual(loadedSettings.authMethod, testSettings.authMethod)
        XCTAssertEqual(loadedSettings.username, testSettings.username)
    }

    func testLoadDefaultSettingsWhenNoDataExists() {
        // Clear any existing settings
        UserDefaults.standard.removeObject(forKey: "NtfySettings")
        UserDefaults.standard.synchronize()

        let loadedSettings = SettingsManager.loadSettings()

        // Should return default settings
        XCTAssertEqual(loadedSettings.serverURL, NtfySettings.default.serverURL)
        XCTAssertEqual(loadedSettings.topics, NtfySettings.default.topics)
        XCTAssertEqual(loadedSettings.maxRecentMessages, NtfySettings.default.maxRecentMessages)
    }

    // MARK: - Keychain Password Tests

    func testSaveAndLoadPassword() {
        let username = "testuser_\(UUID().uuidString)"
        let password = "testPassword123!"

        SettingsManager.savePassword(password, for: username)

        let loadedPassword = SettingsManager.loadPassword(for: username)

        XCTAssertEqual(loadedPassword, password)

        // Clean up
        SettingsManager.deletePassword(for: username)
    }

    func testLoadPasswordReturnsNilWhenNotExists() {
        let username = "nonexistent_\(UUID().uuidString)"

        let loadedPassword = SettingsManager.loadPassword(for: username)

        XCTAssertNil(loadedPassword)
    }

    func testUpdateExistingPassword() {
        let username = "testuser_\(UUID().uuidString)"
        let originalPassword = "originalPassword"
        let newPassword = "newPassword123"

        SettingsManager.savePassword(originalPassword, for: username)
        XCTAssertEqual(SettingsManager.loadPassword(for: username), originalPassword)

        SettingsManager.savePassword(newPassword, for: username)
        let loadedPassword = SettingsManager.loadPassword(for: username)

        XCTAssertEqual(loadedPassword, newPassword)
        XCTAssertNotEqual(loadedPassword, originalPassword)

        // Clean up
        SettingsManager.deletePassword(for: username)
    }

    func testDeletePassword() {
        let username = "testuser_\(UUID().uuidString)"
        let password = "passwordToDelete"

        SettingsManager.savePassword(password, for: username)
        XCTAssertNotNil(SettingsManager.loadPassword(for: username))

        SettingsManager.deletePassword(for: username)

        XCTAssertNil(SettingsManager.loadPassword(for: username))
    }

    func testPasswordWithSpecialCharacters() {
        let username = "testuser_\(UUID().uuidString)"
        let password = "P@$$w0rd!#$%^&*()_+-=[]{}|;:',.<>?/~`"

        SettingsManager.savePassword(password, for: username)

        let loadedPassword = SettingsManager.loadPassword(for: username)

        XCTAssertEqual(loadedPassword, password)

        // Clean up
        SettingsManager.deletePassword(for: username)
    }

    func testPasswordWithEmoji() {
        let username = "testuser_\(UUID().uuidString)"
        let password = "🔐Password123!😀🚀"

        SettingsManager.savePassword(password, for: username)

        let loadedPassword = SettingsManager.loadPassword(for: username)

        XCTAssertEqual(loadedPassword, password)

        // Clean up
        SettingsManager.deletePassword(for: username)
    }

    // MARK: - Keychain Access Token Tests

    func testSaveAndLoadAccessToken() {
        let token = "tk_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(28))"

        SettingsManager.saveAccessToken(token)

        let loadedToken = SettingsManager.loadAccessToken()

        XCTAssertEqual(loadedToken, token)

        // Clean up
        SettingsManager.deleteAccessToken()
    }

    func testLoadAccessTokenReturnsNilWhenNotExists() {
        // Delete any existing token
        SettingsManager.deleteAccessToken()

        let loadedToken = SettingsManager.loadAccessToken()

        XCTAssertNil(loadedToken)
    }

    func testUpdateExistingAccessToken() {
        let originalToken = "tk_originaltoken1234567890abcdef"
        let newToken = "tk_newtoken1234567890abcdefghijk"

        SettingsManager.saveAccessToken(originalToken)
        XCTAssertEqual(SettingsManager.loadAccessToken(), originalToken)

        SettingsManager.saveAccessToken(newToken)
        let loadedToken = SettingsManager.loadAccessToken()

        XCTAssertEqual(loadedToken, newToken)
        XCTAssertNotEqual(loadedToken, originalToken)

        // Clean up
        SettingsManager.deleteAccessToken()
    }

    func testDeleteAccessToken() {
        let token = "tk_tokenToDelete1234567890abcdef"

        SettingsManager.saveAccessToken(token)
        XCTAssertNotNil(SettingsManager.loadAccessToken())

        SettingsManager.deleteAccessToken()

        XCTAssertNil(SettingsManager.loadAccessToken())
    }

    // MARK: - Access Token Validation Tests

    func testValidateAccessTokenWithValidToken() {
        let validToken = "tk_12345678901234567890123456789012"

        XCTAssertTrue(SettingsManager.validateAccessToken(validToken))
    }

    func testValidateAccessTokenWithInvalidPrefix() {
        let invalidToken = "invalid_1234567890123456789012"

        XCTAssertFalse(SettingsManager.validateAccessToken(invalidToken))
    }

    func testValidateAccessTokenWithInvalidLength() {
        let shortToken = "tk_short"
        let longToken = "tk_thisTokenIsTooLongToBeValidForNtfy"

        XCTAssertFalse(SettingsManager.validateAccessToken(shortToken))
        XCTAssertFalse(SettingsManager.validateAccessToken(longToken))
    }

    func testValidateAccessTokenWithEmptyString() {
        XCTAssertFalse(SettingsManager.validateAccessToken(""))
    }

    // MARK: - Multiple Users Tests

    func testPasswordsForMultipleUsers() {
        let user1 = "user1_\(UUID().uuidString)"
        let user2 = "user2_\(UUID().uuidString)"
        let password1 = "password1"
        let password2 = "password2"

        SettingsManager.savePassword(password1, for: user1)
        SettingsManager.savePassword(password2, for: user2)

        XCTAssertEqual(SettingsManager.loadPassword(for: user1), password1)
        XCTAssertEqual(SettingsManager.loadPassword(for: user2), password2)

        // Delete one user's password shouldn't affect the other
        SettingsManager.deletePassword(for: user1)

        XCTAssertNil(SettingsManager.loadPassword(for: user1))
        XCTAssertEqual(SettingsManager.loadPassword(for: user2), password2)

        // Clean up
        SettingsManager.deletePassword(for: user2)
    }

    // MARK: - Edge Cases Tests

    func testEmptyPassword() {
        let username = "testuser_\(UUID().uuidString)"
        let emptyPassword = ""

        SettingsManager.savePassword(emptyPassword, for: username)

        let loadedPassword = SettingsManager.loadPassword(for: username)

        XCTAssertEqual(loadedPassword, emptyPassword)

        // Clean up
        SettingsManager.deletePassword(for: username)
    }

    func testVeryLongPassword() {
        let username = "testuser_\(UUID().uuidString)"
        let longPassword = String(repeating: "a", count: 10000)

        SettingsManager.savePassword(longPassword, for: username)

        let loadedPassword = SettingsManager.loadPassword(for: username)

        XCTAssertEqual(loadedPassword, longPassword)

        // Clean up
        SettingsManager.deletePassword(for: username)
    }

    func testConcurrentKeychainAccess() {
        let expectation = XCTestExpectation(description: "Concurrent keychain operations")
        let username = "concurrent_\(UUID().uuidString)"
        let iterations = 10
        var successCount = 0

        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let group = DispatchGroup()

        for i in 0..<iterations {
            group.enter()
            queue.async {
                let password = "password_\(i)"
                SettingsManager.savePassword(password, for: username)

                if SettingsManager.loadPassword(for: username) != nil {
                    successCount += 1
                }

                group.leave()
            }
        }

        group.notify(queue: .main) {
            XCTAssertGreaterThan(successCount, 0)

            // Clean up
            SettingsManager.deletePassword(for: username)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}