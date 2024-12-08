const { app, BrowserWindow, ipcMain } = require('electron')
const path = require('path')

function createWindow() {
    const win = new BrowserWindow({
        width: 960,
        height: 680,
        minWidth: 960,
        minHeight: 680,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false,
            webSecurity: false,
            enableRemoteModule: true,
            sandbox: false,
            experimentalFeatures: true
        }
    })

    // 开发环境打开开发者工具
    win.webContents.openDevTools()

    // 设置工作目录
    process.chdir(__dirname)

    // 加载页面
    win.loadFile('src/index.html')
}

app.whenReady().then(createWindow)

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit()
    }
})

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow()
    }
}) 