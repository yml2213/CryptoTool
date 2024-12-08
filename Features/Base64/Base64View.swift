import SwiftUI

struct Base64View: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isEncoding: Bool = true
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // 模式选择
            Picker("模式", selection: $isEncoding) {
                Text("编码").tag(true)
                Text("解码").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
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
                            processBase64()
                        }
                }
            }
            .frame(height: 140)
            
            // 控制按钮
            HStack(spacing: 12) {
                Button(action: { processBase64() }) {
                    Label(isEncoding ? "编码" : "解码", 
                          systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    inputText = ""
                    outputText = ""
                }) {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(outputText, forType: .string)
                }) {
                    Label("复制结果", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .disabled(outputText.isEmpty)
            }
            .padding(.horizontal)
            
            // 输出区域
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Base64 结果", systemImage: "key.fill")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
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
        .onAppear {
            processBase64()
        }
    }
    
    private func processBase64() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        if isEncoding {
            guard let data = inputText.data(using: .utf8) else {
                outputText = "编码失败"
                return
            }
            outputText = data.base64EncodedString()
        } else {
            guard let data = Data(base64Encoded: inputText) else {
                outputText = "解码失败"
                return
            }
            outputText = String(data: data, encoding: .utf8) ?? "解码失败"
        }
    }
}

#Preview {
    Base64View()
} 