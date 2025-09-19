//
//  NtfyService.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import Foundation
import Combine

@MainActor
class NtfyService: ObservableObject {
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var messages: [NtfyMessage] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var dataTask: URLSessionDataTask?
    private var settings: NtfySettings
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let notificationManager = NotificationManager.shared
    
    init(settings: NtfySettings) {
        self.settings = settings
    }
    
    func connect() {
        disconnect() // Clean up any existing connection
        
        guard let url = createSSEURL() else {
            connectionError = "Invalid server URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        addAuthenticationHeader(to: &request)
        
        print("🔗 SSE request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("🔗 Full URL: \(url.absoluteString)")
        print("🔗 Auth method: \(settings.authMethod.rawValue)")
        
        switch settings.authMethod {
        case .basicAuth:
            print("🔗 Username: '\(settings.username)'")
            print("🔗 Password length: \(SettingsManager.loadPassword(for: settings.username)?.count ?? 0)")
        case .accessToken:
            print("🔗 Token length: \(SettingsManager.loadAccessToken()?.count ?? 0)")
        }
        
        startSSEConnection(with: request)
        
        isConnected = true
        connectionError = nil
        reconnectAttempts = 0
        
        print("🔗 Connecting to: \(url)")
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        dataTask?.cancel()
        dataTask = nil
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        print("❌ Disconnected from ntfy")
    }
    
    func updateSettings(_ newSettings: NtfySettings) {
        settings = newSettings
        if isConnected {
            connect() // Reconnect with new settings
        }
    }
    
    private func createSSEURL() -> URL? {
        var baseURL = settings.serverURL
        
        // Ensure HTTP/HTTPS protocol
        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            baseURL = "https://" + baseURL
        }
        
        let urlString = "\(baseURL)/\(settings.topic)/json"
        print("🌐 Creating SSE URL: \(urlString)")
        
        return URL(string: urlString)
    }
    
    private func addAuthenticationHeader(to request: inout URLRequest) {
        switch settings.authMethod {
        case .basicAuth:
            guard !settings.username.isEmpty else { return }
            
            let password = SettingsManager.loadPassword(for: settings.username) ?? ""
            let credentials = "\(settings.username):\(password)"
            
            if let authData = credentials.data(using: .utf8) {
                let base64Credentials = authData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }
            
        case .accessToken:
            guard let token = SettingsManager.loadAccessToken(), 
                  SettingsManager.validateAccessToken(token) else { return }
            
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func startSSEConnection(with request: URLRequest) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run { [weak self] in
                        self?.connectionError = "Invalid response type"
                        self?.isConnected = false
                        self?.scheduleReconnect()
                    }
                    return
                }
                
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                print("📡 Response headers: \(httpResponse.allHeaderFields)")
                
                guard httpResponse.statusCode == 200 else {
                    await MainActor.run { [weak self] in
                        self?.connectionError = "HTTP \(httpResponse.statusCode): Authentication or server error"
                        self?.isConnected = false
                        self?.scheduleReconnect()
                    }
                    return
                }
                
                print("✅ SSE connection established")
                
                for try await line in asyncBytes.lines {
                    guard !line.isEmpty else { continue }
                    await handleSSEMessage(line)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.connectionError = error.localizedDescription
                    self?.isConnected = false
                    print("❌ SSE error: \(error)")
                    self?.scheduleReconnect()
                }
            }
        }
    }
    
    private func handleSSEMessage(_ line: String) async {
        guard let data = line.data(using: .utf8) else { return }
        
        do {
            let ntfyMessage = try JSONDecoder().decode(NtfyMessage.self, from: data)
            
            // Skip keepalive and open messages
            guard !ntfyMessage.isKeepalive && ntfyMessage.event != "open" else { 
                print("📋 Skipping \(ntfyMessage.event) event")
                return 
            }
            
            await MainActor.run {
                print("📨 Received message: \(ntfyMessage.message ?? "No message")")
                
                self.messages.insert(ntfyMessage, at: 0)
                
                // Limit stored messages
                if self.messages.count > self.settings.maxRecentMessages {
                    self.messages = Array(self.messages.prefix(self.settings.maxRecentMessages))
                }
                
                // Show notification if enabled
                if self.settings.enableNotifications {
                    self.notificationManager.showNotification(for: ntfyMessage)
                }
            }
        } catch {
            print("❌ Failed to decode message: \(error)")
            print("Raw data: \(line)")
        }
    }
    
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionError = "Failed to reconnect after \(maxReconnectAttempts) attempts"
            return
        }
        
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Exponential backoff, max 30s
        
        print("🔄 Scheduling reconnect attempt \(reconnectAttempts) in \(delay) seconds")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.connect()
            }
        }
    }
}