const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
    printReceipt: (content) => {
        console.log('Sending print request...');
        ipcRenderer.send('print-receipt', content);
    },
    getPrinters: () => ipcRenderer.invoke('get-printers')
});

// Notify when preload is ready
console.log('Electron preload script loaded');
