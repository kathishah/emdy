# Emdy — System Architecture

## System Overview

Emdy is a single-process, native macOS application. It has no backend, no network dependencies for core functionality, and no user accounts. The system boundary is the user's Mac — Emdy reads files from disk, renders them in-process, and interacts with macOS system services for printing, pasteboard, file associations, and updates.

![System Architecture Diagram](system-architecture.png)

> Source file: [architecture.pen](architecture.pen) (open in [pencil.dev](https://pencil.dev))

## Components

### 1. App Shell & Routing

The entry point. Handles application lifecycle, window management, and deciding what view to show based on what was opened.

**Responsibilities:**
- `@main` App struct with `DocumentGroup` for single-file opens
- Detect whether the user opened a file or a directory
- Route to the appropriate view: single document view or directory browser + document view
- Manage Open Recent list (backed by `NSDocumentController`)
- Menu bar: Font switcher, Zoom controls, Print, Tip Jar, Check for Updates

**Inputs:** File open events (double-click, File > Open, drag-and-drop, Open Recent)
**Outputs:** Routes to Document Manager or Directory Browser

### 2. Document Manager

Owns the lifecycle of a single Markdown document.

**Responsibilities:**
- Read `.md` / `.markdown` file from disk
- Pass raw text to the Markdown Renderer
- Watch the file for changes on disk (via `DispatchSource` or `NSFilePresenter`) and re-render if the file is modified externally
- Provide the attributed string to the RTF copy and print systems

**Inputs:** File path from App Shell or Directory Browser
**Outputs:** Raw Markdown string to Renderer; attributed string to Pasteboard and Print

### 3. Markdown Renderer

Parses GFM Markdown and produces a rendered view.

**Responsibilities:**
- Parse GitHub Flavored Markdown (headings, bold, italic, links, lists, code blocks, tables, task lists, strikethrough, blockquotes, images)
- Produce an `NSAttributedString` or SwiftUI view hierarchy for display
- Apply the current font family (serif / sans-serif / monospace) and zoom level
- Resolve image references — both local file paths (relative to the document) and remote URLs
- Handle relative `.md` links: intercept clicks and route them back to the Document Manager to open the linked file within Emdy

**Key decision — Markdown parsing library:**
Options include `swift-markdown` (Apple's parser, CommonMark only), `cmark-gfm` (C library with GFM support), or `Ink` (Swift, limited GFM). Since GFM is required, `cmark-gfm` wrapped in a Swift interface is the likely choice. This is the one area where a third-party dependency is justified.

**Inputs:** Raw Markdown string, font preference, zoom level
**Outputs:** Rendered view, attributed string

### 4. Directory Browser (Sidebar)

Displays when the user opens a folder instead of a single file.

**Responsibilities:**
- List all `.md` and `.markdown` files in the opened directory (one level, non-recursive)
- Display filenames in a sidebar list
- Handle selection: when the user clicks a file, pass it to the Document Manager
- Handle internal `.md` links: if a relative link points to a file in the current directory, select it in the sidebar and render it

**Inputs:** Directory path from App Shell
**Outputs:** Selected file path to Document Manager

### 5. Display Controls

User-facing controls for reading preferences.

**Responsibilities:**
- Font switcher: serif, sans-serif, monospace (three fixed options, stored in `UserDefaults`)
- Zoom in/out (Cmd+/Cmd-, stored in `UserDefaults`)
- Preferences persist across sessions

**Inputs:** User interaction (menu items, keyboard shortcuts)
**Outputs:** Font family and zoom level to Markdown Renderer

### 6. System Integration Layer

Bridges between Emdy and macOS system services.

#### File Association
- Register as handler for `.md` and `.markdown` via `Info.plist` UTType declarations
- On first launch, optionally prompt user to set Emdy as the default handler

#### Pasteboard (RTF Copy)
- Convert selected `NSAttributedString` to RTF data
- Place on `NSPasteboard` via standard Cmd+C
- Result pastes as formatted text in Mail, Google Docs, Slack, etc.

#### Print / Save as PDF
- Present standard macOS print dialog (`NSPrintOperation`)
- The print dialog's built-in "Save as PDF" button handles PDF export for free
- Print the attributed string representation of the current document

#### Image Loading
- Local images: resolve relative paths against the document's directory
- Remote images: fetch via `URLSession`, display inline once loaded
- Failure: show a placeholder or alt text if the image can't be loaded

#### Sparkle (Auto-Update)
- Check for updates on each app launch (silent network request)
- If an update is available, show a standard Sparkle prompt
- User can also trigger a manual check from the menu
- Requires hosting an appcast XML file at a known URL

#### Link Handling
- External links (http/https to non-.md targets): open in the user's default browser via `NSWorkspace`
- Relative `.md` links: resolve against the current document's directory and open within Emdy
- Anchor links: scroll to the heading within the current document

## Data Flow

```
User double-clicks .md file
        │
        ▼
┌─ macOS Launch Services ─┐
│  Routes to Emdy via      │
│  UTType registration     │
└──────────┬───────────────┘
           ▼
┌─ App Shell ──────────────┐
│  File or directory?      │
└──┬───────────────────┬───┘
   │                   │
   ▼                   ▼
Single file         Directory
   │                   │
   │            ┌──────┴──────┐
   │            │  Directory  │
   │            │  Browser    │──▶ user picks file
   │            └─────────────┘         │
   │                                    │
   ▼◀───────────────────────────────────┘
┌─ Document Manager ───────┐
│  Reads file from disk    │
│  Watches for changes     │
└──────────┬───────────────┘
           ▼
┌─ Markdown Renderer ──────┐
│  Parses GFM              │
│  Applies font + zoom     │
│  Loads images             │
│  Resolves links          │
└──────────┬───────────────┘
           ▼
┌─ Rendered Document View ─┐
│                          │
│  Cmd+C ──▶ RTF to pasteboard
│  Cmd+P ──▶ Print dialog
│  Click .md link ──▶ back to Document Manager
│  Click external link ──▶ default browser
└──────────────────────────┘
```

## External Dependencies

| Dependency | Type | Purpose | Required? |
|---|---|---|---|
| `cmark-gfm` (or equivalent) | Swift Package | GFM Markdown parsing | Yes — core functionality |
| Sparkle | Swift Package | Auto-update framework | Yes — distribution is direct download, so updates need a mechanism |
| macOS Print System | OS service | Print and Save as PDF | Provided by OS |
| macOS Pasteboard | OS service | RTF copy | Provided by OS |
| macOS Launch Services | OS service | File association / Open Recent | Provided by OS |
| Update server | Remote | Hosts appcast XML + DMG for Sparkle | Yes — any static file host works |
| Remote image servers | Remote | Serves images referenced in Markdown via URL | Optional — only if documents reference remote images |

## Failure Modes

| Scenario | User impact | Handling |
|---|---|---|
| File can't be read (permissions, missing) | Document doesn't render | Show a clear error message in the document area |
| Malformed Markdown | Partial or broken rendering | Render what's parseable, degrade gracefully — raw text is better than nothing |
| Remote image fails to load | Missing image in document | Show alt text or a "missing image" placeholder |
| Directory has no .md files | Empty sidebar | Show an empty state message: "No Markdown files in this folder" |
| Sparkle update check fails (no network) | No update | Fail silently — the app works entirely offline |
| File changes on disk while open | Stale content | Re-render automatically; if the file is deleted, show a notice |

## Architectural Decisions

| Decision | Chosen | Rationale | Alternative considered |
|---|---|---|---|
| Markdown parser | `cmark-gfm` (C library) | Only mature option with full GFM support including tables and task lists | `swift-markdown` (Apple) — CommonMark only, no GFM extensions |
| Rendering approach | `NSAttributedString` | Needed for RTF copy, print, and fine-grained font/zoom control | SwiftUI native `Text` — limited styling control, harder to produce RTF |
| Directory browsing depth | Single level (flat) | Keeps the sidebar simple; recursive browsing adds complexity for a reader app | Recursive tree view — deferred, may revisit if users request it |
| Internal .md link handling | Navigate within Emdy | Makes directory-based reading feel cohesive; opening every link in Finder would break flow | Open in Finder — simpler but worse experience |
| Update mechanism | Sparkle on launch | Direct download distribution requires a self-update path; checking on launch is unobtrusive | Manual-only — too easy to fall behind on updates |
| Image loading | Local + remote, no cache | Keeps the app stateless; remote images reload each time | Local + cached remote — adds disk management complexity |
