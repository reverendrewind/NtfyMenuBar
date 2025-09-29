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

    private var settings: NtfySettings
    private let notificationManager = NotificationManager.shared
    private var networkMonitor: NetworkMonitor = .shared
    private var networkCancellable: AnyCancellable?
    private var lastMessageTime: Date?
    private var connectionAttemptsSinceLastSuccess = 0

    // Services
    private var connectionManager: ConnectionManager!
    private var fallbackHandler: FallbackHandler!
    init(settings: NtfySettings) {
        self.settings = settings

        // Initialize services
        self.connectionManager = ConnectionManager()
        self.fallbackHandler = FallbackHandler()

        setupServices()
        setupNetworkMonitoring()
    }

    private func setupServices() {
        connectionManager.delegate = self
        fallbackHandler.delegate = self

        // Sync fallback handler state with our published properties
        fallbackHandler.$currentServerIndex
            .assign(to: &$currentServerIndex)
        fallbackHandler.$activeServer
            .assign(to: &$activeServer)
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
        Logger.shared.info("🌐 Network change detected: \(status.connectionDescription)")

        if status.isConnected && !status.wasConnected {
            // Network came back online
            Logger.shared.info("🌐 Network restored - attempting reconnection")
            if !isConnected && settings.isConfigured {
                // Reset fallback handler since network is back
                fallbackHandler.reset()
                connect()
            }
        } else if !status.isConnected && status.wasConnected {
            // Network went offline
            Logger.shared.warning("🌐 Network lost - connection will be affected")
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
        fallbackHandler.startConnection(with: settings.allServers, settings: settings)
    }


    
    func disconnect() {
        connectionManager.disconnect()
        fallbackHandler.reset()
        isConnected = false
        activeServer = nil
        Logger.shared.info("❌ Disconnected from ntfy")
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
        Logger.shared.debug("🌐 Creating SSE URL for server \(server.displayName) with topics [\(topicsString)]: \(urlString)")

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
    
    
    private func handleSSEMessage(_ line: String) async {
        guard let data = line.data(using: .utf8) else { return }
        
        do {
            let ntfyMessage = try JSONDecoder().decode(NtfyMessage.self, from: data)
            
            // Skip keepalive and open messages
            guard !ntfyMessage.isKeepalive && ntfyMessage.event != "open" else { 
                Logger.shared.debug("📋 Skipping \(ntfyMessage.event) event")
                return 
            }
            
            await MainActor.run {
                Logger.shared.debug("📨 Received message: \(ntfyMessage.message ?? "No message")")

                // Update last message time for connection quality tracking
                self.lastMessageTime = Date()
                self.updateConnectionQualityBasedOnActivity()

                self.messages.insert(ntfyMessage, at: 0)

                // Archive the message for persistent storage
                MessageArchive.shared.archiveMessage(ntfyMessage)

                // Limit stored messages in memory
                if self.messages.count > self.settings.maxRecentMessages {
                    self.messages = Array(self.messages.prefix(self.settings.maxRecentMessages))
                }
                
                // Show notification if enabled (check current settings to get latest snooze state)
                let currentSettings = SettingsManager.loadSettings()
                if currentSettings.enableNotifications {
                    self.notificationManager.showNotification(for: ntfyMessage, settings: currentSettings)
                }
            }
        } catch {
            Logger.shared.error("❌ Failed to decode message: \(error)")
            Logger.shared.debug("Raw data: \(line)")
        }
    }
    

    // MARK: - Connection Quality Management

    private func updateConnectionQuality(_ quality: ConnectionQuality) {
        guard connectionQuality != quality else { return }
        connectionQuality = quality
        Logger.shared.debug("📊 Connection quality updated: \(quality.description)")
    }

    private func updateConnectionQualityBasedOnActivity() {
        guard let lastConnection = lastConnectionTime else { return }

        let timeSinceConnection = Date().timeIntervalSince(lastConnection)

        // Improve quality based on successful activity
        if timeSinceConnection < AppConfig.Network.connectionHealthCheckInterval * 10 { // Less than 5 minutes
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

// MARK: - ConnectionManagerDelegate

extension NtfyService: ConnectionManagerDelegate {
    func connectionDidConnect() {
        isConnected = true
        lastConnectionTime = Date()
        connectionAttemptsSinceLastSuccess = 0
        connectionError = nil
        updateConnectionQuality(.excellent)
    }

    func connectionDidDisconnect(error: Error?) {
        isConnected = false
        if let error = error {
            connectionAttemptsSinceLastSuccess += 1
            connectionError = error.localizedDescription
            updateConnectionQualityBasedOnErrors()

            // Let fallback handler handle the retry logic
            fallbackHandler.handleConnectionFailure(
                servers: settings.allServers,
                settings: settings,
                error: error
            )
        }
    }

    func connectionDidReceiveMessage(_ message: String) {
        Task { @MainActor in
            await handleSSEMessage(message)
        }
    }

    func connectionQualityDidChange(_ quality: ConnectionQuality) {
        updateConnectionQuality(quality)
    }
}

// MARK: - FallbackHandlerDelegate

extension NtfyService: FallbackHandlerDelegate {
    func fallbackHandler(_ handler: FallbackHandler, shouldTryServer server: NtfyServer) -> Bool {
        guard let url = createSSEURL(for: server) else {
            connectionError = "Invalid server URL: \(server.url)"
            updateConnectionQuality(.failing)
            return false
        }

        updateConnectionQuality(.unknown)

        var request = URLRequest(url: url)
        request.timeoutInterval = AppConfig.Network.timeoutInterval
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        addAuthenticationHeader(to: &request, for: server)

        connectionManager.connect(to: url, with: request)
        return true
    }

    func fallbackHandler(_ handler: FallbackHandler, didTryAllServers servers: [NtfyServer]) {
        connectionError = "All servers failed - no more fallbacks available"
        updateConnectionQuality(.failing)
    }

    func fallbackHandler(_ handler: FallbackHandler, willRetryAllServersAfterDelay delay: TimeInterval) {
        Logger.shared.warning("🔄 All servers failed - will retry all servers in \(delay) seconds")
    }
}