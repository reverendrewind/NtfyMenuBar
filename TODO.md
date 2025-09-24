# TODO - NtfyMenuBar

*Last Updated: 2025-09-24*
*Feasibility Analysis Completed: 2025-01-20*

📖 **See [CHANGELOG.md](CHANGELOG.md) for completed features and version history**

## Priority Roadmap

### 🟢 HIGH PRIORITY - Feasible & High Value
*Features implementable with existing ntfy HTTP API*

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
- [x] Do Not Disturb scheduling *(Completed v2.5.2)*

#### Connection Improvements - Client-Side ✅
- [x] Auto-reconnect with exponential backoff *(Already implemented)*
- [x] Network change detection and handling *(Completed)*
- [x] Connection quality indicator *(Completed)*
- [x] Fallback server support *(Completed)*

### 🟡 MEDIUM PRIORITY - Feasible with Limitations
*Features with implementation constraints*

#### Message Management (Limited Capabilities)
- [x] View recent message history (client-side caching via SSE) *(Already implemented)*
- [x] Archive management and statistics *(Completed v2.5.2)*
- [x] Browse archived messages with search/filter *(Completed v2.5.2)*
- [x] Clear old archived messages by age *(Completed v2.5.2)*
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
- [ ] **Custom snooze duration picker** *(Removed due to macOS SwiftUI limitations - needs native NSAlert approach)*
- [ ] **AppleScript support for automation** *(High value - requires OSAKit framework integration)*
- [ ] **Enhanced Shortcuts app integration** *(Expand beyond basic intents to full automation suite)*

### 🔴 LOW PRIORITY - Limited Feasibility
*Features limited by ntfy API constraints*

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

### ✅ Recently Completed (v2.5.2)
- **Architectural Refactoring**: Complete SettingsView component extraction (1,843 → 635 lines, 54% reduction)
- **Do Not Disturb Scheduling**: Time-based notification blocking with weekday selection (fixed Sunday-first week bug)
- **Archive Management**: Complete message archive system with statistics, browsing, search, and cleanup
- **Open Source Preparation**: MIT LICENSE, professional logging infrastructure, community-ready codebase
- **Professional Placeholders**: Updated all UI text to action-oriented, professional language

### 🎯 Next Priorities
1. **AppleScript support for automation** - High-value automation integration with OSAKit framework
2. **Enhanced Shortcuts app integration** - Expand beyond basic intents to full automation suite
3. **Custom notification actions** - Interactive notification buttons and responses
4. **Delete individual messages** - Message management capabilities (if API permits)
5. **Export to other services** - Integration with Slack, Discord, etc.
6. **Webhook forwarding** - Forward notifications to external services

### 🏗️ Architecture & Code Quality
- [x] **Complete SettingsView refactoring** *(Completed v2.5.2)* - Extracted 6 core settings components, reduced from 1,843 to 635 lines (54% reduction)
- [x] **Component-based architecture** *(Completed v2.5.2)* - Single-responsibility principle with Views/Settings/ directory structure
- [x] **Professional logging infrastructure** *(Completed v2.5.2)* - OSLog integration replacing debug print statements
- [x] **Open source preparation** *(Completed v2.5.2)* - MIT LICENSE, community-ready codebase
- [ ] **Unit tests for new features** - Test coverage for extracted components and core functionality
- [ ] **Integration tests with mock ntfy server** - End-to-end testing infrastructure

### 📚 Documentation & Testing
- [x] Proxmox VE integration guide *(Completed)*
- [ ] Video tutorials for setup
- [ ] Troubleshooting guide expansion
- [ ] Component architecture documentation
- [ ] Developer contribution guide

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
**✅ Phase 2A Completed**: Complete SettingsView architectural refactoring with component extraction
**✅ Phase 2B Completed**: Connection enhancements, message filtering, notification snoozing, DND scheduling
**✅ Phase 2C Completed**: Archive management system, open source preparation, professional UI polish
**🔄 Phase 3 In Progress**: System integrations (AppleScript, enhanced Shortcuts), advanced automation

### Current Recommendation

Continue focus on **HIGH PRIORITY** and **MEDIUM PRIORITY** items that provide user value within ntfy's API constraints. Next development should prioritize:

1. **AppleScript automation support** - macOS workflow integration
2. **Enhanced Shortcuts app integration** - Expand beyond basic intents for comprehensive automation
3. **System integrations** - Third-party service forwarding (Slack, Discord, webhooks)

---

*Last Updated: 2025-09-24*