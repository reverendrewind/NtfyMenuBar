# TODO - NtfyMenuBar

## Feature Ideas

### ntfy Server Management
Add comprehensive ntfy server management capabilities directly within the menu bar app.

#### Topic Management
- [ ] List all topics on the server
- [ ] Create new topics (with authentication)
- [ ] Delete topics (with confirmation dialog)
- [ ] View topic statistics
  - [ ] Subscriber count
  - [ ] Message count
  - [ ] Last activity timestamp
- [ ] Topic access control management
  - [ ] Set read/write permissions
  - [ ] Manage allowed users per topic

#### User Management (Admin Features)
- [ ] List all users (admin only)
- [ ] Create new users
- [ ] Edit user properties
- [ ] Delete users (with confirmation)
- [ ] Manage user permissions and topic access
- [ ] View user statistics
  - [ ] Message count
  - [ ] Last login
  - [ ] Active topics

#### Server Statistics & Monitoring
- [ ] Server health status indicator
- [ ] Real-time message throughput graph
- [ ] Active subscriber counts
- [ ] Storage usage metrics with visual indicators
- [ ] Uptime monitoring and history
- [ ] Server version information
- [ ] Performance metrics (CPU, memory if available)

#### Message Management
- [ ] View complete message history for topics
- [ ] Search messages by content, date, or tags
- [ ] Filter messages by priority, sender, or metadata
- [ ] Delete individual messages (if permitted)
- [ ] Bulk message operations
- [ ] Export message logs to CSV/JSON
- [ ] Message analytics and trends

#### Access Token Management
- [ ] Generate new access tokens with custom permissions
- [ ] List all active tokens
- [ ] Revoke tokens (with confirmation)
- [ ] Set token expiration dates
- [ ] View token permissions and scopes
- [ ] Token usage statistics and last used timestamps
- [ ] Copy tokens to clipboard securely

#### Server Configuration (Admin Only)
- [ ] View current server configuration
- [ ] Modify server settings through API (if supported)
- [ ] Backup server configurations
- [ ] Restore server configurations
- [ ] Export/import configuration files
- [ ] Server maintenance mode toggle

#### Implementation Approaches
- [ ] **Admin Panel in Settings**: Add new "Server Management" tab
- [ ] **Separate Management Window**: Dedicated server admin interface
- [ ] **Context Menu Integration**: Quick management actions from menu bar
- [ ] **Dashboard Enhancement**: Integrate management features into existing dashboard

#### Technical Requirements
- [ ] Implement ntfy server management API endpoints
- [ ] Handle authentication for admin operations
- [ ] Design intuitive UI matching current app aesthetic
- [ ] Graceful permission handling with clear error messages
- [ ] Support for managing multiple ntfy servers
- [ ] Caching strategy for server data
- [ ] Real-time updates using SSE/WebSocket where applicable

#### Security Considerations
- [ ] Secure storage of admin credentials in Keychain
- [ ] Session management and auto-logout
- [ ] Audit logging for admin actions
- [ ] Rate limiting for API calls
- [ ] Certificate pinning for enhanced security

## Enhancements to Existing Features

### Connection Improvements
- [ ] Auto-reconnect with exponential backoff (improved)
- [ ] Network change detection and handling
- [ ] Connection quality indicator
- [ ] Fallback server support

### UI/UX Improvements
- [ ] Dark/Light mode sync with system
- [ ] Customizable notification sounds
- [ ] Message grouping by topic/priority
- [ ] Keyboard shortcuts for common actions
- [ ] Notification snoozing
- [ ] Do Not Disturb scheduling

### Performance Optimizations
- [ ] Message database with SQLite for history
- [ ] Lazy loading for large message lists
- [ ] Background sync optimization
- [ ] Memory usage optimization for long-running sessions

### Integration Features
- [ ] Export to other services (Slack, Discord, etc.)
- [ ] Webhook forwarding
- [ ] Custom notification actions
- [ ] AppleScript support for automation
- [ ] Shortcuts app integration

## Bug Fixes
- [x] Dock icon appearing despite LSUIElement setting
- [x] SSE connection timeouts and disconnections
- [ ] Add any newly discovered bugs here

## Documentation
- [x] Proxmox VE integration guide
- [ ] Video tutorials for setup
- [ ] API documentation for server management
- [ ] Troubleshooting guide expansion
- [ ] Best practices guide

## Testing
- [ ] Unit tests for server management features
- [ ] Integration tests with mock ntfy server
- [ ] Performance testing with high message volume
- [ ] Multi-server connection testing
- [ ] Error handling test scenarios

---

*Last Updated: 2025-01-20*