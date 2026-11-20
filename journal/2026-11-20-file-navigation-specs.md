# File Navigation Specs (links, back/forward history)

**Date:** 2026-11-20
**Status:** product/UX spec. **Decisions 1-4 confirmed by the USER (2026-11-20); no code written yet.** This document is the *what*. The *how* (phases, tasks, rollout) will go in `2026-11-20-file-navigation-implementation-plan.md`, to be written after the USER approves this spec.
**Builds on:** kathishah/emdy#1 (merged 2026-11-20, `5087c0d`): clicking a link to another `.md` file opens it in a **new window**, `#heading` links did nothing before it and now scroll. Its helper `classifyLink` (`electron/src/renderer/lib/link-target.ts`) is reused here.
**Branch:** `feat/file-navigation`

### Spec coverage

| Area | Status |
| --- | --- |
| In-window navigation, history model, scroll restore (§3, §4) | **FINAL** (USER, 2026-11-20) |
| Toolbar chevrons, View menu items, shortcuts (§5) | **FINAL** (USER, 2026-11-20: "both toolbar chevrons and keyboard shortcuts and menu items") |
| Mouse back/forward buttons (§5.4) | Nice to have; must not block the rest |
| Trackpad swipe, tabs, persisted history, history list (§1) | **NOT PLANNED** |

---

## 1. Goal, scope

**Problem.** Following a link to another markdown file opens a new window. Each window holds one document and has no history, so there is no way back except closing the window, and reading a set of linked docs piles up windows.

**Goal.** Following a link keeps you in the same window and lets you go back and forward, like a browser, landing on the same scroll position. A way to still open a link in a new window.

| | |
|---|---|
| In scope | Renderer (`App.tsx`, `MarkdownView.tsx`, `Toolbar.tsx`, a new pure history module), the View menu (`menu.ts`), `FORK.md` |
| Out of scope | Tabs; history that survives closing the window or quitting; a history list or dropdown on the chevrons; syncing history across windows; trackpad swipe (Electron only emits `swipe` for the three-finger system gesture, so it is not reliable) |

## 2. Definitions

- **Window history**: an ordered list of entries plus a current index, one per window. Entry = `{ path, scrollTop }`.
- **Navigation**: any action in the table in §3.1. A navigation saves the current scroll, pushes an entry and shows it.
- **Fresh start**: the window's first document, or a replacement context (§3.1, second table). History is reset to a single entry.
- **Allowed folders**: the folders and file directories the user has opened. `file:read` (`ipc-handlers.ts:50`) enforces them through `isPathAllowed`, and this spec does not change that.

## 3. Behavior

### 3.1 What counts as navigation

Adds an entry:

| Source | Result |
| --- | --- |
| Plain click on a link to a markdown file | Load that file in this window |
| Click `file.md#section` | Load the file, then scroll to the section |
| Click `#section` | Scroll to the heading in the same file |
| Pick a file in the sidebar | Load that file |
| Pick a file result in the command palette | Load that file and apply the search highlight, as today |

Does **not** add an entry; resets history to one entry for the new document:

- The initial `file:open` / `dir:open` that main sends when a window is created.
- Opening a folder or file in an empty window through the Open dialog (`handleOpen` with no content).

Navigating to the file already shown, with no anchor, does nothing. With an anchor it behaves like a `#section` click.

### 3.2 New window

- **Cmd+click** (Ctrl+click on non-macOS) or **middle-click** on a markdown link opens it in a new window through the existing `openInNewWindow`. The new window starts with its own history.
- A plain click never opens a new window. This replaces the #1 behavior.

### 3.3 Going back and forward

- Back moves to the previous entry and forward to the next, restoring that entry's scroll position.
- A navigation after going back drops the forward entries.
- History is capped at **100** entries per window; the oldest is dropped first.
- If the target is the file already shown, only the scroll position changes; the file is not re-read.
- If an entry's file cannot be read (deleted, moved, or outside the allowed folders): show the existing "Failed to read file" toast, stay on the current entry, and **remove the dead entry** so back does not get stuck on it.
- The find bar closes on navigation, as it does for file select today (`closeFind`).
- Command-palette highlights are not part of history. Going back lands on the saved scroll position without re-applying them.

### 3.4 Scroll restoration

Each entry stores `path` and `scrollTop`. Immediately before leaving an entry, the live scroll position of the content scroller is saved to it. Restoring clamps to the content height, so a file that changed or shrank while you were away still works. A freshly pushed entry starts at the top, or at the anchor if there is one.

## 4. Anchors

- `#section` and `file.md#section` resolve a heading id with the existing `slugifyHeading` ids: exact match first, then lowercased.
- After loading a file for `file.md#section`, scroll on the next animation frame, retrying until the heading exists. If it never exists, stay at the top; no error.
- An anchor navigation records the scroll position it left, so Back returns to it. This resolves the limitation noted in #1 (`other.md#section` did not scroll).

## 5. UI

### 5.1 Toolbar

- Back and forward chevron buttons (`ChevronLeft` / `ChevronRight`, same icon size and stroke as the rest of the toolbar), at the left of the toolbar next to the sidebar toggle.
- Disabled (`aria-disabled`, dimmed, no hover) when there is nowhere to go.
- Tooltip and `aria-label`: "Back (⌘[)" and "Forward (⌘])".
- Not collapsed into the overflow menu at narrow widths (`COLLAPSE_WIDTH` 700): they stay visible.

### 5.2 Menu and keyboard

- View menu, first two items, then a separator: **Back** `CmdOrCtrl+[` and **Forward** `CmdOrCtrl+]`. Neither accelerator is used today.
- The menu is global and history is per window, so the items are always enabled and do nothing when the focused window has no history. The toolbar buttons are the per-window indication.
- The Help > Keyboard Shortcuts item has no handler in the renderer today (`show-shortcuts` is sent from `menu.ts` and nothing listens), so there is no shortcuts list to update. Building that dialog is out of scope.

### 5.3 Accessibility

- Navigation is announced through the existing announcer, for example "Opened intro.md" and "Went back to intro.md".
- The chevrons are real `<button>`s with labels. Focus is not moved by navigation, in line with the current file-select behavior.

### 5.4 Mouse buttons (nice to have)

`mouseup` with button 3 / 4 triggers back / forward. Skip it if it complicates anything.

## 6. Acceptance criteria

1. Plain-clicking `other.md` loads it in the same window; the window count does not change; Back returns to the previous file at the same scroll position; Forward returns to `other.md`.
2. Cmd+click and middle-click on the same link open a new window and leave the current window's history unchanged.
3. Clicking `#section` scrolls to it; Back returns to the earlier scroll position.
4. Clicking `other.md#section` loads `other.md` and scrolls to the section.
5. Selecting a sidebar file or a palette result adds an entry; Back undoes it.
6. A fresh window, and the Open dialog in an empty window, start with Back and Forward disabled.
7. After Back, a new navigation disables Forward.
8. 101 navigations leave 100 entries, the newest 100.
9. Back to a deleted file shows the "Failed to read file" toast, stays put, and the next Back skips the dead entry.
10. The chevrons, the View menu items and `Cmd+[` / `Cmd+]` all behave the same; the chevrons are disabled exactly when there is no entry in that direction.
11. Live reload still works after moving between files (the watcher follows the current file).
12. `npm run lint`, `npm test` and `npm run package` pass.

## 7. Implementation

### 7.1 History model: `electron/src/renderer/lib/nav-history.ts` (new, pure)

```ts
interface NavEntry { path: string; scrollTop: number }
interface NavHistory { entries: NavEntry[]; index: number }
```

Pure functions: `createHistory(path)`, `saveScroll(h, scrollTop)`, `push(h, path)` (truncates forward entries, caps at 100, no-op for the current path), `back(h)`, `forward(h)`, `removeEntry(h, i)`, `canGoBack(h)`, `canGoForward(h)`. No React, no Electron.

### 7.2 Renderer

- `App.tsx`: keep the history in state beside `filePath`. Add `navigateTo(path, { anchor })`, `navigateAnchor(id)`, `goBack()` and `goForward()`. Route `handleFileSelect` and `handleFileSelectWithQuery` through the same path so the sidebar and palette share the behavior. Handle two new menu events, `nav-back` and `nav-forward`. The initial `onFileOpen` / `onDirOpen` call `createHistory`.
- `MarkdownView.tsx`: add `onNavigateFile(path, anchor)` and `onNavigateAnchor(id)` props. A plain click calls them; a modifier or middle click calls `openInNewWindow`. Export `scrollToAnchor` so `App` can call it after a file loads.
- `Toolbar.tsx`: `canGoBack`, `canGoForward`, `onBack`, `onForward` props and the two buttons.
- `useFileWatcher` already follows `filePath`; no change.

### 7.3 Main process

`menu.ts`: two View items sending `nav-back` and `nav-forward`. No new IPC and no change to access control.

## 8. Files, tests, and what stays untouched

**Touch:** `electron/src/renderer/lib/nav-history.ts` (+ test), `App.tsx`, `components/MarkdownView.tsx` (+ test), `components/Toolbar.tsx`, `electron/src/main/menu.ts`, `FORK.md` (new "Link navigation and history" entry with its key files).

**Untouched:** `allowed-paths.ts`, `ipc-handlers.ts`, `preload.ts`, `file-watcher.ts`, `classifyLink`.

**Tests**
- `nav-history.test.ts`: push, back and forward move the index; push after back truncates; the 100 cap keeps the index consistent; pushing the current path is a no-op; `saveScroll` touches only the current entry; `removeEntry` of an earlier, the current and a later entry keeps a valid index.
- `MarkdownView.test.tsx`: plain click calls `onNavigateFile` and not `openInNewWindow`; Cmd+click and middle-click call `openInNewWindow`; `#anchor` calls `onNavigateAnchor`. The existing "opens in a new window" tests move to the Cmd+click case.
- Toolbar: chevrons disabled with no history, enabled after navigation, and they call the handlers.
- Manual (`npm start`): acceptance criteria 1-11 above.

## 9. Assumptions to confirm (not explicitly decided by the USER)

1. **Menu items are always enabled** rather than enabled per window. A per-window state would need a focus-driven menu rebuild like `menu:set-has-file`.
2. **Navigating outside the opened folder tree** leaves nothing highlighted in the sidebar. Access is still limited to the allowed folders, so a link outside them shows the "Failed to read file" toast.
3. **The Open dialog in an empty window** resets history instead of adding an entry.
4. **Palette search highlights** are not restored by Back or Forward.
5. **Cap of 100 entries** per window.

## 10. Decision log

| # | Decision | By | Date |
| --- | --- | --- | --- |
| 1 | A plain click on a markdown link stays in the same window; Cmd+click opens a new window | USER | 2026-11-20 |
| 2 | Sidebar selections go into the history, so Back undoes them | USER | 2026-11-20 |
| 3 | `#anchor` links count as history entries | USER | 2026-11-20 |
| 4 | Both toolbar chevrons and keyboard shortcuts plus View menu items | USER | 2026-11-20 |
| 5 | Specs live in `journal/` as `YYYY-MM-DD-<topic>-specs.md`, modeled on `ik_rabbit/journal/` | USER | 2026-11-20 |
