# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NtfyMenuBar is a native macOS menubar application for receiving ntfy notifications with SwiftUI and modern Swift concurrency. The target server is `https://ntfy.2137.wtf` with authentication required (admin:admin123). The project targets macOS 15.6+ and uses SwiftUI with Swift 5.0.

## Architecture

- **Main App**: `NtfyMenuBar/NtfyMenuBarApp.swift` - Entry point using SwiftUI's `@main` attribute with MenuBarExtra
- **Models**: Data structures for NtfyMessage and NtfySettings with Codable support
- **Services**: WebSocket connection handling via NtfyService using URLSessionWebSocketTask
- **ViewModels**: Observable state management with NtfyViewModel using @MainActor
- **Views**: SwiftUI components including ContentView, SettingsView, and MessageRowView
- **Utilities**: NotificationManager for macOS notifications and SettingsManager for persistence
- **Bundle ID**: `net.raczej.NtfyMenuBar`

## Build and Development Commands

Since this is an Xcode project, development requires Xcode:

```bash
# Open project in Xcode
open NtfyMenuBar.xcodeproj

# Build from command line (requires Xcode, not just command line tools)
xcodebuild -scheme NtfyMenuBar -configuration Debug build

# Run tests
xcodebuild test -scheme NtfyMenuBar -destination 'platform=macOS'

# Run specific test targets
xcodebuild test -scheme NtfyMenuBarTests -destination 'platform=macOS'
xcodebuild test -scheme NtfyMenuBarUITests -destination 'platform=macOS'
```

## Key Configuration

- **Deployment Target**: macOS 15.6
- **Swift Version**: 5.0
- **App Sandbox**: Enabled with network client entitlement
- **SwiftUI Previews**: Enabled
- **Code Signing**: Automatic
- **LSUIElement**: Should be set to YES in Info.plist (hides from Dock)
- **Modern Swift Features**: 
  - Swift Approachable Concurrency enabled
  - Main Actor isolation by default
  - Member import visibility upcoming feature enabled

## Planned Architecture (from ntfy-plan.md)

The project follows a structured approach with clear separation of concerns:

### Core Components
- **WebSocket Service**: Real-time connection to ntfy server with authentication
- **Notification Manager**: Native macOS notification handling
- **Settings Management**: UserDefaults-based persistence
- **MenuBar Integration**: MenuBarExtra with dynamic icon states

### Key Features
- Real-time WebSocket connections with auto-reconnection
- Basic authentication support
- Native macOS notifications with permission handling
- Recent message display with configurable limits
- Connection status indicators
- Settings configuration interface

### Required Entitlements
- `com.apple.security.network.client` for WebSocket connections
- `com.apple.security.app-sandbox` for app sandbox

## Development Notes

- The project uses SwiftUI with previews enabled for rapid development
- App sandbox is enabled, which restricts file system access but allows network connections
- Uses modern Swift concurrency patterns with MainActor isolation
- File system synchronized groups are used for automatic file management in Xcode
- WebSocket connections use URLSessionWebSocketTask for real-time messaging
- Notification permissions are requested on first launch