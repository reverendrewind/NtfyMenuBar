# Accessibility Component Checklist

**Purpose:** Use this checklist when creating or reviewing UI components to ensure accessibility compliance.
**Framework:** SwiftUI for macOS
**Target:** VoiceOver, Full Keyboard Access, and other macOS assistive technologies

---

## Quick Reference

### Essential SwiftUI Accessibility Modifiers

```swift
.accessibilityLabel("Description")           // What it is (replaces default)
.accessibilityHint("Instructions")           // How to use it
.accessibilityValue("Current state")         // Dynamic value/state
.accessibilityHidden(true)                   // Hide decorative elements
.accessibilityElement(children: .combine)    // Group multiple elements
.accessibilityElement(children: .ignore)     // Replace children with custom label
.accessibilityAddTraits(.isButton)           // Add semantic role
.accessibilityRemoveTraits(.isImage)         // Remove incorrect role
.accessibilityInputLabels(["Alt", "Names"])  // Voice Control alternatives
```

---

## Component Checklist

### ✅ Buttons

#### Icon-Only Buttons
**Problem:** Image-only buttons announce as "Button" with no context.

```swift
// ❌ BAD - No accessibility label
Button {
    deleteItem()
} label: {
    Image(systemName: "trash")
}

// ✅ GOOD - Descriptive label
Button {
    deleteItem()
} label: {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete item")
.accessibilityHint("Removes this item permanently")  // Optional but helpful
```

#### Text Buttons
**Note:** Text buttons usually don't need additional labels.

```swift
// ✅ GOOD - Text is automatically used as label
Button("Save Changes") {
    saveChanges()
}

// ✅ BETTER - Add hint for complex actions
Button("Save Changes") {
    saveChanges()
}
.accessibilityHint("Saves all pending changes to the server")
```

#### Toggle Buttons (State Changes)
**Problem:** State not announced.

```swift
// ❌ BAD - State unclear
@State private var isEnabled = false

Button {
    isEnabled.toggle()
} label: {
    Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
}

// ✅ GOOD - State in label
Button {
    isEnabled.toggle()
} label: {
    Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
}
.accessibilityLabel(isEnabled ? "Enabled" : "Disabled")
.accessibilityAddTraits(.isButton)
```

**Checklist:**
- [ ] All buttons have descriptive labels
- [ ] Icon-only buttons use `.accessibilityLabel()`
- [ ] Toggle buttons announce current state
- [ ] Complex actions have `.accessibilityHint()`
- [ ] Destructive actions clearly labeled (e.g., "Delete")

---

### ✅ Images

#### Decorative Images
**Problem:** VoiceOver reads image description when not meaningful.

```swift
// ❌ BAD - Decorative image announced
Image("background-pattern")
    .resizable()

// ✅ GOOD - Hidden from VoiceOver
Image("background-pattern")
    .resizable()
    .accessibilityHidden(true)
```

#### Informative Images
**Problem:** Image conveys information but lacks description.

```swift
// ❌ BAD - No description
Image("server-status-error")

// ✅ GOOD - Descriptive label
Image("server-status-error")
    .accessibilityLabel("Server connection error")

// ✅ BETTER - Include context
Image("server-status-error")
    .accessibilityLabel("Error: Unable to connect to server")
```

#### Images with Text Overlay
**Problem:** Both image and text announced separately.

```swift
// ❌ BAD - Announces image and text separately
ZStack {
    Image("notification-badge")
    Text("5")
}

// ✅ GOOD - Single combined announcement
ZStack {
    Image("notification-badge")
        .accessibilityHidden(true)
    Text("5")
}
.accessibilityElement(children: .ignore)
.accessibilityLabel("5 unread notifications")
```

**Checklist:**
- [ ] Decorative images use `.accessibilityHidden(true)`
- [ ] Informative images have `.accessibilityLabel()`
- [ ] Complex images have detailed descriptions
- [ ] Images with text are properly grouped

---

### ✅ Text Fields

#### Standard Text Fields
**Note:** TextField with placeholder usually accessible by default.

```swift
// ✅ GOOD - Placeholder used as label
TextField("Enter username", text: $username)

// ✅ BETTER - Explicit label with hint
VStack(alignment: .leading) {
    Text("Username")
        .font(.subheadline)
    TextField("Enter username", text: $username)
        .accessibilityLabel("Username")
        .accessibilityHint("Enter your ntfy server username")
}
```

#### Password Fields

```swift
// ✅ GOOD - SecureField is accessible
SecureField("Password", text: $password)
    .accessibilityLabel("Password")

// ✅ BETTER - With validation feedback
VStack(alignment: .leading) {
    SecureField("Password", text: $password)
        .accessibilityLabel("Password")

    if showError {
        Text("Password must be at least 8 characters")
            .foregroundColor(.red)
            .accessibilityAddTraits(.isStaticText)
    }
}
```

#### Search Fields

```swift
// ✅ GOOD - Clear purpose
TextField("Search messages...", text: $searchText)
    .accessibilityLabel("Search messages")
    .accessibilityHint("Type to filter messages by title or content")

// ✅ BETTER - With clear button
HStack {
    TextField("Search messages...", text: $searchText)
        .accessibilityLabel("Search messages")

    if !searchText.isEmpty {
        Button {
            searchText = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
        }
        .accessibilityLabel("Clear search")
    }
}
```

**Checklist:**
- [ ] All text fields have labels (explicit or placeholder)
- [ ] Labels describe expected input
- [ ] Required fields marked as such
- [ ] Error messages are accessible
- [ ] Clear buttons have labels

---

### ✅ Lists & Collections

#### Message Lists

```swift
// ❌ BAD - Each element announced separately
ForEach(messages) { message in
    VStack(alignment: .leading) {
        Text(message.title)
        Text(message.body)
        Text(message.time)
    }
}

// ✅ GOOD - Combined into single announcement
ForEach(messages) { message in
    VStack(alignment: .leading) {
        Text(message.title)
        Text(message.body)
        Text(message.time)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(message.title): \(message.body). \(message.time)")
    .accessibilityAddTraits(.isButton)  // If tappable
}
```

#### List with Actions

```swift
// ✅ GOOD - Actions clearly labeled
ForEach(items) { item in
    HStack {
        Text(item.name)
        Spacer()
        Button {
            editItem(item)
        } label: {
            Image(systemName: "pencil")
        }
        .accessibilityLabel("Edit \(item.name)")

        Button {
            deleteItem(item)
        } label: {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete \(item.name)")
    }
}
```

#### Empty States

```swift
// ❌ BAD - Image and text separate
VStack {
    Image(systemName: "tray")
    Text("No items")
}

// ✅ GOOD - Combined with clear message
VStack {
    Image(systemName: "tray")
        .accessibilityHidden(true)
    Text("No items")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("No items available")
```

**Checklist:**
- [ ] List items have complete context in one announcement
- [ ] Empty states clearly communicate lack of content
- [ ] Actions within list items are labeled
- [ ] Lists support keyboard navigation

---

### ✅ Status Indicators

#### Connection Status

```swift
// ❌ BAD - Color only
Circle()
    .fill(isConnected ? .green : .red)
    .frame(width: 8, height: 8)

// ✅ GOOD - Text + icon + color
Label(
    isConnected ? "Connected" : "Disconnected",
    systemImage: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill"
)
.foregroundColor(isConnected ? .green : .red)
.accessibilityLabel("Connection status: \(isConnected ? "Connected" : "Disconnected")")
```

#### Badge Indicators

```swift
// ❌ BAD - Visual badge only
ZStack(alignment: .topTrailing) {
    Image(systemName: "bell")
    Circle()
        .fill(.red)
        .frame(width: 8, height: 8)
}

// ✅ GOOD - Accessible badge
ZStack(alignment: .topTrailing) {
    Image(systemName: "bell")
    Circle()
        .fill(.red)
        .frame(width: 8, height: 8)
        .accessibilityHidden(true)
}
.accessibilityLabel("Notifications with unread items")
.accessibilityValue("\(unreadCount) unread")
```

#### Progress Indicators

```swift
// ✅ GOOD - Progress announced
ProgressView(value: progress, total: 1.0)
    .accessibilityLabel("Upload progress")
    .accessibilityValue("\(Int(progress * 100)) percent complete")
    .accessibilityAddTraits(.updatesFrequently)
```

**Checklist:**
- [ ] Status not conveyed by color alone
- [ ] Icons provide redundant information
- [ ] Text labels always present
- [ ] Current state announced clearly

---

### ✅ Custom Controls

#### Toggle/Switch

```swift
// ✅ GOOD - Native toggle is accessible
Toggle("Enable notifications", isOn: $isEnabled)

// ✅ GOOD - Custom toggle with proper traits
Button {
    isEnabled.toggle()
} label: {
    HStack {
        Text("Enable notifications")
        Spacer()
        Image(systemName: isEnabled ? "checkmark.square" : "square")
    }
}
.accessibilityLabel("Enable notifications")
.accessibilityValue(isEnabled ? "On" : "Off")
.accessibilityAddTraits(.isToggle)
```

#### Slider/Stepper

```swift
// ✅ GOOD - Native controls are accessible
Stepper("Retry delay: \(retryDelay)s", value: $retryDelay, in: 5...300)

Slider(value: $volume, in: 0...100)
    .accessibilityLabel("Volume")
    .accessibilityValue("\(Int(volume)) percent")
```

#### Picker

```swift
// ✅ GOOD - Picker with clear options
Picker("Theme", selection: $selectedTheme) {
    Text("Light").tag(Theme.light)
    Text("Dark").tag(Theme.dark)
    Text("System").tag(Theme.system)
}
.accessibilityLabel("Appearance theme")
.accessibilityValue(selectedTheme.rawValue)
```

**Checklist:**
- [ ] Custom controls use appropriate `.accessibilityAddTraits()`
- [ ] Current value announced with `.accessibilityValue()`
- [ ] State changes announced
- [ ] Keyboard navigation supported

---

### ✅ Modals & Sheets

#### Settings Sheet

```swift
// ✅ GOOD - Clear title and dismissal
.sheet(isPresented: $showingSettings) {
    NavigationStack {
        SettingsView()
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showingSettings = false
                    }
                }
            }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Settings window")
}
```

#### Alert Dialogs

```swift
// ✅ GOOD - Native alert is accessible
.alert("Delete Message", isPresented: $showingDeleteAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        deleteMessage()
    }
} message: {
    Text("This action cannot be undone.")
}
```

#### Popovers

```swift
// ✅ GOOD - Popover with clear content
Button("Filter options") {
    showFilterPopover.toggle()
}
.popover(isPresented: $showFilterPopover) {
    FilterOptionsView()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter options")
}
```

**Checklist:**
- [ ] Modal purpose clear from title
- [ ] Dismiss action clearly labeled
- [ ] Focus moves to modal when opened
- [ ] Escape key closes modal

---

### ✅ Navigation

#### Tab Bar / Segmented Control

```swift
// ✅ GOOD - Tabs with icons and labels
Picker("Settings category", selection: $selectedTab) {
    ForEach(SettingsTab.allCases) { tab in
        Label(tab.title, systemImage: tab.icon)
            .tag(tab)
    }
}
.pickerStyle(.segmented)
```

#### Menu Bar Items

```swift
// ✅ GOOD - Menu items with clear labels
let menu = NSMenu()

let openItem = NSMenuItem(
    title: "Open Dashboard",
    action: #selector(openDashboard),
    keyEquivalent: ""
)
openItem.accessibilityLabel = "Open Dashboard"
menu.addItem(openItem)
```

#### Breadcrumbs / Navigation Path

```swift
// ✅ GOOD - Clear navigation hierarchy
HStack {
    Button("Settings") { goToSettings() }
    Text(">").accessibilityHidden(true)
    Text("Connection")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Settings, Connection")
```

**Checklist:**
- [ ] Navigation elements clearly labeled
- [ ] Current location announced
- [ ] Keyboard shortcuts for common actions
- [ ] Back/close actions available

---

## Common Patterns

### Pattern: Filter/Search Bar

```swift
struct AccessibleSearchBar: View {
    @Binding var searchText: String
    @Binding var showFilters: Bool
    @FocusState var isFocused: Bool

    var body: some View {
        HStack {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .accessibilityHidden(true)  // Decorative

                TextField("Search...", text: $searchText)
                    .focused($isFocused)
                    .accessibilityLabel("Search")
                    .accessibilityHint("Type to filter results")

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .accessibilityLabel("Clear search")
                }
            }

            // Filter button
            Button {
                showFilters.toggle()
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
            .accessibilityLabel("Filters")
            .accessibilityHint("Show filter options")
        }
    }
}
```

### Pattern: Card with Multiple Elements

```swift
struct AccessibleMessageCard: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.title)
                    .font(.headline)
                Spacer()
                Text(message.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(message.body)
                .font(.body)

            if !message.tags.isEmpty {
                HStack {
                    ForEach(message.tags, id: \.self) { tag in
                        Text("🏷")
                            .accessibilityLabel(tag)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        // Combine all into single announcement
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityDescription: String {
        let tagsText = message.tags.isEmpty ? "" : "Tags: \(message.tags.joined(separator: ", "))"
        return "\(message.title): \(message.body). \(message.time). \(tagsText)"
    }
}
```

### Pattern: Settings Form

```swift
struct AccessibleSettingsForm: View {
    @Binding var serverURL: String
    @Binding var enableNotifications: Bool

    var body: some View {
        Form {
            Section("Connection") {
                VStack(alignment: .leading) {
                    Text("Server URL")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("https://ntfy.sh", text: $serverURL)
                        .accessibilityLabel("Server URL")
                        .accessibilityHint("Enter your ntfy server address")

                    if !isValidURL(serverURL) {
                        Text("Invalid URL format")
                            .foregroundColor(.red)
                            .font(.caption)
                            .accessibilityAddTraits(.isStaticText)
                    }
                }
            }

            Section("Notifications") {
                Toggle("Enable push notifications", isOn: $enableNotifications)
                    .accessibilityHint("Receive notifications for new messages")
            }
        }
    }

    func isValidURL(_ url: String) -> Bool {
        // Validation logic
        return url.starts(with: "http")
    }
}
```

---

## Testing Guide

### Manual Testing with VoiceOver

1. **Enable VoiceOver:** Cmd+F5
2. **Basic Navigation:**
   - VO+Right Arrow: Next element
   - VO+Left Arrow: Previous element
   - VO+Space: Activate element
   - VO+Shift+Down: Interact with element
   - VO+Shift+Up: Stop interacting

3. **Test Checklist:**
   - [ ] Navigate entire component with keyboard only
   - [ ] Verify all interactive elements reachable
   - [ ] Check labels are descriptive and concise
   - [ ] Confirm state changes announced
   - [ ] Test with eyes closed (real VoiceOver experience)

### Accessibility Inspector (Xcode)

1. **Launch:** Xcode > Open Developer Tool > Accessibility Inspector
2. **Select target:** Click crosshair, click your app element
3. **Check:**
   - [ ] Label is present and descriptive
   - [ ] Traits are appropriate (button, text, etc.)
   - [ ] Value shows current state (if applicable)
   - [ ] Hint provides usage instructions (if needed)

4. **Run Audit:**
   - Click "Audit" button
   - Review all warnings and errors
   - Fix issues and re-audit

### Automated Testing

```swift
func testButtonAccessibility() {
    let app = XCUIApplication()
    app.launch()

    let button = app.buttons["Delete item"]
    XCTAssertTrue(button.exists, "Button should exist")
    XCTAssertTrue(button.isHittable, "Button should be hittable")
    XCTAssertEqual(button.label, "Delete item", "Button should have correct label")
}
```

---

## Common Mistakes

### ❌ Mistake 1: Icon-Only Button Without Label
```swift
// WRONG
Button { delete() } label: {
    Image(systemName: "trash")
}
// VoiceOver: "Button"

// RIGHT
Button { delete() } label: {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete")
// VoiceOver: "Delete, button"
```

### ❌ Mistake 2: Using Color Alone
```swift
// WRONG
Text("Error")
    .foregroundColor(.red)
// Only visual indication

// RIGHT
Label("Error", systemImage: "exclamationmark.triangle")
    .foregroundColor(.red)
// Icon + text + color
```

### ❌ Mistake 3: Not Hiding Decorative Elements
```swift
// WRONG
HStack {
    Image(systemName: "checkmark")
    Text("Saved")
}
// VoiceOver: "Checkmark, Saved"

// RIGHT
HStack {
    Image(systemName: "checkmark")
        .accessibilityHidden(true)
    Text("Saved")
}
// VoiceOver: "Saved"
```

### ❌ Mistake 4: Not Grouping Related Elements
```swift
// WRONG
VStack {
    Text("John Doe")
    Text("Software Engineer")
    Text("San Francisco")
}
// VoiceOver: "John Doe", "Software Engineer", "San Francisco" (3 stops)

// RIGHT
VStack {
    Text("John Doe")
    Text("Software Engineer")
    Text("San Francisco")
}
.accessibilityElement(children: .combine)
// VoiceOver: "John Doe, Software Engineer, San Francisco" (1 stop)
```

### ❌ Mistake 5: Dynamic Content Not Announced
```swift
// WRONG
Text("\(messageCount) messages")
// Changes not announced

// RIGHT
Text("\(messageCount) messages")
    .accessibilityAddTraits(.updatesFrequently)
    .onChange(of: messageCount) { newCount in
        announceToVoiceOver("Now showing \(newCount) messages")
    }
```

---

## Quick Start Template

```swift
import SwiftUI

struct AccessibleComponentTemplate: View {
    // MARK: - State
    @State private var isEnabled = false

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon-only button
            Button {
                performAction()
            } label: {
                Image(systemName: "star")
            }
            .accessibilityLabel("Favorite")
            .accessibilityHint("Add to favorites")

            // Toggle
            Toggle("Enable feature", isOn: $isEnabled)

            // Text field
            TextField("Enter name", text: .constant(""))
                .accessibilityLabel("Name")
                .accessibilityHint("Enter your full name")

            // Status indicator
            HStack {
                Circle()
                    .fill(isEnabled ? .green : .red)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)

                Text(isEnabled ? "Active" : "Inactive")
            }

            // Grouped content
            VStack {
                Text("Title")
                Text("Subtitle")
            }
            .accessibilityElement(children: .combine)
        }
        .padding()
    }

    // MARK: - Actions
    private func performAction() {
        // Action implementation
    }
}
```

---

## Resources

### Apple Documentation
- [Accessibility Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [SwiftUI Accessibility Modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [Accessibility Programming Guide](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/)

### Tools
- **Accessibility Inspector** (Xcode)
- **VoiceOver** (Cmd+F5)
- **Voice Control** (System Settings)
- **Keyboard Viewer** (System Settings)

### Community
- [Apple Developer Forums - Accessibility](https://developer.apple.com/forums/tags/accessibility)
- [SwiftUI Accessibility Examples](https://github.com/topics/swiftui-accessibility)

---

## Version History

- **v1.0** (October 12, 2025) - Initial checklist for NtfyMenuBar audit
- Templates and patterns based on NtfyMenuBar accessibility audit findings

---

**Remember:** Accessibility is not optional. Every user deserves equal access to your application's features.
