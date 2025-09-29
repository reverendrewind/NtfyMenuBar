//
//  ConnectionManager.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import Foundation
import Combine

// MARK: - Connection Errors

enum ConnectionError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case authenticationFailed
    case networkUnavailable
    case timeout
    case streamError(underlying: Error)
    case sslError(message: String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .networkUnavailable:
            return "Network connection unavailable"
        case .timeout:
            return "Connection timed out"
        case .streamError(let error):
            return "Stream error: \(error.localizedDescription)"
        case .sslError(let message):
            return "SSL/TLS error: \(message)"
        case .cancelled:
            return "Connection cancelled"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Please verify the server URL is correct"
        case .authenticationFailed:
            return "Check your username/password or access token in settings"
        case .networkUnavailable:
            return "Please check your internet connection"
        case .timeout:
            return "The server may be slow or unreachable. Try again later."
        case .sslError:
            return "There may be a security issue with the server certificate"
        default:
            return nil
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .cancelled, .invalidURL:
            return false
        case .networkUnavailable, .timeout, .streamError:
            return true
        case .httpError(let code, _):
            return code >= 500 || code == 429 // Server errors or rate limiting
        case .authenticationFailed, .sslError:
            return false
        case .invalidResponse:
            return true
        }
    }
}

// MARK: - Protocol

protocol ConnectionManagerDelegate: AnyObject {
    func connectionDidConnect()
    func connectionDidDisconnect(error: Error?)
    func connectionDidReceiveMessage(_ message: String)
    func connectionQualityDidChange(_ quality: ConnectionQuality)
}

// MARK: - Connection Manager

class ConnectionManager: NSObject {
    weak var delegate: ConnectionManagerDelegate?

    private var dataTask: URLSessionDataTask?
    private var keepaliveTimer: Timer?
    private var isConnected = false
    private var connectionStartTime: Date?
    private var lastMessageTime: Date?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 0
        config.timeoutIntervalForResource = 0
        config.waitsForConnectivity = true
        config.networkServiceType = .background

        // Add additional error handling configuration
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // MARK: - Public Interface

    func connect(to url: URL, with request: URLRequest) {
        disconnect() // Clean up any existing connection

        // Validate URL
        guard url.scheme == "https" || url.scheme == "http" else {
            delegate?.connectionDidDisconnect(error: ConnectionError.invalidURL)
            Logger.shared.error("🔴 ConnectionManager: Invalid URL scheme: \(url.scheme ?? "nil")")
            return
        }

        connectionStartTime = Date()
        Logger.shared.info("🔗 ConnectionManager: Starting SSE connection to \(url)")
        startSSEConnection(with: request)
    }

    func disconnect() {
        Logger.shared.info("🔌 ConnectionManager: Disconnecting")

        dataTask?.cancel()
        dataTask = nil
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
        connectionStartTime = nil
        lastMessageTime = nil
        reconnectAttempts = 0

        if isConnected {
            isConnected = false
            delegate?.connectionDidDisconnect(error: ConnectionError.cancelled)
        }
    }

    var connectionStatus: Bool {
        return isConnected
    }

    var connectionDuration: TimeInterval? {
        guard let startTime = connectionStartTime, isConnected else { return nil }
        return Date().timeIntervalSince(startTime)
    }

    var timeSinceLastMessage: TimeInterval? {
        guard let lastTime = lastMessageTime else { return nil }
        return Date().timeIntervalSince(lastTime)
    }

    // MARK: - Private Implementation

    private func startSSEConnection(with request: URLRequest) {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                let (asyncBytes, response) = try await urlSession.bytes(for: request)

                // Handle response validation
                try await self.validateResponse(response)

                Logger.shared.info("✅ ConnectionManager: SSE connection established")

                await MainActor.run {
                    self.isConnected = true
                    self.reconnectAttempts = 0
                    self.delegate?.connectionDidConnect()
                    self.delegate?.connectionQualityDidChange(.excellent)
                    self.startKeepaliveTimer()
                }

                // Process incoming stream
                try await self.processStream(asyncBytes)

            } catch let error as ConnectionError {
                await self.handleConnectionError(error)
            } catch {
                // Wrap unknown errors
                let connectionError = self.categorizeError(error)
                await self.handleConnectionError(connectionError)
            }
        }
    }

    private func validateResponse(_ response: URLResponse) async throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConnectionError.invalidResponse
        }

        Logger.shared.info("📡 ConnectionManager: HTTP Status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200:
            // Success
            return
        case 401, 403:
            throw ConnectionError.authenticationFailed
        case 404:
            throw ConnectionError.httpError(statusCode: 404, message: "Topic not found")
        case 429:
            throw ConnectionError.httpError(statusCode: 429, message: "Rate limited. Please try again later.")
        case 500...599:
            throw ConnectionError.httpError(statusCode: httpResponse.statusCode, message: "Server error")
        default:
            throw ConnectionError.httpError(statusCode: httpResponse.statusCode, message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }
    }

    private func processStream(_ asyncBytes: URLSession.AsyncBytes) async throws {
        var emptyLineCount = 0
        let maxEmptyLines = 10

        for try await line in asyncBytes.lines {
            // Update last message time
            lastMessageTime = Date()

            // Handle empty lines (SSE heartbeat)
            if line.isEmpty {
                emptyLineCount += 1
                if emptyLineCount > maxEmptyLines {
                    // Update connection quality if too many empty lines
                    await MainActor.run {
                        self.delegate?.connectionQualityDidChange(.poor)
                    }
                }
                continue
            }

            // Reset empty line counter on actual data
            emptyLineCount = 0

            // Process the message
            await MainActor.run {
                self.delegate?.connectionDidReceiveMessage(line)

                // Update connection quality based on message frequency
                if let timeSince = self.timeSinceLastMessage {
                    let quality: ConnectionQuality = {
                        switch timeSince {
                        case 0..<30: return .excellent
                        case 30..<60: return .good
                        case 60..<120: return .poor
                        default: return .failing
                        }
                    }()
                    self.delegate?.connectionQualityDidChange(quality)
                }
            }
        }
    }

    private func handleConnectionError(_ error: ConnectionError) async {
        Logger.shared.error("🔴 ConnectionManager error: \(error.localizedDescription)")

        await MainActor.run {
            self.isConnected = false
            self.keepaliveTimer?.invalidate()

            // Check if we should attempt reconnection
            if error.isRecoverable && self.reconnectAttempts < self.maxReconnectAttempts {
                self.reconnectAttempts += 1
                Logger.shared.info("🔄 ConnectionManager: Will attempt reconnection (\(self.reconnectAttempts)/\(self.maxReconnectAttempts))")
            }

            self.delegate?.connectionDidDisconnect(error: error)

            // Update connection quality
            self.delegate?.connectionQualityDidChange(.failing)
        }
    }

    private func categorizeError(_ error: Error) -> ConnectionError {
        let nsError = error as NSError

        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorCancelled:
                return .cancelled
            case NSURLErrorTimedOut:
                return .timeout
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkUnavailable
            case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateHasBadDate,
                 NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasUnknownRoot,
                 NSURLErrorServerCertificateNotYetValid:
                return .sslError(message: nsError.localizedDescription)
            default:
                return .streamError(underlying: error)
            }
        default:
            return .streamError(underlying: error)
        }
    }

    private func startKeepaliveTimer() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.Network.keepaliveInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isConnected else { return }

            // Check connection health
            if let timeSince = self.timeSinceLastMessage, timeSince > 60 {
                Logger.shared.warning("⚠️ ConnectionManager: No messages for \(Int(timeSince))s")

                // Update quality if no messages for a while
                let quality: ConnectionQuality = timeSince > 120 ? .poor : .good
                self.delegate?.connectionQualityDidChange(quality)
            } else {
                Logger.shared.debug("🏓 ConnectionManager: Keepalive check - connection healthy")
            }
        }
    }
}

// MARK: - URLSession Delegate

extension ConnectionManager: URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            Logger.shared.error("🔴 URLSession became invalid: \(error.localizedDescription)")
            let connectionError = categorizeError(error)
            Task {
                await handleConnectionError(connectionError)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Logger.shared.error("🔴 URLSession task completed with error: \(error.localizedDescription)")
            let connectionError = categorizeError(error)
            Task {
                await handleConnectionError(connectionError)
            }
        }
    }
}