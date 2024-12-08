import SwiftUI
import CryptoKit

struct SHAView: View {
    @State private var inputText: String = ""
    @State private var shaResults: [String: String] = [:]
    @Environment(\.colorScheme) var colorScheme
    
    // 定义显示顺序
    private let resultOrder = [
        "SHA1",
        "SHA256", 
        "SHA384",
        "SHA512"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // 输入区域
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("输入文本", systemImage: "text.alignleft")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .onChange(of: inputText) { _, _ in
                            generateSHA()
                        }
                }
            }
            .frame(height: 140)
            
            // 控制按钮
            HStack(spacing: 12) {
                Button(action: { generateSHA() }) {
                    Label("生成", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    inputText = ""
                    generateSHA()
                }) {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: {
                    let allResults = resultOrder.compactMap { key in
                        if let value = shaResults[key] {
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
                .disabled(shaResults.isEmpty)
            }
            .padding(.horizontal)
            
            // 输出区域
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("SHA 结果", systemImage: "key.fill")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(resultOrder.enumerated()), id: \.element) { index, key in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(key)
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .rounded))
                                
                                HStack(alignment: .top) {
                                    Text(shaResults[key] ?? "")
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Button(action: {
                                        if let value = shaResults[key] {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(value, forType: .string)
                                        }
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(shaResults[key]?.isEmpty ?? true)
                                }
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
            
            Spacer()
        }
        .padding()
        .onAppear {
            generateSHA()
        }
    }
    
    private func generateSHA() {
        guard !inputText.isEmpty else {
            shaResults = Dictionary(uniqueKeysWithValues: resultOrder.map { ($0, "") })
            return
        }
        
        guard let inputData = inputText.data(using: .utf8) else {
            shaResults = Dictionary(uniqueKeysWithValues: resultOrder.map { ($0, "转换失败") })
            return
        }
        
        // 计算各种SHA值
        shaResults = [
            "SHA1": Insecure.SHA1.hash(data: inputData).map { String(format: "%02hhx", $0) }.joined(),
            "SHA256": SHA256.hash(data: inputData).map { String(format: "%02hhx", $0) }.joined(),
            "SHA384": SHA384.hash(data: inputData).map { String(format: "%02hhx", $0) }.joined(),
            "SHA512": SHA512.hash(data: inputData).map { String(format: "%02hhx", $0) }.joined()
        ]
    }
}

#Preview {
    SHAView()
}