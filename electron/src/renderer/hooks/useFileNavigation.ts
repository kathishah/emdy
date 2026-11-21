import { useCallback, useLayoutEffect, useRef, useState, type RefObject } from 'react';
import {
  back,
  canGoBack,
  canGoForward,
  createHistory,
  current,
  forward,
  push,
  removeEntry,
  saveScroll,
  type NavHistory,
} from '../lib/nav-history';

const ANCHOR_RETRY_FRAMES = 10;

export interface UseFileNavigationArgs {
  /** The content scroller; only `scrollTop` is used. */
  scrollRef: RefObject<{ scrollTop: number } | null>;
  readFile: (path: string) => Promise<string>;
  /** Display a document: set content and path, clear error/deleted state. */
  show: (path: string, content: string) => void;
  onReadError: () => void;
  /** Called after every successful navigation (e.g. to close the find bar). */
  onNavigate: () => void;
  announce: (message: string) => void;
}

export interface FileNavigation {
  canGoBack: boolean;
  canGoForward: boolean;
  /**
   * Load a file (adds a history entry), optionally scrolling to a heading.
   * Resolves true when `path` is now showing, false if the read failed or a
   * newer navigation superseded this one.
   */
  navigateTo: (path: string, anchor?: string | null) => Promise<boolean>;
  /** Scroll to a heading in the current file (adds a history entry). */
  navigateAnchor: (id: string) => void;
  goBack: () => Promise<void>;
  goForward: () => Promise<void>;
  /** Start a fresh single-entry history for a newly opened document. */
  reset: (path: string) => void;
}

type PendingScroll = { top: number } | { anchor: string } | null;

function baseName(path: string): string {
  return path.slice(path.lastIndexOf('/') + 1) || path;
}

function findHeading(id: string): HTMLElement | null {
  return document.getElementById(id) ?? document.getElementById(id.toLowerCase());
}

function scrollHeadingIntoView(el: HTMLElement) {
  const reduced = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  el.scrollIntoView({ block: 'start', behavior: reduced ? 'auto' : 'smooth' });
}

/**
 * Per-window back/forward history across markdown files and in-page anchors.
 * See journal/2026-11-20-file-navigation-specs.md.
 */
export function useFileNavigation(args: UseFileNavigationArgs): FileNavigation {
  const argsRef = useRef(args);
  argsRef.current = args;

  const historyRef = useRef<NavHistory | null>(null);
  // Bumped by every navigation; a load that is no longer the latest is dropped.
  const tokenRef = useRef(0);
  const pendingRef = useRef<PendingScroll>(null);
  const [flags, setFlags] = useState({ back: false, forward: false });
  const [tick, setTick] = useState(0);

  const commit = useCallback((next: NavHistory, pending: PendingScroll) => {
    historyRef.current = next;
    pendingRef.current = pending;
    setFlags({ back: canGoBack(next), forward: canGoForward(next) });
    setTick((t) => t + 1);
  }, []);

  // Apply the scroll once React has committed the new document, so a restored
  // position is not clamped to the previous document's height.
  useLayoutEffect(() => {
    const pending = pendingRef.current;
    if (!pending) return;
    pendingRef.current = null;
    if ('top' in pending) {
      const scroller = argsRef.current.scrollRef.current;
      if (scroller) scroller.scrollTop = pending.top;
      return;
    }
    let frames = 0;
    let raf = 0;
    const attempt = () => {
      const el = findHeading(pending.anchor);
      if (el) {
        scrollHeadingIntoView(el);
        return;
      }
      frames += 1;
      if (frames < ANCHOR_RETRY_FRAMES) raf = requestAnimationFrame(attempt);
    };
    attempt();
    return () => cancelAnimationFrame(raf);
  }, [tick]);

  const reset = useCallback((path: string) => {
    tokenRef.current += 1;
    commit(createHistory(path), null);
  }, [commit]);

  const navigateAnchor = useCallback((id: string) => {
    const h = historyRef.current;
    if (!h) return;
    const el = findHeading(id);
    if (!el) return;
    tokenRef.current += 1;
    const top = argsRef.current.scrollRef.current?.scrollTop ?? 0;
    commit(push(saveScroll(h, top), current(h).path), null);
    scrollHeadingIntoView(el);
    argsRef.current.onNavigate();
  }, [commit]);

  const navigateTo = useCallback(async (path: string, anchor?: string | null): Promise<boolean> => {
    const h = historyRef.current;
    if (h && current(h).path === path) {
      if (anchor) navigateAnchor(anchor);
      return true;
    }
    const token = ++tokenRef.current;
    let content: string;
    try {
      content = await argsRef.current.readFile(path);
    } catch {
      if (token === tokenRef.current) argsRef.current.onReadError();
      return false;
    }
    if (token !== tokenRef.current) return false;

    // Read the scroll position before the new document replaces the old one.
    const top = argsRef.current.scrollRef.current?.scrollTop ?? 0;
    const latest = historyRef.current;
    const next = latest ? push(saveScroll(latest, top), path) : createHistory(path);
    argsRef.current.show(path, content);
    commit(next, anchor ? { anchor } : { top: 0 });
    argsRef.current.onNavigate();
    argsRef.current.announce(`Opened ${baseName(path)}`);
    return true;
  }, [commit, navigateAnchor]);

  const moveTo = useCallback(async (direction: 'back' | 'forward') => {
    const h = historyRef.current;
    if (!h) return;
    if (direction === 'back' ? !canGoBack(h) : !canGoForward(h)) return;
    const token = ++tokenRef.current;
    const targetIndex = (direction === 'back' ? back(h) : forward(h)).index;
    const saved = saveScroll(h, argsRef.current.scrollRef.current?.scrollTop ?? 0);
    const target = saved.entries[targetIndex];
    const verb = direction === 'back' ? 'Went back to' : 'Went forward to';

    if (target.path === current(saved).path) {
      commit({ entries: saved.entries, index: targetIndex }, { top: target.scrollTop });
      argsRef.current.onNavigate();
      argsRef.current.announce(`${verb} ${baseName(target.path)}`);
      return;
    }

    let content: string;
    try {
      content = await argsRef.current.readFile(target.path);
    } catch {
      if (token !== tokenRef.current) return;
      // Stay where we are and drop the entry so the next Back/Forward skips it.
      commit(removeEntry(saved, targetIndex), null);
      argsRef.current.onReadError();
      return;
    }
    if (token !== tokenRef.current) return;

    argsRef.current.show(target.path, content);
    commit({ entries: saved.entries, index: targetIndex }, { top: target.scrollTop });
    argsRef.current.onNavigate();
    argsRef.current.announce(`${verb} ${baseName(target.path)}`);
  }, [commit]);

  const goBack = useCallback(() => moveTo('back'), [moveTo]);
  const goForward = useCallback(() => moveTo('forward'), [moveTo]);

  return {
    canGoBack: flags.back,
    canGoForward: flags.forward,
    navigateTo,
    navigateAnchor,
    goBack,
    goForward,
    reset,
  };
}
