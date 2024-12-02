import SwiftUI
import CryptoKit

struct MD5View: View {
    @State private var inputText: String = ""
    @State private var md5Results: [String: String] = [:]
    @Environment(\.colorScheme) var colorScheme
    
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
        VStack(spacing: 16) {
            // 输入区域 - 固定高度
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("输入文本", systemImage: "text.alignleft")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 80) // 固定高度
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .onChange(of: inputText) { _, _ in
                            generateMD5()
                        }
                }
            }
            .frame(height: 140) // 固定整个输入区域的高度
            
            // 控制按钮
            HStack(spacing: 12) {
                Button(action: { generateMD5() }) {
                    Label("生成", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    inputText = ""
                    generateMD5()
                }) {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: {
                    let allResults = resultOrder.compactMap { key in
                        if let value = md5Results[key] {
                            return "\(key): \(value)"
                        }
                        return nil
                    }.joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(allResults, forType: .string)
                }) {
                    Label("复制全部", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .disabled(md5Results.isEmpty)
            }
            .padding(.horizontal)
            
            // 输出区域 - 斑马纹理
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("MD5 结果", systemImage: "key.fill")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(resultOrder.enumerated()), id: \.element) { index, key in
                            HStack {
                                Text(key)
                                    .frame(width: 120, alignment: .leading)
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .rounded))
                                
                                Text(md5Results[key] ?? "")
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    if let value = md5Results[key] {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(value, forType: .string)
                                    }
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .disabled(md5Results[key]?.isEmpty ?? true)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(index % 2 == 0 ?
                                      Color(NSColor.controlBackgroundColor) :
                                      Color(NSColor.controlBackgroundColor).opacity(0.5))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.vertical, 4)
                }
            }
            
            Spacer() // 让内容固定在顶部
        }
        .padding()
        .onAppear {
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
