# NtfyMenuBar

A native macOS menu bar application for [ntfy](https://ntfy.sh) notifications. Get real-time push notifications directly in your menu bar without cluttering your dock.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-green)

## Features

- **Menu Bar Integration**: Runs discretely in your menu bar without a dock icon
- **One-Click Dashboard**: Click menu bar icon to open dashboard, click again to close (toggle behavior)
- **Quick Message Preview**: Right-click menu shows 5 most recent messages with timestamps
- **Real-time Notifications**: Live connection to ntfy servers using Server-Sent Events (SSE)
- **Dual Authentication**: Support for both Basic Authentication and Bearer Token authentication
- **Secure Storage**: Credentials stored securely in macOS Keychain
- **Native macOS Notifications**: System notifications for incoming messages
- **Smart Window Positioning**: Windows appear in upper-right corner, properly positioned and sized
- **Custom App Icons**: Generated from SVG with proper menu bar template rendering
- **Customizable Settings**: Configure notification preferences and message limits
- **Sandbox Compatible**: Full App Sandbox support with proper network entitlements

## Screenshots

*Menu Bar Interface*
- Clean, minimal menu bar icon
- Dropdown menu with quick access to dashboard and settings

*Settings Panel*
- Server configuration (URL and topic)
- Authentication method selection
- Secure credential management
- Notification preferences

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later (for building from source)
- Active ntfy server (self-hosted or ntfy.sh)

## Installation

### Option 1: Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/reverendrewind/NtfyMenuBar.git
   cd NtfyMenuBar
   ```

2. Open `NtfyMenuBar.xcodeproj` in Xcode

3. Build and run the project (⌘+R)

### Option 2: Download Release

*Releases coming soon - check the [Releases](https://github.com/reverendrewind/NtfyMenuBar/releases) page*

## Setup

1. **Launch the app** - NtfyMenuBar will appear in your menu bar
2. **Open Settings** - Click the menu bar icon and select "Settings..."
3. **Configure Server**:
   - **Server URL**: Your ntfy server URL (e.g., `https://ntfy.sh` or your self-hosted instance)
   - **Topic**: The topic you want to subscribe to (e.g., `my-notifications`)

4. **Choose Authentication Method**:
   - **Basic Auth**: Username and password (leave empty for public servers)
   - **Access Token**: 32-character token starting with `tk_` (for ntfy.sh Pro or self-hosted with auth)

5. **Set Preferences**:
   - Enable/disable system notifications
   - Configure maximum recent messages (5-100)

6. **Connect** - The app will automatically connect when properly configured

## Authentication

### Basic Authentication
For password-protected ntfy servers:
```
Username: your-username
Password: your-password
```

### Access Token Authentication
For ntfy.sh Pro or token-based authentication:
```
Token: tk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Access tokens must be exactly 32 characters and start with `tk_`. Tokens are stored securely in the macOS Keychain.

## Usage

### Menu Bar Interaction
- **Left Click**: Toggle dashboard window (open/close)
- **Right Click**: Access context menu with:
  - Recent 5 messages with timestamps
  - Settings access
  - Connect/Disconnect toggle
  - Clear messages
  - Quit application

### Receiving Notifications
Once configured and connected, you'll receive:
- Native macOS notifications for new messages
- Quick message preview in right-click menu
- Full message history in the dashboard
- Real-time updates via Server-Sent Events

### Sending Notifications
Send notifications to your configured topic using curl, the ntfy mobile app, or any HTTP client:

```bash
# Simple message
curl -d "Hello from ntfy!" https://ntfy.sh/your-topic

# With title and tags
curl -X POST https://ntfy.sh/your-topic \
  -H "Title: Server Alert" \
  -H "Tags: warning,server" \
  -d "Server maintenance in 5 minutes"

# With authentication (if required)
curl -u username:password -d "Authenticated message" https://your-server.com/your-topic
```

## Privacy & Security

- **Local Storage**: Only server URL, topic, and preferences stored locally
- **Keychain Integration**: All passwords and tokens stored securely in macOS Keychain
- **No Data Collection**: No analytics, tracking, or data sent to third parties
- **Sandbox Security**: Full App Sandbox compliance for enhanced security
- **Memory Safety**: Proper memory management with weak references to prevent leaks

## Architecture

### Key Components

- **NtfyMenuBarApp**: SwiftUI app entry point with AppDelegate integration
- **StatusBarController**: NSStatusItem management for menu bar interactions
- **NtfyService**: SSE connection management and message processing
- **SettingsManager**: Secure credential storage using Keychain Services
- **NtfyViewModel**: Reactive state management with Combine
- **NotificationManager**: macOS notification handling

### Technologies Used

- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **URLSession**: HTTP streaming for Server-Sent Events
- **Keychain Services**: Secure credential storage
- **UserNotifications**: Native macOS notification system

## Development

### Build Requirements
- macOS 13.0+ development machine
- Xcode 14.0+
- Valid Apple Developer ID (for distribution)

### Project Structure
```
NtfyMenuBar/
├── NtfyMenuBar/
│   ├── NtfyMenuBarApp.swift      # App entry point
│   ├── Models/                   # Data models
│   ├── Views/                    # SwiftUI views
│   ├── ViewModels/              # View models
│   ├── Services/                # Network services
│   └── Utilities/               # Helper utilities
├── NtfyMenuBar.entitlements     # Sandbox entitlements
├── Info.plist                  # App configuration
└── CLAUDE.md                   # Development documentation
```

### Key Configurations
- **Info.plist**: `LSUIElement = true` (hides from dock)
- **Entitlements**: Network client access for SSE connections
- **Sandbox**: Full App Sandbox with network permissions

## Troubleshooting

### Connection Issues
- Verify server URL is accessible
- Check authentication credentials
- Ensure topic name is correct
- Review network connectivity

### Authentication Problems
- Basic Auth: Verify username/password
- Token Auth: Ensure token format (32 chars, starts with `tk_`)
- Check server authentication requirements

### Notification Issues
- Grant notification permissions in System Settings
- Verify "Enable Notifications" setting in app preferences
- Check Do Not Disturb settings

### Performance
- Reduce "Recent Messages" limit if memory usage is high
- Check Console.app for any error messages
- Restart the app if connection becomes unstable

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [ntfy](https://ntfy.sh) - Simple pub-sub notification service
- [Binwiederhier](https://github.com/binwiederhier) - Creator of ntfy
- Apple's SwiftUI and Combine frameworks

## Support

- **Issues**: [GitHub Issues](https://github.com/reverendrewind/NtfyMenuBar/issues)
- **Discussions**: [GitHub Discussions](https://github.com/reverendrewind/NtfyMenuBar/discussions)
- **ntfy Documentation**: [ntfy.sh/docs](https://ntfy.sh/docs)

---

Made with ❤️ for the macOS community