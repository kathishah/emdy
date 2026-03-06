# Emdy — Project Plan

## To Do

### App Features
- [ ] Register as default macOS handler for `.md` / `.markdown` (UTType in Info.plist + first-launch prompt)
- [ ] File watching — re-render when the open file changes on disk
- [ ] Drag-and-drop file opening (drop a `.md` file onto the app icon or window)
- [ ] Anchor link handling — click a heading link to scroll within the document
- [ ] Remote image loading (fetch and display images referenced by URL)
- [ ] Image load failure — show alt text or placeholder
- [ ] Error state when a file can't be read (permissions, missing)
- [ ] Empty state when a directory has no Markdown files
- [ ] File-deleted notice when an open file is removed from disk
- [ ] License key system — validation, activation, and gating in-app
- [ ] User-facing help documentation (accessible from Help menu)

### Licensing & Payments
- [ ] License key generation service
- [ ] Payment processing integration
- [ ] Email confirmation on purchase

### Distribution & Packaging
- [ ] Sparkle auto-update integration
- [ ] Appcast XML hosting setup
- [ ] DMG packaging and code signing
- [ ] Direct download website

### Polish & QA
- [ ] Test on macOS light and dark mode across all views
- [ ] Keyboard shortcuts audit and implementation (ensure all standard shortcuts work, add any missing)
- [ ] Accessibility pass (VoiceOver, keyboard navigation)
- [ ] Performance testing with large Markdown files
- [ ] Expand test coverage beyond `MarkdownRendererTests`

### Marketing & Launch
- [ ] Marketing site design and build (visual directions started in `visual-design.pen`)
- [ ] App icon design
- [ ] Screenshots and promotional assets

---

## Completed

### Research & Planning
- [x] Design brief — product vision, audience, constraints, user research (`docs/design-brief.md`)
- [x] System architecture document and diagram (`docs/system-architecture.md`, `docs/architecture.pen`)
- [x] User journeys for all core scenarios (`docs/user-journeys.md`)
- [x] Service blueprint mapping frontstage, backstage, and support processes (`docs/service-blueprint.md`, `docs/service-blueprint.pen`)
- [x] App wireframes for all 7 screens (`docs/app-wireframes.pen`)
- [x] Visual design exploration — moodboards and 4 layout directions (`docs/visual-design.pen`)
- [x] CLAUDE.md with full project conventions and architecture reference

### Core App (Swift / SwiftUI)
- [x] macOS app scaffold — `@main` App struct with `DocumentGroup` for file handling
- [x] Markdown parsing and rendering (GFM via `NSAttributedString`)
- [x] GFM table rendering
- [x] Open and render single Markdown files
- [x] Directory browsing via sidebar (recursive, with expandable folders)
- [x] Sidebar width constrained to 200-320px (ideal 240)
- [x] Optimal content width — text capped at ~680px, centered, background fills window
- [x] Find in page (`Cmd+F`) with `NSTextFinder` integration
- [x] Minimap for document navigation (toggle via toolbar, click to jump, drag to scroll)
- [x] Syntax highlighting for fenced code blocks (Swift, Python, JS/TS, Go, Rust, Java/Kotlin, C/C++, Ruby, Bash, SQL, generic fallback)
- [x] Zoom in/out (`Cmd+` / `Cmd-`)
- [x] Font switcher — serif, sans-serif, monospace (IBM Plex Sans, Serif, Mono bundled as static TTFs)
- [x] Theme switcher — Light, Dark, System (dark palette is warm, Braun-inspired)
- [x] Copy selected text as RTF
- [x] Export as PDF (dedicated save dialog) and Print (standard macOS print dialog)
- [x] Open Recent / reopen last file
- [x] Relative `.md` link handling — navigate within Emdy
- [x] External link handling — open in default browser
- [x] Local image resolution (relative to document directory)
- [x] Display settings persisted to UserDefaults (font family, zoom, theme)
- [x] Color palette with semantic colors for light and dark modes
- [x] Status bar view
- [x] Toast notifications
- [x] Empty state view
- [x] Toolbar with consistent spacing (4px rhythm, `ControlGroup` wrapping, `toolbar(id:)`)

### Tests
- [x] Markdown renderer tests (`EmdyTests/MarkdownRendererTests.swift`)
- [x] Directory search model tests (`EmdyTests/DirectorySearchModelTests.swift`)
