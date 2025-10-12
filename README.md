# NtfyMenuBar

A lightweight macOS menu bar client for [ntfy](https://ntfy.sh) notifications.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-green)

## Features

- Native macOS menu bar integration
- Real-time Server-Sent Events (SSE) connection
- Secure credential storage in Keychain
- System notifications with priority indicators
- Dark/light mode support
- Message archiving and search
- Notification snoozing
- Multi-server fallback support

## Requirements

- macOS 15.6 or later
- Active ntfy server (self-hosted or ntfy.sh)

## Quick Start

1. **Download** the latest release or build from source
2. **Launch** - App appears in menu bar
3. **Configure** via Settings:
   - Server URL (e.g., `https://ntfy.sh`)
   - Topics to subscribe to
   - Authentication if required
4. **Connect** - Notifications appear automatically

## Authentication

### Basic Auth
```
Username: your-username
Password: your-password
```

### Access Token
```
Token: tk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
Tokens are stored securely in macOS Keychain.

## Sending Notifications

```bash
# Simple message
curl -d "Hello from ntfy!" https://ntfy.sh/your-topic

# Rich notification
curl -X POST https://ntfy.sh/your-topic \
  -H "Title: Server Alert" \
  -H "Priority: 4" \
  -H "Tags: warning,server" \
  -d "Maintenance starting in 5 minutes"
```

**Priority Levels:**
- 5: Critical (🔴)
- 4: High (🟠)
- 3: Default (🟡)
- 2: Low (🔵)
- 1: Minimal (⚪)

## Keyboard Shortcuts

- **⌘F** - Focus search field
- **⌘,** - Open Settings
- **⌘Q** - Quit application
- **⌘W** - Close window
- **Escape** - Close current window
- **Tab** - Navigate between controls
- **Space/Return** - Activate buttons and controls

## Accessibility

NtfyMenuBar supports macOS accessibility features:

- **VoiceOver** - Full screen reader support (⌘F5 to toggle)
- **Full Keyboard Access** - Complete keyboard navigation
- **Display Accommodations** - High contrast, reduce motion, color filters
- **Dynamic Type** - Respects system text size preferences
- **Voice Control** - Navigate and control via voice commands

For accessibility feedback, please [open an issue](https://github.com/reverendrewind/NtfyMenuBar/issues).

## Building from Source

```bash
git clone https://github.com/reverendrewind/NtfyMenuBar.git
cd NtfyMenuBar
open NtfyMenuBar.xcodeproj
```

Build with Xcode (⌘+R) or command line:
```bash
xcodebuild -scheme NtfyMenuBar -configuration Release build
```

## Architecture

- **SwiftUI** - Modern declarative UI
- **Combine** - Reactive state management
- **URLSession** - SSE streaming
- **Keychain Services** - Secure storage
- **App Sandbox** - Enhanced security

Key components:
- `NtfyService` - Connection management
- `SettingsManager` - Secure credential storage
- `ConnectionManager` - Enhanced error handling
- `MessageArchive` - Local message storage

## Proxmox Integration

Perfect for Proxmox VE webhook notifications:

```
URL: https://ntfy.sh/proxmox-alerts
Headers:
  Title: [{{ secrets.server-name }}] {{ title }}
  Priority: {{ lookup (json '{"critical":5,"warning":4,"info":3}') severity }}
  Tags: proxmox,{{ secrets.server-name }}
```

## Privacy & Security

- Local data storage only
- Keychain integration for credentials
- No analytics or tracking
- Full App Sandbox compliance
- Memory-safe implementation

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/name`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push branch (`git push origin feature/name`)
5. Open Pull Request

## License

MIT License - see [LICENSE](LICENSE) file.

## Support

- [Issues](https://github.com/reverendrewind/NtfyMenuBar/issues)
- [Discussions](https://github.com/reverendrewind/NtfyMenuBar/discussions)
- [ntfy Documentation](https://ntfy.sh/docs)

---

Made with ❤️ for the macOS community