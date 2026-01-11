const { app, BrowserWindow, Menu, shell } = require('electron');
const path = require('path');

// رابط الموقع
const SITE_URL = 'https://sham-coffee.web.app';

let mainWindow;

function createWindow() {
    // إنشاء نافذة التطبيق
    mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        minWidth: 1024,
        minHeight: 700,
        title: 'قهوة الشام - نظام العامل',
        icon: path.join(__dirname, 'icon.ico'),
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            webSecurity: true
        },
        autoHideMenuBar: true,
        backgroundColor: '#0f172a'
    });

    // تحميل صفحة تسجيل الدخول للعامل
    mainWindow.loadURL(SITE_URL + '/login-worker.html');

    // إخفاء القائمة
    Menu.setApplicationMenu(null);

    // فتح الروابط الخارجية في المتصفح
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        if (url.startsWith('https://sham-coffee.web.app')) {
            return { action: 'allow' };
        }
        shell.openExternal(url);
        return { action: 'deny' };
    });

    // عند إغلاق النافذة
    mainWindow.on('closed', () => {
        mainWindow = null;
    });

    // إضافة اختصارات لوحة المفاتيح
    mainWindow.webContents.on('before-input-event', (event, input) => {
        // F5 أو Ctrl+R لإعادة التحميل
        if (input.key === 'F5' || (input.control && input.key === 'r')) {
            mainWindow.reload();
            event.preventDefault();
        }
        // F11 للشاشة الكاملة
        if (input.key === 'F11') {
            mainWindow.setFullScreen(!mainWindow.isFullScreen());
            event.preventDefault();
        }
        // Ctrl+Shift+I لأدوات المطور (للتصحيح)
        if (input.control && input.shift && input.key === 'I') {
            mainWindow.webContents.toggleDevTools();
            event.preventDefault();
        }
    });
}

// عند جاهزية التطبيق
app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

// إغلاق التطبيق عند إغلاق جميع النوافذ (Windows)
app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

// منع فتح نوافذ جديدة غير مرغوبة
app.on('web-contents-created', (event, contents) => {
    contents.on('new-window', (navigationEvent, url) => {
        navigationEvent.preventDefault();
        if (url.startsWith('https://sham-coffee.web.app')) {
            mainWindow.loadURL(url);
        } else {
            shell.openExternal(url);
        }
    });
});

console.log('☕ تطبيق قهوة الشام جاهز');






