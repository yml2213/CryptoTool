import SwiftUI
import CryptoKit

struct MD5View: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var md5Results: [String: String] = [:]
    
    // 定义固定顺序
    private let resultOrder = [
        "32位 小写",
        "32位 大写",
        "32位 反转",
        "32位 大写反转",
        "16位 小写",
        "16位 反转"
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            // 输入区域
            GroupBox(label: Text("输入")) {
                TextEditor(text: $inputText)
                    .frame(minHeight: 60, maxHeight: 200) // 默认约3行高度，最大200
                    .lineLimit(3...10) // 默认显示3行，最多10行
                    .onChange(of: inputText) { _, _ in
                        generateMD5()
                    }
            }
            
            // 控制按钮
            HStack {
                Button("生成") {
                    generateMD5()
                }
                
                Button("清空") {
                    inputText = ""
                    generateMD5()
                }
                
                Spacer()
                
                Button("复制全部") {
                    let allResults = resultOrder.compactMap { key in
                        if let value = md5Results[key] {
                            return "\(key): \(value)"
                        }
                        return nil
                    }.joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(allResults, forType: .string)
                }
                .disabled(md5Results.isEmpty)
            }
            .padding(.horizontal)
            
            // 输出区域
            GroupBox(label: Text("输出")) {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(resultOrder, id: \.self) { key in
                            HStack {
                                Text(key)
                                    .frame(width: 120, alignment: .leading)
                                    .foregroundColor(.secondary)
                                
                                Text(md5Results[key] ?? "")
                                    .textSelection(.enabled)
                                
                                Spacer()
                                
                                Button("复制") {
                                    if let value = md5Results[key] {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(value, forType: .string)
                                    }
                                }
                                .buttonStyle(.borderless)
                                .disabled(md5Results[key]?.isEmpty ?? true)
                            }
                            .padding(.horizontal)
                            
                            if key != resultOrder.last {
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 300)
            }
        }
        .onAppear {
            // 初始化空结果
            generateMD5()
        }
    }
    
    private func generateMD5() {
        guard !inputText.isEmpty else {
            // 初始化所有格式为空字符串
            md5Results = Dictionary(uniqueKeysWithValues: resultOrder.map { ($0, "") })
            return
        }
        
        guard let inputData = inputText.data(using: .utf8) else {
            md5Results = Dictionary(uniqueKeysWithValues: resultOrder.map { ($0, "转换失败") })
            return
        }
        
        // 计算基础MD5
        let computed = Insecure.MD5.hash(data: inputData)
        let md5_32 = computed.map { String(format: "%02hhx", $0) }.joined()
        
        // 生成所有格式，按指定顺序
        let md5_16 = {
            let start = md5_32.index(md5_32.startIndex, offsetBy: 8)
            let end = md5_32.index(start, offsetBy: 16)
            return String(md5_32[start..<end])
        }()
        
        md5Results = [
            "32位 小写": md5_32,
            "32位 大写": md5_32.uppercased(),
            "32位 反转": String(md5_32.reversed()),
            "32位 大写反转": String(md5_32.uppercased().reversed()),
            "16位 小写": md5_16,
            "16位 反转": String(md5_16.reversed())
        ]
    }
}

#Preview {
    MD5View()
}
