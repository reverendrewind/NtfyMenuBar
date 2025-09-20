//
//  NtfyViewModel.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 19/09/2025.
//

import Foundation
import Combine

@MainActor
class NtfyViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var hasUnreadMessages = false
    @Published var messages: [NtfyMessage] = []
    @Published var settings: NtfySettings
    @Published var connectionError: String?
    
    private var ntfyService: NtfyService?
    private var cancellables = Set<AnyCancellable>()

    // Expose service for UI access to connection quality
    var service: NtfyService {
        return ntfyService ?? NtfyService(settings: settings)
    }
    
    // Closure to open settings window (set by StatusBarController)
    var openSettingsAction: (() -> Void)?
    
    init() {
        self.settings = SettingsManager.loadSettings()
        setupService()
        
        // Autoconnect if server is configured and autoconnect is enabled
        if settings.isConfigured && settings.autoConnect {
            // Delay slightly to ensure UI is ready
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    print("🚀 Autoconnecting to configured server...")
                    connect()
                }
            }
        }
    }
    
    func connect() {
        guard settings.isConfigured else {
            connectionError = "Please configure server settings first"
            return
        }
        
        ntfyService?.connect()
    }
    
    func disconnect() {
        ntfyService?.disconnect()
    }
    
    func clearMessages() {
        messages.removeAll()
        hasUnreadMessages = false
        NotificationManager.shared.clearAllNotifications()
    }
    
    func updateSettings(_ newSettings: NtfySettings) {
        settings = newSettings
        SettingsManager.saveSettings(newSettings)
        setupService()
        
        if isConnected {
            disconnect()
            connect()
        }
    }
    
    private func setupService() {
        ntfyService = NtfyService(settings: settings)
        
        ntfyService?.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
        
        ntfyService?.$connectionError
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionError, on: self)
            .store(in: &cancellables)
        
        ntfyService?.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessages in
                self?.messages = newMessages
                self?.hasUnreadMessages = !newMessages.isEmpty
            }
            .store(in: &cancellables)
    }
}