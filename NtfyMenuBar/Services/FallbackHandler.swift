//
//  FallbackHandler.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import Foundation
import Combine

protocol FallbackHandlerDelegate: AnyObject {
    func fallbackHandler(_ handler: FallbackHandler, shouldTryServer server: NtfyServer) -> Bool
    func fallbackHandler(_ handler: FallbackHandler, didTryAllServers servers: [NtfyServer])
    func fallbackHandler(_ handler: FallbackHandler, willRetryAllServersAfterDelay delay: TimeInterval)
}

class FallbackHandler: ObservableObject {
    @Published var currentServerIndex = 0
    @Published var activeServer: NtfyServer?

    weak var delegate: FallbackHandlerDelegate?

    private var reconnectAttempts = 0
    private let maxReconnectAttempts = AppConfig.Network.maxReconnectAttempts
    private var serverFailureTimes: [String: Date] = [:]
    private var fallbackTimer: Timer?
    private var reconnectTimer: Timer?

    // MARK: - Public Interface

    func startConnection(with servers: [NtfyServer], settings: NtfySettings) {
        currentServerIndex = 0
        clearAllTimers()
        tryNextServer(servers: servers, settings: settings)
    }

    func handleConnectionFailure(servers: [NtfyServer], settings: NtfySettings, error: Error) {
        // Mark current server as failed
        if let activeServer = activeServer {
            serverFailureTimes[activeServer.url] = Date()
        }

        tryNextServer(servers: servers, settings: settings)
    }

    func reset() {
        currentServerIndex = 0
        activeServer = nil
        reconnectAttempts = 0
        serverFailureTimes.removeAll()
        clearAllTimers()
    }

    // MARK: - Private Implementation

    private func tryNextServer(servers: [NtfyServer], settings: NtfySettings) {
        guard currentServerIndex < servers.count else {
            // All servers failed
            delegate?.fallbackHandler(self, didTryAllServers: servers)
            scheduleRetryAllServers(delay: settings.fallbackRetryDelay, servers: servers, settings: settings)
            return
        }

        let server = servers[currentServerIndex]
        activeServer = server

        // Check if server recently failed and should be skipped temporarily
        if let failureTime = serverFailureTimes[server.url],
           Date().timeIntervalSince(failureTime) < settings.fallbackRetryDelay {
            print("🚫 FallbackHandler: Skipping server \(server.displayName) - recently failed")
            currentServerIndex += 1
            tryNextServer(servers: servers, settings: settings)
            return
        }

        // Ask delegate if we should try this server
        if delegate?.fallbackHandler(self, shouldTryServer: server) == true {
            print("🔗 FallbackHandler: Trying server [\(currentServerIndex + 1)/\(servers.count)]: \(server.displayName)")
        } else {
            // Move to next server if delegate says no
            currentServerIndex += 1
            tryNextServer(servers: servers, settings: settings)
        }
    }

    func moveToNextServer(servers: [NtfyServer], settings: NtfySettings) {
        currentServerIndex += 1
        reconnectAttempts = 0 // Reset attempts for new server
        tryNextServer(servers: servers, settings: settings)
    }

    private func scheduleRetryAllServers(delay: TimeInterval, servers: [NtfyServer], settings: NtfySettings) {
        print("🔄 FallbackHandler: All servers failed - will retry all servers in \(delay) seconds")
        delegate?.fallbackHandler(self, willRetryAllServersAfterDelay: delay)

        fallbackTimer?.invalidate()
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.currentServerIndex = 0
            self.serverFailureTimes.removeAll() // Clear failure cache
            self.tryNextServer(servers: servers, settings: settings)
        }
    }

    private func clearAllTimers() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    deinit {
        clearAllTimers()
    }
}