# NtfyMenuBar

A native macOS menu bar application for [ntfy](https://ntfy.sh) notifications. Get real-time push notifications directly in your menu bar without cluttering your dock.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-green)

## Features

- **Menu Bar Integration**: Runs discretely in your menu bar without a dock icon (LSUIElement)
- **Flat Panel Dashboard**: Click menu bar icon to open borderless dashboard directly below menu bar
- **Toggle Behavior**: Click dashboard icon to open, click again (or click outside) to close
- **Quick Message Preview**: Right-click menu shows 5 most recent messages with timestamps
- **Real-time Notifications**: Live connection to ntfy servers using Server-Sent Events (SSE)
- **Auto-connect at Launch**: Automatically connects to configured server when app starts
- **Dual Authentication**: Support for both Basic Authentication and Bearer Token authentication
- **Secure Storage**: Credentials stored securely in macOS Keychain
- **Enhanced Notifications**: Rich, branded notifications with priority indicators and interactive actions
- **Multi-Desktop Support**: Dashboard appears on current desktop/space, not locked to launch desktop
- **Custom App Icons**: Generated from SVG with proper menu bar template rendering
- **Customizable Settings**: Configure notification preferences, message limits, and auto-connect
- **Connection Stability**: Improved SSE handling with auto-reconnect and keepalive timers
- **Sandbox Compatible**: Full App Sandbox support with proper network entitlements

## Screenshots

*Menu Bar Interface*
- Clean, minimal menu bar icon that matches system appearance
- Right-click context menu with recent messages and quick actions
- Borderless dashboard panel that appears directly below menu bar

*Dashboard Features*
- Shows server URL and topic in header when connected
- Connection status indicator (green=connected, red=disconnected, orange=not configured)
- Real-time message list with empty state when no notifications
- Settings and connection controls in footer

*Settings Panel*
- Server configuration (URL and topic) with validation
- Authentication method selection (Basic Auth or Access Token)
- Secure credential management via macOS Keychain
- Notification preferences and auto-connect toggle
- Recent messages limit configuration (5-100 messages)

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
   - Toggle auto-connect at launch
   - Configure maximum recent messages (5-100)

6. **Connect** - The app will automatically connect when properly configured (if auto-connect enabled)

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
- **Left Click**: Toggle borderless dashboard panel (appears directly below menu bar)
- **Right Click**: Access context menu with:
  - Recent 5 messages with timestamps and priority indicators
  - Quick access to dashboard and settings
  - Connect/Disconnect toggle with current status
  - Clear messages option
  - Quit application
- **Click Outside Dashboard**: Automatically closes the dashboard panel
- **Escape Key**: Close dashboard when it has focus

### Enhanced Notifications
Once configured and connected, you'll receive rich, branded notifications featuring:

**Visual Branding:**
- "ntfy:" prefix for instant recognition
- Priority-based emoji indicators (🔴 Urgent, 🟠 High, 🟡 Default, 🔵 Low, ⚪ Min)
- Smart content formatting with metadata display

**Rich Content:**
- Message content with intelligent truncation
- Priority level and tag information
- Timestamp and topic context
- Server identification

**Interactive Actions:**
- "Open Dashboard" button for quick access
- "Mark Read" to dismiss notifications
- "Dismiss" for immediate removal
- Click notification to open dashboard

**Priority Features:**
- Critical sounds for high-priority messages (4-5)
- Visual priority indicators throughout
- Badge numbers based on message importance

### Notification Examples

**High Priority Alert:**
```
Title: ntfy: 🔴 Server Alert
Subtitle: 📂 production • 🌐 ntfy
Body: Database connection lost - immediate attention required
      ⚠️ Priority: 5
      🏷️ Tags: urgent, database, production
      🕐 2:30 PM
[Open Dashboard] [Mark Read] [Dismiss]
```

**Regular Update:**
```
Title: ntfy: 📢 Deployment Complete  
Subtitle: 📂 updates • 🌐 ntfy
Body: Version 2.1.4 successfully deployed to staging
      🏷️ Tags: deployment, staging
      🕐 2:25 PM
[Open Dashboard] [Mark Read] [Dismiss]
```

### Sending Rich Notifications
Send notifications to your configured topic using curl, the ntfy mobile app, or any HTTP client. The app enhances all notifications with branding and interactive features:

```bash
# Simple message (enhanced automatically)
curl -d "Hello from ntfy!" https://ntfy.sh/your-topic

# Rich notification with priority and tags
curl -X POST https://ntfy.sh/your-topic \
  -H "Title: Server Alert" \
  -H "Priority: 4" \
  -H "Tags: warning,server,production" \
  -d "Server maintenance starting in 5 minutes"

# Critical alert (gets 🔴 indicator and critical sound)
curl -X POST https://ntfy.sh/your-topic \
  -H "Title: Database Down" \
  -H "Priority: 5" \
  -H "Tags: urgent,database,critical" \
  -d "Primary database connection lost - immediate attention required"

# Low priority update (gets 🔵 indicator)
curl -X POST https://ntfy.sh/your-topic \
  -H "Title: Backup Complete" \
  -H "Priority: 2" \
  -H "Tags: backup,success" \
  -d "Daily backup completed successfully at 3:00 AM"

# With authentication (if required)
curl -u username:password \
  -H "Title: Authenticated Alert" \
  -H "Priority: 3" \
  -d "Secured message content" \
  https://your-server.com/your-topic
```

**Priority Levels & Visual Indicators:**
- **Priority 5** → 🔴 Critical (urgent sound, immediate attention)
- **Priority 4** → 🟠 High (critical sound, important)  
- **Priority 3** → 🟡 Default (standard notification)
- **Priority 2** → 🔵 Low (quiet notification)
- **Priority 1** → ⚪ Minimal (subtle notification)

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

## Proxmox VE Integration

NtfyMenuBar provides excellent integration with Proxmox VE's webhook notification system, allowing you to receive server alerts, backup notifications, and system updates directly in your macOS menu bar.

### Quick Setup

1. **Configure your ntfy topic** in NtfyMenuBar (e.g., `proxmox-alerts`)
2. **Create a webhook target** in Proxmox VE
3. **Map notification severities** to ntfy priorities for visual indicators

### Basic Webhook Configuration

In Proxmox VE, create a webhook notification target with:

```
URL: https://your-ntfy-server.com/your-topic
Method: POST
Headers:
  Title: [Proxmox] {{ title }}
  Priority: {{ #if (eq severity "critical") }}5{{ else }}{{ #if (eq severity "warning") }}4{{ else }}3{{ /if }}{{ /if }}
  Tags: proxmox,server
Body: {{ message }}
```

### Advanced Configuration with Severity Mapping

For rich notifications with proper priority indicators:

```
URL: https://your-ntfy-server.com/your-topic
Method: POST
Headers:
  Title: [{{ secrets.server-name }}] {{ title }}
  Priority: {{ lookup (json '{"critical":5,"error":5,"warning":4,"info":3,"notice":2}') severity }}
  Tags: proxmox,{{ secrets.server-name }},{{ secrets.environment }}
Body: {{ message }}\n\n📍 Server: {{ secrets.server-name }}\n🕐 Time: {{ timestamp }}
```

### Severity to Priority Mapping

| Proxmox Severity | ntfy Priority | Visual Indicator | Sound |
|------------------|---------------|------------------|-------|
| `critical`       | 5             | 🔴 Critical      | Critical |
| `error`          | 5             | 🔴 Critical      | Critical |
| `warning`        | 4             | 🟠 High          | Critical |
| `info`           | 3             | 🟡 Default       | Standard |
| `notice`         | 2             | 🔵 Low           | Standard |

### Common Use Cases

**Backup Notifications:**
```
Headers:
  Title: [{{ secrets.server-name }}] Backup {{ #if (eq severity "info") }}Complete{{ else }}Failed{{ /if }}
  Priority: {{ #if (eq severity "info") }}2{{ else }}5{{ /if }}
  Tags: proxmox,backup,{{ secrets.server-name }}
```

**Replication Alerts:**
```
Headers:
  Title: [{{ secrets.server-name }}] Replication Alert
  Priority: 4
  Tags: proxmox,replication,{{ secrets.server-name }}
```

**System Alerts:**
```
Headers:
  Title: [{{ secrets.server-name }}] System Alert
  Priority: 5
  Tags: proxmox,system,urgent,{{ secrets.server-name }}
```

### Authentication Setup

For secure ntfy servers, configure authentication in Proxmox secrets:

**Basic Auth:**
```
Secrets:
  username: your-ntfy-username
  password: your-ntfy-password

Headers:
  Authorization: Basic {{ base64 (concat secrets.username ":" secrets.password) }}
```

**Access Token:**
```
Secrets:
  token: tk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Headers:
  Authorization: Bearer {{ secrets.token }}
```

### Multi-Server Configuration

For multiple Proxmox servers, use server-specific topics or tags:

```
URL: https://your-ntfy-server.com/proxmox-{{ secrets.server-name }}
# OR
Tags: proxmox,{{ secrets.server-name }},{{ secrets.datacenter }}
```

### Testing Your Configuration

Test your webhook with a simple curl command:

```bash
curl -X POST https://your-ntfy-server.com/your-topic \
  -H "Title: [Test] Proxmox Integration Test" \
  -H "Priority: 3" \
  -H "Tags: proxmox,test" \
  -d "This is a test notification from Proxmox VE webhook integration"
```

### Troubleshooting

**Notifications not appearing:**
- Verify ntfy server URL and topic configuration
- Check Proxmox VE webhook target test results
- Ensure authentication credentials are correct
- Verify network connectivity from Proxmox to ntfy server

**Wrong priority indicators:**
- Check severity mapping in webhook configuration
- Verify Handlebars templating syntax
- Test with manual curl commands using different priorities

**Missing server context:**
- Ensure secrets are properly configured in Proxmox
- Verify templating variables in webhook body/headers
- Check for proper escaping of special characters

## Support

- **Issues**: [GitHub Issues](https://github.com/reverendrewind/NtfyMenuBar/issues)
- **Discussions**: [GitHub Discussions](https://github.com/reverendrewind/NtfyMenuBar/discussions)
- **ntfy Documentation**: [ntfy.sh/docs](https://ntfy.sh/docs)
- **Proxmox VE Notifications**: [PVE Docs](https://pve.proxmox.com/pve-docs/chapter-notifications.html)

## Acknowledgments

- [ntfy](https://ntfy.sh) - Simple pub-sub notification service
- [Binwiederhier](https://github.com/binwiederhier) - Creator of ntfy
- Apple's SwiftUI and Combine frameworks

---

Made with ❤️ for the macOS community