// 移动 CryptoTool/ContentView.swift -> CryptoTool/App/ContentView.swift 
import SwiftUI


struct ContentView: View {
    @State private var selectedTab = "MD5"
    @State private var searchText = ""
    @State private var isEditing = false
    @State private var draggedIndex: Int?
    @State private var cryptoOptions = [
        (icon: "number.circle", name: "MD5", description: "信息摘要算法"),
        (icon: "key.fill", name: "SHA", description: "安全散列算法"),
        (icon: "lock.fill", name: "HMAC", description: "哈希消息认证码"),
        (icon: "lock.shield.fill", name: "AES", description: "高级加密标准"),
        (icon: "key.horizontal.fill", name: "DES", description: "数据加密标准"),
        (icon: "key.horizontal", name: "RSA", description: "非对称加密算法"),
        (icon: "doc.fill", name: "Base64", description: "基础编码"),
        (icon: "link", name: "URL", description: "URL编解码"),
        (icon: "character.book.closed", name: "Unicode", description: "Unicode编解码")
    ]
    
    struct DraggableItem: Identifiable, Equatable {
        let id = UUID()
        let icon: String
        let name: String
        let description: String
        
        static func == (lhs: DraggableItem, rhs: DraggableItem) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    private func createDraggableItems() -> [DraggableItem] {
        cryptoOptions.map { DraggableItem(icon: $0.icon, name: $0.name, description: $0.description) }
    }
    
    private var filteredOptions: [DraggableItem] {
        let items = createDraggableItems()
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func moveItem(from source: Int, to destination: Int) {
        let item = cryptoOptions[source]
        cryptoOptions.remove(at: source)
        cryptoOptions.insert(item, at: destination)
        saveOrder()
    }
    
    private func listItemView(for item: DraggableItem, index: Int) -> some View {
        HStack(spacing: 12) {
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            Image(systemName: item.icon)
                .foregroundColor(selectedTab == item.name ? .blue : .secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .fontWeight(selectedTab == item.name ? .medium : .regular)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(selectedTab == item.name ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onTapGesture {
            if !isEditing {
                selectedTab = item.name
            }
        }
        .opacity(draggedIndex == index ? 0.5 : 1.0)
        .onDrag {
            self.draggedIndex = index
            return NSItemProvider(object: "\(index)" as NSString)
        }
        .onDrop(of: [.plainText], delegate: DropViewDelegate(item: item,
                                                           currentIndex: index,
                                                           draggedIndex: $draggedIndex,
                                                           items: $cryptoOptions))
    }
    
    var body: some View {
        HSplitView {
            // 左侧导航栏
            VStack {
                // 列表
                List {
                    // 暂时注释掉编辑按钮
                    /*HStack {
                        Spacer()
                        // 编辑按钮
                        Button(action: { isEditing.toggle() }) {
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                                .foregroundColor(isEditing ? .blue : .secondary)
                        }
                        .buttonStyle(.borderless)
                        .help(isEditing ? "完成编辑" : "编辑顺序")
                    }
                    .padding(.horizontal, 8)*/
                    
                    ForEach(Array(filteredOptions.enumerated()), id: \.1.id) { index, option in
                        listItemView(for: option, index: index)
                            .animation(.easeInOut, value: isEditing)
                    }
                }
                .listStyle(SidebarListStyle())
            }
            .frame(width: 180)
            .background(Color(NSColor.controlBackgroundColor))
            .searchable(text: $searchText, placement: .toolbar, prompt: "搜索")
            
            // 右侧内容区
            Group {
                switch selectedTab {
                case "MD5":
                    MD5View()
                case "SHA":
                    SHAView()
                case "HMAC":
                    HMACView()
                case "AES":
                    AESView()
                case "DES":
                    DESView()
                case "RSA":
                    RSAView()
                case "Base64":
                    Base64View()
                case "URL":
                    URLView()
                case "Unicode":
                    UnicodeView()
                default:
                    MD5View()
                }
            }
            .frame(minWidth: 700, maxWidth: .infinity, minHeight: 00, maxHeight: .infinity)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            // 添加过渡动画
            .animation(.easeInOut, value: selectedTab)
        }
        .frame(minWidth: 960, minHeight: 680)
        .onAppear {
            // 打印当前选项列表
            print("Current crypto options:", cryptoOptions.map { $0.name })
            loadOrder()
        }
    }
    
    // 保存顺序到UserDefaults
    private func saveOrder() {
        let order = cryptoOptions.map { ["icon": $0.icon, "name": $0.name, "description": $0.description] }
        UserDefaults.standard.set(order, forKey: "cryptoOptionsOrder")
    }
    
    // 从UserDefaults加载顺序
    private func loadOrder() {
        guard let savedOrder = UserDefaults.standard.array(forKey: "cryptoOptionsOrder") as? [[String: String]] else {
            return // 如果没有保存的顺序，使用默认顺序
        }
        
        let loadedOptions = savedOrder.compactMap { dict -> (icon: String, name: String, description: String)? in
            guard let icon = dict["icon"],
                  let name = dict["name"],
                  let description = dict["description"] else {
                return nil
            }
            return (icon: icon, name: name, description: description)
        }
        
        // 确保加载的选项包含所有必需的项目
        let requiredNames = ["MD5", "SHA", "HMAC", "AES", "DES", "RSA", "Base64"]
        let loadedNames = loadedOptions.map { $0.name }
        
        if !loadedOptions.isEmpty && requiredNames.allSatisfy({ loadedNames.contains($0) }) {
            cryptoOptions = loadedOptions
        } else {
            // 如果保存的数据不完整，使用默认选项
            print("使用默认加密选项列表")
        }
    }
}

struct DropViewDelegate: DropDelegate {
    let item: ContentView.DraggableItem
    let currentIndex: Int
    @Binding var draggedIndex: Int?
    @Binding var items: [(icon: String, name: String, description: String)]
    
    func dropEntered(info: DropInfo) {
        guard let draggedIndex = self.draggedIndex,
              draggedIndex != currentIndex else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            let fromIndex = draggedIndex
            let toIndex = currentIndex
            let item = items[fromIndex]
            items.remove(at: fromIndex)
            items.insert(item, at: toIndex)
            self.draggedIndex = toIndex
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        self.draggedIndex = nil
        return true
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
}

#Preview {
    ContentView()
}
