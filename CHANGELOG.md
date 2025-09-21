# Changelog

All notable changes to NtfyMenuBar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.4.0] - 2024-09-21

### Added
- **Comprehensive notification snoozing system**
  - 8 preset durations: 5min, 15min, 30min, 1hr, 2hr, 4hr, 8hr, "Until tomorrow"
  - Real-time countdown display and auto-expiration
  - Dashboard and menu bar controls with visual feedback
  - Snooze state persistence across app restarts
- **Custom snooze icon implementation**
  - Branded grayed-out ntfy bell with diagonal slash for snooze state
  - Multi-resolution support (1x, 2x, 3x) for crisp display
  - Maintains brand consistency while clearly indicating muted state

### Fixed
- **Dashboard header display**
  - Now shows actual server URL instead of "Primary server"
  - Improved server identification in multi-server setups
- **Snooze functionality**
  - Resolved issue where notifications continued during snooze
  - Proper settings synchronization between components
- **Swift 6 compatibility**
  - Fixed concurrency warnings and actor isolation issues
  - Improved timer management for snooze countdown
- **Snooze countdown display**
  - Now properly rounds to nearest minute for accurate time display
  - Resolved misleading countdown (e.g., 4:59 now correctly shows "5m" instead of "4m")
- **Snooze icon visibility**
  - Updated diagonal slash to be more muted and cohesive with grayed-out bell icon
  - Enhanced visual consistency in menu bar snooze state

## [v2.3.0] - Message Filtering & Grouping

### Added
- **Advanced message filtering system**
  - Multi-selection filters for topics and priorities
  - Compact dropdown menus replace large filter panels
  - Comprehensive search across content, titles, topics, and tags
- **Message grouping with collapsible sections**
  - Group by topic or priority with visual indicators
  - Expand/collapse functionality for better organization

### Improved
- **Message layout density**
  - Reduced spacing between messages for better space utilization
  - Maintained readability while maximizing content display

## [v2.2.0] - Access Token Management

### Added
- **Comprehensive access token management system**
  - Generate and manage ntfy access tokens directly from the app
  - Secure clipboard copying with automatic clearing
  - Token validation and format checking
- **Enhanced authentication options**
  - Support for both Basic Authentication and Bearer Token authentication
  - Seamless switching between authentication methods

### Improved
- **Security enhancements**
  - All credentials stored securely in macOS Keychain
  - Improved token handling and validation

## [v2.1.0] - UI Improvements & Server Support

### Added
- **Comprehensive UI improvements**
  - Enhanced visual feedback and user experience
  - Improved error handling and user messaging
- **Fallback server support**
  - Better handling of server connectivity issues
  - Improved connection stability and error recovery

### Improved
- **Dashboard positioning and sizing**
  - Fixed dashboard positioning issues
  - Better handling of different screen configurations
- **Settings integration**
  - Improved integration between dashboard and StatusBarController
  - Better state management across components

## [v2.0.0] - Dark Mode & Enhanced Features

### Added
- **Dark mode support**
  - Configurable appearance with Light, Dark, and System options
  - Automatic system theme following
- **Enhanced notification system**
  - Rich, branded notifications with priority indicators
  - Interactive notification actions (Open, Mark Read, Dismiss)
  - Priority-based emoji indicators and sounds
- **Multi-desktop support**
  - Dashboard appears on current desktop/space
  - Proper window collection behavior across Spaces

### Improved
- **Connection stability**
  - Improved SSE handling with auto-reconnect
  - Keepalive timers for connection health monitoring
  - Better error handling for network timeouts

## [v1.2.0] - Tag Emoji System

### Added
- **Comprehensive tag emoji mapping system**
  - 99+ supported tag types with automatic emoji assignment
  - Categories include: System, Infrastructure, Development, Communication, Web/API, Business, Gaming, IoT/Smart Home, Transportation, Food, Health, Education, Finance, Science, Location, Time, Tools, Weather
- **Visual tag indicators**
  - Instant notification categorization through emojis
  - Improved message scanning and recognition

## [v1.1.0] - Borderless Dashboard

### Added
- **Borderless dashboard panel**
  - Clean, flat panel design that appears centered below menu bar icon
  - Click-outside-to-close functionality
  - Escape key support for keyboard navigation
- **Multi-desktop support**
  - Dashboard appears on current desktop, not locked to launch desktop
  - Proper positioning across different screen configurations

### Improved
- **Menu bar interaction**
  - Enhanced positioning with overflow protection
  - Better visual integration with macOS design language

## [v1.0.0] - Initial Release

### Added
- **Core menu bar application**
  - Native macOS menu bar integration with LSUIElement configuration
  - Real-time ntfy notifications using Server-Sent Events (SSE)
  - Auto-connect at launch functionality
- **Authentication support**
  - Basic Authentication (username/password)
  - Bearer Token authentication for ntfy.sh Pro
  - Secure credential storage in macOS Keychain
- **Dashboard interface**
  - Real-time message list with connection status
  - Server URL and topic display in header
  - Settings panel integration
- **Notification system**
  - Native macOS notifications with branding
  - Priority-based visual and audio indicators
  - Message persistence and management
- **Security features**
  - Full App Sandbox support
  - Network client entitlements for SSE connections
  - No data collection or third-party tracking

### Technical Implementation
- **SwiftUI & Combine architecture**
  - Modern declarative UI framework
  - Reactive state management
- **Server-Sent Events (SSE)**
  - Real-time connection using URLSession streaming
  - Automatic reconnection with exponential backoff
- **Keychain Services integration**
  - Secure credential storage and retrieval
  - Platform-native security practices

---

For more details about each release, visit the [GitHub Releases](https://github.com/reverendrewind/NtfyMenuBar/releases) page.