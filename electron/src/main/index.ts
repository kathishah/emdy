import { app, BrowserWindow, ipcMain, nativeTheme, protocol, net, session, systemPreferences, shell } from 'electron';
import path from 'node:path';
import fs from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import started from 'electron-squirrel-startup';
import { registerFileHandlers, scanDirectory, setCurrentPaths } from './ipc-handlers';
import { registerSettingsHandlers, registerNudgeHandlers, nudgeTrackAppLaunch, getSettings } from './settings-store';
import { registerFileWatcher } from './file-watcher';
import { registerExportHandlers } from './pdf-export';
import { buildMenu } from './menu';
import { addAllowedRoot, isPathAllowed, hardenWindow } from './allowed-paths';
import { setupAutoUpdater, registerAutoUpdaterIPC } from './auto-updater';

if (started) {
  app.quit();
}

// Prevent macOS Keychain "confidential information" dialog on first launch.
// Emdy stores nothing sensitive in web storage, so encrypted storage is unnecessary.
app.commandLine.appendSwitch('use-mock-keychain');

let mainWindow: BrowserWindow | null = null;
let pendingFilePath: string | null = null;
const rendererReadyContents = new Set<number>();
const queuedOpenPaths = new Map<number, string>();

// Background colors per theme to avoid white flash on launch
const BG_COLORS: Record<string, { light: string; dark: string }> = {
  warm:    { light: '#F5F3EF', dark: '#1C1A16' },
  cool:    { light: '#F5F5F4', dark: '#1A1A19' },
  neutral: { light: '#F0F0F0', dark: '#1C1C1E' },
  fresh:   { light: '#FFFBF0', dark: '#0A1628' },
  neon:    { light: '#F4F2F8', dark: '#050510' },
};

function getCliOpenPath(argv: string[]): string | null {
  const args = process.defaultApp ? argv.slice(2) : argv.slice(1);
  const candidate = args.find((arg) => arg && !arg.startsWith('-'));
  if (!candidate) return null;
  return path.resolve(candidate);
}

async function openPathInWindow(win: BrowserWindow, filePath: string) {
  const stat = await fs.stat(filePath);
  if (stat.isDirectory()) {
    addAllowedRoot(filePath);
    setCurrentPaths({ dirPath: filePath });
    const entries = await scanDirectory(filePath);
    win.webContents.send('dir:open', filePath, entries);
  } else {
    addAllowedRoot(path.dirname(filePath));
    setCurrentPaths({ filePath });
    const content = await fs.readFile(filePath, 'utf-8');
    win.webContents.send('file:open', filePath, content);
    app.addRecentDocument(filePath);
  }
}

async function flushQueuedPath(win: BrowserWindow) {
  const queuedPath = queuedOpenPaths.get(win.webContents.id);
  if (!queuedPath) return;
  queuedOpenPaths.delete(win.webContents.id);
  await openPathInWindow(win, queuedPath);
}

async function queueOrOpenPath(filePath: string) {
  const resolvedPath = path.resolve(filePath);
  const win = mainWindow || BrowserWindow.getAllWindows()[0];
  if (!win) {
    pendingFilePath = resolvedPath;
    return;
  }

  if (rendererReadyContents.has(win.webContents.id) && !win.webContents.isLoading()) {
    await openPathInWindow(win, resolvedPath);
  } else {
    queuedOpenPaths.set(win.webContents.id, resolvedPath);
  }
}

const gotSingleInstanceLock = app.requestSingleInstanceLock();

if (!gotSingleInstanceLock) {
  app.quit();
}

pendingFilePath = getCliOpenPath(process.argv);

const createWindow = () => {
  const settings = getSettings();
  const isDark = settings.theme === 'dark' || (settings.theme === 'system' && nativeTheme.shouldUseDarkColors);
  const palette = BG_COLORS[settings.colorTheme] || BG_COLORS.warm;

  mainWindow = new BrowserWindow({
    width: 1000,
    height: 700,
    minWidth: 600,
    minHeight: 400,
    show: false,
    backgroundColor: isDark ? palette.dark : palette.light,
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 16, y: 16 },
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });
  const win = mainWindow;
  const webContentsId = win.webContents.id;

  win.once('ready-to-show', () => {
    win.show();
  });

  if (MAIN_WINDOW_VITE_DEV_SERVER_URL) {
    win.loadURL(MAIN_WINDOW_VITE_DEV_SERVER_URL);
  } else {
    win.loadFile(
      path.join(__dirname, `../renderer/${MAIN_WINDOW_VITE_NAME}/index.html`),
    );
  }

  hardenWindow(win);
  rendererReadyContents.delete(webContentsId);

  if (pendingFilePath) {
    queuedOpenPaths.set(webContentsId, pendingFilePath);
    pendingFilePath = null;
  }

  win.on('closed', () => {
    rendererReadyContents.delete(webContentsId);
    queuedOpenPaths.delete(webContentsId);
    if (mainWindow === win) {
      mainWindow = null;
    }
  });
};

app.on('second-instance', async (_event, argv) => {
  const cliPath = getCliOpenPath(argv);
  if (!cliPath) return;

  const win = mainWindow || BrowserWindow.getAllWindows()[0];
  if (win) {
    if (win.isMinimized()) win.restore();
    win.focus();
  }

  try {
    await queueOrOpenPath(cliPath);
  } catch {
    // Ignore invalid path arguments
  }
});

ipcMain.handle('window:toggle-maximize', (event) => {
  const win = BrowserWindow.fromWebContents(event.sender);
  if (!win) return;
  if (win.isMaximized()) win.unmaximize();
  else win.maximize();
});

ipcMain.on('renderer:ready', async (event) => {
  const win = BrowserWindow.fromWebContents(event.sender);
  if (!win) return;

  rendererReadyContents.add(event.sender.id);

  try {
    await flushQueuedPath(win);
  } catch {
    // Ignore unreadable startup paths
  }
});

registerFileHandlers();
registerSettingsHandlers();
registerFileWatcher();
registerExportHandlers();
registerNudgeHandlers();
registerAutoUpdaterIPC();

// System accent color
ipcMain.handle('system:accent-color', () => {
  return '#' + systemPreferences.getAccentColor().slice(0, 6);
});

ipcMain.handle('app:version', () => {
  return app.getVersion();
});

ipcMain.handle('app:open-external', (_event, url: string) => {
  try {
    const parsed = new URL(url);
    if (parsed.protocol === 'https:' || parsed.protocol === 'http:') {
      shell.openExternal(url);
    }
  } catch {
    // Invalid URL — ignore
  }
});

// Register protocol to serve local files for markdown images
protocol.registerSchemesAsPrivileged([
  { scheme: 'local-file', privileges: { supportFetchAPI: true, standard: true } },
]);

app.on('ready', () => {
  protocol.handle('local-file', (request) => {
    const parsed = new URL(request.url);
    const resolved = path.resolve(decodeURIComponent(parsed.pathname));
    if (!isPathAllowed(resolved)) {
      return new Response('Forbidden', { status: 403 });
    }
    return net.fetch(pathToFileURL(resolved).href);
  });

  // Content Security Policy — only applied in production (Vite HMR needs looser policy)
  if (!MAIN_WINDOW_VITE_DEV_SERVER_URL) {
    session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
      callback({
        responseHeaders: {
          ...details.responseHeaders,
          'Content-Security-Policy': [
            "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' local-file: data:; font-src 'self'; connect-src 'self' https://emdyapp.com; object-src 'none'; base-uri 'self'; form-action 'none'",
          ],
        },
      });
    });
  }

  createWindow();
  nudgeTrackAppLaunch();
  buildMenu(sendMenuEvent);
  setupAutoUpdater();

  // Forward system accent color changes to renderer (macOS)
  systemPreferences.subscribeNotification('AppleColorPreferencesChangedNotification', () => {
    const color = '#' + systemPreferences.getAccentColor().slice(0, 6);
    for (const win of BrowserWindow.getAllWindows()) {
      if (!win.isDestroyed()) {
        win.webContents.send('system:accent-color-changed', color);
      }
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// Handle opening files/directories via OS (double-click, drag to dock, Open Recent)
app.on('open-file', async (event, filePath) => {
  event.preventDefault();
  try {
    await queueOrOpenPath(filePath);
  } catch {
    // File/directory can't be read
  }
});

let hasFileOpen = false;

ipcMain.handle('menu:set-has-file', (_event, hasFile: unknown) => {
  const value = Boolean(hasFile);
  if (value !== hasFileOpen) {
    hasFileOpen = value;
    buildMenu(sendMenuEvent, hasFileOpen);
  }
});

function sendMenuEvent(event: string) {
  const win = BrowserWindow.getFocusedWindow() || mainWindow;
  if (win && !win.isDestroyed()) {
    win.webContents.send('menu:event', event);
  }
}
