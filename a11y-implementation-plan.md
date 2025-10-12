# NtfyMenuBar Accessibility Implementation Plan

**Project:** NtfyMenuBar
**Plan Version:** 1.0
**Created:** October 12, 2025
**Status:** Ready for Implementation

---

## Overview

This implementation plan addresses **15 accessibility issues** identified in the audit, organized by priority and implementation effort. Total estimated time: **4-6 hours** spread across three phases.

### Issue Breakdown
- **Critical:** 3 issues (blocks VoiceOver users)
- **Major:** 7 issues (significant usability impact)
- **Minor:** 5 issues (best practices)

### Implementation Strategy
1. **Quick Wins** (30 min) - High impact, low effort
2. **Phase 1** (1-2 hrs) - Critical accessibility blockers
3. **Phase 2** (2-3 hrs) - Major usability improvements
4. **Phase 3** (1-2 hrs) - Best practices and polish

---

## Quick Wins (15-30 minutes)

### Goal: Fix 4 high-impact issues with minimal code changes

| Issue | File | Lines | Effort | Impact |
|-------|------|-------|--------|--------|
| Icon button labels | SearchAndFilterBar.swift | 33-70 | 5 min | High |
| Icon button labels | ConnectionSettingsView.swift | 91-98 | 2 min | High |
| Menu bar accessibility | StatusBarController.swift | 44-99 | 10 min | Critical |
| Filter status indicator | SearchAndFilterBar.swift | 48-70 | 5 min | High |

---

### Quick Win #1: Add Labels to Icon-Only Buttons

**Priority:** Critical
**Effort:** 5 minutes
**Files:** SearchAndFilterBar.swift

#### Implementation:

```swift
// SearchAndFilterBar.swift:33-41
// CHANGE: Add .accessibilityLabel()

if !searchText.isEmpty {
    Button {
        searchText = ""
    } label: {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Clear search")  // ADD THIS LINE
}
```

```swift
// SearchAndFilterBar.swift:49-62
// CHANGE: Add .accessibilityLabel() and .accessibilityHint()

Button {
    showFilterOptions.toggle()
} label: {
    HStack(spacing: 3) {
        Image(systemName: "line.3.horizontal.decrease.circle")
            .font(.system(size: 12))
        if hasActiveFilters {
            Circle()
                .fill(Color.blue)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)  // ADD THIS LINE
        }
    }
    .foregroundColor(hasActiveFilters ? .blue : .secondary)
}
.buttonStyle(.plain)
.accessibilityLabel(hasActiveFilters ? "Filters (active)" : "Filters")  // ADD THIS LINE
.accessibilityHint("Opens filter options for priorities and topics")  // ADD THIS LINE
.popover(isPresented: $showFilterOptions) {
    // ... existing code ...
}
```

**Testing:**
1. Run app and open dashboard
2. Enable VoiceOver (Cmd+F5)
3. Navigate to search field with text entered
4. Verify clear button announces "Clear search, button"
5. Navigate to filter button
6. Verify it announces "Filters, button" or "Filters (active), button"

---

### Quick Win #2: Add Labels to Topic Remove Buttons

**Priority:** Critical
**Effort:** 2 minutes
**Files:** ConnectionSettingsView.swift

#### Implementation:

```swift
// ConnectionSettingsView.swift:91-98
// CHANGE: Add .accessibilityLabel()

Button(action: {
    removeTopic(topic)
}) {
    Image(systemName: "xmark.circle.fill")
        .font(.system(size: 12))
        .foregroundColor(.secondary)
}
.buttonStyle(.plain)
.accessibilityLabel("Remove topic \(topic)")  // ADD THIS LINE
```

**Testing:**
1. Open Settings > Connection
2. Add a topic (e.g., "test")
3. Enable VoiceOver
4. Navigate to topic badge
5. Verify remove button announces "Remove topic test, button"

---

### Quick Win #3: Add Menu Bar Status Item Accessibility

**Priority:** Critical
**Effort:** 10 minutes
**Files:** StatusBarController.swift

#### Implementation:

```swift
// StatusBarController.swift:44-58
// CHANGE: Add accessibility properties to button

private func setupStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusItem?.button {
        // Set the icon
        if let image = NSImage(named: StringConstants.Assets.menuBarIcon) {
            image.isTemplate = true
            button.image = image
        }

        // ADD THESE LINES:
        button.accessibilityTitle = "Ntfy Notifications"
        button.accessibilityLabel = "Ntfy menu bar, click to open dashboard, right-click for menu"

        // Set up actions
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
}
```

```swift
// StatusBarController.swift:80-99
// CHANGE: Update accessibility when icon changes state

private func updateStatusIcon() {
    guard let button = statusItem?.button else { return }

    if viewModel.isSnoozed {
        if let image = NSImage(named: StringConstants.Assets.menuBarIconSnooze) {
            image.isTemplate = true
            button.image = image
            button.toolTip = "Notifications snoozed - \(viewModel.snoozeStatusText)"
            // ADD THESE LINES:
            button.accessibilityTitle = "Ntfy Notifications (Snoozed)"
            button.accessibilityLabel = "Ntfy menu bar, notifications snoozed until \(viewModel.snoozeStatusText), click to open dashboard"
        }
    } else {
        if let image = NSImage(named: StringConstants.Assets.menuBarIcon) {
            image.isTemplate = true
            button.image = image
            button.toolTip = "ntfy Notifications"
            // ADD THESE LINES:
            button.accessibilityTitle = "Ntfy Notifications"
            button.accessibilityLabel = "Ntfy menu bar, click to open dashboard, right-click for menu"
        }
    }
}
```

**Testing:**
1. Launch app
2. Enable VoiceOver
3. Navigate to menu bar (VO+M)
4. Move to Ntfy icon (VO+Left/Right Arrow)
5. Verify announcement: "Ntfy Notifications, Ntfy menu bar, click to open dashboard, right-click for menu"
6. Test snoozed state:
   - Right-click icon > Snooze notifications > 5 minutes
   - Navigate back to menu bar icon
   - Verify announcement includes "(Snoozed)" and snooze time

---

### Quick Win #4: Fix Filter Status Indicator

**Priority:** Major
**Effort:** 5 minutes (already done in Quick Win #1)
**Files:** SearchAndFilterBar.swift

See Quick Win #1 above - the filter button fixes include:
- Hiding the blue circle from VoiceOver (`.accessibilityHidden(true)`)
- Adding state to button label ("Filters" vs "Filters (active)")
- Adding hint about what the button does

**Testing:** See Quick Win #1 testing steps

---

## Phase 1: Critical Fixes (1-2 hours)

### Goal: Remove all accessibility blockers for VoiceOver users

---

### Task 1.1: Fix Decorative Emoji Announcements in Messages

**Priority:** Critical
**Effort:** 20 minutes
**Files:** MessageRowView.swift
**Issue:** VoiceOver reads emoji descriptions instead of tag names

#### Implementation:

```swift
// MessageRowView.swift:43-56
// REPLACE: Entire tag display section

// BEFORE:
if let tags = message.tags, !tags.isEmpty {
    HStack {
        ForEach(tags.prefix(UIConstants.MenuBar.recentMessagesLimit), id: \.self) { tag in
            Text(emojiForTag(tag))
                .font(.caption)
        }

        if tags.count > UIConstants.MenuBar.recentMessagesLimit {
            Text("+\(tags.count - UIConstants.MenuBar.recentMessagesLimit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// AFTER:
if let tags = message.tags, !tags.isEmpty {
    HStack {
        ForEach(tags.prefix(UIConstants.MenuBar.recentMessagesLimit), id: \.self) { tag in
            Text(emojiForTag(tag))
                .font(.caption)
        }

        if tags.count > UIConstants.MenuBar.recentMessagesLimit {
            Text("+\(tags.count - UIConstants.MenuBar.recentMessagesLimit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    .accessibilityElement(children: .ignore)  // Ignore individual emojis
    .accessibilityLabel("Tags: \(tags.joined(separator: ", "))")  // Announce tag names
}
```

**Testing:**
1. Send test notification with tags: `curl -H "Tags: urgent,server,production" -d "Test message" https://ntfy.sh/your-topic`
2. Open dashboard
3. Enable VoiceOver
4. Navigate to message with tags
5. Verify VoiceOver announces "Tags: urgent, server, production" not emoji descriptions

---

### Task 1.2: Improve Message Row Accessibility

**Priority:** Critical
**Effort:** 30 minutes
**Files:** MessageRowView.swift
**Issue:** Message components announced separately, priority not included

#### Implementation:

**Step 1:** Add helper computed property for accessibility:

```swift
// MessageRowView.swift
// ADD after line 63 (after timeString property)

private var accessibilityDescription: String {
    let priorityText = priorityDescription
    let messageText = message.message ?? StringConstants.NotificationContent.noMessage
    let tagsText = message.tags?.isEmpty == false ?
        "Tags: \(message.tags!.joined(separator: ", "))." : ""

    return "\(priorityText) \(message.displayTitle): \(messageText). Topic: \(message.topic). \(timeString). \(tagsText)"
}

private var priorityDescription: String {
    switch message.priority {
    case 5: return "Urgent priority."
    case 4: return "High priority."
    case 3: return "Normal priority."
    case 2: return "Low priority."
    case 1: return "Minimal priority."
    default: return ""
    }
}
```

**Step 2:** Update body to use accessibility:

```swift
// MessageRowView.swift:13-62
// CHANGE: Add accessibility modifiers to main VStack

var body: some View {
    VStack(alignment: .leading, spacing: 2) {
        // ... existing content (lines 14-56) ...
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 2)
    .background(Color.theme.cardBackground)
    .cornerRadius(6)
    // ADD THESE LINES:
    .accessibilityElement(children: .ignore)  // Combine into single element
    .accessibilityLabel(accessibilityDescription)  // Use our custom description
    .accessibilityAddTraits(.isButton)  // Indicate it's interactive
}
```

**Testing:**
1. Open dashboard with messages
2. Enable VoiceOver
3. Navigate through messages
4. Verify each message announced as: "High priority. Server Alert: Maintenance starting in 5 minutes. Topic: alerts. 2 hours ago. Tags: warning, server."

---

### Task 1.3: Fix Empty State Accessibility

**Priority:** Major
**Effort:** 5 minutes
**Files:** EmptyStateView.swift

#### Implementation:

```swift
// EmptyStateView.swift:11-23
// CHANGE: Add accessibility modifiers

var body: some View {
    VStack(spacing: 8) {
        Image(systemName: "bell.slash")
            .font(.title2)
            .foregroundColor(.secondary)
            .accessibilityHidden(true)  // ADD THIS LINE - icon is decorative

        Text("No notifications yet")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
    // ADD THESE LINES:
    .accessibilityElement(children: .combine)
    .accessibilityLabel("No notifications yet")
    .accessibilityAddTraits(.isStaticText)
}
```

**Testing:**
1. Clear all messages (right-click menu bar icon > Clear messages)
2. Open dashboard
3. Enable VoiceOver
4. Verify announcement: "No notifications yet"

---

### Task 1.4: Fix Snooze Menu Item Emoji

**Priority:** Major
**Effort:** 15 minutes
**Files:** MenuBuilder.swift

#### Implementation:

```swift
// MenuBuilder.swift:116-134
// CHANGE: Remove emoji from VoiceOver announcement

private func addSnoozeStatusItems(to menu: NSMenu) {
    guard let viewModel = viewModel else { return }

    // REPLACE these lines:
    let snoozeStatusItem = NSMenuItem(
        title: "🔕 \(viewModel.snoozeStatusText)",
        action: nil,
        keyEquivalent: ""
    )
    snoozeStatusItem.isEnabled = false
    menu.addItem(snoozeStatusItem)

    // WITH:
    let statusText = "Snoozed until \(viewModel.snoozeStatusText)"
    let snoozeStatusItem = NSMenuItem(
        title: "🔕 \(viewModel.snoozeStatusText)",  // Keep emoji for visual users
        action: nil,
        keyEquivalent: ""
    )
    snoozeStatusItem.isEnabled = false

    // Create attributed string with accessibility label
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
    ]
    let attributedTitle = NSMutableAttributedString(
        string: "🔕 \(viewModel.snoozeStatusText)",
        attributes: attributes
    )

    snoozeStatusItem.attributedTitle = attributedTitle
    snoozeStatusItem.accessibilityLabel = statusText  // VoiceOver uses this

    menu.addItem(snoozeStatusItem)

    // ... rest of method unchanged ...
}
```

**Alternative Simpler Approach:**
```swift
// Just remove emoji for VoiceOver users:
let snoozeStatusItem = NSMenuItem(
    title: viewModel.snoozeStatusText,  // No emoji
    action: nil,
    keyEquivalent: ""
)
snoozeStatusItem.isEnabled = false
menu.addItem(snoozeStatusItem)
```

**Testing:**
1. Right-click menu bar icon
2. Snooze notifications > 5 minutes
3. Right-click again to open menu
4. Enable VoiceOver
5. Navigate to snooze status item
6. Verify announcement: "Snoozed until [time]" without "bell with cancellation stroke"

---

## Phase 2: Major Improvements (2-3 hours)

### Goal: Enhance usability for all assistive technology users

---

### Task 2.1: Add Accessibility Hints to Settings Tabs

**Priority:** Major
**Effort:** 20 minutes
**Files:** SettingsView.swift

#### Implementation:

**Step 1:** Add hint helper method:

```swift
// SettingsView.swift
// ADD after line 201 (after isValidConfiguration)

private func accessibilityHintForTab(_ tab: SettingsTab) -> String {
    switch tab {
    case .connection:
        return "Configure server URL, topics, and authentication"
    case .tokens:
        return "Manage access tokens for ntfy server"
    case .fallbacks:
        return "Set up backup servers for failover"
    case .dnd:
        return "Schedule Do Not Disturb times"
    case .archive:
        return "View and manage archived messages"
    case .preferences:
        return "Adjust appearance and notification settings"
    }
}
```

**Step 2:** Update picker:

```swift
// SettingsView.swift:88-95
// CHANGE: Add accessibility label and hint

Picker("", selection: $selectedTab) {
    ForEach(SettingsTab.allCases, id: \.self) { tab in
        Label(tab.rawValue, systemImage: tab.systemImage)
            .tag(tab)
    }
}
.pickerStyle(.segmented)
.accessibilityLabel("Settings category")  // ADD THIS LINE
.accessibilityValue(selectedTab.rawValue)  // ADD THIS LINE
```

Note: Individual segments get hints automatically from their labels in SwiftUI.

**Testing:**
1. Open Settings
2. Enable VoiceOver
3. Navigate to tab picker
4. Verify each tab announces its name and purpose

---

### Task 2.2: Add Dynamic Filter Result Announcements

**Priority:** Major
**Effort:** 30 minutes
**Files:** ContentView.swift

#### Implementation:

**Step 1:** Add announcement helper:

```swift
// ContentView.swift
// ADD after line 150 (after clearAllFilters method)

private func announceFilterResults() {
    guard hasActiveFilters else { return }

    let announcement = "Showing \(filteredMessages.count) of \(viewModel.messages.count) messages"

    // Post accessibility announcement
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if let window = NSApplication.shared.keyWindow {
            NSAccessibility.post(
                element: window,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement,
                    .priority: NSAccessibility.Priority.medium
                ]
            )
        }
    }
}
```

**Step 2:** Add onChange modifier:

```swift
// ContentView.swift:59
// CHANGE: Add onChange to main VStack

VStack(alignment: .leading, spacing: 8) {
    // ... existing content ...
}
.padding()
.frame(width: UIConstants.Dashboard.width, height: UIConstants.Dashboard.height)
.background(Color.theme.windowBackground)
.onChange(of: filteredMessages.count) { _ in  // ADD THIS LINE
    announceFilterResults()  // ADD THIS LINE
}  // ADD THIS LINE
.onExitCommand {
    // ... existing code ...
}
// ... rest of modifiers ...
```

**Step 3:** Update filter count display:

```swift
// ContentView.swift:98-101
// CHANGE: Add accessibility traits

Text("\(filteredMessages.count) of \(viewModel.messages.count) messages")
    .font(.caption)
    .foregroundColor(.secondary)
    .accessibilityAddTraits(.updatesFrequently)  // ADD THIS LINE
```

**Testing:**
1. Open dashboard with multiple messages
2. Enable VoiceOver
3. Apply filter (e.g., search for "test")
4. Verify VoiceOver announces: "Showing 3 of 10 messages"
5. Change filter, verify new announcement

---

### Task 2.3: Improve Topic Badge Accessibility

**Priority:** Major
**Effort:** 5 minutes
**Files:** MessageRowView.swift

#### Implementation:

```swift
// MessageRowView.swift:22-30
// CHANGE: Add accessibility label to topic badge

Text(message.topic)
    .font(.caption2)
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(Color.blue.opacity(0.2))
    .cornerRadius(4)
    .foregroundColor(.blue)
    .accessibilityLabel("Topic: \(message.topic)")  // ADD THIS LINE
```

**Note:** This may be redundant if Task 1.2 is completed (full message accessibility), but provides individual context if user navigates element-by-element.

**Testing:**
1. Enable VoiceOver
2. Navigate through message row with VO+Right Arrow
3. When focus reaches topic badge, verify: "Topic: alerts"

---

### Task 2.4: Enhance Connection Status Accessibility

**Priority:** Major
**Effort:** 10 minutes
**Files:** ConnectionSettingsView.swift

#### Implementation:

```swift
// ConnectionSettingsView.swift:252-264
// CHANGE: Add explicit accessibility labels

HStack {
    Text("Status:")
        .fontWeight(.medium)
    Spacer()
    if viewModel.isConnected {
        Label(StringConstants.StatusMessages.connected, systemImage: "checkmark.circle.fill")
            .foregroundColor(.green)
            .accessibilityLabel("Connection status: Connected")  // ADD THIS LINE
    } else {
        Label(StringConstants.StatusMessages.disconnected, systemImage: "xmark.circle.fill")
            .foregroundColor(.red)
            .accessibilityLabel("Connection status: Disconnected")  // ADD THIS LINE
    }
}
```

**Testing:**
1. Open Settings > Connection
2. Enable VoiceOver
3. Navigate to status indicator
4. Verify announcement includes "Connection status: Connected" or "Disconnected"
5. Test both connected and disconnected states

---

### Task 2.5: Add Clear Filters Button Accessibility

**Priority:** Major
**Effort:** 2 minutes
**Files:** ContentView.swift

#### Implementation:

```swift
// ContentView.swift:104-107
// CHANGE: Add accessibility label

Button("Clear filters") {
    clearAllFilters()
}
.font(.caption)
.accessibilityLabel("Clear all active filters")  // ADD THIS LINE
.accessibilityHint("Removes search text and priority filters")  // ADD THIS LINE
```

**Testing:**
1. Apply filters to messages
2. Enable VoiceOver
3. Navigate to "Clear filters" button
4. Verify announcement: "Clear all active filters, button. Removes search text and priority filters"

---

## Phase 3: Enhanced Experience (1-2 hours)

### Goal: Polish and best practices for power users

---

### Task 3.1: Implement VoiceOver Rotor for Messages

**Priority:** Minor
**Effort:** 45 minutes
**Files:** ContentView.swift, MessageRowView.swift

#### Implementation:

**Step 1:** Update MessageRowView (already done in Task 1.2):

Ensure messages have `.accessibilityAddTraits(.isButton)` and proper labels.

**Step 2:** Add rotor support to ContentView:

```swift
// ContentView.swift:80-91
// CHANGE: Add accessibility rotor

private var messagesView: some View {
    ScrollView {
        LazyVStack(spacing: 4) {
            ForEach(viewModel.messages, id: \.uniqueId) { message in
                MessageRowView(message: message)
                    .padding(.horizontal, 2)
            }
        }
        .padding(.top, 4)
    }
    .frame(maxHeight: .infinity)
    .accessibilityRotor("Messages") {  // ADD THIS BLOCK
        ForEach(viewModel.messages, id: \.uniqueId) { message in
            AccessibilityRotorEntry(message.displayTitle, id: message.uniqueId) {
                // Find and return the view for this message
                // SwiftUI will handle focusing it
            }
        }
    }
}
```

**Testing:**
1. Open dashboard with multiple messages
2. Enable VoiceOver
3. Open VoiceOver rotor (VO+U)
4. Select "Messages" category
5. Navigate through messages using Up/Down arrows
6. Verify quick navigation between messages

**Note:** VoiceOver rotor is advanced and may require additional SwiftUI view structure changes for optimal functionality.

---

### Task 3.2: Document Keyboard Shortcuts

**Priority:** Minor
**Effort:** 15 minutes
**Files:** README.md (or create ACCESSIBILITY.md)

#### Implementation:

**Option 1:** Add to README.md:

```markdown
## Keyboard Shortcuts

- **⌘F** - Focus search field
- **⌘,** - Open Settings
- **⌘Q** - Quit application
- **⌘W** - Close window
- **Escape** - Close current window
- **Tab** - Navigate between controls
- **Space/Return** - Activate buttons and controls
- **⌘+/-** - Adjust text size (system-wide)

## Accessibility

NtfyMenuBar supports macOS accessibility features:

- **VoiceOver** - Full screen reader support (⌘F5 to toggle)
- **Full Keyboard Access** - Complete keyboard navigation
- **Display Accommodations** - High contrast, reduce motion, color filters
- **Dynamic Type** - Respects system text size preferences
- **Voice Control** - Navigate and control via voice commands

For accessibility feedback, please [open an issue](https://github.com/reverendrewind/NtfyMenuBar/issues).
```

**Option 2:** Create separate ACCESSIBILITY.md file with comprehensive guide.

---

### Task 3.3: Add Search Field Accessibility Enhancement

**Priority:** Minor
**Effort:** 10 minutes
**Files:** SearchAndFilterBar.swift

#### Implementation:

```swift
// SearchAndFilterBar.swift:27-30
// CHANGE: Add accessibility properties

TextField("Search messages...", text: $searchText)
    .textFieldStyle(.plain)
    .font(.caption)
    .focused($isSearchFocused)
    .accessibilityLabel("Search messages")  // ADD THIS LINE
    .accessibilityHint("Type to filter messages by title or content")  // ADD THIS LINE
```

**Testing:**
1. Open dashboard
2. Enable VoiceOver
3. Press Cmd+F (should focus search)
4. Verify announcement: "Search messages, edit text. Type to filter messages by title or content"

---

### Task 3.4: Add Accessibility to Dashboard Header Actions

**Priority:** Minor
**Effort:** 15 minutes
**Files:** DashboardHeaderView.swift (need to check this file)

If DashboardHeaderView has icon-only buttons, apply same pattern as Quick Wins.

---

### Task 3.5: Create Accessibility Testing Script

**Priority:** Minor
**Effort:** 30 minutes
**Files:** NtfyMenuBarUITests/AccessibilityTests.swift (new file)

#### Implementation:

```swift
//
//  AccessibilityTests.swift
//  NtfyMenuBarUITests
//
//  Created by Accessibility Audit on 12/10/2025.
//

import XCTest

class AccessibilityTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMenuBarIconHasAccessibilityLabel() throws {
        let app = XCUIApplication()
        app.launch()

        // Test menu bar icon
        let menuBarIcon = app.menuBarItems["Ntfy Notifications"]
        XCTAssertTrue(menuBarIcon.exists, "Menu bar icon should have accessibility label")
    }

    func testSearchFieldIsAccessible() throws {
        let app = XCUIApplication()
        app.launch()

        // Open dashboard
        // Note: May need to adjust based on actual UI structure
        let searchField = app.searchFields["Search messages"]
        XCTAssertTrue(searchField.exists, "Search field should be accessible")
    }

    func testIconButtonsHaveLabels() throws {
        let app = XCUIApplication()
        app.launch()

        // Test clear search button appears when text entered
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("test")

        let clearButton = app.buttons["Clear search"]
        XCTAssertTrue(clearButton.exists, "Clear search button should have label")
    }

    func testSettingsTabsAccessible() throws {
        let app = XCUIApplication()
        app.launch()

        // Open settings (Cmd+,)
        app.typeKey(",", modifiers: .command)

        // Check settings tabs exist and have labels
        let connectionTab = app.buttons["Connection"]
        let tokensTab = app.buttons["Access tokens"]

        XCTAssertTrue(connectionTab.exists, "Connection tab should be accessible")
        XCTAssertTrue(tokensTab.exists, "Tokens tab should be accessible")
    }

    func testEmptyStateIsAccessible() throws {
        let app = XCUIApplication()
        app.launch()

        // Clear all messages first
        // Then check empty state
        let emptyState = app.staticTexts["No notifications yet"]
        // May need to adjust based on actual state
    }

    func testMessageRowsAreAccessible() throws {
        let app = XCUIApplication()
        app.launch()

        // Assuming there are messages
        // Check that message rows have proper accessibility
        let messages = app.buttons.matching(NSPredicate(format: "label CONTAINS 'priority'"))
        XCTAssertGreaterThan(messages.count, 0, "Messages should have accessibility labels including priority")
    }
}
```

**Testing:**
1. Open project in Xcode
2. Select test target
3. Run tests (Cmd+U)
4. Review results and fix any failures

---

## Testing Checklist

### Pre-Implementation Testing
- [ ] Read full audit report
- [ ] Understand each issue
- [ ] Set up test environment

### During Implementation (After Each Phase)

**Quick Wins Validation:**
- [ ] All icon-only buttons announce purpose
- [ ] Menu bar icon has proper label
- [ ] Filter indicator accessible
- [ ] Test with VoiceOver enabled

**Phase 1 Validation:**
- [ ] Tag emojis announce tag names
- [ ] Messages announce complete context
- [ ] Empty state clear and concise
- [ ] Snooze status readable

**Phase 2 Validation:**
- [ ] Settings tabs have descriptions
- [ ] Filter changes announced dynamically
- [ ] Topic badges have context
- [ ] Connection status clear
- [ ] All buttons have labels

**Phase 3 Validation:**
- [ ] Rotor navigation works
- [ ] Keyboard shortcuts documented
- [ ] All text fields have hints
- [ ] Automated tests pass

### Final Testing

**VoiceOver Complete Walkthrough:**
1. [ ] Launch app and navigate to menu bar icon
2. [ ] Click to open dashboard
3. [ ] Navigate through all messages
4. [ ] Use search and filters
5. [ ] Open settings
6. [ ] Navigate through all settings tabs
7. [ ] Configure connection settings
8. [ ] Close and reopen app

**Keyboard-Only Navigation:**
1. [ ] Complete all tasks without mouse/trackpad
2. [ ] Verify Tab order is logical
3. [ ] Test all keyboard shortcuts

**Accessibility Inspector Audit:**
1. [ ] Run app
2. [ ] Open Xcode > Open Developer Tool > Accessibility Inspector
3. [ ] Run audit on each screen
4. [ ] Fix any reported issues

---

## Progress Tracking

### Quick Wins
- [ ] Task QW1: Icon button labels (SearchAndFilterBar.swift)
- [ ] Task QW2: Topic remove buttons (ConnectionSettingsView.swift)
- [ ] Task QW3: Menu bar accessibility (StatusBarController.swift)
- [ ] Task QW4: Filter status indicator (SearchAndFilterBar.swift)

### Phase 1
- [ ] Task 1.1: Fix emoji announcements (MessageRowView.swift)
- [ ] Task 1.2: Message row accessibility (MessageRowView.swift)
- [ ] Task 1.3: Empty state (EmptyStateView.swift)
- [ ] Task 1.4: Snooze menu emoji (MenuBuilder.swift)

### Phase 2
- [ ] Task 2.1: Settings tab hints (SettingsView.swift)
- [ ] Task 2.2: Dynamic filter announcements (ContentView.swift)
- [ ] Task 2.3: Topic badge labels (MessageRowView.swift)
- [ ] Task 2.4: Connection status (ConnectionSettingsView.swift)
- [ ] Task 2.5: Clear filters button (ContentView.swift)

### Phase 3
- [ ] Task 3.1: VoiceOver rotor (ContentView.swift)
- [ ] Task 3.2: Document shortcuts (README.md)
- [ ] Task 3.3: Search field hints (SearchAndFilterBar.swift)
- [ ] Task 3.4: Dashboard header (DashboardHeaderView.swift)
- [ ] Task 3.5: Automated tests (AccessibilityTests.swift)

---

## Tools & Resources

### Built-in macOS Tools
- **VoiceOver** - Cmd+F5 to toggle
- **Accessibility Inspector** - Xcode > Open Developer Tool
- **Accessibility Keyboard Viewer** - System Settings > Accessibility > Keyboard
- **Voice Control** - System Settings > Accessibility > Voice Control

### Testing Commands
```bash
# Enable full keyboard access (for testing)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Run accessibility audit
# (Use Accessibility Inspector UI)

# Run automated tests
xcodebuild test -scheme NtfyMenuBar -destination 'platform=macOS'
```

### Documentation
- [Apple Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [SwiftUI Accessibility](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [Testing with VoiceOver](https://developer.apple.com/documentation/accessibility/voiceover)

---

## Success Criteria

### Must Have (Before Release)
✅ All critical issues resolved
✅ VoiceOver can access all features
✅ Icon-only buttons have labels
✅ Menu bar icon properly labeled
✅ Emoji tags announced correctly

### Should Have (Best Practice)
✅ All major issues resolved
✅ Settings fully accessible
✅ Dynamic content announced
✅ Keyboard shortcuts documented

### Nice to Have (Future)
✅ VoiceOver rotor support
✅ Automated accessibility tests
✅ User testing with AT users
✅ Accessibility statement published

---

## Post-Implementation

### Validation Steps
1. Complete all testing checklists
2. Run Accessibility Inspector audit
3. Document any deferred items
4. Update user-facing documentation

### Future Considerations
- [ ] Beta test with VoiceOver users
- [ ] Add accessibility page to documentation
- [ ] Consider hiring accessibility consultant
- [ ] Regular accessibility audits for new features

### Maintenance
- Review accessibility on every PR
- Test new features with VoiceOver
- Keep accessibility checklist updated
- Monitor user feedback for a11y issues

---

**Plan Status:** Ready for Implementation
**Estimated Total Time:** 4-6 hours
**Priority:** High (affects all assistive technology users)
**Next Step:** Begin Quick Wins implementation
