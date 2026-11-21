/**
 * Per-window navigation history: an ordered list of visited documents and the
 * index of the one being shown. Pure and immutable; no React or Electron.
 */
export const MAX_ENTRIES = 100;

export interface NavEntry {
  path: string;
  /** Scroll position of the content scroller when the user left this entry. */
  scrollTop: number;
}

export interface NavHistory {
  entries: NavEntry[];
  index: number;
}

export function createHistory(path: string): NavHistory {
  return { entries: [{ path, scrollTop: 0 }], index: 0 };
}

export function current(h: NavHistory): NavEntry {
  return h.entries[h.index];
}

export function canGoBack(h: NavHistory): boolean {
  return h.index > 0;
}

export function canGoForward(h: NavHistory): boolean {
  return h.index < h.entries.length - 1;
}

/** Record the live scroll position on the current entry. */
export function saveScroll(h: NavHistory, scrollTop: number): NavHistory {
  const entries = h.entries.slice();
  entries[h.index] = { ...entries[h.index], scrollTop };
  return { entries, index: h.index };
}

/**
 * Add an entry after the current one and move to it. Forward entries are
 * dropped and the oldest entries are discarded past MAX_ENTRIES. The same path
 * as the current entry is allowed (an in-page #anchor creates its own entry).
 */
export function push(h: NavHistory, path: string): NavHistory {
  let entries = [...h.entries.slice(0, h.index + 1), { path, scrollTop: 0 }];
  if (entries.length > MAX_ENTRIES) {
    entries = entries.slice(entries.length - MAX_ENTRIES);
  }
  return { entries, index: entries.length - 1 };
}

export function back(h: NavHistory): NavHistory {
  return canGoBack(h) ? { entries: h.entries, index: h.index - 1 } : h;
}

export function forward(h: NavHistory): NavHistory {
  return canGoForward(h) ? { entries: h.entries, index: h.index + 1 } : h;
}

/**
 * Remove an entry (for example one whose file can no longer be read). The
 * current entry stays current unless it is the one removed, in which case the
 * nearest remaining entry takes over. The last remaining entry is never removed.
 */
export function removeEntry(h: NavHistory, index: number): NavHistory {
  if (h.entries.length <= 1 || index < 0 || index >= h.entries.length) return h;
  const entries = h.entries.filter((_, i) => i !== index);
  let next = h.index;
  if (index < h.index) next = h.index - 1;
  else if (index === h.index) next = Math.min(h.index, entries.length - 1);
  return { entries, index: next };
}
