# Help Docs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add macOS Help Book, keyboard shortcut cheat sheet, and first-launch welcome screen to Emdy.

**Architecture:** Three independent components — (1) a Help Book bundle of HTML files registered via Info.plist, (2) a `ShortcutCheatSheet` SwiftUI sheet, and (3) a `WelcomeView` SwiftUI sheet shown on first launch. All three are wired into the Help menu and app lifecycle.

**Tech Stack:** Swift, SwiftUI, AppKit, HTML/CSS (Help Book), xcodegen

---

### Task 1: Help Book — bundle structure and Info.plist registration

**Files:**
- Create: `Emdy/Resources/Emdy.help/Contents/Info.plist`
- Modify: `Emdy/Info.plist`
- Modify: `project.yml`

**Step 1: Create the Help Book directory structure**

```bash
mkdir -p Emdy/Resources/Emdy.help/Contents/Resources/en.lproj
```

**Step 2: Create the Help Book Info.plist**

Create `Emdy/Resources/Emdy.help/Contents/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>com.emdy.app.help</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Emdy Help</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleSignature</key>
    <string>hbwr</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>HPDBookAccessPath</key>
    <string>en.lproj/</string>
    <key>HPDBookIconPath</key>
    <string></string>
    <key>HPDBookIndexPath</key>
    <string>search.helpindex</string>
    <key>HPDBookTitle</key>
    <string>Emdy Help</string>
    <key>HPDBookType</key>
    <string>3</string>
</dict>
</plist>
```

**Step 3: Register Help Book in app Info.plist**

Add to `Emdy/Info.plist` inside the top-level `<dict>`:

```xml
<key>CFBundleHelpBookFolder</key>
<string>Emdy.help</string>
<key>CFBundleHelpBookName</key>
<string>Emdy Help</string>
```

**Step 4: Add Help Book as a resource in project.yml**

Add to the `resources` array under the `Emdy` target:

```yaml
- path: Emdy/Resources/Emdy.help
  buildPhase: resources
```

**Step 5: Regenerate Xcode project and verify build**

```bash
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Emdy -configuration Debug build
```

Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add Emdy/Resources/Emdy.help/Contents/Info.plist Emdy/Info.plist project.yml
git commit -m "Add Help Book bundle structure and register in Info.plist"
```

---

### Task 2: Help Book — HTML content pages

**Files:**
- Create: `Emdy/Resources/Emdy.help/Contents/Resources/en.lproj/style.css`
- Create: `Emdy/Resources/Emdy.help/Contents/Resources/en.lproj/index.html`
- Create: `Emdy/Resources/Emdy.help/Contents/Resources/en.lproj/opening.html`
- Create: `Emdy/Resources/Emdy.help/Contents/Resources/en.lproj/navigating.html`
- Create: `Emdy/Resources/Emdy.help/Contents/Resources/en.lproj/display.html`
- Create: `Emdy/Resources/Emdy.help/Contents/Resources/en.lproj/sharing.html`
- Create: `Emdy/Resources/Emdy.help/Contents/Resources/en.lproj/shortcuts.html`

**Step 1: Create shared stylesheet**

Create `style.css` with minimal styling. Apple Help Viewer provides base styles; just add light layout polish:

```css
body {
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    max-width: 600px;
    margin: 0 auto;
    padding: 20px;
    line-height: 1.5;
}
h1 { font-size: 1.5em; margin-bottom: 0.5em; }
h2 { font-size: 1.2em; margin-top: 1.5em; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { text-align: left; padding: 6px 12px; border-bottom: 1px solid #ddd; }
th { font-weight: 600; }
kbd {
    display: inline-block;
    padding: 2px 6px;
    font-family: -apple-system, sans-serif;
    font-size: 0.85em;
    background: #f0f0f0;
    border: 1px solid #ccc;
    border-radius: 4px;
}
a { color: #5A6D7A; }
ul { padding-left: 1.5em; }
```

**Step 2: Create index.html**

Landing page with app name, brief description, and links to each topic page. Each link uses `<a href="topic.html">`. Include `<meta name="AppleTitle" content="Emdy Help">` for Help Viewer registration.

**Step 3: Create opening.html**

Cover: opening a single file (File > Open or Cmd+O), opening a directory, drag-and-drop onto Dock icon and windows, Open Recent submenu.

**Step 4: Create navigating.html**

Cover: heading navigator sidebar (Shift+Cmd+H), minimap (Shift+Cmd+M), find in page (Cmd+F / Cmd+G / Shift+Cmd+G), clicking anchor links in documents.

**Step 5: Create display.html**

Cover: zoom in/out/reset (Cmd+/Cmd-/Cmd+0), font styles — sans-serif (Cmd+1), serif (Cmd+2), monospace (Cmd+3), themes — light (Cmd+7), dark (Cmd+8), system (Cmd+9).

**Step 6: Create sharing.html**

Cover: copy as RTF (select text, Cmd+C — pastes formatted into other apps), export PDF (Shift+Cmd+E), print (Cmd+P).

**Step 7: Create shortcuts.html**

Full reference table with all keyboard shortcuts grouped by category: File, Edit, View, Sharing. Use `<kbd>` tags for keys.

**Step 8: Build and verify Help Viewer opens**

```bash
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Emdy -configuration Debug build
```

Launch the app, open Help menu — should open Help Viewer with index page.

**Step 9: Generate search index**

```bash
hiutil -Caf Emdy/Resources/Emdy.help/Contents/Resources/search.helpindex Emdy/Resources/Emdy.help/Contents/Resources/en.lproj/
```

**Step 10: Commit**

```bash
git add Emdy/Resources/Emdy.help/
git commit -m "Add Help Book HTML content pages and search index"
```

---

### Task 3: Keyboard Shortcut Cheat Sheet

**Files:**
- Create: `Emdy/Views/ShortcutCheatSheet.swift`
- Modify: `Emdy/Commands/EmdyMenuCommands.swift`
- Modify: `Emdy/EmdyApp.swift`

**Step 1: Create ShortcutCheatSheet view**

Create `Emdy/Views/ShortcutCheatSheet.swift`. Data model:

```swift
struct ShortcutEntry {
    let action: String
    let keys: String
}

struct ShortcutCategory {
    let name: String
    let shortcuts: [ShortcutEntry]
}
```

Static data for all categories:

- **File**: Open (Cmd+O), Close (Cmd+W), Print (Cmd+P), Export PDF (Shift+Cmd+E)
- **Edit**: Copy (Cmd+C), Select All (Cmd+A), Find (Cmd+F), Find Next (Cmd+G), Find Previous (Shift+Cmd+G)
- **View**: Zoom In (Cmd++), Zoom Out (Cmd+-), Actual Size (Cmd+0), Sans-Serif (Cmd+1), Serif (Cmd+2), Monospace (Cmd+3), Light (Cmd+7), Dark (Cmd+8), System (Cmd+9), Toggle Headings (Shift+Cmd+H), Toggle Minimap (Shift+Cmd+M), Refresh (Cmd+R)

Layout: Two-column grid per category. Category name as a section header. Action name left, key badge right. Use `ColorPalette` for theming. Presented as `.sheet` with a close button.

**Step 2: Add Help menu items to EmdyMenuCommands**

Add a `CommandGroup(replacing: .help)` block with:
- "Keyboard Shortcuts" — posts a notification to show the cheat sheet
- "Welcome to Emdy" — posts a notification to show welcome screen

Add notification names:

```swift
static let showShortcutCheatSheet = Notification.Name("emdy.showShortcutCheatSheet")
static let showWelcome = Notification.Name("emdy.showWelcome")
```

**Step 3: Wire up sheet presentation in EmdyApp or DocumentContentView**

Add `@State private var showShortcutSheet = false` and an `.onReceive` for the notification, presenting `ShortcutCheatSheet` as a `.sheet`.

**Step 4: Build, test the sheet opens from Help menu**

```bash
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Emdy -configuration Debug build
```

Launch, Help > Keyboard Shortcuts should open the sheet.

**Step 5: Commit**

```bash
git add Emdy/Views/ShortcutCheatSheet.swift Emdy/Commands/EmdyMenuCommands.swift Emdy/EmdyApp.swift
git commit -m "Add keyboard shortcut cheat sheet accessible from Help menu"
```

---

### Task 4: Welcome Screen

**Files:**
- Create: `Emdy/Views/WelcomeView.swift`
- Modify: `Emdy/EmdyApp.swift`

**Step 1: Create WelcomeView**

Create `Emdy/Views/WelcomeView.swift`. A SwiftUI view with:

- App icon or SF Symbol at the top
- "Welcome to Emdy" title
- Four feature rows, each with an SF Symbol icon, title, and one-line description:
  1. `doc.richtext` — "Read Markdown beautifully" / "Renders your files with serif, sans-serif, or monospace type"
  2. `list.bullet.indent` — "Navigate with ease" / "Jump through headings or scan the minimap"
  3. `paintpalette` — "Make it yours" / "Switch themes, adjust zoom, pick your font"
  4. `square.and.arrow.up` — "Share your way" / "Copy as rich text, export PDF, or print"
- Bottom: "Open File" and "Open Folder" buttons, plus "Get Started" to dismiss
- Styled with `ColorPalette`, uses `.monospaced` design for headings to match app aesthetic
- Frame: ~480px wide

**Step 2: Add first-launch logic to EmdyApp**

In `EmdyApp.swift`:

```swift
@State private var showWelcome = false

// In .onAppear or body:
.onAppear {
    if !UserDefaults.standard.bool(forKey: "hasShownWelcome") {
        showWelcome = true
        UserDefaults.standard.set(true, forKey: "hasShownWelcome")
    }
}
```

Also add `.onReceive` for the `showWelcome` notification (from Help menu) to re-show it.

**Step 3: Wire Open File / Open Folder buttons**

The "Open File" button should trigger the same open panel logic as `OpenCommands`. The "Open Folder" button should open a directory-only panel and use `openWindow(value: url)`.

**Step 4: Build and test**

```bash
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Emdy -configuration Debug build
```

Reset the flag to test first launch: `defaults delete com.emdy.app hasShownWelcome`

Launch — welcome screen should appear. Dismiss, relaunch — should not appear. Help > Welcome to Emdy — should appear again.

**Step 5: Commit**

```bash
git add Emdy/Views/WelcomeView.swift Emdy/EmdyApp.swift
git commit -m "Add welcome screen shown on first launch"
```

---

### Task 5: Final integration and cleanup

**Step 1: Rebuild and verify all three components work together**

```bash
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Emdy -configuration Debug build
```

Test checklist:
- Help menu > Emdy Help opens Help Viewer with index page
- Help menu > Keyboard Shortcuts opens cheat sheet
- Help menu > Welcome to Emdy opens welcome screen
- First launch shows welcome (after `defaults delete com.emdy.app hasShownWelcome`)
- Help Viewer search works (type a term in the search field)
- Cheat sheet and welcome screen respect light/dark theme

**Step 2: Run tests**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme Emdy test
```

Expected: All existing tests pass.

**Step 3: Commit any final adjustments**

```bash
git add -A
git commit -m "Polish help docs integration"
```
