import { beforeEach, describe, expect, it, vi } from 'vitest';

const electronMocks = vi.hoisted(() => ({
  buildFromTemplate: vi.fn((template: unknown) => ({ template })),
  setApplicationMenu: vi.fn(),
}));

vi.mock('electron', () => ({
  Menu: {
    buildFromTemplate: electronMocks.buildFromTemplate,
    setApplicationMenu: electronMocks.setApplicationMenu,
  },
  app: { isPackaged: true, name: 'Emdy' },
}));

import { buildMenu } from './menu';

type Item = { label?: string; accelerator?: string; type?: string; click?: () => void; submenu?: Item[] };

function viewMenu(): Item[] {
  const template = electronMocks.buildFromTemplate.mock.calls.at(-1)?.[0] as Item[] | undefined;
  const view = template?.find((entry) => entry.label === 'View');
  if (!view?.submenu) throw new Error('View menu not found');
  return view.submenu;
}

describe('View menu back/forward', () => {
  const sendEvent = vi.fn();

  beforeEach(() => {
    sendEvent.mockReset();
    electronMocks.buildFromTemplate.mockClear();
  });

  it('starts with Back and Forward on Cmd+[ and Cmd+], then a separator', () => {
    buildMenu(sendEvent, true);
    const [back, forward, separator] = viewMenu();
    expect(back).toMatchObject({ label: 'Back', accelerator: 'CmdOrCtrl+[' });
    expect(forward).toMatchObject({ label: 'Forward', accelerator: 'CmdOrCtrl+]' });
    expect(separator.type).toBe('separator');
  });

  it('sends nav-back and nav-forward events when clicked', () => {
    buildMenu(sendEvent, true);
    const [back, forward] = viewMenu();
    back.click?.();
    forward.click?.();
    expect(sendEvent).toHaveBeenNthCalledWith(1, 'nav-back');
    expect(sendEvent).toHaveBeenNthCalledWith(2, 'nav-forward');
  });

  it('is present even before a file is open (the menu is global)', () => {
    buildMenu(sendEvent, false);
    expect(viewMenu()[0]).toMatchObject({ label: 'Back' });
  });

  it('does not reuse an accelerator already taken in the app menu', () => {
    buildMenu(sendEvent, true);
    const template = electronMocks.buildFromTemplate.mock.calls.at(-1)?.[0] as Item[];
    const accelerators: string[] = [];
    const walk = (items: Item[]) => items.forEach((item) => {
      if (item.accelerator) accelerators.push(item.accelerator);
      if (item.submenu) walk(item.submenu);
    });
    walk(template);
    expect(new Set(accelerators).size).toBe(accelerators.length);
  });
});
