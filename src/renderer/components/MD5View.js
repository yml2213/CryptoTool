const CryptoJS = require('crypto-js')

export default {
    name: 'MD5View',
    data() {
        return {
            inputText: '',
            results: {
                '32位 小写': '',
                '32位 大写': '',
                '32位 反转': '',
                '32位 大写反转': '',
                '16位 小写': '',
                '16位 反转': ''
            }
        }
    },
    methods: {
        generateMD5() {
            if (!this.inputText) {
                this.clearResults()
                return
            }

            const md5 = CryptoJS.MD5(this.inputText).toString()

            this.results = {
                '32位 小写': md5,
                '32位 大写': md5.toUpperCase(),
                '32位 反转': md5.split('').reverse().join(''),
                '32位 大写反转': md5.toUpperCase().split('').reverse().join(''),
                '16位 小写': md5.substring(8, 24),
                '16位 反转': md5.substring(8, 24).split('').reverse().join('')
            }
        },
        clearResults() {
            Object.keys(this.results).forEach(key => {
                this.results[key] = ''
            })
        },
        copyResult(value) {
            navigator.clipboard.writeText(value)
        }
    },
    template: `
    <div class="space-y-4">
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
          输入文本
        </label>
        <textarea
          v-model="inputText"
          @input="generateMD5"
          class="w-full h-32 p-2 border rounded-md"
          placeholder="输入需要处理的文本"
        ></textarea>
      </div>

      <div class="space-y-4">
        <div v-for="(value, key) in results" :key="key"
          class="flex items-center justify-between p-3 bg-white dark:bg-gray-800 rounded-md">
          <span class="text-sm text-gray-600 dark:text-gray-400">{{key}}</span>
          <div class="flex items-center space-x-2">
            <code class="text-sm">{{value}}</code>
            <button
              @click="copyResult(value)"
              class="p-1 text-gray-500 hover:text-gray-700"
              :disabled="!value"
            >
              复制
            </button>
          </div>
        </div>
      </div>
    </div>
  `
} 