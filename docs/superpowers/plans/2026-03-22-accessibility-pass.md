# Accessibility Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the Emdy Electron app to WCAG 2.1 Level AA conformance across all interactive components.

**Architecture:** Six horizontal layers applied across the full app — semantic landmarks, ARIA roles/labels, focus indicators, focus trapping, live regions, and reduced motion/contrast. Each layer builds on the previous. Two new shared hooks (`useFocusTrap`, `useAnnounce`) and one small component (`SkipLink`) are introduced. No new dependencies.

**Tech Stack:** React 18, TypeScript, CSS custom properties, Lucide React icons

**Spec:** `docs/superpowers/specs/2026-03-22-accessibility-pass-design.md`

**Testing note:** No test framework is configured yet. Each task includes manual verification steps using VoiceOver and keyboard-only navigation. Run the app with `cd electron && npm start` throughout.

**Deferred:** `FindBar.tsx` is not currently rendered in `App.tsx`. Accessibility work on FindBar (search role, labels, match count announcements) is deferred until the component is wired up.

---

### Task 1: SkipLink component and semantic landmarks in App.tsx

**Files:**
- Create: `electron/src/renderer/components/SkipLink.tsx`
- Modify: `electron/src/renderer/App.tsx`
- Modify: `electron/src/renderer/styles/global.css`

- [ ] **Step 1: Create SkipLink component**

Create `electron/src/renderer/components/SkipLink.tsx`:

```tsx
import React from 'react';

export function SkipLink() {
  return (
    <a href="#main-content" className="skip-link">
      Skip to content
    </a>
  );
}
```

- [ ] **Step 2: Add skip-link styles to global.css**

Add to the end of `electron/src/renderer/styles/global.css`:

```css
/* Accessibility: Skip link */
.skip-link {
  position: absolute;
  top: -100px;
  left: 16px;
  z-index: 10000;
  padding: 8px 16px;
  background: var(--bg-primary);
  color: var(--text-primary);
  border: 2px solid var(--accent);
  border-radius: var(--radius-sm);
  font-size: var(--fs-sm);
  text-decoration: none;
}

.skip-link:focus {
  top: 8px;
}
```

- [ ] **Step 3: Add landmarks and SkipLink to App.tsx**

In `App.tsx`:

1. Add import: `import { SkipLink } from './components/SkipLink';`

2. In the return JSX, add `<SkipLink />` as the first child of `<div className="app">` (before the titlebar div at line 247).

3. Wrap the sidebar container (line 289-298) — change the outer `<div className={...sidebar-container...}>` to `<nav aria-label="Files" className={...sidebar-container...}>`.

4. In `renderContent()` (line 218-243), wrap the content column return. Change the outermost `<div className="content-column">` (line 219) to `<main id="main-content" className="content-column">` and its closing `</div>` (line 241) to `</main>`.

5. For the non-file content states (WelcomeView, EmptyState, "Select a file" message), wrap each in `<main id="main-content">`. For example, WelcomeView (line 216) becomes:
```tsx
return <main id="main-content"><WelcomeView onOpen={handleOpen} /></main>;
```
Do the same for the file-deleted EmptyState (line 203), error EmptyState (line 206), and the "Select a file" empty state (line 209-213).

- [ ] **Step 4: Verify landmarks**

Run: `cd electron && npm start`

1. Open VoiceOver (Cmd+F5)
2. Use VO+U to open the rotor, navigate to "Landmarks"
3. Confirm you see: "Files navigation", "main" (or "main content")
4. Press Tab — confirm "Skip to content" link appears briefly, then disappears on blur
5. Activate the skip link — confirm focus moves to the main content area

- [ ] **Step 5: Commit**

```bash
git add electron/src/renderer/components/SkipLink.tsx electron/src/renderer/App.tsx electron/src/renderer/styles/global.css
git commit -m "a11y: add skip link and semantic landmarks (nav, main)"
```

---

### Task 2: Semantic structure in Toolbar, Minimap, StatusBar

**Files:**
- Modify: `electron/src/renderer/components/Toolbar.tsx`
- Modify: `electron/src/renderer/components/Minimap.tsx`
- Modify: `electron/src/renderer/components/StatusBar.tsx`

- [ ] **Step 1: Add toolbar role**

In `Toolbar.tsx`, find the root `<div className="toolbar">` (around line 100). Add `role="toolbar"` and `aria-label="Document tools"`:

```tsx
<div className="toolbar" role="toolbar" aria-label="Document tools">
```

- [ ] **Step 2: Hide minimap from assistive technology**

In `Minimap.tsx`, find the root `<div className="minimap"...>` (around line 151). Add `aria-hidden="true"`:

```tsx
<div className={`minimap${visible ? ' open' : ''}`} aria-hidden="true">
```

- [ ] **Step 3: Add status role to StatusBar**

In `StatusBar.tsx`, find the root `<div className="status-bar">` (around line 23). Add `role="status"`:

```tsx
<div className="status-bar" role="status">
```

- [ ] **Step 4: Verify**

Run the app. Open VoiceOver rotor (VO+U) → Landmarks. Confirm "Document tools toolbar" appears. Confirm minimap content is not read by VoiceOver when navigating. Confirm status bar content is announced when it changes.

- [ ] **Step 5: Commit**

```bash
git add electron/src/renderer/components/Toolbar.tsx electron/src/renderer/components/Minimap.tsx electron/src/renderer/components/StatusBar.tsx
git commit -m "a11y: add toolbar role, hide minimap, status role on StatusBar"
```

---

### Task 3: Sidebar semantic structure (DirectoryBrowser)

**Files:**
- Modify: `electron/src/renderer/components/DirectoryBrowser.tsx`

- [ ] **Step 1: Convert file list to ul/li structure**

In `DirectoryBrowser.tsx`:

1. Change the `<div className="sidebar-tree">` (around line 28) to `<ul className="sidebar-tree" role="tree">`.

2. In the `FileItem` component (around line 56-72): wrap the return in `<li role="treeitem">`. The inner `<button>` keeps its existing classes and handlers. Remove the outer div if one exists.

3. In the `FolderItem` component (around line 75-134): wrap the return `<div className="tree-folder-group">` in `<li role="treeitem" aria-expanded={expanded}>`. The nested children container becomes `<ul role="group">`. Each child FileItem/FolderItem is already wrapped in `<li>` from the above change.

4. Add `aria-current="page"` to the active file's `<li>` element: when `entry.path === activePath`, set `aria-current="page"` on the `<li>`.

- [ ] **Step 2: Add CSS for list reset**

Add to `global.css`:

```css
/* Accessibility: reset list styles for tree */
.sidebar-tree,
.sidebar-tree ul {
  list-style: none;
  padding: 0;
  margin: 0;
}
```

- [ ] **Step 3: Add aria-expanded to folder toggle**

In the `FolderItem` component, on the `<button className="tree-folder">` (around line 104), add `aria-expanded={expanded}`:

```tsx
<button className="tree-folder" onClick={() => setExpanded(!expanded)} aria-expanded={expanded}>
```

- [ ] **Step 4: Verify**

Run the app, open a folder. VoiceOver should announce "Files, navigation" when entering the sidebar. Navigate the file tree — confirm VoiceOver announces "expanded"/"collapsed" on folders, and "current page" on the active file.

- [ ] **Step 5: Commit**

```bash
git add electron/src/renderer/components/DirectoryBrowser.tsx electron/src/renderer/styles/global.css
git commit -m "a11y: convert sidebar to semantic tree with aria-expanded and aria-current"
```

---

### Task 4: ARIA labels on all icon-only buttons (Toolbar)

**Files:**
- Modify: `electron/src/renderer/components/Toolbar.tsx`

- [ ] **Step 1: Add aria-label to each icon-only button**

In `Toolbar.tsx`, add `aria-label` to every button that only has an icon. Also add `aria-expanded` to the toggle buttons that control panel visibility. Find each button and add the attribute:

| Button location | Add |
|----------------|-----|
| Sidebar toggle button (~line 108) | `aria-label="Toggle sidebar" aria-expanded={sidebarVisible}` |
| Zoom out button (in zoom group) | `aria-label="Zoom out"` |
| Zoom in button (in zoom group) | `aria-label="Zoom in"` |
| Search button | `aria-label="Search files"` |
| Font selector trigger | `aria-label="Font" aria-haspopup="true" aria-expanded={fontMenuOpen}` |
| Copy button | `aria-label="Copy to clipboard"` |
| Export PDF button | `aria-label="Export as PDF"` |
| Settings button | `aria-label="Settings"` |
| Minimap toggle button | `aria-label="Toggle minimap" aria-expanded={minimapVisible}` |
| Overflow menu trigger (collapsed view) | `aria-label="More actions" aria-haspopup="true" aria-expanded={overflowOpen}` |

- [ ] **Step 2: Add menu roles to font dropdown and overflow menu**

For the font dropdown (inside `fontMenuRef`):
- The dropdown container div gets `role="menu"`
- Each font option button gets `role="menuitem"`

For the overflow menu (inside `overflowRef`):
- The dropdown container div gets `role="menu"`
- Each option button gets `role="menuitem"`

- [ ] **Step 3: Verify**

Run the app. Tab to the toolbar. VoiceOver should announce each button's label (e.g., "Toggle sidebar, button, expanded"). Open font dropdown — VoiceOver should announce "menu" and individual menu items.

- [ ] **Step 4: Commit**

```bash
git add electron/src/renderer/components/Toolbar.tsx
git commit -m "a11y: add aria-labels to icon buttons, menu roles to dropdowns"
```

---

### Task 5: ARIA on CommandPalette (dialog, combobox, listbox)

**Files:**
- Modify: `electron/src/renderer/components/CommandPalette.tsx`

- [ ] **Step 1: Add dialog role and combobox pattern**

In `CommandPalette.tsx`:

1. On the `<div className="command-palette">` container (around line 134), add:
```tsx
<div className="command-palette ..." role="dialog" aria-modal="true" aria-label="Search files and content">
```

2. On the `<input>` element, add combobox attributes:
```tsx
<input
  ref={inputRef}
  className="command-palette-input"
  placeholder="Search files and content…"
  value={query}
  onChange={(e) => setQuery(e.target.value)}
  onKeyDown={handleKeyDown}
  role="combobox"
  aria-expanded={flatItems.length > 0}
  aria-controls="command-palette-listbox"
  aria-activedescendant={selectedIndex >= 0 ? `command-palette-option-${selectedIndex}` : undefined}
  aria-autocomplete="list"
/>
```

3. On the results container `<div className="command-palette-results">`, add:
```tsx
<div className="command-palette-results" role="listbox" id="command-palette-listbox">
```

4. On each result button, add `role="option"`, a unique `id`, and `aria-selected`:
```tsx
<button
  className={`command-palette-result${isSelected ? ' selected' : ''}`}
  role="option"
  id={`command-palette-option-${selectableIndex}`}
  aria-selected={isSelected}
  ...
>
```
Note: `selectableIndex` is the index within the selectable (non-header) items, matching `selectedIndex`.

5. On group headers, add `role="presentation"`:
```tsx
<div className="command-palette-group-header" role="presentation">
```

- [ ] **Step 2: Verify**

Run the app. Press Cmd+F to open command palette. VoiceOver should announce "Search files and content, dialog". Type a query — VoiceOver should announce the selected result as you arrow through. The group headers should not be read as list items.

- [ ] **Step 3: Commit**

```bash
git add electron/src/renderer/components/CommandPalette.tsx
git commit -m "a11y: add dialog role and combobox pattern to CommandPalette"
```

---

### Task 6: ARIA on SettingsModal (dialog, radiogroups)

**Files:**
- Modify: `electron/src/renderer/components/SettingsModal.tsx`

- [ ] **Step 1: Add dialog role and aria-labelledby**

In `SettingsModal.tsx`:

1. Add an `id` to the settings title (around line 42):
```tsx
<span className="settings-title" id="settings-modal-title">Settings</span>
```

2. On the modal container `<div className="settings-modal">`, add:
```tsx
<div className={`settings-modal${active ? ' active' : ''}`} role="dialog" aria-modal="true" aria-labelledby="settings-modal-title">
```

3. Add `aria-label="Close"` to the close button.

- [ ] **Step 2: Add radiogroup for color scheme**

Wrap the color scheme `<div className="settings-options">` with radiogroup semantics:

```tsx
<div className="settings-options" role="radiogroup" aria-label="Color scheme">
  {colorThemes.map((ct) => (
    <button
      className={`settings-option${colorTheme === ct.value ? ' active' : ''}`}
      onClick={() => onColorThemeChange(ct.value)}
      role="radio"
      aria-checked={colorTheme === ct.value}
      aria-label={`${ct.label} theme`}
    >
      ...
    </button>
  ))}
</div>
```

- [ ] **Step 3: Add radiogroup for appearance**

Wrap the appearance `<div className="settings-options">` similarly:

```tsx
<div className="settings-options" role="radiogroup" aria-label="Appearance">
  {appearances.map((a) => (
    <button
      className={`settings-option${theme === a.value ? ' active' : ''}`}
      onClick={() => onThemeChange(a.value)}
      role="radio"
      aria-checked={theme === a.value}
    >
      {a.label}
    </button>
  ))}
</div>
```

- [ ] **Step 4: Verify**

Run the app. Open settings (gear icon or via menu). VoiceOver should announce "Settings, dialog". Navigate to color scheme — should announce "Color scheme, radio group" and each option as "Warm theme, radio button, selected" or "not selected". Same pattern for appearance.

- [ ] **Step 5: Commit**

```bash
git add electron/src/renderer/components/SettingsModal.tsx
git commit -m "a11y: add dialog role and radiogroup patterns to SettingsModal"
```

---

### Task 7: ARIA on remaining components (ToastNotification, FileContextMenu, MarkdownView)

**Files:**
- Modify: `electron/src/renderer/components/ToastNotification.tsx`
- Modify: `electron/src/renderer/components/FileContextMenu.tsx`
- Modify: `electron/src/renderer/components/MarkdownView.tsx`

- [ ] **Step 1: Add role="status" to toast container**

In `ToastNotification.tsx`, on the `<div className="toast-container">` (around line 15), add:

```tsx
<div className="toast-container" role="status" aria-live="polite">
```

Add `aria-label="Close"` to each toast's close button.

- [ ] **Step 2: Add menu role to FileContextMenu**

In `FileContextMenu.tsx`, on the `<div className="context-menu">` (around line 31), add:

```tsx
<div className="context-menu" role="menu" style={{top: y, left: x}} ref={ref}>
```

On each `<button className="context-menu-item">`, add `role="menuitem"`.

- [ ] **Step 3: Add aria-label to copy button in MarkdownView**

In `MarkdownView.tsx`, find the `CodeBlock` component's copy button (around line 103). Add `aria-label="Copy code"` alongside the existing `title`:

```tsx
<button className="code-block-copy" onClick={handleCopy} title="Copy code" aria-label="Copy code">
```

- [ ] **Step 4: Verify**

Run the app. Trigger a toast (e.g., copy to clipboard) — VoiceOver should announce the toast message. Right-click a file — context menu items should announce as "menu item". Navigate to a code block — copy button should announce "Copy code, button".

- [ ] **Step 5: Commit**

```bash
git add electron/src/renderer/components/ToastNotification.tsx electron/src/renderer/components/FileContextMenu.tsx electron/src/renderer/components/MarkdownView.tsx
git commit -m "a11y: add roles to toasts, context menu, and code block copy button"
```

---

### Task 8: Focus indicators (global.css)

**Files:**
- Modify: `electron/src/renderer/styles/global.css`

- [ ] **Step 1: Remove outline:none from command palette input**

In `global.css`, find the `.command-palette-input` rule (around line 593). Remove the `outline: none;` line.

- [ ] **Step 2: Add focus-visible styles**

Add to `global.css`:

```css
/* Accessibility: Focus indicators */
button:focus-visible,
a:focus-visible,
input:focus-visible,
select:focus-visible,
[role="option"]:focus-visible,
[role="menuitem"]:focus-visible,
[role="radio"]:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

/* Dark mode: add subtle glow for visibility against dark backgrounds */
[data-theme-appearance="dark"] button:focus-visible,
[data-theme-appearance="dark"] a:focus-visible,
[data-theme-appearance="dark"] input:focus-visible,
[data-theme-appearance="dark"] select:focus-visible,
[data-theme-appearance="dark"] [role="option"]:focus-visible,
[data-theme-appearance="dark"] [role="menuitem"]:focus-visible,
[data-theme-appearance="dark"] [role="radio"]:focus-visible {
  box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.1);
}

/* Suppress focus ring on mouse click */
button:focus:not(:focus-visible),
a:focus:not(:focus-visible),
input:focus:not(:focus-visible) {
  outline: none;
}

/* Skip link focus is handled by .skip-link:focus */
.skip-link:focus-visible {
  outline: none;
}
```

Note: Check what attribute the theme provider sets on `<html>` for dark mode (e.g., `data-theme-appearance`, `data-theme`, or a class). Adjust the dark mode selector accordingly.

- [ ] **Step 3: Verify**

Run the app. Tab through all interactive elements — each should show a visible focus ring in the accent color. Click buttons with the mouse — no focus ring should appear. Verify in both light and dark modes.

- [ ] **Step 4: Commit**

```bash
git add electron/src/renderer/styles/global.css
git commit -m "a11y: add focus-visible indicators, remove outline:none from command palette"
```

---

### Task 9: Toolbar roving tabindex

**Files:**
- Modify: `electron/src/renderer/components/Toolbar.tsx`

- [ ] **Step 1: Add roving tabindex logic**

In `Toolbar.tsx`:

1. Add a ref to track the currently focused button index:
```tsx
const [rovingIndex, setRovingIndex] = useState(0);
const toolbarRef = useRef<HTMLDivElement>(null);
```

2. Add a `data-toolbar-btn` attribute to each top-level toolbar button (not dropdown menu items inside menus). Then query by that attribute:
```tsx
const getToolbarButtons = useCallback((): HTMLButtonElement[] => {
  if (!toolbarRef.current) return [];
  return Array.from(
    toolbarRef.current.querySelectorAll<HTMLButtonElement>('[data-toolbar-btn]')
  );
}, []);
```

3. Add a `onKeyDown` handler on the toolbar root:
```tsx
const handleToolbarKeyDown = useCallback((e: React.KeyboardEvent) => {
  const buttons = getToolbarButtons();
  if (buttons.length === 0) return;

  if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
    e.preventDefault();
    const direction = e.key === 'ArrowRight' ? 1 : -1;
    const next = (rovingIndex + direction + buttons.length) % buttons.length;
    setRovingIndex(next);
    buttons[next]?.focus();
  }
}, [rovingIndex, getToolbarButtons]);
```

4. Set `tabIndex` on toolbar buttons: the button at `rovingIndex` gets `tabIndex={0}`, all others get `tabIndex={-1}`. Apply this by adding a `useEffect` that updates tabindex on the DOM elements whenever `rovingIndex` or the button list changes.

5. Add `ref={toolbarRef}` and `onKeyDown={handleToolbarKeyDown}` to the toolbar root div.

- [ ] **Step 2: Verify**

Run the app. Tab to the toolbar — only one button receives focus. Press ArrowRight/ArrowLeft — focus moves between toolbar buttons. Press Tab — focus leaves the toolbar entirely and moves to the sidebar or content.

- [ ] **Step 3: Commit**

```bash
git add electron/src/renderer/components/Toolbar.tsx
git commit -m "a11y: add roving tabindex to toolbar for keyboard navigation"
```

---

### Task 9b: Dropdown menu keyboard navigation

**Files:**
- Modify: `electron/src/renderer/components/Toolbar.tsx`

- [ ] **Step 1: Add arrow key navigation to font dropdown and overflow menu**

In `Toolbar.tsx`, add keyboard handling for the font dropdown and overflow menu. When a dropdown is open, arrow keys should navigate between `role="menuitem"` buttons:

1. Add a shared handler for dropdown keyboard navigation:
```tsx
const handleMenuKeyDown = useCallback((e: React.KeyboardEvent, closeMenu: () => void) => {
  const menu = e.currentTarget;
  const items = Array.from(menu.querySelectorAll<HTMLElement>('[role="menuitem"]'));
  const currentIndex = items.indexOf(document.activeElement as HTMLElement);

  if (e.key === 'ArrowDown') {
    e.preventDefault();
    const next = (currentIndex + 1) % items.length;
    items[next]?.focus();
  } else if (e.key === 'ArrowUp') {
    e.preventDefault();
    const prev = (currentIndex - 1 + items.length) % items.length;
    items[prev]?.focus();
  } else if (e.key === 'Escape') {
    e.preventDefault();
    closeMenu();
  }
}, []);
```

2. Add `onKeyDown={(e) => handleMenuKeyDown(e, () => setFontMenuOpen(false))}` to the font dropdown container.

3. Add `onKeyDown={(e) => handleMenuKeyDown(e, () => setOverflowOpen(false))}` to the overflow menu container.

4. When a dropdown opens, focus the first menu item. Add a `useEffect` for each:
```tsx
useEffect(() => {
  if (fontMenuOpen) {
    const firstItem = fontMenuRef.current?.querySelector<HTMLElement>('[role="menuitem"]');
    firstItem?.focus();
  }
}, [fontMenuOpen]);
```
Same pattern for overflow menu.

- [ ] **Step 2: Verify**

Run the app. Click the font button — dropdown opens and first item is focused. ArrowDown/ArrowUp cycles through items. Enter selects. Escape closes and returns focus to the trigger button.

- [ ] **Step 3: Commit**

```bash
git add electron/src/renderer/components/Toolbar.tsx
git commit -m "a11y: add arrow key navigation to toolbar dropdown menus"
```

---

### Task 10: Sidebar keyboard navigation

**Files:**
- Modify: `electron/src/renderer/components/DirectoryBrowser.tsx`

- [ ] **Step 1: Add arrow key navigation to sidebar**

In `DirectoryBrowser.tsx`:

1. Add a `onKeyDown` handler on the `<ul className="sidebar-tree" role="tree">`:

```tsx
const handleTreeKeyDown = useCallback((e: React.KeyboardEvent) => {
  const tree = e.currentTarget;
  const items = Array.from(tree.querySelectorAll<HTMLElement>('button.tree-item, button.tree-folder'));
  const currentIndex = items.indexOf(document.activeElement as HTMLElement);
  const currentButton = items[currentIndex];

  if (e.key === 'ArrowDown') {
    e.preventDefault();
    const next = Math.min(currentIndex + 1, items.length - 1);
    items[next]?.focus();
  } else if (e.key === 'ArrowUp') {
    e.preventDefault();
    const prev = Math.max(currentIndex - 1, 0);
    items[prev]?.focus();
  } else if (e.key === 'ArrowRight') {
    // Expand folder if collapsed
    if (currentButton?.classList.contains('tree-folder')) {
      const li = currentButton.closest('li');
      if (li?.getAttribute('aria-expanded') === 'false') {
        e.preventDefault();
        currentButton.click(); // triggers expand
      }
    }
  } else if (e.key === 'ArrowLeft') {
    // Collapse folder if expanded
    if (currentButton?.classList.contains('tree-folder')) {
      const li = currentButton.closest('li');
      if (li?.getAttribute('aria-expanded') === 'true') {
        e.preventDefault();
        currentButton.click(); // triggers collapse
      }
    }
  }
}, []);
```

2. Add `onKeyDown={handleTreeKeyDown}` to the `<ul>` element.

- [ ] **Step 2: Verify**

Run the app with a folder open. Tab to the sidebar. Use ArrowUp/ArrowDown to navigate between files and folders. ArrowRight expands a collapsed folder, ArrowLeft collapses an expanded folder. Press Enter to open a file. Press Tab to leave the sidebar.

- [ ] **Step 3: Commit**

```bash
git add electron/src/renderer/components/DirectoryBrowser.tsx
git commit -m "a11y: add arrow key navigation to sidebar file tree"
```

---

### Task 11: useFocusTrap hook

**Files:**
- Create: `electron/src/renderer/hooks/useFocusTrap.ts`

- [ ] **Step 1: Create the hook**

Create `electron/src/renderer/hooks/useFocusTrap.ts`:

```tsx
import { useEffect, useRef } from 'react';

const FOCUSABLE_SELECTOR = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';

export function useFocusTrap(containerRef: React.RefObject<HTMLElement | null>, active: boolean) {
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (!active) return;

    // Capture the element that had focus before the trap activated
    previousFocusRef.current = document.activeElement as HTMLElement;

    const container = containerRef.current;
    if (!container) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return;

      const focusable = Array.from(
        container.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR)
      ).filter((el) => !el.hasAttribute('disabled') && el.offsetParent !== null);

      if (focusable.length === 0) {
        e.preventDefault();
        return;
      }

      const first = focusable[0];
      const last = focusable[focusable.length - 1];

      if (e.shiftKey) {
        if (document.activeElement === first) {
          e.preventDefault();
          last.focus();
        }
      } else {
        if (document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    };

    container.addEventListener('keydown', handleKeyDown);

    return () => {
      container.removeEventListener('keydown', handleKeyDown);
      // Restore focus to the element that was focused before
      previousFocusRef.current?.focus();
    };
  }, [active, containerRef]);
}
```

- [ ] **Step 2: Verify the hook compiles**

Run: `cd electron && npx tsc --noEmit --skipLibCheck`

Expected: no errors related to `useFocusTrap.ts`

- [ ] **Step 3: Commit**

```bash
git add electron/src/renderer/hooks/useFocusTrap.ts
git commit -m "a11y: create useFocusTrap hook for modal focus management"
```

---

### Task 12: Apply focus trapping to modals

**Files:**
- Modify: `electron/src/renderer/components/CommandPalette.tsx`
- Modify: `electron/src/renderer/components/SettingsModal.tsx`
- Modify: `electron/src/renderer/components/FileContextMenu.tsx`

- [ ] **Step 1: Add focus trap to CommandPalette**

In `CommandPalette.tsx`:

1. Import: `import { useFocusTrap } from '../hooks/useFocusTrap';`
2. Add a ref for the modal container:
```tsx
const modalRef = useRef<HTMLDivElement>(null);
```
3. Call the hook:
```tsx
useFocusTrap(modalRef, visible);
```
4. Add `ref={modalRef}` to the `<div className="command-palette">` element.

- [ ] **Step 2: Add focus trap to SettingsModal**

In `SettingsModal.tsx`:

1. Import `useRef` and `useEffect` from React and `useFocusTrap` from the hook.
2. Add a ref and call the hook:
```tsx
const modalRef = useRef<HTMLDivElement>(null);
useFocusTrap(modalRef, visible);
```
3. Add `ref={modalRef}` to the `<div className="settings-modal">` element.
4. Add initial focus on open — focus the first focusable element when the modal becomes visible:
```tsx
useEffect(() => {
  if (visible && modalRef.current) {
    const firstFocusable = modalRef.current.querySelector<HTMLElement>('button, [href], input');
    firstFocusable?.focus();
  }
}, [visible]);
```

- [ ] **Step 3: Add focus trap to FileContextMenu**

In `FileContextMenu.tsx`:

1. Import `useFocusTrap` from the hook.
2. Call the hook using the existing `ref`:
```tsx
useFocusTrap(ref, true);  // Always active when mounted
```
3. Add initial focus: in a `useEffect`, focus the first menu item on mount:
```tsx
useEffect(() => {
  const firstItem = ref.current?.querySelector<HTMLElement>('button');
  firstItem?.focus();
}, []);
```

- [ ] **Step 4: Verify**

Run the app.

1. Open command palette (Cmd+F) — Tab should cycle within the palette only, not reach the toolbar or sidebar. Press Escape — focus returns to the element that was focused before.
2. Open settings — same focus trap behavior. Escape returns focus.
3. Right-click a file — context menu traps focus, first item is focused. Escape returns focus.

- [ ] **Step 5: Commit**

```bash
git add electron/src/renderer/components/CommandPalette.tsx electron/src/renderer/components/SettingsModal.tsx electron/src/renderer/components/FileContextMenu.tsx
git commit -m "a11y: apply focus trapping to CommandPalette, SettingsModal, FileContextMenu"
```

---

### Task 13: AnnounceProvider and useAnnounce hook

**Files:**
- Create: `electron/src/renderer/hooks/useAnnounce.tsx`
- Modify: `electron/src/renderer/App.tsx`

- [ ] **Step 1: Create AnnounceProvider and useAnnounce**

Create `electron/src/renderer/hooks/useAnnounce.tsx`:

```tsx
import React, { createContext, useContext, useRef, useCallback } from 'react';

interface AnnounceContextValue {
  announce: (message: string) => void;
  announceAssertive: (message: string) => void;
}

const AnnounceContext = createContext<AnnounceContextValue>({
  announce: () => {},
  announceAssertive: () => {},
});

export function useAnnounce() {
  return useContext(AnnounceContext);
}

const srOnlyStyle: React.CSSProperties = {
  position: 'absolute',
  width: '1px',
  height: '1px',
  padding: 0,
  margin: '-1px',
  overflow: 'hidden',
  clip: 'rect(0, 0, 0, 0)',
  whiteSpace: 'nowrap',
  border: 0,
};

export function AnnounceProvider({ children }: { children: React.ReactNode }) {
  const politeRef = useRef<HTMLDivElement>(null);
  const assertiveRef = useRef<HTMLDivElement>(null);

  const setMessage = useCallback((ref: React.RefObject<HTMLDivElement | null>, message: string) => {
    if (!ref.current) return;
    // Clear then set to ensure repeated identical messages trigger announcement
    ref.current.textContent = '';
    requestAnimationFrame(() => {
      if (ref.current) ref.current.textContent = message;
    });
  }, []);

  const announce = useCallback((message: string) => {
    setMessage(politeRef, message);
  }, [setMessage]);

  const announceAssertive = useCallback((message: string) => {
    setMessage(assertiveRef, message);
  }, [setMessage]);

  return (
    <AnnounceContext.Provider value={{ announce, announceAssertive }}>
      {children}
      <div ref={politeRef} aria-live="polite" aria-atomic="true" style={srOnlyStyle} />
      <div ref={assertiveRef} aria-live="assertive" aria-atomic="true" style={srOnlyStyle} />
    </AnnounceContext.Provider>
  );
}
```

- [ ] **Step 2: Wrap App with AnnounceProvider**

In `App.tsx`:

1. Import: `import { AnnounceProvider } from './hooks/useAnnounce';`
2. Wrap the entire return JSX in `<AnnounceProvider>`:

```tsx
return (
  <AnnounceProvider>
    <div className="app">
      ...
    </div>
  </AnnounceProvider>
);
```

- [ ] **Step 3: Verify the hook compiles**

Run: `cd electron && npx tsc --noEmit --skipLibCheck`

Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add electron/src/renderer/hooks/useAnnounce.tsx electron/src/renderer/App.tsx
git commit -m "a11y: create AnnounceProvider and useAnnounce hook for live regions"
```

---

### Task 14: Wire up App-level announcements

**Files:**
- Modify: `electron/src/renderer/App.tsx`

- [ ] **Step 1: Add announce hook and zoom announcements**

In `App.tsx`:

1. Import `useAnnounce`:
```tsx
import { useAnnounce } from './hooks/useAnnounce';
```

2. Inside the `App` component (after `useDisplaySettings`), call:
```tsx
const { announce, announceAssertive } = useAnnounce();
```

3. Announce zoom changes — add a `useEffect` watching `display.zoom`:
```tsx
const prevZoomRef = useRef(display.zoom);
useEffect(() => {
  if (prevZoomRef.current !== display.zoom) {
    announce(`Zoom ${Math.round(display.zoom * 100)}%`);
    prevZoomRef.current = display.zoom;
  }
}, [display.zoom, announce]);
```

- [ ] **Step 2: Add file open and error announcements**

Still in `App.tsx`:

1. Announce file opens — add a `useEffect` watching `filePath`:
```tsx
const prevFileRef = useRef(filePath);
useEffect(() => {
  if (filePath && prevFileRef.current !== filePath) {
    announce(`Opened ${filePath.split('/').pop()}`);
  }
  prevFileRef.current = filePath;
}, [filePath, announce]);
```

2. Announce file errors assertively — in `handleFileSelect` catch block (around line 93), add after `addToast`:
```tsx
announceAssertive('Error: could not read file');
```

3. Announce file deletion — in the `useFileWatcher` `onDeleted` callback (around line 144), add after `addToast`:
```tsx
announceAssertive('File was deleted');
```

Note: `handleFileSelect` and the `useFileWatcher` callbacks need `announceAssertive` in their dependency arrays. Since these are memoized with `useCallback`, add `announceAssertive` to the deps.

- [ ] **Step 3: Verify**

Run the app with VoiceOver on. Open a file — hear "Opened filename.md". Press Cmd+/- — hear "Zoom 110%". Delete a file externally — hear "File was deleted".

- [ ] **Step 4: Commit**

```bash
git add electron/src/renderer/App.tsx
git commit -m "a11y: add live region announcements for zoom, file open, errors"
```

---

### Task 14b: Wire up CommandPalette result count announcement

**Files:**
- Modify: `electron/src/renderer/components/CommandPalette.tsx`

- [ ] **Step 1: Add result count announcement**

In `CommandPalette.tsx`:

1. Import: `import { useAnnounce } from '../hooks/useAnnounce';`
2. Call: `const { announce } = useAnnounce();`
3. Add a `useEffect` that announces result count when results change:
```tsx
useEffect(() => {
  if (!visible) return;
  if (query.length === 0) return;
  const count = results.length;
  if (count > 0) {
    announce(`${count} result${count === 1 ? '' : 's'}`);
  } else if (!searching) {
    announce('No results');
  }
}, [results, searching, visible, query, announce]);
```

- [ ] **Step 2: Verify**

Run the app with VoiceOver on. Open command palette (Cmd+F) and type a query — hear the result count announced. Clear and retype — hear the updated count.

- [ ] **Step 3: Commit**

```bash
git add electron/src/renderer/components/CommandPalette.tsx
git commit -m "a11y: announce command palette result count to screen readers"
```

---

### Task 15: Reduced motion support

**Files:**
- Modify: `electron/src/renderer/styles/global.css`

- [ ] **Step 1: Add prefers-reduced-motion media query**

Add to the end of `global.css`:

```css
/* Accessibility: Reduced motion */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

- [ ] **Step 2: Verify**

On macOS: System Settings → Accessibility → Display → Reduce motion (enable). Run the app. Confirm: sidebar open/close is instant, command palette backdrop appears instantly, toast notifications appear/disappear without fade, toolbar button hover transitions are instant.

- [ ] **Step 3: Commit**

```bash
git add electron/src/renderer/styles/global.css
git commit -m "a11y: add prefers-reduced-motion support"
```

---

### Task 16: Color contrast audit and fixes

**Files:**
- Modify: `electron/src/renderer/lib/color-themes.ts`

- [ ] **Step 1: Audit all 8 theme combinations**

For each theme (Warm, Cool, Fresh, Neon) in each appearance (light, dark), calculate contrast ratios programmatically. Read the hex values from `color-themes.ts`, convert to relative luminance using the WCAG formula (`L = 0.2126*R + 0.7152*G + 0.0722*B` where R/G/B are linearized), then compute `(L1 + 0.05) / (L2 + 0.05)`. Check these token pairings:

| Token pair | Minimum ratio | WCAG criterion |
|-----------|---------------|----------------|
| `textPrimary` on `bgPrimary` | 4.5:1 | 1.4.3 |
| `textSecondary` on `bgPrimary` | 4.5:1 | 1.4.3 |
| `textMuted` on `bgPrimary` | 4.5:1 | 1.4.3 |
| `accent` on `bgPrimary` | 3:1 | 1.4.11 (UI components) |
| `textPrimary` on `bgSecondary` | 4.5:1 | 1.4.3 |
| `border` on `bgPrimary` | 3:1 | 1.4.11 |

Document results. For any failures, adjust the token value to meet the minimum.

- [ ] **Step 2: Fix any failing contrast ratios**

Adjust token values in `color-themes.ts` to meet AA. Prefer darkening light-mode muted text or lightening dark-mode muted text — smallest change that reaches the threshold.

- [ ] **Step 3: Add verification comment**

Add a comment block at the top of the `color-themes.ts` file:

```typescript
// Color contrast: All token pairings verified against WCAG 2.1 AA
// (4.5:1 for normal text, 3:1 for large text and UI components)
// Last verified: 2026-03-22
```

- [ ] **Step 4: Verify visually**

Run the app in all 8 theme combinations. Confirm text is readable, nothing looks washed out, and the visual design is preserved.

- [ ] **Step 5: Commit**

```bash
git add electron/src/renderer/lib/color-themes.ts
git commit -m "a11y: verify and fix color contrast ratios for WCAG AA"
```

---

### Task 17: Final integration verification

**Files:** None (verification only)

- [ ] **Step 1: Full keyboard walkthrough**

Tab through the entire app from top to bottom. Verify:
- Skip link appears and works
- Toolbar uses roving tabindex (arrow keys between buttons, Tab exits)
- Sidebar uses arrow keys between files, Enter opens
- Content area is reachable
- All buttons show focus ring
- Modals trap focus, Escape restores focus

- [ ] **Step 2: Full VoiceOver walkthrough**

Enable VoiceOver (Cmd+F5). Navigate the entire app:
- Landmarks are announced (navigation, toolbar, main)
- All buttons have labels
- Modals announce their role
- Settings radiogroups work
- Command palette combobox announces results
- Toasts are announced
- Zoom changes are announced

- [ ] **Step 3: Reduced motion check**

Enable "Reduce motion" in System Settings. Verify all animations and transitions are disabled.

- [ ] **Step 4: Type check**

Run: `cd electron && npx tsc --noEmit --skipLibCheck`

Expected: no errors

- [ ] **Step 5: Commit (if any fixes needed)**

If any issues were found and fixed during verification, commit them:

Stage only the specific files that were fixed, then commit:

```bash
git add <fixed-files>
git commit -m "a11y: fix integration issues found during final verification"
```
