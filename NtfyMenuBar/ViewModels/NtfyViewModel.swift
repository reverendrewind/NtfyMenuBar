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
    
    init() {
        self.settings = SettingsManager.loadSettings()
        setupService()
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