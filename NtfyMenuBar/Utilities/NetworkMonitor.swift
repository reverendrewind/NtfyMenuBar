//
//  NetworkMonitor.swift
//  NtfyMenuBar
//
//  Created by Claude on 20/01/2025.
//

import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = false
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                await self?.updateNetworkStatus(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updateNetworkStatus(_ path: NWPath) async {
        let wasConnected = isConnected
        let previousType = connectionType

        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive

        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = nil
        }

        // Log network changes
        if wasConnected != isConnected {
            print("🌐 Network status changed: \(isConnected ? "Connected" : "Disconnected")")
        }

        if previousType != connectionType {
            print("🌐 Connection type changed: \(connectionType?.description ?? "Unknown")")
        }

        // Post notification for network change
        if wasConnected != isConnected || previousType != connectionType {
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: NetworkStatus(
                    isConnected: isConnected,
                    connectionType: connectionType,
                    isExpensive: isExpensive,
                    wasConnected: wasConnected
                )
            )
        }
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Supporting Types

struct NetworkStatus {
    let isConnected: Bool
    let connectionType: NWInterface.InterfaceType?
    let isExpensive: Bool
    let wasConnected: Bool

    var connectionDescription: String {
        guard isConnected else { return "No connection" }

        switch connectionType {
        case .wifi:
            return isExpensive ? "WiFi (Limited)" : "WiFi"
        case .cellular:
            return isExpensive ? "Cellular (Limited)" : "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        default:
            return "Connected"
        }
    }
}

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .wiredEthernet: return "Ethernet"
        case .loopback: return "Loopback"
        case .other: return "Other"
        @unknown default: return "Unknown"
        }
    }
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}