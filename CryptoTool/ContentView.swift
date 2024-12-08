import SwiftUI

struct ContentView: View {
    @State private var selectedTab = "MD5"
    @State private var searchText = ""
    
    let cryptoOptions = [
        (icon: "number.circle", name: "MD5", description: "信息摘要算法"),
        (icon: "key.fill", name: "SHA", description: "安全散列算法"),
        (icon: "lock.fill", name: "HMAC", description: "哈希消息认证码"),
        (icon: "lock.shield.fill", name: "AES", description: "高级加密标准"),
        (icon: "key.horizontal.fill", name: "DES", description: "数据加密标准"),
        (icon: "doc.fill", name: "Base64", description: "基础编码")
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
            .frame(width: 220)
            .background(Color(NSColor.controlBackgroundColor))
            
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
                case "Base64":
                    Base64View()
                default:
                    MD5View()
                }
            }
            .frame(minWidth: 700, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            // 添加过渡动画
            .animation(.easeInOut, value: selectedTab)
        }
        .frame(minWidth: 960, minHeight: 680)
    }
}

#Preview {
    ContentView()
}
