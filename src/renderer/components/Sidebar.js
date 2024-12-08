export default {
    name: 'Sidebar',
    props: {
        options: Array,
        selected: String
    },
    template: `
        <div class="w-64 h-screen bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
            <div class="p-4">
                <div v-for="option in options" 
                     :key="option.name"
                     @click="$emit('select', option.name)"
                     class="flex items-center p-3 mb-2 rounded-lg cursor-pointer transition-colors duration-150"
                     :class="selected === option.name ? 
                            'bg-blue-50 dark:bg-blue-900/50' : 
                            'hover:bg-gray-100 dark:hover:bg-gray-700/50'">
                    <i :class="[option.icon, 
                              selected === option.name ? 
                              'text-blue-600 dark:text-blue-400' : 
                              'text-gray-500 dark:text-gray-400']"
                       class="text-xl mr-3"></i>
                    <div>
                        <div class="font-medium" 
                             :class="selected === option.name ? 
                                    'text-blue-600 dark:text-blue-400' : 
                                    'text-gray-700 dark:text-gray-300'">
                            {{option.name}}
                        </div>
                        <div class="text-xs text-gray-500 dark:text-gray-400">
                            {{option.description}}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `
} 