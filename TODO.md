# TODO - NtfyMenuBar

*Last Updated: 2025-01-20*
*Feasibility Analysis Completed: 2025-01-20*

## Priority Roadmap

### 🟢 HIGH PRIORITY - Feasible & High Value
*Features that can be implemented with existing ntfy HTTP API and provide significant user value*

#### Access Token Management - API Available ✅
- [ ] Generate new access tokens - `POST /v1/account/token`
- [ ] Copy tokens to clipboard securely
- [ ] Token regeneration and management UI
- [ ] Secure token storage in Keychain (already implemented)

#### UI/UX Improvements - Client-Side ✅
- [x] Dark/Light mode sync with system *(Already implemented)*
- [ ] Customizable notification sounds
- [ ] Message grouping by topic/priority
- [ ] Keyboard shortcuts for common actions
- [ ] Notification snoozing
- [ ] Do Not Disturb scheduling

#### Connection Improvements - Client-Side ✅
- [x] Auto-reconnect with exponential backoff *(Already implemented)*
- [ ] Network change detection and handling
- [ ] Connection quality indicator
- [ ] Fallback server support

### 🟡 MEDIUM PRIORITY - Feasible with Limitations
*Features possible but with constraints or workarounds*

#### Message Management (Limited Capabilities)
- [ ] View recent message history (client-side caching via SSE)
- [ ] Delete individual messages (if API permits)
- [ ] Export message logs to CSV/JSON (cached messages only)
- [ ] Message filtering by priority/topic (client-side)

#### Multi-Server Support
- [ ] Support for managing multiple ntfy servers
- [ ] Server switching in UI
- [ ] Per-server credential management

#### Integration Features
- [ ] Export to other services (Slack, Discord, etc.)
- [ ] Webhook forwarding
- [ ] Custom notification actions
- [ ] AppleScript support for automation
- [ ] Shortcuts app integration

### 🔴 LOW PRIORITY - Limited Feasibility
*Features that are difficult or impossible with current ntfy API*

#### Topic Statistics - ⚠️ API Limitations
- [ ] ~~Subscriber count~~ *(Not available via HTTP API)*
- [ ] ~~Message count~~ *(Not available via HTTP API)*
- [ ] ~~Last activity timestamp~~ *(Not available via HTTP API)*

#### Server Statistics & Monitoring - ❌ Not Possible
- [ ] ~~Server health status indicator~~ *(CLI/admin only)*
- [ ] ~~Real-time message throughput graph~~ *(No API support)*
- [ ] ~~Active subscriber counts~~ *(Not exposed via API)*
- [ ] ~~Storage usage metrics~~ *(CLI/admin only)*
- [ ] ~~Uptime monitoring and history~~ *(No API support)*
- [ ] ~~Server version information~~ *(CLI only)*
- [ ] ~~Performance metrics (CPU, memory)~~ *(Not available)*

#### Server Configuration - ❌ Admin/CLI Only
- [ ] ~~View current server configuration~~ *(Requires server access)*
- [ ] ~~Modify server settings through API~~ *(Not supported)*
- [ ] ~~Backup server configurations~~ *(File system access required)*
- [ ] ~~Server maintenance mode toggle~~ *(CLI only)*

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

## 📊 Feasibility Analysis Summary

### Research Findings (January 2025)

After comprehensive research of ntfy's HTTP API capabilities, the following constraints were identified:

#### ✅ **Available HTTP API Endpoints:**
- **Account Management**: Personal access token generation, password changes
- **Authentication**: Basic auth and Bearer tokens
- **Publishing/Subscribing**: Full message flow support

#### ⚠️ **Limited API Support:**
- **Message History**: Only cached messages accessible, no server-side search
- **Topic Management**: Basic operations only, no statistics
- **Token Management**: Generation available, but limited administrative controls

#### ❌ **No HTTP API Support:**
- **User Management**: All user operations are CLI-only (ntfy user commands)
- **Server Statistics**: Health, performance, storage metrics
- **Server Configuration**: All configuration is file-based
- **Topic Statistics**: Subscriber counts, message counts, activity timestamps
- **Advanced Monitoring**: Real-time throughput, uptime tracking

#### 🔧 **CLI-Only Features:**
Most server administration requires CLI access:
- **User Management**: `ntfy user add/del/list/change-pass/change-role`
- Server configuration changes
- Database management and backups
- Performance monitoring
- System health checks

### Recommendation

Focus development on **HIGH PRIORITY** items that provide immediate user value and are technically feasible. The original TODO scope was overly ambitious given ntfy's API limitations. A more realistic approach would be:

1. **Phase 1**: Personal access token management and enhanced authentication
2. **Phase 2**: UI/UX improvements and connection enhancements
3. **Phase 3**: Client-side message management and multi-server support

**Note**: User management features were removed from the roadmap as ntfy only supports CLI-based user administration (`ntfy user` commands) with no HTTP API endpoints available.

---

*Last Updated: 2025-01-20*