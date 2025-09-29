//
//  SettingsManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import Foundation
import Security

struct SettingsManager {
    private static let settingsKey = "NtfySettings"
    private static let passwordKey = "NtfyPassword"
    private static let tokenKey = "NtfyAccessToken"
    static func saveSettings(_ settings: NtfySettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    static func loadSettings() -> NtfySettings {
        print("🔍 SettingsManager.loadSettings() called")

        // Try loading from current UserDefaults first
        if let data = UserDefaults.standard.data(forKey: settingsKey) {
            print("🔍 Found settings data in standard UserDefaults: \(data.count) bytes")
            do {
                let settings = try JSONDecoder().decode(NtfySettings.self, from: data)
                print("🔍 Successfully decoded settings from standard: serverURL=\(settings.serverURL), topics=\(settings.topics), username=\(settings.username)")
                Logger.shared.info("⚙️ Loaded settings: serverURL=\(settings.serverURL), topics=\(settings.topics)")
                return settings
            } catch {
                print("🔍 Failed to decode settings from standard: \(error)")
            }
        }

        // Try to directly read from the sandboxed plist file
        let sandboxedPlistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/net.raczej.NtfyMenuBar/Data/Library/Preferences/net.raczej.NtfyMenuBar.plist")

        if FileManager.default.fileExists(atPath: sandboxedPlistPath.path),
           let plistData = NSDictionary(contentsOf: sandboxedPlistPath),
           let settingsData = plistData[settingsKey] as? Data {
            print("🔍 Found settings data in sandboxed plist: \(settingsData.count) bytes")
            do {
                let settings = try JSONDecoder().decode(NtfySettings.self, from: settingsData)
                print("🔍 Successfully decoded settings from sandboxed plist: serverURL=\(settings.serverURL), topics=\(settings.topics), username=\(settings.username)")

                // Migrate to standard UserDefaults for future use
                UserDefaults.standard.set(settingsData, forKey: settingsKey)
                print("🔍 Migrated settings from sandbox to standard UserDefaults")

                Logger.shared.info("⚙️ Loaded settings: serverURL=\(settings.serverURL), topics=\(settings.topics)")
                return settings
            } catch {
                print("🔍 Failed to decode settings from sandboxed plist: \(error)")
            }
        }

        print("🔍 No settings data found in any UserDefaults location")
        Logger.shared.info("⚙️ No settings data found in UserDefaults")
        return .default
    }
    
    static func savePassword(_ password: String, for username: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecAttrService as String: passwordKey,
            kSecValueData as String: password.data(using: .utf8) ?? Data()
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadPassword(for username: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecAttrService as String: passwordKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    static func deletePassword(for username: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecAttrService as String: passwordKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Access Token Management
    
    static func saveAccessToken(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "access_token",
            kSecAttrService as String: tokenKey,
            kSecValueData as String: token.data(using: .utf8) ?? Data()
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "access_token",
            kSecAttrService as String: tokenKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    static func deleteAccessToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "access_token",
            kSecAttrService as String: tokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    static func validateAccessToken(_ token: String) -> Bool {
        // ntfy tokens must start with "tk_" and be 32 characters long
        return token.hasPrefix("tk_") && token.count == 32
    }
}