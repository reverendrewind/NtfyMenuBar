# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NtfyMenuBar is a native macOS menu bar application for receiving ntfy.sh notifications. Built with SwiftUI and modern Swift concurrency, it provides a clean, borderless dashboard that appears directly below the menu bar icon. The app integrates seamlessly with macOS using LSUIElement configuration to remain hidden from the dock while providing rich, interactive notifications with priority indicators and auto-connect functionality.

## Architecture

- **Main App**: `NtfyMenuBar/NtfyMenuBarApp.swift` - SwiftUI app with AppDelegate for status bar control
- **Status Bar**: `StatusBarController.swift` - NSStatusItem management with centered dashboard positioning and overflow protection
- **Models**: Data structures for NtfyMessage, NtfySettings, and NtfyUser with Codable support
- **Services**: Server-Sent Events (SSE) via NtfyService using URLSession streaming, UserManagementService for admin operations
- **ViewModels**: Observable state management with NtfyViewModel using @MainActor and action closures for StatusBarController integration
- **Views**: SwiftUI components including ContentView, SettingsView, MessageRowView, UserManagementView, and CreateUserSheet
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
- Comprehensive user management with role-based permissions and admin features

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
- **User Management Removal**: Removed user management feature - ntfy only supports CLI-based user management, no HTTP API available
- **Multiple Topics Support**: Full support for subscribing to multiple topics simultaneously with topic badges in message display

### Technical Implementation Details
- **Window Positioning**: Uses `visibleFrame.maxY - windowHeight` for placement below menu bar
- **Borderless Windows**: Custom DashboardWindow class overrides canBecomeKey for proper focus
- **SSE Streaming**: URLSession.bytes(for:) with AsyncSequence for real-time message processing
- **Keychain Storage**: Secure credential storage using Keychain Services API
- **State Management**: @MainActor isolation with Combine publishers for reactive UI updates
- **Notification Categories**: UNNotificationCategory with interactive actions (Open, Mark Read, Dismiss)
- **Multiple Topics**: Comma-separated topic URLs (`/topic1,topic2,topic3/json`) for simultaneous subscriptions with topic badges in UI

### Known Patterns
- **Window Delegate**: Uses windowDidResignKey for click-outside-to-close behavior
- **Task Management**: Async/await patterns with proper error handling and cancellation
- **Memory Management**: Weak self references in timers and closures to prevent retain cycles
- **Settings Persistence**: Codable structs with UserDefaults and separate Keychain credential storage

### ntfy API Limitations
- **User Management**: ntfy only provides CLI-based user management (`sudo ntfy user ...` commands). No HTTP API endpoints exist for admin user operations.
- **Available HTTP APIs**: Only self-service account management endpoints (`/v1/account/*`) for logged-in users to manage their own accounts.
- **Server Requirements**: Account features require `enable-login: true` in server configuration.

### Testing
- App sandbox is enabled, restricting file system access but allowing network connections
- Uses modern Swift concurrency patterns with MainActor isolation
- Notification permissions are requested on first launch
- Works across multiple desktops/Spaces with proper window collection behavior