import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { Toolbar } from './Toolbar';

function renderToolbar(overrides: Partial<React.ComponentProps<typeof Toolbar>> = {}) {
  const props: React.ComponentProps<typeof Toolbar> = {
    zoom: 100,
    fontFamily: 'sans',
    fileName: 'intro.md',
    filePath: '/notes/intro.md',
    onFileContextMenu: vi.fn(),
    onZoomIn: vi.fn(),
    onZoomOut: vi.fn(),
    onZoomReset: vi.fn(),
    onFontChange: vi.fn(),
    contentWidth: 'wide',
    onContentWidthChange: vi.fn(),
    sidebarVisible: false,
    hasSidebar: false,
    onToggleSidebar: vi.fn(),
    outlineVisible: false,
    hasOutline: false,
    onToggleOutline: vi.fn(),
    minimapVisible: false,
    onToggleMinimap: vi.fn(),
    onSearch: vi.fn(),
    onExportPDF: vi.fn(),
    onCopyHTML: vi.fn(),
    onOpenSettings: vi.fn(),
    hasContent: true,
    canGoBack: false,
    canGoForward: false,
    onBack: vi.fn(),
    onForward: vi.fn(),
    ...overrides,
  };
  return { ...render(<Toolbar {...props} />), props };
}

describe('Toolbar back/forward', () => {
  it('renders Back and Forward buttons with shortcut tooltips', () => {
    renderToolbar();
    expect(screen.getByRole('button', { name: 'Back' })).toHaveAttribute('data-tooltip', 'Back  ⌘[');
    expect(screen.getByRole('button', { name: 'Forward' })).toHaveAttribute('data-tooltip', 'Forward  ⌘]');
  });

  it('marks both aria-disabled and ignores clicks when there is nowhere to go', () => {
    const { props } = renderToolbar({ canGoBack: false, canGoForward: false });
    const back = screen.getByRole('button', { name: 'Back' });
    const forward = screen.getByRole('button', { name: 'Forward' });
    expect(back).toHaveAttribute('aria-disabled', 'true');
    expect(forward).toHaveAttribute('aria-disabled', 'true');
    fireEvent.click(back);
    fireEvent.click(forward);
    expect(props.onBack).not.toHaveBeenCalled();
    expect(props.onForward).not.toHaveBeenCalled();
  });

  it('enables each button independently and calls its handler', () => {
    const { props } = renderToolbar({ canGoBack: true, canGoForward: false });
    const back = screen.getByRole('button', { name: 'Back' });
    const forward = screen.getByRole('button', { name: 'Forward' });
    expect(back).toHaveAttribute('aria-disabled', 'false');
    expect(forward).toHaveAttribute('aria-disabled', 'true');
    fireEvent.click(back);
    expect(props.onBack).toHaveBeenCalledTimes(1);
    fireEvent.click(forward);
    expect(props.onForward).not.toHaveBeenCalled();
  });

  it('calls onForward when forward is enabled', () => {
    const { props } = renderToolbar({ canGoForward: true });
    fireEvent.click(screen.getByRole('button', { name: 'Forward' }));
    expect(props.onForward).toHaveBeenCalledTimes(1);
  });

  it('takes part in the toolbar arrow-key navigation', () => {
    renderToolbar();
    expect(screen.getByRole('button', { name: 'Back' })).toHaveAttribute('data-toolbar-btn');
    expect(screen.getByRole('button', { name: 'Forward' })).toHaveAttribute('data-toolbar-btn');
  });

  it('stays visible when the window is narrow enough to collapse the toolbar', () => {
    renderToolbar();
    act(() => {
      Object.defineProperty(window, 'innerWidth', { configurable: true, value: 500 });
      window.dispatchEvent(new Event('resize'));
    });
    expect(screen.getByRole('button', { name: 'Back' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Forward' })).toBeInTheDocument();
  });

  it('is not shown when no document is open', () => {
    renderToolbar({ hasContent: false, fileName: null, filePath: null });
    expect(screen.queryByRole('button', { name: 'Back' })).toBeNull();
    expect(screen.queryByRole('button', { name: 'Forward' })).toBeNull();
  });
});
