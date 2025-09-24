//
//  ConnectionManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import Foundation
import Combine

protocol ConnectionManagerDelegate: AnyObject {
    func connectionDidConnect()
    func connectionDidDisconnect(error: Error?)
    func connectionDidReceiveMessage(_ message: String)
    func connectionQualityDidChange(_ quality: ConnectionQuality)
}

class ConnectionManager: NSObject {
    weak var delegate: ConnectionManagerDelegate?

    private var dataTask: URLSessionDataTask?
    private var keepaliveTimer: Timer?
    private var isConnected = false

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 0
        config.timeoutIntervalForResource = 0
        config.waitsForConnectivity = true
        config.networkServiceType = .background
        return URLSession(configuration: config)
    }()

    // MARK: - Public Interface

    func connect(to url: URL, with request: URLRequest) {
        disconnect() // Clean up any existing connection

        print("🔗 ConnectionManager: Starting SSE connection to \(url)")
        startSSEConnection(with: request)
    }

    func disconnect() {
        print("❌ ConnectionManager: Disconnecting")
        dataTask?.cancel()
        dataTask = nil
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil

        if isConnected {
            isConnected = false
            delegate?.connectionDidDisconnect(error: nil)
        }
    }

    var connectionStatus: Bool {
        return isConnected
    }

    // MARK: - Private Implementation

    private func startSSEConnection(with request: URLRequest) {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                let (asyncBytes, response) = try await urlSession.bytes(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        let error = NSError(domain: "ConnectionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                        self.delegate?.connectionDidDisconnect(error: error)
                    }
                    return
                }

                print("📡 ConnectionManager: HTTP Status: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    await MainActor.run {
                        let error = NSError(domain: "ConnectionManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): Server error"])
                        self.delegate?.connectionDidDisconnect(error: error)
                    }
                    return
                }

                print("✅ ConnectionManager: SSE connection established")

                await MainActor.run {
                    self.isConnected = true
                    self.delegate?.connectionDidConnect()
                    self.startKeepaliveTimer()
                }

                for try await line in asyncBytes.lines {
                    guard !line.isEmpty else { continue }
                    await MainActor.run {
                        self.delegate?.connectionDidReceiveMessage(line)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isConnected = false
                    self.delegate?.connectionDidDisconnect(error: error)
                }
            }
        }
    }

    private func startKeepaliveTimer() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.Network.keepaliveInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isConnected else { return }
            print("🏓 ConnectionManager: Keepalive check - connection still active")
        }
    }
}