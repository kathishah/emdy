# Performance Report

## Test Environment
- Machine: macOS (Apple Silicon)
- Mode: Dev (npm start, Vite HMR, unminified React)
- Date: 2026-03-22

## Fixture Sizes
| File | Lines | Words | Size |
|------|-------|-------|------|
| perf-small.md | 525 | ~4K | 46 KB |
| perf-medium.md | 3,134 | 17,474 | 123 KB |
| perf-large.md | 11,137 | 62,133 | 322 KB |

## Baseline Measurements (before fixes)

| Operation | Small | Medium | Large | Target |
|-----------|-------|--------|-------|--------|
| File load (IPC) | ~1ms | ~2ms | 3.5ms | < 500ms |
| Render | fast | not measured | 2,786ms | < 500ms |
| Minimap sync (first) | 4ms | ~150ms | 348ms | < 200ms |
| Minimap clones during render | 2 | ~8 | 16 | 1 |
| Scroll FPS | 60 | 60 | 60 | 60fps |

## Fixes Applied

1. **React.memo on MarkdownView** — prevents re-renders on unrelated state changes (toast, sidebar toggle). Stabilized `style` prop with `useMemo`.

2. **Prism highlighting capped at 200 lines** — code blocks over 200 lines show truncated with a "Show all" button. Copy still captures full code.

3. **Minimap initial sync deferred** — uses `requestIdleCallback` so DOM cloning doesn't block the initial React render.

4. **Minimap MutationObserver delayed 3s** — prevents repeated cloning during React's incremental render. Throttled to max once per 500ms when active.

5. **Minimap auto-scroll suppressed during drag** — prevents feedback loop where drag → scroll → auto-scroll → amplified drag.

## After-Fix Measurements

| Operation | Small | Medium | Large | Target | Status |
|-----------|-------|--------|-------|--------|--------|
| File load (IPC) | ~1ms | 2.4ms | 3.1ms | < 500ms | Pass |
| Render | fast | 1,424ms | 1,659ms | < 500ms | **FAIL** |
| Minimap sync (first) | 2ms | ~110ms | 144ms | < 200ms | Pass |
| Minimap clones during render | 2 | ~3 | 5 | — | Improved |
| Scroll FPS | 60 | 60 | 60 | 60fps | Pass |

## Remaining Bottleneck

The render time for medium (1.4s) and large (1.7s) files exceeds the 500ms target. The bottleneck is `react-markdown` itself — parsing and rendering thousands of lines into React elements. Prism highlighting is a secondary cost.

### Recommended next step

**Virtualized rendering** — only render Markdown content visible in the viewport plus a buffer zone above/below. This is a significant architectural change that would require:

- Splitting the Markdown content into sections (by heading or by line count)
- Only rendering visible sections
- Measuring section heights for accurate scroll position
- Maintaining scroll position as sections mount/unmount

This is a separate project that should go through its own design/plan cycle.

### Context: dev mode vs. production

All measurements were taken in dev mode. React's development build adds significant overhead (strict mode double-rendering, prop validation, dev warnings). Production builds would be faster, but the `npm run package` build is currently broken (chokidar bundling issue — separate fix needed).
