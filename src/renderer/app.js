const { createApp } = Vue

// 异步加载组件
async function loadComponents() {
    const [Sidebar, MD5View] = await Promise.all([
        import('./components/Sidebar.js'),
        import('./components/MD5View.js')
    ])

    const App = {
        components: {
            Sidebar: Sidebar.default,
            MD5View: MD5View.default
        },
        data() {
            return {
                selectedTab: 'MD5',
                cryptoOptions: [
                    { icon: 'bi bi-hash-square', name: 'MD5', description: '信息摘要算法' },
                    { icon: 'bi bi-shield-lock', name: 'SHA', description: '安全散列算法' },
                    { icon: 'bi bi-key', name: 'HMAC', description: '哈希消息认证码' },
                    { icon: 'bi bi-lock', name: 'AES', description: '高级加密标准' },
                    { icon: 'bi bi-key-fill', name: 'DES', description: '数据加密标准' },
                    { icon: 'bi bi-key-fill', name: 'RSA', description: '非对称加密算法' },
                    { icon: 'bi bi-file-text', name: 'Base64', description: '基础编码' }
                ]
            }
        },
        template: `
            <div class="flex h-screen bg-gray-100 dark:bg-gray-900">
                <Sidebar 
                    :options="cryptoOptions"
                    :selected="selectedTab"
                    @select="selectedTab = $event"
                />
                <component 
                    :is="selectedTab + 'View'"
                    class="content p-4"
                />
            </div>
        `
    }

    const app = createApp(App)
    app.mount('#app')
}

loadComponents() 