const { app, BrowserWindow, ipcMain, session } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        minWidth: 1200,
        minHeight: 700,
        icon: path.join(__dirname, 'icon.ico'),
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js'),
            webviewTag: true
        },
        autoHideMenuBar: true,
        frame: true,
        backgroundColor: '#1a1a2e'
    });

    // Load the login page
    mainWindow.loadFile('pages/login.html');

    // Handle printing from webview/iframe
    mainWindow.webContents.on('did-attach-webview', (event, webContents) => {
        webContents.on('will-print', (e) => {
            e.preventDefault();
        });
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

// Silent printing handler
ipcMain.on('print-receipt', (event, receiptHTML) => {
    const printWindow = new BrowserWindow({
        show: false,
        width: 300,
        height: 600,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                @page { size: auto; margin: 5mm; }
                body { margin: 0; padding: 10px; font-family: Arial, sans-serif; }
            </style>
        </head>
        <body>${receiptHTML}</body>
        </html>
    `;

    printWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(htmlContent)}`);

    printWindow.webContents.on('did-finish-load', () => {
        // Get list of printers
        printWindow.webContents.getPrintersAsync().then(printers => {
            console.log('Available printers:', printers.map(p => p.name));
            
            // Find thermal printer or use default
            let printerName = '';
            const thermalPrinter = printers.find(p => 
                p.name.toLowerCase().includes('pos') || 
                p.name.toLowerCase().includes('thermal') ||
                p.name.toLowerCase().includes('receipt') ||
                p.name.toLowerCase().includes('epos') ||
                p.name.toLowerCase().includes('e-pos')
            );
            
            if (thermalPrinter) {
                printerName = thermalPrinter.name;
                console.log('Using thermal printer:', printerName);
            }

            // Print silently
            printWindow.webContents.print({
                silent: true,
                printBackground: true,
                deviceName: printerName,
                margins: { marginType: 'none' }
            }, (success, errorType) => {
                if (!success) {
                    console.error('Print failed:', errorType);
                } else {
                    console.log('Print successful!');
                }
                printWindow.close();
            });
        });
    });
});

// Handle print request from renderer
ipcMain.handle('get-printers', async () => {
    const printers = await mainWindow.webContents.getPrintersAsync();
    return printers;
});

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (mainWindow === null) {
        createWindow();
    }
});
