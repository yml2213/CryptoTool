import SwiftUI

struct Base64View: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // 输入输出区域
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("输入文本", systemImage: "text.alignleft")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("输入需要处理的文本")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                    
                    // 控制按钮
                    HStack(spacing: 12) {
                        // 左侧按钮组
                        HStack(spacing: 12) {
                            Button(action: {
                                do {
                                    guard let data = inputText.data(using: .utf8) else {
                                        outputText = "编码失败"
                                        return
                                    }
                                    outputText = data.base64EncodedString()
                                }
                            }) {
                                Label("编码", systemImage: "arrow.right.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .help("Base64编码")
                            
                            Button(action: {
                                do {
                                    guard let data = Data(base64Encoded: inputText) else {
                                        outputText = "解码失败"
                                        return
                                    }
                                    outputText = String(data: data, encoding: .utf8) ?? "解码失败"
                                }
                            }) {
                                Label("解码", systemImage: "arrow.left.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .help("Base64解码")
                            
                            Button(action: {
                                inputText = ""
                                outputText = ""
                            }) {
                                Label("清空", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .help("清空输入和输出")
                            
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(outputText, forType: .string)
                            }) {
                                Label("复制结果", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            .disabled(outputText.isEmpty)
                            .help("将结果复制到剪贴板")
                            
                            Button(action: {
                                let temp = inputText
                                inputText = outputText
                                outputText = temp
                            }) {
                                Label("互换", systemImage: "arrow.up.arrow.down")
                            }
                            .buttonStyle(.bordered)
                            .help("交换输入和输出的位置")
                            .disabled(outputText.isEmpty)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // 输出结果
                    HStack {
                        Label("处理结果", systemImage: "text.alignleft")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        
                        Spacer()
                        
                        if !outputText.isEmpty {
                            Text("处理完成")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    Text(outputText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: inputText) { _, _ in
            guard !inputText.isEmpty else {
                outputText = ""
                return
            }
            // 默认进行编码
            guard let data = inputText.data(using: .utf8) else {
                outputText = "编码失败"
                return
            }
            outputText = data.base64EncodedString()
        }
    }
}

#Preview {
    Base64View()
} 