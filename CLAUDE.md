# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NtfyMenuBar is a native macOS menu bar application for receiving ntfy.sh notifications. Built with SwiftUI and modern Swift concurrency, it provides a clean, borderless dashboard that appears directly below the menu bar icon. The app integrates seamlessly with macOS using LSUIElement configuration to remain hidden from the dock while providing rich, interactive notifications with priority indicators and auto-connect functionality.

## Architecture

- **Main App**: `NtfyMenuBar/NtfyMenuBarApp.swift` - SwiftUI app with AppDelegate for status bar control
- **Status Bar**: `StatusBarController.swift` - NSStatusItem management with centered dashboard positioning and overflow protection
- **Models**: Data structures for NtfyMessage and NtfySettings with Codable support
- **Services**: Server-Sent Events (SSE) via NtfyService using URLSession streaming
- **ViewModels**: Observable state management with NtfyViewModel using @MainActor and action closures for StatusBarController integration
- **Views**: SwiftUI components including ContentView, SettingsView, and MessageRowView
- **Utilities**: NotificationManager for rich macOS notifications, SettingsManager for Keychain storage, ThemeManager for dark mode support, and SnoozeDuration for notification snoozing
- **Bundle ID**: `net.raczej.NtfyMenuBar`

### Key Design Decisions

**Menu Bar Integration:**
- Uses NSStatusItem with custom DashboardWindow class for borderless display
- LSUIElement = true hides app from dock while maintaining menu bar presence
- Positioning centered below menu bar icon using button coordinates with screen edge overflow protection
- Multi-desktop support with .moveToActiveSpace collection behavior

**Connection Management:**
- Server-Sent Events (SSE) instead of WebSocket for better ntfy compatibility
- Auto-reconnect with exponential backoff (up to 10 attempts, max 60s delay)
- Keepalive timers every 25 seconds for connection health monitoring
- Improved error handling for network timeouts and connection loss

**User Experience:**
- Borderless dashboard appears centered below menu bar icon with overflow protection
- Click-outside-to-close and Escape key support
- Auto-connect at launch option for seamless experience
- Rich notifications with priority emojis and interactive actions
- Dark mode support with Light/Dark/System appearance options
- Integrated settings window management between dashboard and StatusBarController
- Notification snoozing system with 8 preset durations and custom branded icon

## Development Environment

Requires Xcode 14.0+ for development. See README.md for detailed build instructions.

## Key Configuration

- **Deployment Target**: macOS 14.0+ (Sonoma)
- **Swift Version**: 6.0
- **App Sandbox**: Enabled with network client entitlement
- **SwiftUI Previews**: Enabled
- **Code Signing**: Automatic
- **LSUIElement**: Should be set to YES in Info.plist (hides from Dock)
- **Modern Swift Features**:
  - Swift 6 Concurrency enabled with strict checking
  - Main Actor isolation by default
  - Enhanced sendability and isolation checking
  - Member import visibility upcoming feature enabled

### Required Entitlements
- `com.apple.security.network.client` for Server-Sent Events (SSE) connections
- `com.apple.security.app-sandbox` for app sandbox
- User notification permissions for native macOS notifications

## Development Notes

### Current Implementation Status
See [CHANGELOG.md](CHANGELOG.md) for complete version history and feature progression.

**Current v2.4.0 Features:**
- **Notification Snoozing**: Comprehensive snoozing system with 8 preset durations and custom branded icon
- **SSE Connection**: Server-Sent Events for real-time notifications (migrated from WebSocket)
- **Multi-Desktop Support**: Dashboard appears on current desktop with proper positioning
- **Message Filtering & Grouping**: Advanced filtering by topic/priority with search functionality
- **Access Token Management**: Complete token generation and management via ntfy HTTP API
- **Dark Mode**: Full Light/Dark/System appearance support

### Technical Implementation Details
- **Window Positioning**: Uses `visibleFrame.maxY - windowHeight` for placement below menu bar with overflow protection
- **Borderless Windows**: Custom DashboardWindow class overrides canBecomeKey for proper focus and click-outside-to-close
- **SSE Streaming**: URLSession.bytes(for:) with AsyncSequence for real-time message processing and auto-reconnection
- **Keychain Storage**: Secure credential storage using Keychain Services API for both Basic Auth and access tokens
- **State Management**: @MainActor isolation with Combine publishers for reactive UI updates and Swift 6 compatibility
- **Notification Categories**: UNNotificationCategory with interactive actions (Open, Mark Read, Dismiss)
- **Snooze System**: SnoozeDuration enum with 8 presets, real-time countdown, and custom branded menu bar icon switching
- **Access Token API**: POST to `/v1/account/token` with secure clipboard integration and masked display format
- **Message Filtering**: Real-time search and multi-selection filtering with dropdown UI components

### Development Patterns
- **Window Delegate**: Uses windowDidResignKey for click-outside-to-close behavior
- **Task Management**: Async/await patterns with proper error handling and cancellation
- **Memory Management**: Weak self references in timers and closures to prevent retain cycles
- **Settings Persistence**: Codable structs with UserDefaults and separate Keychain credential storage
- **Timer Management**: Proper snooze countdown with @MainActor isolation and automatic cleanup

### ntfy API Limitations & Constraints
- **User Management**: ntfy only provides CLI-based user management (`sudo ntfy user ...` commands). No HTTP API endpoints exist for admin operations.
- **Message History**: No persistent message history API - messages are only available via real-time SSE connection
- **Topic Statistics**: No API for subscriber counts, message counts, or topic analytics
- **Server Configuration**: No HTTP API for server settings or configuration management
- **Available APIs**: Limited to self-service account management (`/v1/account/*`) and message publishing

### Testing & Deployment
- **App Sandbox**: Enabled, restricting file system access but allowing network connections
- **Swift Concurrency**: Uses modern async/await patterns with MainActor isolation for Swift 6 compatibility
- **Notification Permissions**: Requested on first launch with proper error handling
- **Multi-Desktop Support**: Works across Spaces with proper window collection behavior