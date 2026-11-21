import React, { createRef } from 'react';
import { beforeEach, describe, it, expect, vi } from 'vitest';
import { render, waitFor, act, fireEvent } from '@testing-library/react';
import { MarkdownView, type MarkdownViewHandle, type HighlightState } from './MarkdownView';
import { warm } from '../lib/color-themes';

const mermaidMocks = vi.hoisted(() => ({
  initialize: vi.fn(),
  render: vi.fn(),
}));

vi.mock('mermaid', () => ({
  default: mermaidMocks,
}));

const colors = warm.light;

beforeEach(() => {
  mermaidMocks.initialize.mockClear();
  mermaidMocks.render.mockReset();
  mermaidMocks.render.mockResolvedValue({
    svg: '<svg viewBox="0 0 100 50" width="100%" style="max-width: 100px;"><text>Diagram</text></svg>',
  });
});

function setup(initialHighlight: HighlightState | null = null, onMatchesChanged = vi.fn()) {
  const ref = createRef<MarkdownViewHandle>();
  const utils = render(
    <MarkdownView
      ref={ref}
      content={'Alpha beta alpha gamma alpha'}
      colors={colors}
      highlight={initialHighlight}
      onMatchesChanged={onMatchesChanged}
    />
  );
  return { ...utils, ref, onMatchesChanged };
}

describe('MarkdownView highlight integration', () => {
  it('renders no marks when highlight is null', async () => {
    const { container, onMatchesChanged } = setup(null);
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(0);
    });
    expect(onMatchesChanged).toHaveBeenCalledWith(0, false, []);
  });

  it('walks and wraps matches when highlight is present', async () => {
    const { container, onMatchesChanged } = setup({
      query: 'alpha',
      currentIndex: 0,
      mode: 'multi-persistent',
    });
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(3);
    });
    const lastCall = onMatchesChanged.mock.calls.at(-1)!;
    expect(lastCall[0]).toBe(3);
    expect(lastCall[1]).toBe(false);
    expect(Array.isArray(lastCall[2])).toBe(true);
    expect(lastCall[2].length).toBe(3);
  });

  it('marks the current match with data-current', async () => {
    const { container } = setup({ query: 'alpha', currentIndex: 1, mode: 'multi-persistent' });
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(3);
    });
    const marks = container.querySelectorAll('mark[data-emdy-match]');
    expect(marks[0].getAttribute('data-current')).toBe(null);
    expect(marks[1].getAttribute('data-current')).toBe('true');
    expect(marks[2].getAttribute('data-current')).toBe(null);
  });

  it('clears marks when highlight flips back to null', async () => {
    const { container, rerender } = render(
      <MarkdownView
        content={'alpha beta alpha'}
        colors={colors}
        highlight={{ query: 'alpha', currentIndex: 0, mode: 'multi-persistent' }}
      />
    );
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(2);
    });

    rerender(
      <MarkdownView content={'alpha beta alpha'} colors={colors} highlight={null} />
    );
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(0);
    });
  });

  it('moves data-current when currentIndex changes', async () => {
    const { container, rerender } = render(
      <MarkdownView
        content={'alpha beta alpha gamma alpha'}
        colors={colors}
        highlight={{ query: 'alpha', currentIndex: 0, mode: 'multi-persistent' }}
      />
    );
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(3);
    });
    let marks = container.querySelectorAll('mark[data-emdy-match]');
    expect(marks[0].getAttribute('data-current')).toBe('true');

    rerender(
      <MarkdownView
        content={'alpha beta alpha gamma alpha'}
        colors={colors}
        highlight={{ query: 'alpha', currentIndex: 2, mode: 'multi-persistent' }}
      />
    );
    marks = container.querySelectorAll('mark[data-emdy-match]');
    await waitFor(() => {
      expect(marks[2].getAttribute('data-current')).toBe('true');
    });
    expect(marks[0].getAttribute('data-current')).toBe(null);
  });

  it('exposes getMatchCount via imperative handle', async () => {
    const { container, ref } = setup({ query: 'alpha', currentIndex: 0, mode: 'multi-persistent' });
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(3);
    });
    expect(ref.current?.getMatchCount()).toBe(3);
  });

  it('scrollToMatch is callable without throwing when match exists', async () => {
    const { container, ref } = setup({ query: 'alpha', currentIndex: 0, mode: 'multi-persistent' });
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(3);
    });
    // jsdom's scrollIntoView is a no-op stub; ensure the call doesn't throw.
    expect(() => act(() => ref.current?.scrollToMatch(1))).not.toThrow();
  });

  it('focusMatchAtLine returns an index given a plausible line', async () => {
    const { container, ref } = setup({ query: 'alpha', currentIndex: 0, mode: 'multi-persistent' });
    await waitFor(() => {
      expect(container.querySelectorAll('mark[data-emdy-match]').length).toBe(3);
    });
    // Content renders as one block (a single paragraph). Line 1 → block 0 → first match.
    expect(ref.current?.focusMatchAtLine(1)).toBe(0);
  });
});

describe('MarkdownView Mermaid integration', () => {
  it('renders mermaid fences as diagrams', async () => {
    const { container } = render(
      <MarkdownView
        content={'```mermaid\nsequenceDiagram\nAlice->>Bob: Hello\n```'}
        colors={colors}
      />
    );

    await waitFor(() => {
      expect(container.querySelector('.mermaid-diagram svg')).toBeInTheDocument();
    });

    expect(mermaidMocks.initialize).toHaveBeenCalledWith(expect.objectContaining({
      startOnLoad: false,
      securityLevel: 'strict',
      theme: 'base',
    }));
    expect(mermaidMocks.render).toHaveBeenCalledWith(
      expect.stringMatching(/^emdy-mermaid-/),
      'sequenceDiagram\nAlice->>Bob: Hello'
    );
    expect(container.querySelector('.code-block-wrapper')).toBeNull();

    const svg = container.querySelector('.mermaid-diagram svg');
    expect(svg?.getAttribute('width')).toBe('100');
    expect(svg?.getAttribute('height')).toBe('50');
    expect(svg?.getAttribute('style') ?? '').not.toContain('max-width');
  });

  it('falls back to the source block when mermaid rendering fails', async () => {
    mermaidMocks.render.mockRejectedValueOnce(new Error('bad diagram'));

    const { container } = render(
      <MarkdownView
        content={'```mermaid\nsequenceDiagram\nAlice--Bob\n```'}
        colors={colors}
      />
    );

    await waitFor(() => {
      expect(container.querySelector('.mermaid-error-message')).toHaveTextContent('bad diagram');
    });
    expect(container.querySelector('.code-block-wrapper')).toBeInTheDocument();
  });
});

describe('MarkdownView link clicks', () => {
  const openExternal = vi.fn();
  const openInNewWindow = vi.fn();
  const onNavigateFile = vi.fn();
  const onNavigateAnchor = vi.fn();

  beforeEach(() => {
    openExternal.mockReset();
    openInNewWindow.mockReset().mockResolvedValue(undefined);
    onNavigateFile.mockReset();
    onNavigateAnchor.mockReset();
    (window as unknown as { electronAPI: unknown }).electronAPI = { openExternal, openInNewWindow };
  });

  function renderLinks(
    filePath: string | null = '/notes/guide/intro.md',
    handlers: { onNavigateFile?: typeof onNavigateFile; onNavigateAnchor?: typeof onNavigateAnchor } = {
      onNavigateFile,
      onNavigateAnchor,
    }
  ) {
    const content = [
      '[web](https://example.com)',
      '[sibling](other.md)',
      '[parent](../README.md#setup)',
      '[image](diagram.png)',
      '[jump](#target-section)',
      '',
      '## Target Section',
    ].join('\n\n');
    return render(<MarkdownView content={content} colors={colors} filePath={filePath} {...handlers} />);
  }

  function getLink(container: HTMLElement, text: string): HTMLElement {
    const link = Array.from(container.querySelectorAll('a')).find((a) => a.textContent === text);
    if (!link) throw new Error(`link not found: ${text}`);
    return link;
  }

  function click(container: HTMLElement, text: string, init?: MouseEventInit) {
    // fireEvent returns false when the default action was prevented
    return fireEvent.click(getLink(container, text), init);
  }

  function auxClick(el: HTMLElement, button: number) {
    fireEvent(el, new MouseEvent('auxclick', { bubbles: true, cancelable: true, button }));
  }

  it('opens http(s) links externally', () => {
    const { container } = renderLinks();
    expect(click(container, 'web')).toBe(false);
    expect(openExternal).toHaveBeenCalledWith('https://example.com');
    expect(onNavigateFile).not.toHaveBeenCalled();
    expect(openInNewWindow).not.toHaveBeenCalled();
  });

  it('plain click on a relative markdown link navigates in the same window', () => {
    const { container } = renderLinks();
    expect(click(container, 'sibling')).toBe(false);
    expect(onNavigateFile).toHaveBeenCalledWith('/notes/guide/other.md', null);
    expect(openInNewWindow).not.toHaveBeenCalled();
    expect(openExternal).not.toHaveBeenCalled();
  });

  it('passes the fragment of a file link along', () => {
    const { container } = renderLinks();
    click(container, 'parent');
    expect(onNavigateFile).toHaveBeenCalledWith('/notes/README.md', 'setup');
  });

  it('Cmd+click and Ctrl+click open the file in a new window instead', () => {
    const { container } = renderLinks();
    expect(click(container, 'sibling', { metaKey: true })).toBe(false);
    expect(openInNewWindow).toHaveBeenLastCalledWith('/notes/guide/other.md');
    click(container, 'parent', { ctrlKey: true });
    expect(openInNewWindow).toHaveBeenLastCalledWith('/notes/README.md');
    expect(openInNewWindow).toHaveBeenCalledTimes(2);
    expect(onNavigateFile).not.toHaveBeenCalled();
  });

  it('middle-click opens the file in a new window', () => {
    const { container } = renderLinks();
    auxClick(getLink(container, 'sibling'), 1);
    expect(openInNewWindow).toHaveBeenCalledWith('/notes/guide/other.md');
    expect(onNavigateFile).not.toHaveBeenCalled();
  });

  it('other auxiliary buttons do nothing', () => {
    const { container } = renderLinks();
    auxClick(getLink(container, 'sibling'), 2);
    expect(openInNewWindow).not.toHaveBeenCalled();
    expect(onNavigateFile).not.toHaveBeenCalled();
  });

  it('modifier clicks still open web links externally', () => {
    const { container } = renderLinks();
    click(container, 'web', { metaKey: true });
    expect(openExternal).toHaveBeenCalledWith('https://example.com');
    expect(openInNewWindow).not.toHaveBeenCalled();
  });

  it('does nothing for non-markdown targets but still blocks navigation', () => {
    const { container } = renderLinks();
    expect(click(container, 'image')).toBe(false);
    expect(onNavigateFile).not.toHaveBeenCalled();
    expect(openInNewWindow).not.toHaveBeenCalled();
    expect(openExternal).not.toHaveBeenCalled();
  });

  it('ignores relative file links when no file is open', () => {
    const { container } = renderLinks(null);
    click(container, 'sibling');
    expect(onNavigateFile).not.toHaveBeenCalled();
    expect(openInNewWindow).not.toHaveBeenCalled();
  });

  it('hands #anchor links to onNavigateAnchor without scrolling itself', () => {
    const scrollSpy = vi.spyOn(Element.prototype, 'scrollIntoView');
    const { container } = renderLinks();
    expect(click(container, 'jump')).toBe(false);
    expect(onNavigateAnchor).toHaveBeenCalledWith('target-section');
    expect(container.querySelector('#target-section')).not.toBeNull();
    expect(scrollSpy).not.toHaveBeenCalled();
    expect(openInNewWindow).not.toHaveBeenCalled();
    scrollSpy.mockRestore();
  });

  it('falls back to a new window when no navigation handler is provided', () => {
    const { container } = renderLinks('/notes/guide/intro.md', {});
    click(container, 'sibling');
    expect(openInNewWindow).toHaveBeenCalledWith('/notes/guide/other.md');
  });

  it('swallows a rejected open (missing file or path outside allowed folders)', async () => {
    openInNewWindow.mockRejectedValueOnce(new Error('Access denied'));
    const { container } = renderLinks();
    click(container, 'sibling', { metaKey: true });
    await Promise.resolve();
    expect(openInNewWindow).toHaveBeenCalledTimes(1);
  });
});
