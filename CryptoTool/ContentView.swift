import SwiftUI

struct ContentView: View {
    @State private var selectedTab = "MD5"
    @State private var searchText = ""
    
    let cryptoOptions = [
        (icon: "number.circle", name: "MD5", description: "信息摘要算法"),
        (icon: "key.fill", name: "SHA", description: "安全散列算法"),
        (icon: "lock.fill", name: "HMAC", description: "哈希消息认证码"),
        (icon: "shield.fill", name: "RC4", description: "流加密算法"),
        (icon: "lock.shield.fill", name: "AES", description: "高级加密标准"),
        (icon: "key.horizontal.fill", name: "DES", description: "数据加密标准"),
        (icon: "key.horizontal", name: "3DES", description: "三重DES"),
        (icon: "doc.fill", name: "Base64", description: "基础编码"),
        (icon: "arrow.triangle.2.circlepath", name: "Rabbit", description: "流加密算法"),
        (icon: "key.viewfinder", name: "PBKDF2/EvpKDF", description: "密钥派生函数")
    ]
    
    var filteredOptions: [(icon: String, name: String, description: String)] {
        if searchText.isEmpty {
            return cryptoOptions
        }
        return cryptoOptions.filter { $0.name.localizedCaseInsensitiveContains(searchText) ||
                                    $0.description.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        HSplitView {
            // 左侧导航栏
            VStack {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // 选项列表
                List(filteredOptions, id: \.name) { option in
                    HStack(spacing: 12) {
                        Image(systemName: option.icon)
                            .foregroundColor(selectedTab == option.name ? .blue : .secondary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.name)
                                .fontWeight(selectedTab == option.name ? .medium : .regular)
                            Text(option.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .background(selectedTab == option.name ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                    .onTapGesture {
                        selectedTab = option.name
                    }
                }
                .listStyle(SidebarListStyle())
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor))
            
            // 右侧内容区
            Group {
                switch selectedTab {
                case "MD5":
                    MD5View()
                case "SHA":
                    Text("SHA View - Coming Soon")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))
                case "HMAC":
                    Text("HMAC View - Coming Soon")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))
                // ... 其他 case
                default:
                    MD5View()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

#Preview {
    ContentView()
}
