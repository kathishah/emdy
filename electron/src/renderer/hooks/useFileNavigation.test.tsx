import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, renderHook } from '@testing-library/react';
import { useFileNavigation } from './useFileNavigation';

const FILES: Record<string, string> = {
  '/n/a.md': 'A',
  '/n/b.md': 'B',
  '/n/c.md': 'C',
};

function addHeading(id: string): HTMLElement {
  const el = document.createElement('h2');
  el.id = id;
  document.body.appendChild(el);
  return el;
}

function setup(files: Record<string, string> = { ...FILES }) {
  const scroller = { scrollTop: 0 };
  const scrollRef = { current: scroller };
  const readFile = vi.fn(async (path: string) => {
    if (!(path in files)) throw new Error(`ENOENT ${path}`);
    return files[path];
  });
  const show = vi.fn();
  const onReadError = vi.fn();
  const onNavigate = vi.fn();
  const announce = vi.fn();
  const hook = renderHook(() =>
    useFileNavigation({ scrollRef, readFile, show, onReadError, onNavigate, announce })
  );
  return { hook, scroller, files, readFile, show, onReadError, onNavigate, announce };
}

let scrollSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  scrollSpy = vi.spyOn(Element.prototype, 'scrollIntoView');
});

afterEach(() => {
  scrollSpy.mockRestore();
  document.body.innerHTML = '';
});

describe('useFileNavigation', () => {
  it('starts with back and forward disabled and reset() keeps it that way', () => {
    const { hook } = setup();
    expect(hook.result.current.canGoBack).toBe(false);
    expect(hook.result.current.canGoForward).toBe(false);
    act(() => hook.result.current.reset('/n/a.md'));
    expect(hook.result.current.canGoBack).toBe(false);
    expect(hook.result.current.canGoForward).toBe(false);
  });

  it('navigateTo reads the file, shows it, resets scroll and enables back', async () => {
    const { hook, scroller, readFile, show, onNavigate, announce } = setup();
    act(() => hook.result.current.reset('/n/a.md'));
    scroller.scrollTop = 120;

    let result: boolean | undefined;
    await act(async () => {
      result = await hook.result.current.navigateTo('/n/b.md');
    });

    expect(result).toBe(true);
    expect(readFile).toHaveBeenCalledWith('/n/b.md');
    expect(show).toHaveBeenCalledWith('/n/b.md', 'B');
    expect(scroller.scrollTop).toBe(0);
    expect(hook.result.current.canGoBack).toBe(true);
    expect(hook.result.current.canGoForward).toBe(false);
    expect(onNavigate).toHaveBeenCalledTimes(1);
    expect(announce).toHaveBeenCalledWith('Opened b.md');
  });

  it('goBack restores the saved scroll position and goForward returns', async () => {
    const { hook, scroller, show, announce } = setup();
    act(() => hook.result.current.reset('/n/a.md'));
    scroller.scrollTop = 120;
    await act(async () => {
      await hook.result.current.navigateTo('/n/b.md');
    });
    scroller.scrollTop = 40;

    await act(async () => {
      await hook.result.current.goBack();
    });
    expect(show).toHaveBeenLastCalledWith('/n/a.md', 'A');
    expect(scroller.scrollTop).toBe(120);
    expect(hook.result.current.canGoBack).toBe(false);
    expect(hook.result.current.canGoForward).toBe(true);
    expect(announce).toHaveBeenLastCalledWith('Went back to a.md');

    await act(async () => {
      await hook.result.current.goForward();
    });
    expect(show).toHaveBeenLastCalledWith('/n/b.md', 'B');
    expect(scroller.scrollTop).toBe(40);
    expect(hook.result.current.canGoForward).toBe(false);
    expect(announce).toHaveBeenLastCalledWith('Went forward to b.md');
  });

  it('a new navigation after going back drops forward', async () => {
    const { hook } = setup();
    act(() => hook.result.current.reset('/n/a.md'));
    await act(async () => {
      await hook.result.current.navigateTo('/n/b.md');
    });
    await act(async () => {
      await hook.result.current.goBack();
    });
    expect(hook.result.current.canGoForward).toBe(true);
    await act(async () => {
      await hook.result.current.navigateTo('/n/c.md');
    });
    expect(hook.result.current.canGoForward).toBe(false);
    expect(hook.result.current.canGoBack).toBe(true);
  });

  it('navigating to the file already shown does nothing', async () => {
    const { hook, readFile, show, onNavigate } = setup();
    act(() => hook.result.current.reset('/n/a.md'));
    let result: boolean | undefined;
    await act(async () => {
      result = await hook.result.current.navigateTo('/n/a.md');
    });
    expect(result).toBe(true);
    expect(readFile).not.toHaveBeenCalled();
    expect(show).not.toHaveBeenCalled();
    expect(onNavigate).not.toHaveBeenCalled();
    expect(hook.result.current.canGoBack).toBe(false);
  });

  it('navigateAnchor scrolls to the heading, adds an entry and Back restores the old scroll', async () => {
    const { hook, scroller, readFile, show } = setup();
    const heading = addHeading('target');
    act(() => hook.result.current.reset('/n/a.md'));
    scroller.scrollTop = 300;

    act(() => hook.result.current.navigateAnchor('target'));
    expect(scrollSpy.mock.instances.at(-1)).toBe(heading);
    expect(hook.result.current.canGoBack).toBe(true);
    expect(readFile).not.toHaveBeenCalled();

    scroller.scrollTop = 900;
    await act(async () => {
      await hook.result.current.goBack();
    });
    expect(scroller.scrollTop).toBe(300);
    expect(readFile).not.toHaveBeenCalled();
    expect(show).not.toHaveBeenCalled();
  });

  it('navigateAnchor falls back to a lowercased id and ignores a missing heading', () => {
    const { hook } = setup();
    const heading = addHeading('setup');
    act(() => hook.result.current.reset('/n/a.md'));

    act(() => hook.result.current.navigateAnchor('Setup'));
    expect(scrollSpy.mock.instances.at(-1)).toBe(heading);
    expect(hook.result.current.canGoBack).toBe(true);

    const before = scrollSpy.mock.calls.length;
    act(() => hook.result.current.navigateAnchor('does-not-exist'));
    expect(scrollSpy.mock.calls.length).toBe(before);
  });

  it('navigateAnchor with a missing heading adds no entry', () => {
    const { hook } = setup();
    act(() => hook.result.current.reset('/n/a.md'));
    act(() => hook.result.current.navigateAnchor('nope'));
    expect(hook.result.current.canGoBack).toBe(false);
  });

  it('navigateTo(path, anchor) loads the file and scrolls to the heading once it exists', async () => {
    const { hook, show } = setup();
    let heading: HTMLElement | null = null;
    show.mockImplementation(() => {
      heading = addHeading('section');
    });
    act(() => hook.result.current.reset('/n/a.md'));

    await act(async () => {
      await hook.result.current.navigateTo('/n/b.md', 'section');
    });

    expect(heading).not.toBeNull();
    expect(scrollSpy.mock.instances.at(-1)).toBe(heading);
  });

  it('navigateTo the current file with an anchor behaves as an anchor navigation', async () => {
    const { hook, readFile } = setup();
    const heading = addHeading('part');
    act(() => hook.result.current.reset('/n/a.md'));

    await act(async () => {
      await hook.result.current.navigateTo('/n/a.md', 'part');
    });

    expect(readFile).not.toHaveBeenCalled();
    expect(scrollSpy.mock.instances.at(-1)).toBe(heading);
    expect(hook.result.current.canGoBack).toBe(true);
  });

  it('a failed read reports the error and adds no entry', async () => {
    const { hook, show, onReadError, onNavigate } = setup();
    act(() => hook.result.current.reset('/n/a.md'));

    let result: boolean | undefined;
    await act(async () => {
      result = await hook.result.current.navigateTo('/n/missing.md');
    });

    expect(result).toBe(false);
    expect(onReadError).toHaveBeenCalledTimes(1);
    expect(show).not.toHaveBeenCalled();
    expect(onNavigate).not.toHaveBeenCalled();
    expect(hook.result.current.canGoBack).toBe(false);
  });

  it('going back to a deleted file stays put, removes the dead entry and the next Back skips it', async () => {
    const { hook, files, show, onReadError } = setup();
    act(() => hook.result.current.reset('/n/a.md'));
    await act(async () => {
      await hook.result.current.navigateTo('/n/b.md');
    });
    await act(async () => {
      await hook.result.current.navigateTo('/n/c.md');
    });
    delete files['/n/b.md'];
    show.mockClear();

    await act(async () => {
      await hook.result.current.goBack();
    });
    expect(onReadError).toHaveBeenCalledTimes(1);
    expect(show).not.toHaveBeenCalled();
    expect(hook.result.current.canGoBack).toBe(true);

    await act(async () => {
      await hook.result.current.goBack();
    });
    expect(show).toHaveBeenLastCalledWith('/n/a.md', 'A');
    expect(hook.result.current.canGoBack).toBe(false);
  });

  it('ignores the result of a superseded navigation', async () => {
    const { hook, readFile, show } = setup();
    let releaseSlow: (value: string) => void = () => undefined;
    readFile.mockImplementation((path: string) => {
      if (path === '/n/slow.md') {
        return new Promise<string>((resolve) => {
          releaseSlow = resolve;
        });
      }
      return Promise.resolve(FILES[path]);
    });
    act(() => hook.result.current.reset('/n/a.md'));

    let slow: Promise<boolean> = Promise.resolve(true);
    act(() => {
      slow = hook.result.current.navigateTo('/n/slow.md');
    });
    await act(async () => {
      await hook.result.current.navigateTo('/n/b.md');
    });
    let slowResult: boolean | undefined;
    await act(async () => {
      releaseSlow('SLOW');
      slowResult = await slow;
    });

    expect(slowResult).toBe(false);
    expect(show).toHaveBeenCalledTimes(1);
    expect(show).toHaveBeenCalledWith('/n/b.md', 'B');
    await act(async () => {
      await hook.result.current.goBack();
    });
    expect(show).toHaveBeenLastCalledWith('/n/a.md', 'A');
  });

  it('reset starts a fresh single-entry history', async () => {
    const { hook } = setup();
    act(() => hook.result.current.reset('/n/a.md'));
    await act(async () => {
      await hook.result.current.navigateTo('/n/b.md');
    });
    await act(async () => {
      await hook.result.current.goBack();
    });
    expect(hook.result.current.canGoForward).toBe(true);

    act(() => hook.result.current.reset('/n/c.md'));
    expect(hook.result.current.canGoBack).toBe(false);
    expect(hook.result.current.canGoForward).toBe(false);
  });

  it('back and forward do nothing when there is nowhere to go', async () => {
    const { hook, readFile, show } = setup();
    act(() => hook.result.current.reset('/n/a.md'));
    await act(async () => {
      await hook.result.current.goBack();
      await hook.result.current.goForward();
    });
    expect(readFile).not.toHaveBeenCalled();
    expect(show).not.toHaveBeenCalled();
  });
});
