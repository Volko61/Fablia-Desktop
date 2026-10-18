const { app, BrowserWindow, Menu, shell, dialog } = require("electron");
const path = require("node:path");

const SITE = "https://fablia.fr";
const SITE_HOST = new URL(SITE).hostname;
const isStore = !!process.windowsStore;

if (!app.requestSingleInstanceLock()) {
  app.quit();
}

let win;

function isInternal(url) {
  try {
    const host = new URL(url).hostname;
    return host === SITE_HOST || host.endsWith("." + SITE_HOST);
  } catch {
    return false;
  }
}

function createWindow() {
  win = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 480,
    minHeight: 600,
    backgroundColor: "#00201f",
    title: "Fablia",
    icon: path.join(__dirname, "..", "build", "icon.png"),
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      sandbox: true,
      nodeIntegration: false,
    },
  });

  // Links to other sites (OAuth providers excepted) open in the system browser.
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (isInternal(url)) return { action: "allow" };
    shell.openExternal(url);
    return { action: "deny" };
  });
  win.webContents.on("will-navigate", (event, url) => {
    if (!isInternal(url)) {
      event.preventDefault();
      shell.openExternal(url);
    }
  });

  win.webContents.on("did-fail-load", (_e, code, _desc, _url, isMainFrame) => {
    if (isMainFrame && code !== -3) {
      win.loadFile(path.join(__dirname, "offline.html"));
    }
  });

  win.loadURL(SITE);
}

function buildMenu() {
  const template = [
    {
      label: "Fablia",
      submenu: [
        { label: "Accueil", click: () => win?.loadURL(SITE) },
        { label: "Recharger", role: "reload" },
        { label: "Plein écran", role: "togglefullscreen" },
        { type: "separator" },
        { label: "Quitter", role: "quit" },
      ],
    },
    { label: "Édition", role: "editMenu" },
    {
      label: "Affichage",
      submenu: [
        { role: "resetZoom", label: "Zoom par défaut" },
        { role: "zoomIn", label: "Zoom +" },
        { role: "zoomOut", label: "Zoom −" },
      ],
    },
  ];
  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

function checkForUpdates() {
  // Microsoft Store handles its own updates; other channels use GitHub releases.
  if (isStore || !app.isPackaged) return;
  const { autoUpdater } = require("electron-updater");
  autoUpdater.autoDownload = true;
  autoUpdater.on("update-downloaded", (info) => {
    dialog
      .showMessageBox(win, {
        type: "info",
        buttons: ["Redémarrer maintenant", "Plus tard"],
        defaultId: 0,
        message: `Fablia ${info.version} est prête.`,
        detail: "Redémarrez l'application pour installer la mise à jour.",
      })
      .then(({ response }) => {
        if (response === 0) autoUpdater.quitAndInstall();
      });
  });
  autoUpdater.on("error", (err) => console.error("update check failed:", err.message));
  autoUpdater.checkForUpdatesAndNotify().catch(() => {});
}

app.on("second-instance", () => {
  if (!win) return;
  if (win.isMinimized()) win.restore();
  win.focus();
});

app.whenReady().then(() => {
  buildMenu();
  createWindow();
  checkForUpdates();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
