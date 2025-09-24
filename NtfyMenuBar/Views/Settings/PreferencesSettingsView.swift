//
//  PreferencesSettingsView.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import SwiftUI

struct PreferencesSettingsView: View {
    @EnvironmentObject var viewModel: NtfyViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var enableNotifications: Bool = true
    @State private var maxRecentMessages: Int = 20
    @State private var currentTheme: AppearanceMode = .system
    @State private var notificationSound: NotificationSound = .default
    @State private var customSoundForHighPriority: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                notificationSection
                appearanceSection
                messageSection
                soundSection
                aboutSection
            }
            .padding(20)
        }
        .onAppear {
            loadSettings()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSettings()
                }
            }
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)

            Toggle(StringConstants.SettingsLabels.enableNotifications, isOn: $enableNotifications)
                .toggleStyle(.switch)

            if enableNotifications {
                Text("Notifications will appear in Notification Center and show priority indicators.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)

            Picker(StringConstants.SettingsLabels.appearanceMode, selection: $currentTheme) {
                Text(StringConstants.AppearanceModes.light).tag(AppearanceMode.light)
                Text(StringConstants.AppearanceModes.dark).tag(AppearanceMode.dark)
                Text(StringConstants.AppearanceModes.system).tag(AppearanceMode.system)
            }
            .pickerStyle(.segmented)
            .onChange(of: currentTheme) { _, newTheme in
                themeManager.setTheme(newTheme)
            }

            Text("Changes the appearance of the app interface.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Message Section

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Messages")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text(StringConstants.SettingsLabels.maxRecentMessages)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Stepper(value: $maxRecentMessages, in: AppConfig.Messages.minRecentMessages...AppConfig.Messages.maxRecentMessages) {
                    Text("\(maxRecentMessages) messages")
                }
            }

            Text("Maximum number of recent messages to display in the dashboard and menu bar.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sounds")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text(StringConstants.SettingsLabels.notificationSound)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("", selection: $notificationSound) {
                    ForEach(NotificationSound.allCases, id: \.self) { sound in
                        Text(sound.displayName).tag(sound)
                    }
                }
                .pickerStyle(.menu)
            }

            Toggle(StringConstants.SettingsLabels.customSoundForHighPriority, isOn: $customSoundForHighPriority)
                .toggleStyle(.switch)

            Text("High priority messages will use the selected sound. Other messages use the default system sound.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Version:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }

                Divider()

                HStack {
                    Link("Documentation", destination: URL(string: StringConstants.URLs.ntfyDocs)!)
                        .foregroundColor(.blue)

                    Spacer()

                    Link("GitHub", destination: URL(string: StringConstants.URLs.githubRepo)!)
                        .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func loadSettings() {
        let settings = viewModel.settings
        enableNotifications = settings.enableNotifications
        maxRecentMessages = settings.maxRecentMessages
        currentTheme = themeManager.currentTheme
        notificationSound = settings.notificationSound
        customSoundForHighPriority = settings.customSoundForHighPriority
    }

    private func saveSettings() {
        var settings = viewModel.settings
        settings.enableNotifications = enableNotifications
        settings.maxRecentMessages = maxRecentMessages
        settings.notificationSound = notificationSound
        settings.customSoundForHighPriority = customSoundForHighPriority

        viewModel.updateSettings(settings)
        themeManager.setTheme(currentTheme)
    }
}


#Preview {
    PreferencesSettingsView()
        .environmentObject(NtfyViewModel())
        .environmentObject(ThemeManager())
}