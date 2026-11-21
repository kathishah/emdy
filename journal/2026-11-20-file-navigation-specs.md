# File Navigation Specs (links, back/forward history)

**Date:** 2026-11-20
**Status:** product/UX spec **plus implementation plan (§11-§15, same entry).** **Decisions 1-4 confirmed by the USER (2026-11-20); the plan is written and awaiting USER approval; no feature code written yet.** §1-§10 are the *what*; §11-§15 are the *how* (test-first tasks, verification, rollout, status log). If the two disagree, §1-§10 win; fix the plan.
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
- If an entry's file cannot be read (deleted, moved, or outside the allowed folders): show the existing "Failed to read file" toast, stay on the current entry, and **remove the dead entry** so back does not get stuck on it. The same applies to a failed forward-navigation and to a sidebar or palette pick: the toast is shown and the document on screen is kept. (Before this change a failed sidebar pick replaced the document with the file-error view.)
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
- Shown only while a document is open. Disabled (`aria-disabled`, dimmed, no hover, click ignored) when there is nowhere to go; `aria-disabled` rather than `disabled` so they stay in the toolbar's arrow-key navigation.
- `aria-label` "Back" / "Forward"; tooltip (`data-tooltip`, like the other toolbar buttons) "Back  ⌘[" and "Forward  ⌘]".
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

Pure functions: `createHistory(path)`, `current(h)`, `saveScroll(h, scrollTop)`, `push(h, path)` (truncates forward entries, caps at 100; it always adds an entry, including for the same path, which is how a `#anchor` entry is made; the "already on this file" rule lives in the hook), `back(h)`, `forward(h)`, `removeEntry(h, i)`, `canGoBack(h)`, `canGoForward(h)`. No React, no Electron.

### 7.2 Renderer

- `App.tsx`: call `useFileNavigation` (§11), which owns the history. It exposes `navigateTo(path, anchor?)` (resolves `true` when the file is showing, so a palette pick only applies its highlight after a successful load), `navigateAnchor(id)`, `goBack()` and `goForward()`. Route `handleFileSelect` and `handleFileSelectWithQuery` through the same path so the sidebar and palette share the behavior. Handle two new menu events, `nav-back` and `nav-forward`. The initial `onFileOpen` / `onDirOpen` call `createHistory`.
- `MarkdownView.tsx`: add optional `onNavigateFile(path, anchor)` and `onNavigateAnchor(id)` props. A plain click calls them; a Cmd/Ctrl click or middle click calls `openInNewWindow`; with no `onNavigateFile` a plain click also falls back to a new window. The handlers are read through a ref so changing them never rebuilds the markdown components. Anchor scrolling moved into the hook (the local `scrollToAnchor` is gone).
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

---

## 11. Implementation plan: approach

**Test-first (red, then green).** Four of the five tasks are pure logic or component behavior that is cheap to test, so each starts with tests that fail and ends when they pass. The two pieces that are mostly wiring to Electron (the View menu items and the mouse buttons) have no test harness in this repo, so they are checked manually against §6.

| Piece | Test-first? | Why |
| --- | --- | --- |
| `nav-history.ts` (pure reducer) | **Yes** | No React, no Electron; the edge cases (cap, truncate, dead entry) are exactly what tests are good at |
| `useFileNavigation` hook (new) | **Yes** | Holds the navigate / back / forward / scroll / dead-entry logic; testable with `renderHook` and a mocked `window.electronAPI` |
| `MarkdownView` click routing | **Yes** | Extends the existing component tests (the link-click block added in #1) |
| `Toolbar` chevrons | **Yes** | Small new component test |
| `menu.ts` items, mouse buttons, real windows | **No, manual** | Needs a running Electron app; covered by §6 acceptance criteria 10 and 11 |

**Why a hook.** `App.tsx` has no tests and already owns four copies of "read a file, set content, set path, reset scroll" (`handleOpen`, `handleFileSelect`, `handleFileSelectWithQuery`, `onFileOpen`). Putting the history behavior in `electron/src/renderer/hooks/useFileNavigation.ts` keeps it testable and keeps `App.tsx` thin. `App` passes in the pieces it owns, and the hook does not touch `App` state directly:

```ts
interface UseFileNavigationArgs {
  scrollRef: React.RefObject<HTMLElement | null>;      // content scroller
  readFile: (path: string) => Promise<string>;          // window.electronAPI.readFile
  show: (path: string, content: string) => void;        // App: setContent + setFilePath + clear error/deleted + closeFind
  onReadError: () => void;                              // App: toast + announceAssertive
  announce: (message: string) => void;
}
interface FileNavigation {
  canGoBack: boolean;
  canGoForward: boolean;
  navigateTo(path: string, anchor?: string | null): Promise<void>;
  navigateAnchor(id: string): void;
  goBack(): Promise<void>;
  goForward(): Promise<void>;
  reset(path: string): void;                            // fresh start (§3.1, second table)
}
```

**Rules for each red step.**
- Run the new tests and confirm they fail for the right reason: an assertion failure, not a missing import. Create the module with the exported names as stubs that return their input unchanged first, then write the tests.
- Commit red and green separately only if the USER asks; the default is one commit per task with the tests included.
- Never weaken a test to make it pass. If a test is wrong, fix it and say so in the status log.

## 12. Tasks

Run everything from `electron/`. Baseline before starting: `npm test` (73 tests), `npm run lint` (one existing warning at `MarkdownView.test.tsx:58`) and `npx tsc --noEmit` all pass on `main`.

### Task 1: History model (`lib/nav-history.ts`)
1. **Red:** add `nav-history.test.ts` with the §8 cases: push/back/forward move the index; push after back truncates forward entries; the 100 cap drops the oldest and keeps the index valid; pushing the current path is a no-op; `saveScroll` updates only the current entry; `removeEntry` of an earlier, the current and a later entry keeps a valid index; `canGoBack` / `canGoForward` at both ends; `back` at the start and `forward` at the end return the same history. All fail against the stubs.
2. **Green:** implement the module (contract in §7.1). Pure and immutable; no mutation of the input.
3. **Gate:** `npx vitest run src/renderer/lib/nav-history.test.ts` passes.

### Task 2: Navigation hook (`hooks/useFileNavigation.ts`)
1. **Red:** add `useFileNavigation.test.tsx` using `renderHook`, a fake `readFile` and a plain `<div>` for `scrollRef`:
   - `navigateTo` saves the live `scrollTop` of the current entry, reads the file, calls `show`, and enables back (acceptance 1).
   - `goBack` shows the previous file and restores its saved `scrollTop`; `goForward` returns (1).
   - `navigateAnchor` adds an entry for the same path without calling `readFile`, scrolls the heading into view, and Back returns to the earlier `scrollTop` (3).
   - `navigateTo(path, 'section')` loads the file and scrolls to the section once it exists (4).
   - A navigation after `goBack` disables forward (7).
   - `navigateTo` to the file already shown with no anchor does nothing.
   - A failed `readFile` calls `onReadError`, leaves the current entry in place and removes the dead entry, so the next Back skips it (9).
   - Two quick navigations: the earlier read resolving late must not overwrite the later one (stale-result guard, §14 risk 1).
   - `reset(path)` leaves one entry; back and forward are both disabled (6).
2. **Green:** implement the hook on top of `nav-history`. Use a navigation counter ref to ignore superseded loads. Retry the anchor scroll on the next animation frame until the element exists, then give up quietly (§4).
3. **Gate:** the new file passes; `npm test` still passes.

### Task 3: Link click routing (`MarkdownView`)
1. **Red:** in `MarkdownView.test.tsx`, change the link-click block from #1: plain click on `other.md` calls `onNavigateFile('/notes/guide/other.md', null)` and not `openInNewWindow`; Cmd+click and Ctrl+click call `openInNewWindow` and not `onNavigateFile`; a middle-click (`auxclick`, button 1) calls `openInNewWindow`; `#target-section` calls `onNavigateAnchor('target-section')` and no longer scrolls inside `MarkdownView`; `parent` (`../README.md#setup`) calls `onNavigateFile('/notes/README.md', 'setup')`; external, non-markdown and no-file-open cases are unchanged.
2. **Green:** add the two props and the modifier / `onAuxClick` handling (§7.2). Move `scrollToAnchor` out so the hook owns scrolling, and delete the unused copy.
3. **Gate:** `MarkdownView.test.tsx` passes.

### Task 4: Toolbar chevrons
1. **Red:** new `Toolbar.test.tsx`: both chevrons render with `aria-label` "Back (⌘[)" and "Forward (⌘])"; they are `aria-disabled` when `canGoBack` / `canGoForward` are false and clicking does not call the handler; when enabled, clicking calls `onBack` / `onForward`; they stay rendered at a width below `COLLAPSE_WIDTH` (700). If the existing component can't render in the test as-is, add the smallest stub for what it needs; do not refactor it.
2. **Green:** add `canGoBack`, `canGoForward`, `onBack`, `onForward` props and the buttons (§5.1), using `ChevronLeft` / `ChevronRight` from `lucide-react` at the toolbar's `ICON` size.
3. **Gate:** `Toolbar.test.tsx` passes.

### Task 5: Wire it into the app (manual verification)
No automated test (`App.tsx` is not testable today); the behavior it relies on is covered by Tasks 1-4.
1. `App.tsx`: call `useFileNavigation`; pass `onNavigateFile` / `onNavigateAnchor` to `MarkdownView`, and the four new props to `Toolbar`. Route `handleFileSelect` and `handleFileSelectWithQuery` through `navigateTo` (keep `applyHighlight`). Call `reset` from `onFileOpen`, `onDirOpen` and the Open dialog path of `handleOpen` (§3.1, second table).
2. `App.tsx`: handle menu events `nav-back` and `nav-forward`. Optional: a `mouseup` listener for buttons 3 and 4 (§5.4), cleaned up on unmount; drop it if it complicates anything.
3. `menu.ts`: two View items first, then a separator: Back `CmdOrCtrl+[`, Forward `CmdOrCtrl+]`, sending `nav-back` and `nav-forward`.
4. **Gate:** `npx tsc --noEmit` and `npm run lint` clean; manual checks for acceptance 1-11 with `npm start`.

### Task 6: Docs
1. `FORK.md`: add "Link navigation and history" under "Intentional fork differences", with a short description and the key files (`nav-history.ts`, `useFileNavigation.ts`, `MarkdownView.tsx`, `Toolbar.tsx`, `App.tsx`, `menu.ts`), so future upstream merges keep it.
2. This entry: tick the status log (§15) and record any change to the spec.

## 13. Verification

Automated, from `electron/`: `npm test`, `npm run lint`, `npx tsc --noEmit`, and `npm run package` (a local unsigned build, per `CONTRIBUTING.md`).

Manual, with `npm start`, on a folder of linked markdown files that includes an `#anchor` link, a `file.md#section` link, a link to a deleted file and a link outside the opened folder. Walk through acceptance criteria 1-11 in §6. Test the Cmd+click window once, and confirm the new window's Back is disabled.

## 14. Risks and mitigations

1. **Stale loads.** Two quick clicks: the slower read of the first can land after the second and show the wrong file. Mitigation: a navigation counter in the hook; a result is applied only if it is still the latest. Covered by a Task 2 test.
2. **Scroll saved too late.** If the scroll position is read after the new content renders, the old entry stores the wrong value. Mitigation: read `scrollTop` before calling `show` (Task 2 test asserts the order).
3. **Anchor not found.** Headings are created by the renderer after `show`. Mitigation: retry on the next animation frame, then give up quietly (§4).
4. **`Cmd+[` / `Cmd+]` collisions.** Neither is used by the app today (checked in `menu.ts`). Re-check if upstream adds accelerators when merged.
5. **Menu is global.** An always-enabled item in a window with no history does nothing; accepted (§9 item 1).
6. **Listener leaks under React StrictMode.** The optional mouse listener must clean up in the effect's return; the existing renderer code is run in StrictMode in dev.
7. **Merge conflicts with upstream.** `App.tsx`, `MarkdownView.tsx` and `Toolbar.tsx` are the fork's most-edited files. Mitigation: most new logic lives in two new files; record the touch points in `FORK.md`.

## 15. Rollout, rollback, status log

**Rollout.** This is a desktop app change with no server side and no deploy. Open a PR from `feat/file-navigation` into `kathishah/emdy` `main`, squash-merge as in #1, and let the USER decide when to cut a release. There is no PR-time CI, so the Verification section is the safety net.

**Rollback.** Revert the squash commit. Nothing is persisted (history is in memory only), so there is no data to migrate.

**Status log** (update in place):

| Date | Event |
| --- | --- |
| 2026-11-20 | Spec §1-§10 written; USER decisions 1-4 recorded; committed `468a8ac` |
| 2026-11-20 | Implementation plan §11-§15 written (test-first); awaiting USER approval |
| 2026-11-20 | **Plan approved by the USER; implementation started on `feat/file-navigation`** |
| 2026-11-20 | Tasks 1-4 done test-first (red then green): `nav-history` (15 tests), `useFileNavigation` (15), `MarkdownView` link routing (22 in file), `Toolbar` (7). Task 5 wired in `App.tsx` and `menu.ts` (View > Back/Forward, mouse buttons 3/4). Task 6: `FORK.md` entry. `npm test` 116 passing, `tsc` clean, eslint 0 errors (5 pre-existing warnings). |
| 2026-11-20 | **End-to-end run on the packaged app** (`electron-forge package`, launched with a debug port and an isolated `--user-data-dir`, driven over CDP with real mouse input; scratch scripts not committed): 21/21 checks pass. Covered: plain click stays in the window; Back/Forward via toolbar restore the exact scroll (1888 before and after); `#anchor` and `other.md#second-part` scroll to the heading and Back restores; Cmd+click opens a second window with its own empty history and leaves the first untouched; Back onto a deleted file toasts, stays put, and the next Back skips it; missing-file and outside-folder links toast and change nothing; mouse Back/Forward buttons work. Also added `src/main/menu.test.ts` (4 tests) for the View menu items and events. |
| 2026-11-20 | **Not verified end to end:** the native View menu items and `Cmd+[` / `Cmd+]` (macOS denied `osascript` the Accessibility permission, so the menu could not be driven). The menu template and event names are unit tested and the same `goBack` / `goForward` are exercised by the chevrons and mouse buttons; press the shortcuts once in a real window to close this out. The web link click path (`openExternal`) was not clicked, to avoid opening a browser. |
| 2026-11-20 | **Finding (pre-existing, dev only):** in `npm start` heading ids get a `-2` suffix (the id counter in `MarkdownView` increments twice because React StrictMode renders each heading twice), so `#anchor` links find nothing in dev. Packaged builds are unaffected, which is why the E2E ran on a packaged build. Not changed here; worth a separate fix. |
| 2026-11-20 | Deviations from the plan, all recorded above: `navigateTo` returns a boolean; `onNavigate` and `announce` args added to the hook; chevrons only render while a document is open; failed reads toast instead of showing the file-error view. |
