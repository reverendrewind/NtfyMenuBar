# VoiceOver Testing Guide for NtfyMenuBar

This guide provides step-by-step instructions for manually testing NtfyMenuBar's accessibility with VoiceOver.

## Prerequisites

1. **Build and run** the NtfyMenuBar app
2. **Enable VoiceOver:** Press **Cmd+F5** (or go to System Settings > Accessibility > VoiceOver)
3. **VoiceOver navigation basics:**
   - **VO+Right Arrow** - Move to next element
   - **VO+Left Arrow** - Move to previous element
   - **VO+Space** - Activate element (click button, etc.)
   - **VO+Shift+Down** - Interact with element
   - **VO+Shift+Up** - Stop interacting
   - **VO+M** - Navigate to menu bar

(Note: "VO" = **Control+Option** keys)

---

## Test 1: Menu Bar Icon Accessibility

### Steps:
1. **Enable VoiceOver** (Cmd+F5)
2. **Navigate to menu bar** (VO+M)
3. **Move to Ntfy icon** (VO+Left/Right Arrow)

### Expected Results:
- ✅ VoiceOver announces: **"Ntfy Notifications, Ntfy menu bar, click to open dashboard, right-click for menu"**
- ✅ Icon is clearly identified as the Ntfy app
- ✅ Interaction instructions are provided

### If Snoozed:
- ✅ VoiceOver announces: **"Ntfy Notifications (Snoozed), notifications snoozed until [time]"**

### Pass/Fail:
- [ ] PASS - All announcements correct
- [ ] FAIL - Missing or incorrect labels

---

## Test 2: Dashboard Search and Filter

### Steps:
1. **Click menu bar icon** to open dashboard
2. **Press Cmd+F** (should focus search field)
3. **Navigate to search field** (VO+Right Arrow until you reach it)

### Expected Results:
- ✅ VoiceOver announces: **"Search messages, edit text. Type to filter messages by title or content"**
- ✅ Cmd+F successfully focuses the search field

### Test Clear Search Button:
4. **Type some text** in search field (e.g., "test")
5. **Navigate to clear button** (VO+Right Arrow)

### Expected Results:
- ✅ VoiceOver announces: **"Clear search, button"**
- ✅ Button is clearly identified and actionable

### Test Filter Button:
6. **Navigate to filter button** (VO+Right Arrow)

### Expected Results:
- ✅ VoiceOver announces: **"Filters, button. Opens filter options for priorities and topics"** (when no filters active)
- ✅ VoiceOver announces: **"Filters (active), button"** (when filters are applied)
- ✅ Blue circle indicator is hidden from VoiceOver (not announced)

### Pass/Fail:
- [ ] PASS - All search/filter elements accessible
- [ ] FAIL - Missing or incorrect labels

---

## Test 3: Message Rows

### Prerequisites:
- Ensure you have at least one message in the dashboard
- If no messages, send a test notification:
  ```bash
  curl -d "Test message" -H "Priority: 4" -H "Tags: urgent,test" https://ntfy.sh/your-topic
  ```

### Steps:
1. **Navigate to a message** (VO+Right Arrow until you reach a message row)

### Expected Results:
- ✅ VoiceOver announces full message context in one statement:
  - Priority level (e.g., "High priority")
  - Title
  - Message body
  - Topic
  - Time
  - Tags (e.g., "Tags: urgent, test")
- ✅ Example: **"High priority. Test Alert: Server restarting. Topic: alerts. 5 minutes ago. Tags: urgent, server"**
- ✅ Tags announced by name, NOT as emoji descriptions
- ✅ Message is announced as a button (actionable)

### Test Multiple Messages:
2. **Navigate through all messages** (VO+Right Arrow)
3. Each message should provide complete context

### Pass/Fail:
- [ ] PASS - Messages fully accessible with all context
- [ ] FAIL - Missing information or emoji noise

---

## Test 4: Empty State

### Prerequisites:
- Clear all messages: Right-click menu bar icon > "Clear messages"

### Steps:
1. **Open dashboard**
2. **Navigate to empty state** (VO+Right Arrow)

### Expected Results:
- ✅ VoiceOver announces: **"No notifications yet"**
- ✅ Bell icon is hidden from VoiceOver (not announced)
- ✅ Clear, simple message

### Pass/Fail:
- [ ] PASS - Empty state clearly communicated
- [ ] FAIL - Confusing or missing announcement

---

## Test 5: Settings Accessibility

### Steps:
1. **Open Settings** (Cmd+, or Right-click menu bar > Settings)
2. **Navigate to tab picker** (VO+Right Arrow)

### Expected Results:
- ✅ VoiceOver announces: **"Settings category, [selected tab name]"**
- ✅ Each tab can be selected and announced

### Test Connection Settings:
3. **Select Connection tab**
4. **Navigate through form fields**

### Expected Results:
- ✅ Server URL field has label: **"Server URL"**
- ✅ Username field has label: **"Username"**
- ✅ Password field has label: **"Password"** (and is a secure field)
- ✅ Connection status announces: **"Connection status: Connected"** or **"Disconnected"**

### Test Topic Remove Buttons:
5. **Navigate to existing topic badges**
6. **Navigate to remove button** (X icon)

### Expected Results:
- ✅ VoiceOver announces: **"Remove topic [topic-name], button"**
- ✅ Clear what will be removed

### Pass/Fail:
- [ ] PASS - All settings accessible
- [ ] FAIL - Missing or unclear labels

---

## Test 6: Filter Results and Announcements

### Steps:
1. **Open dashboard with multiple messages**
2. **Type in search field** (e.g., "test")
3. **Wait for results to filter**

### Expected Results:
- ✅ Filter count text appears: "X of Y messages"
- ✅ VoiceOver announces dynamically: **"Showing X of Y messages"**
- ✅ Announcement happens automatically when filter changes

### Test Clear Filters Button:
4. **Navigate to "Clear filters" button**

### Expected Results:
- ✅ VoiceOver announces: **"Clear all active filters, button. Removes search text and priority filters"**

### Pass/Fail:
- [ ] PASS - Filter results announced correctly
- [ ] FAIL - No announcements or missing labels

---

## Test 7: Snooze Menu Items

### Steps:
1. **Right-click menu bar icon**
2. **Snooze notifications** > Select "5 minutes"
3. **Right-click menu bar icon again**
4. **Navigate to snooze status item** (VO+Down Arrow in menu)

### Expected Results:
- ✅ VoiceOver announces: **"Snoozed until [time]"** (NO emoji description)
- ✅ Clear snooze item is accessible: **"Clear snooze"**

### Pass/Fail:
- [ ] PASS - Snooze items accessible without emoji noise
- [ ] FAIL - Emoji descriptions announced

---

## Test 8: Keyboard Navigation

### Steps:
1. **Disable mouse/trackpad** (or just don't use it)
2. **Navigate entire app using only keyboard:**
   - **Tab** - Move between controls
   - **Space/Return** - Activate buttons
   - **Cmd+F** - Focus search
   - **Escape** - Close windows
   - **Cmd+,** - Open settings
   - **Cmd+Q** - Quit app

### Expected Results:
- ✅ All interactive elements reachable via keyboard
- ✅ Logical tab order (top to bottom, left to right)
- ✅ No keyboard traps (can escape from all controls)
- ✅ Keyboard shortcuts work as documented

### Pass/Fail:
- [ ] PASS - Complete keyboard accessibility
- [ ] FAIL - Unreachable elements or broken shortcuts

---

## Test 9: Accessibility Inspector (Xcode Tool)

### Prerequisites:
- **Open Xcode** > Open Developer Tool > **Accessibility Inspector**

### Steps:
1. **Run NtfyMenuBar**
2. **Click target selector** (crosshair icon)
3. **Click on various UI elements**

### Expected Results for Each Element:
- ✅ **Label:** Descriptive text (e.g., "Clear search")
- ✅ **Traits:** Appropriate role (button, text field, etc.)
- ✅ **Value:** Current state if applicable
- ✅ **Hint:** Usage instructions if needed
- ✅ No warnings or errors

### Run Accessibility Audit:
4. **Click "Audit" button** in Accessibility Inspector
5. **Review all warnings/errors**

### Expected Results:
- ✅ Zero critical issues
- ✅ Any warnings have valid justifications

### Pass/Fail:
- [ ] PASS - Clean accessibility inspector results
- [ ] FAIL - Unresolved warnings or errors

---

## Test 10: Real-World Scenario

### Full Workflow Test:
1. **Enable VoiceOver** (Cmd+F5)
2. **Launch NtfyMenuBar** (from Applications)
3. **Navigate to menu bar icon** (VO+M)
4. **Click to open dashboard**
5. **Search for a message** (Cmd+F, type text)
6. **Navigate through filtered results**
7. **Clear filters**
8. **Open Settings** (Cmd+,)
9. **Navigate through all settings tabs**
10. **Close settings** (Cmd+W or click Cancel)
11. **Right-click menu bar icon**
12. **Navigate through context menu**
13. **Snooze notifications**
14. **Verify snooze status**

### Expected Results:
- ✅ Every step completable using VoiceOver
- ✅ All information available via audio
- ✅ No confusion or missing context
- ✅ Logical flow and navigation

### Pass/Fail:
- [ ] PASS - Complete workflow accessible
- [ ] FAIL - Blockers or confusion points

---

## Summary Checklist

### Critical Issues (Must Pass):
- [ ] Menu bar icon has accessibility label
- [ ] All icon-only buttons have labels
- [ ] Message tags announced as text (not emoji)
- [ ] Settings forms fully accessible

### Major Issues (Should Pass):
- [ ] Filter status communicated clearly
- [ ] Connection status has context
- [ ] Dynamic filter results announced
- [ ] Clear filters button labeled

### Minor Issues (Nice to Have):
- [ ] Search field has helpful hint
- [ ] Settings tabs have descriptions
- [ ] Keyboard shortcuts all work

---

## Troubleshooting

### VoiceOver Not Reading Elements:
- Check System Settings > Accessibility > VoiceOver is enabled
- Restart VoiceOver (Cmd+F5 twice)
- Restart the app

### Elements Not Keyboard Accessible:
- Enable Full Keyboard Access: System Settings > Keyboard > Keyboard Shortcuts > Use keyboard navigation

### Menu Bar Icon Not Found:
- Ensure app is running
- Navigate to menu bar (VO+M)
- Check for "Ntfy" in menu bar extras

---

## Reporting Issues

If you encounter accessibility problems:

1. **Document the issue:**
   - What element is affected?
   - What does VoiceOver announce (or not announce)?
   - Expected vs actual behavior

2. **Include context:**
   - macOS version
   - VoiceOver enabled?
   - Steps to reproduce

3. **Report:**
   - [GitHub Issues](https://github.com/reverendrewind/NtfyMenuBar/issues)
   - Label as "accessibility"

---

## Additional Resources

- [Apple VoiceOver User Guide](https://support.apple.com/guide/voiceover/welcome/mac)
- [Accessibility Inspector Guide](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXTestingApps.html)
- [macOS Keyboard Shortcuts](https://support.apple.com/en-us/HT201236)

---

**Testing Date:** _____________

**Tester Name:** _____________

**macOS Version:** _____________

**App Version:** _____________

**Overall Result:** PASS / FAIL

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
