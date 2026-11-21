import { describe, it, expect } from 'vitest';
import {
  MAX_ENTRIES,
  createHistory,
  saveScroll,
  push,
  back,
  forward,
  removeEntry,
  canGoBack,
  canGoForward,
  current,
  type NavHistory,
} from './nav-history';

function paths(h: NavHistory): string[] {
  return h.entries.map((e) => e.path);
}

function build(...pathList: string[]): NavHistory {
  let h = createHistory(pathList[0]);
  for (const p of pathList.slice(1)) h = push(h, p);
  return h;
}

describe('createHistory', () => {
  it('starts with one entry at scrollTop 0 with nowhere to go', () => {
    const h = createHistory('/a.md');
    expect(h.entries).toEqual([{ path: '/a.md', scrollTop: 0 }]);
    expect(h.index).toBe(0);
    expect(canGoBack(h)).toBe(false);
    expect(canGoForward(h)).toBe(false);
  });
});

describe('push', () => {
  it('adds an entry after the current one and moves to it', () => {
    const h = push(createHistory('/a.md'), '/b.md');
    expect(paths(h)).toEqual(['/a.md', '/b.md']);
    expect(h.index).toBe(1);
    expect(current(h)).toEqual({ path: '/b.md', scrollTop: 0 });
    expect(canGoBack(h)).toBe(true);
    expect(canGoForward(h)).toBe(false);
  });

  it('allows the same path again (used for #anchor entries)', () => {
    const h = push(createHistory('/a.md'), '/a.md');
    expect(paths(h)).toEqual(['/a.md', '/a.md']);
    expect(h.index).toBe(1);
  });

  it('drops forward entries when pushing after going back', () => {
    let h = build('/a.md', '/b.md', '/c.md');
    h = back(h);
    h = push(h, '/d.md');
    expect(paths(h)).toEqual(['/a.md', '/b.md', '/d.md']);
    expect(h.index).toBe(2);
    expect(canGoForward(h)).toBe(false);
  });

  it('caps history at MAX_ENTRIES, dropping the oldest and keeping the index valid', () => {
    let h = createHistory('/0.md');
    for (let i = 1; i <= MAX_ENTRIES; i++) h = push(h, `/${i}.md`);
    expect(h.entries).toHaveLength(MAX_ENTRIES);
    expect(h.entries[0].path).toBe('/1.md');
    expect(current(h).path).toBe(`/${MAX_ENTRIES}.md`);
    expect(h.index).toBe(MAX_ENTRIES - 1);
  });

  it('does not mutate the previous history', () => {
    const h = createHistory('/a.md');
    push(h, '/b.md');
    expect(paths(h)).toEqual(['/a.md']);
    expect(h.index).toBe(0);
  });
});

describe('back and forward', () => {
  it('move the index one step', () => {
    let h = build('/a.md', '/b.md', '/c.md');
    h = back(h);
    expect(current(h).path).toBe('/b.md');
    expect(canGoBack(h)).toBe(true);
    expect(canGoForward(h)).toBe(true);
    h = back(h);
    expect(current(h).path).toBe('/a.md');
    expect(canGoBack(h)).toBe(false);
    h = forward(h);
    expect(current(h).path).toBe('/b.md');
  });

  it('return the same history at either end', () => {
    const start = createHistory('/a.md');
    expect(back(start)).toBe(start);
    const end = build('/a.md', '/b.md');
    expect(forward(end)).toBe(end);
  });
});

describe('saveScroll', () => {
  it('updates only the current entry', () => {
    let h = build('/a.md', '/b.md', '/c.md');
    h = back(h);
    h = saveScroll(h, 240);
    expect(h.entries.map((e) => e.scrollTop)).toEqual([0, 240, 0]);
  });

  it('does not mutate the previous history', () => {
    const h = createHistory('/a.md');
    saveScroll(h, 99);
    expect(h.entries[0].scrollTop).toBe(0);
  });
});

describe('removeEntry', () => {
  it('removing an earlier entry keeps the current entry current', () => {
    const h = removeEntry(build('/a.md', '/b.md', '/c.md'), 0);
    expect(paths(h)).toEqual(['/b.md', '/c.md']);
    expect(current(h).path).toBe('/c.md');
  });

  it('removing a later entry keeps the current entry current', () => {
    let h = build('/a.md', '/b.md', '/c.md');
    h = back(h);
    h = removeEntry(h, 2);
    expect(paths(h)).toEqual(['/a.md', '/b.md']);
    expect(current(h).path).toBe('/b.md');
    expect(canGoForward(h)).toBe(false);
  });

  it('removing the current entry moves to the nearest valid one', () => {
    let h = build('/a.md', '/b.md', '/c.md');
    h = removeEntry(h, 2);
    expect(paths(h)).toEqual(['/a.md', '/b.md']);
    expect(current(h).path).toBe('/b.md');
    h = build('/a.md', '/b.md', '/c.md');
    h = back(back(h));
    h = removeEntry(h, 0);
    expect(paths(h)).toEqual(['/b.md', '/c.md']);
    expect(current(h).path).toBe('/b.md');
  });

  it('never removes the only entry', () => {
    const h = createHistory('/a.md');
    expect(removeEntry(h, 0)).toBe(h);
  });

  it('ignores an out-of-range index', () => {
    const h = build('/a.md', '/b.md');
    expect(removeEntry(h, 5)).toBe(h);
    expect(removeEntry(h, -1)).toBe(h);
  });
});
