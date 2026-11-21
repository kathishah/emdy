# Fork Notes

This fork tracks upstream at `ghaida/emdy` and carries a small set of intentional
local differences. Use this file as the running checklist during future upstream
integrations.

## Intentional fork differences

### Fluid wide reading width

- The app defaults to `contentWidth: 'wide'`.
- Legacy saved values from earlier fork builds (`narrow` and `medium`) are
  migrated to `wide`.
- `default` remains a fixed reading column.
- `wide` uses the available content area instead of an upstream fixed width.
- The minimap measures the rendered document width in `wide` mode so it stays
  scaled correctly as the window changes.

Key files:

- `electron/src/main/settings-store.ts`
- `electron/src/renderer/hooks/useDisplaySettings.ts`
- `electron/src/renderer/App.tsx`
- `electron/src/renderer/components/Minimap.tsx`
- `electron/src/renderer/lib/types.ts`

### Document outline sidebar

- Markdown headings receive stable outline IDs during rendering.
- A left-side outline panel lists headings, tracks the active heading while
  scrolling, and scrolls to a heading when selected.
- The toolbar includes an outline toggle when headings are present.

Key files:

- `electron/src/renderer/components/OutlinePanel.tsx`
- `electron/src/renderer/components/MarkdownView.tsx`
- `electron/src/renderer/App.tsx`
- `electron/src/renderer/components/Toolbar.tsx`
- `electron/src/renderer/styles/global.css`

### File-opening behavior

- Renderer readiness is signaled through `renderer:ready`.
- Startup, Finder, and CLI file opens are queued until the renderer is ready.
- After a file or folder is already open, additional OS/CLI opens are routed to
  new windows.
- New windows show a short pending/loading state while their initial path is
  delivered.

Key files:

- `electron/src/main/index.ts`
- `electron/src/main/ipc-handlers.ts`
- `electron/src/preload/preload.ts`
- `electron/src/renderer/App.tsx`
- `electron/src/renderer/lib/types.ts`

### Link navigation and history

- A plain click on a link to another markdown file loads it in the same window;
  Cmd/Ctrl+click or middle-click opens it in a new window. `#heading` links
  scroll in place.
- Each window keeps its own back/forward history (files, sidebar picks,
  command-palette picks and `#anchor` jumps), with scroll position restored.
  History is in memory only and capped at 100 entries.
- Back/forward: toolbar chevrons, View menu (`Cmd+[` / `Cmd+]`) and the mouse
  back/forward buttons.
- File access is unchanged: loading still goes through `file:read` and
  `isPathAllowed`, so links outside the opened folders do nothing but toast.
- Spec and plan: `journal/2026-11-20-file-navigation-specs.md`.

Key files:

- `electron/src/renderer/lib/nav-history.ts`
- `electron/src/renderer/lib/link-target.ts`
- `electron/src/renderer/hooks/useFileNavigation.ts`
- `electron/src/renderer/components/MarkdownView.tsx`
- `electron/src/renderer/components/Toolbar.tsx`
- `electron/src/renderer/App.tsx`
- `electron/src/main/menu.ts`

### Contributor dependency setup

- The fork carries dependency/version and override changes for local contributor
  setup. Re-check these during upstream integrations before accepting upstream
  package metadata wholesale.

Key files:

- `electron/package.json`
- `electron/package-lock.json`
- `electron/forge.config.ts`

## Integration checklist

- Fetch upstream first: `git fetch --all --prune`.
- Compare fork delta: `git log --oneline --left-right --cherry-pick origin/main...upstream/main`.
- Prefer an integration branch, then rebase or merge deliberately.
- Preserve the intentional differences above unless the fork owner decides to
  drop them.
- Run from `electron/`:
  - `npm run lint`
  - `npm test`
  - `npm run package`
- When validating width/minimap changes, test with an existing settings file
  from older fork builds because legacy `contentWidth` values can affect both
  layout and minimap scaling.
