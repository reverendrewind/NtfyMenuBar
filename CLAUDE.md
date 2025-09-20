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
- **Utilities**: NotificationManager for rich macOS notifications, SettingsManager for Keychain storage, and ThemeManager for dark mode support
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

### Recent Major Changes
- **SSE Implementation**: Migrated from WebSocket to Server-Sent Events for better ntfy compatibility
- **Menu Bar Positioning**: Implemented proper positioning using screen.visibleFrame coordinates
- **Auto-connect**: Added launch-time connection with user preference toggle
- **Enhanced Notifications**: Rich notifications with priority indicators and interactive actions
- **Connection Stability**: Improved reconnection logic and keepalive timers
- **Multi-Desktop Support**: Windows now appear on current desktop, not launch desktop

### Technical Implementation Details
- **Window Positioning**: Uses `visibleFrame.maxY - windowHeight` for placement below menu bar
- **Borderless Windows**: Custom DashboardWindow class overrides canBecomeKey for proper focus
- **SSE Streaming**: URLSession.bytes(for:) with AsyncSequence for real-time message processing
- **Keychain Storage**: Secure credential storage using Keychain Services API
- **State Management**: @MainActor isolation with Combine publishers for reactive UI updates
- **Notification Categories**: UNNotificationCategory with interactive actions (Open, Mark Read, Dismiss)

### Known Patterns
- **Window Delegate**: Uses windowDidResignKey for click-outside-to-close behavior
- **Task Management**: Async/await patterns with proper error handling and cancellation
- **Memory Management**: Weak self references in timers and closures to prevent retain cycles
- **Settings Persistence**: Codable structs with UserDefaults and separate Keychain credential storage

### Testing
- App sandbox is enabled, restricting file system access but allowing network connections
- Uses modern Swift concurrency patterns with MainActor isolation
- Notification permissions are requested on first launch
- Works across multiple desktops/Spaces with proper window collection behavior