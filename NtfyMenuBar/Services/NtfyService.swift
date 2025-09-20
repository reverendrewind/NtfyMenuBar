//
//  NtfyService.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import Foundation
import Combine
import Network

enum ConnectionQuality {
    case unknown
    case excellent  // Recent successful connection, low latency
    case good       // Stable connection, normal response times
    case poor       // Intermittent issues, slower responses
    case failing    // Frequent disconnections, high latency

    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .poor: return "Poor"
        case .failing: return "Failing"
        }
    }

    var color: String {
        switch self {
        case .unknown: return "gray"
        case .excellent: return "green"
        case .good: return "blue"
        case .poor: return "orange"
        case .failing: return "red"
        }
    }
}

@MainActor
class NtfyService: ObservableObject {
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var messages: [NtfyMessage] = []
    @Published var connectionQuality: ConnectionQuality = .unknown
    @Published var lastConnectionTime: Date?
    @Published var currentServerIndex = 0
    @Published var activeServer: NtfyServer?

    private var webSocketTask: URLSessionWebSocketTask?
    private var dataTask: URLSessionDataTask?
    private var settings: NtfySettings
    private var reconnectTimer: Timer?
    private var fallbackTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3 // Reduced to try fallbacks faster
    private let notificationManager = NotificationManager.shared
    private var keepaliveTimer: Timer?
    private var networkMonitor: NetworkMonitor = .shared
    private var networkCancellable: AnyCancellable?
    private var connectionStartTime: Date?
    private var lastMessageTime: Date?
    private var connectionAttemptsSinceLastSuccess = 0
    private var serverFailureTimes: [String: Date] = [:]
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 0
        config.timeoutIntervalForResource = 0
        config.waitsForConnectivity = true
        config.networkServiceType = .background
        return URLSession(configuration: config)
    }()
    
    init(settings: NtfySettings) {
        self.settings = settings
        setupNetworkMonitoring()
    }

    private func setupNetworkMonitoring() {
        // Monitor network changes and respond accordingly
        networkCancellable = NotificationCenter.default
            .publisher(for: .networkStatusChanged)
            .sink { [weak self] notification in
                guard let networkStatus = notification.object as? NetworkStatus else { return }
                Task { @MainActor [weak self] in
                    self?.handleNetworkChange(networkStatus)
                }
            }
    }

    private func handleNetworkChange(_ status: NetworkStatus) {
        print("🌐 Network change detected: \(status.connectionDescription)")

        if status.isConnected && !status.wasConnected {
            // Network came back online
            print("🌐 Network restored - attempting reconnection")
            if !isConnected && settings.isConfigured {
                // Reset reconnect attempts since network is back
                reconnectAttempts = 0
                connect()
            }
        } else if !status.isConnected && status.wasConnected {
            // Network went offline
            print("🌐 Network lost - connection will be affected")
            updateConnectionQuality(.failing)
        }

        // Update connection quality based on network type
        if status.isConnected {
            if status.isExpensive {
                updateConnectionQuality(.poor)
            } else if isConnected {
                // Maintain current quality or improve if connection is stable
                if connectionQuality == .failing {
                    updateConnectionQuality(.good)
                }
            }
        }
    }
    
    func connect() {
        disconnect() // Clean up any existing connection
        currentServerIndex = 0 // Start with primary server
        tryConnectToServer()
    }

    private func tryConnectToServer() {
        let availableServers = settings.allServers

        guard currentServerIndex < availableServers.count else {
            connectionError = "All servers failed - no more fallbacks available"
            updateConnectionQuality(.failing)
            scheduleRetryAllServers()
            return
        }

        let server = availableServers[currentServerIndex]
        activeServer = server

        // Check if server recently failed and should be skipped temporarily
        if let failureTime = serverFailureTimes[server.url],
           Date().timeIntervalSince(failureTime) < settings.fallbackRetryDelay {
            print("🚫 Skipping server \(server.displayName) - recently failed")
            currentServerIndex += 1
            tryConnectToServer()
            return
        }

        guard let url = createSSEURL(for: server) else {
            connectionError = "Invalid server URL: \(server.url)"
            updateConnectionQuality(.failing)
            tryNextServer()
            return
        }

        connectionStartTime = Date()
        updateConnectionQuality(.unknown)

        var request = URLRequest(url: url)
        request.timeoutInterval = 15 // Shorter timeout for faster fallback
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        addAuthenticationHeader(to: &request, for: server)

        print("🔗 Trying server [\(currentServerIndex + 1)/\(availableServers.count)]: \(server.displayName)")
        print("🔗 SSE request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("🔗 Full URL: \(url.absoluteString)")

        startSSEConnection(with: request)

        connectionError = nil

        print("🔗 Connecting to: \(url)")
    }

    private func tryNextServer() {
        currentServerIndex += 1
        reconnectAttempts = 0 // Reset attempts for new server

        if currentServerIndex < settings.allServers.count {
            print("🔄 Trying next fallback server...")
            Task { @MainActor in
                self.tryConnectToServer()
            }
        } else {
            connectionError = "All servers failed"
            updateConnectionQuality(.failing)
            scheduleRetryAllServers()
        }
    }

    private func scheduleRetryAllServers() {
        print("🔄 All servers failed - will retry all servers in \(settings.fallbackRetryDelay) seconds")

        fallbackTimer?.invalidate()
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: settings.fallbackRetryDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentServerIndex = 0
                self.serverFailureTimes.removeAll() // Clear failure cache
                self.tryConnectToServer()
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        dataTask?.cancel()
        dataTask = nil
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
        activeServer = nil

        print("❌ Disconnected from ntfy")
    }
    
    func updateSettings(_ newSettings: NtfySettings) {
        settings = newSettings
        if isConnected {
            connect() // Reconnect with new settings
        }
    }
    
    private func createSSEURL(for server: NtfyServer) -> URL? {
        var baseURL = server.url

        // Ensure HTTP/HTTPS protocol
        if !baseURL.hasPrefix("http://") && !baseURL.hasPrefix("https://") {
            baseURL = "https://" + baseURL
        }

        let topicsString = settings.topics.joined(separator: ",")
        let urlString = "\(baseURL)/\(topicsString)/json"
        print("🌐 Creating SSE URL for server \(server.displayName) with topics [\(topicsString)]: \(urlString)")

        return URL(string: urlString)
    }

    private func addAuthenticationHeader(to request: inout URLRequest, for server: NtfyServer) {
        switch server.authMethod {
        case .basicAuth:
            guard !server.username.isEmpty else { return }

            // Try server-specific credentials first, then fall back to primary credentials
            let password = SettingsManager.loadPassword(for: server.username) ??
                          SettingsManager.loadPassword(for: settings.username) ?? ""
            let credentials = "\(server.username):\(password)"

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
                let (asyncBytes, response) = try await urlSession.bytes(for: request)
                
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
                        guard let self = self, let activeServer = self.activeServer else { return }

                        self.connectionError = "HTTP \(httpResponse.statusCode): Authentication or server error for \(activeServer.displayName)"
                        self.isConnected = false

                        // Mark server as failed
                        self.serverFailureTimes[activeServer.url] = Date()

                        // Try next server instead of reconnecting to same one
                        self.tryNextServer()
                    }
                    return
                }
                
                print("✅ SSE connection established")

                await MainActor.run { [weak self] in
                    self?.isConnected = true
                    self?.lastConnectionTime = Date()
                    self?.reconnectAttempts = 0
                    self?.connectionAttemptsSinceLastSuccess = 0
                    self?.connectionError = nil
                    self?.updateConnectionQuality(.excellent)
                    self?.startKeepaliveTimer()
                }
                
                for try await line in asyncBytes.lines {
                    guard !line.isEmpty else { continue }
                    await handleSSEMessage(line)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }

                    let isNetworkError = (error as NSError).domain == NSURLErrorDomain
                    let errorCode = (error as NSError).code
                    let serverName = self.activeServer?.displayName ?? "unknown server"

                    if isNetworkError {
                        switch errorCode {
                        case NSURLErrorTimedOut:
                            self.connectionError = "Connection timed out to \(serverName)"
                            print("⏰ SSE timeout error for \(serverName): \(error)")
                        case NSURLErrorNetworkConnectionLost:
                            self.connectionError = "Network connection lost to \(serverName)"
                            print("📶 SSE network lost for \(serverName): \(error)")
                        case NSURLErrorNotConnectedToInternet:
                            self.connectionError = "No internet connection"
                            print("🌐 SSE no internet: \(error)")
                        default:
                            self.connectionError = "\(error.localizedDescription) (\(serverName))"
                            print("❌ SSE network error (\(errorCode)) for \(serverName): \(error)")
                        }
                    } else {
                        self.connectionError = "\(error.localizedDescription) (\(serverName))"
                        print("❌ SSE error for \(serverName): \(error)")
                    }

                    self.isConnected = false
                    self.connectionAttemptsSinceLastSuccess += 1

                    // Mark current server as failed
                    if let activeServer = self.activeServer {
                        self.serverFailureTimes[activeServer.url] = Date()
                    }

                    self.updateConnectionQualityBasedOnErrors()

                    // Try next server instead of reconnecting to same one
                    self.tryNextServer()
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

                // Update last message time for connection quality tracking
                self.lastMessageTime = Date()
                self.updateConnectionQualityBasedOnActivity()

                self.messages.insert(ntfyMessage, at: 0)
                
                // Limit stored messages
                if self.messages.count > self.settings.maxRecentMessages {
                    self.messages = Array(self.messages.prefix(self.settings.maxRecentMessages))
                }
                
                // Show notification if enabled
                if self.settings.enableNotifications {
                    self.notificationManager.showNotification(for: ntfyMessage, settings: self.settings)
                }
            }
        } catch {
            print("❌ Failed to decode message: \(error)")
            print("Raw data: \(line)")
        }
    }
    
    private func startKeepaliveTimer() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                // Monitor connection health - if no data received in reasonable time, reconnect
                guard let self = self, self.isConnected else { return }
                print("🏓 Keepalive check - connection still active")
            }
        }
    }
    
    private func scheduleReconnect() {
        // Legacy method - now handled by tryNextServer and scheduleRetryAllServers
        guard reconnectAttempts < maxReconnectAttempts else {
            tryNextServer()
            return
        }

        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 15.0) // Shorter max delay for faster fallback

        print("🔄 Scheduling reconnect attempt \(reconnectAttempts) in \(delay) seconds")

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.tryConnectToServer()
            }
        }
    }

    // MARK: - Connection Quality Management

    private func updateConnectionQuality(_ quality: ConnectionQuality) {
        guard connectionQuality != quality else { return }
        connectionQuality = quality
        print("📊 Connection quality updated: \(quality.description)")
    }

    private func updateConnectionQualityBasedOnActivity() {
        guard let lastConnection = lastConnectionTime else { return }

        let timeSinceConnection = Date().timeIntervalSince(lastConnection)

        // Improve quality based on successful activity
        if timeSinceConnection < 300 { // Less than 5 minutes
            if connectionQuality == .poor || connectionQuality == .failing {
                updateConnectionQuality(.good)
            } else if connectionQuality == .good && timeSinceConnection < 60 {
                updateConnectionQuality(.excellent)
            }
        }
    }

    private func updateConnectionQualityBasedOnErrors() {
        if connectionAttemptsSinceLastSuccess >= 5 {
            updateConnectionQuality(.failing)
        } else if connectionAttemptsSinceLastSuccess >= 3 {
            updateConnectionQuality(.poor)
        } else if connectionAttemptsSinceLastSuccess >= 1 {
            updateConnectionQuality(.good)
        }
    }

    deinit {
        networkCancellable?.cancel()
    }
}