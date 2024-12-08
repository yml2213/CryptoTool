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
    
    // 添加临时数据存储
    private let tempDataKey = "MD5View_TempData"
    
    init() {
        if let savedData = TempDataManager.shared.getData(forKey: tempDataKey) as? [String: String] {
            _inputText = State(initialValue: savedData["inputText"] ?? "")
        }
    }
    
    private func saveCurrentData() {
        let dataToSave: [String: String] = [
            "inputText": inputText
        ]
        TempDataManager.shared.saveData(dataToSave, forKey: tempDataKey)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 输入输出区域
            SharedViews.GroupBoxView {
                // 输入区域
                SharedViews.InputTextEditor(
                    title: "输入文本",
                    placeholder: "输入需要处理的文本",
                    text: $inputText,
                    onChange: { generateMD5() }
                )
                
                // 控制按钮
                SharedViews.ActionButtons(
                    primaryAction: { generateMD5() },
                    primaryLabel: "生成",
                    primaryIcon: "arrow.right.circle.fill",
                    clearAction: {
                        inputText = ""
                        generateMD5()
                    },
                    copyAction: {
                        let allResults = resultOrder.compactMap { key in
                            if let value = md5Results[key] {
                                return "\(key): \(value)"
                            }
                            return nil
                        }.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(allResults, forType: .string)
                    },
                    swapAction: nil,
                    isOutputEmpty: md5Results.isEmpty
                )
                
                // 结果显示
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
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            generateMD5()
        }
        .onChange(of: inputText) { _ in
            saveCurrentData()
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
