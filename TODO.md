# TODO - NtfyMenuBar

*Last Updated: 2025-09-21*
*Feasibility Analysis Completed: 2025-01-20*

📖 **See [CHANGELOG.md](CHANGELOG.md) for completed features and version history**

## Priority Roadmap

### 🟢 HIGH PRIORITY - Feasible & High Value
*Features that can be implemented with existing ntfy HTTP API and provide significant user value*

#### Access Token Management - API Available ✅
- [x] Generate new access tokens - `POST /v1/account/token` *(Completed)*
- [x] Copy tokens to clipboard securely *(Completed)*
- [x] Token regeneration and management UI *(Completed)*
- [x] Secure token storage in Keychain *(Already implemented)*

#### UI/UX Improvements - Client-Side ✅
- [x] Dark/Light mode sync with system *(Already implemented)*
- [x] Customizable notification sounds *(Completed)*
- [x] Message grouping by topic/priority *(Completed)*
- [x] Keyboard shortcuts for common actions *(Completed)*
- [x] Notification snoozing *(Completed v2.4.0)*
- [x] Do Not Disturb scheduling *(Completed)*

#### Connection Improvements - Client-Side ✅
- [x] Auto-reconnect with exponential backoff *(Already implemented)*
- [x] Network change detection and handling *(Completed)*
- [x] Connection quality indicator *(Completed)*
- [x] Fallback server support *(Completed)*

### 🟡 MEDIUM PRIORITY - Feasible with Limitations
*Features possible but with constraints or workarounds*

#### Message Management (Limited Capabilities)
- [x] View recent message history (client-side caching via SSE) *(Already implemented)*
- [ ] Delete individual messages (if API permits)
- [x] Export message logs to CSV/JSON (cached messages only) *(Completed)*
- [x] Message filtering by priority/topic (client-side) *(Completed)*

#### Multi-Server Support
- [x] Support for managing multiple ntfy servers *(Completed)*
- [x] Server switching in UI *(Completed)*
- [x] Per-server credential management *(Completed)*

#### Integration Features
- [ ] Export to other services (Slack, Discord, etc.)
- [ ] Webhook forwarding
- [ ] Custom notification actions
- [ ] AppleScript support for automation *(Deferred to future version - sandbox configuration complexity)*
- [x] Shortcuts app integration *(Completed)*

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

## Current Status Summary

### ✅ Recently Completed (v2.4.0)
- **Notification Snoozing**: Complete implementation with 8 preset durations and custom branded icon
- **Message Filtering**: Advanced search and multi-selection filtering system
- **Bug Fixes**: Dashboard header display, snooze functionality, Swift 6 compatibility

### 🎯 Next Priorities
1. **Custom notification actions** - Interactive notification buttons and responses
2. **Delete individual messages** - Message management capabilities (if API permits)
3. **Export to other services** - Integration with Slack, Discord, etc.
4. **Webhook forwarding** - Forward notifications to external services

### 📚 Documentation & Testing
- [x] Proxmox VE integration guide *(Completed)*
- [ ] Video tutorials for setup
- [ ] Troubleshooting guide expansion
- [ ] Unit tests for new features
- [ ] Integration tests with mock ntfy server

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

### Implementation Progress

**✅ Phase 1 Completed**: Personal access token management, enhanced authentication, UI/UX improvements
**✅ Phase 2 Completed**: Connection enhancements, message filtering, notification snoozing
**🔄 Phase 3 In Progress**: Client-side message management (export functionality), system integrations

### Current Recommendation

Continue focus on **HIGH PRIORITY** and **MEDIUM PRIORITY** items that provide user value within ntfy's API constraints. Next development should prioritize:

1. **Do Not Disturb scheduling** - High user value, client-side implementation
2. **Message export functionality** - Medium priority, works with cached messages
3. **System integrations** - AppleScript and Shortcuts app support for automation

---

*Last Updated: 2025-09-21*