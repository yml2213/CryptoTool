import SwiftUI
import CryptoKit

// MD5长度选项
enum MD5Length: String, CaseIterable {
    case md5_16 = "16位"
    case md5_32 = "32位"
}

struct MD5View: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isUppercase: Bool = true
    @State private var isReversed: Bool = false
    @State private var md5Length: MD5Length = .md5_32
    
    var body: some View {
        VStack(spacing: 10) {
            // 输入区域
            GroupBox(label: Text("输入")) {
                TextEditor(text: $inputText)
                    .frame(height: 200)
            }
            
            // 控制面板
            HStack {
                Button("生成") {
                    generateMD5()
                }
                
                Button("清空") {
                    inputText = ""
                    outputText = ""
                }
                
                Divider()
                
                Picker("MD5长度", selection: $md5Length) {
                    ForEach(MD5Length.allCases, id: \.self) { length in
                        Text(length.rawValue).tag(length)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Divider()
                
                Toggle("大写", isOn: $isUppercase)
                    .toggleStyle(.switch)
                    .onChange(of: isUppercase) { _, _ in
                        if !outputText.isEmpty {
                            generateMD5()
                        }
                    }
                
                Toggle("反转", isOn: $isReversed)
                    .toggleStyle(.switch)
                    .onChange(of: isReversed) { _, _ in
                        if !outputText.isEmpty {
                            generateMD5()
                        }
                    }
            }
            .padding()
            
            // 输出区域
            GroupBox(label: Text("输出")) {
                TextEditor(text: .constant(outputText))
                    .frame(height: 200)
            }
            
            // 复制按钮
            if !outputText.isEmpty {
                Button("复制结果") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(outputText, forType: .string)
                }
                .padding(.top, 5)
            }
        }
    }
    
    // MD5计算函数
    private func generateMD5() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        guard let inputData = inputText.data(using: .utf8) else {
            outputText = "转换失败"
            return
        }
        
        // 计算MD5
        let computed = Insecure.MD5.hash(data: inputData)
        var hashString = computed.map { String(format: "%02hhx", $0) }.joined()
        
        // 处理大小写
        hashString = isUppercase ? hashString.uppercased() : hashString.lowercased()
        
        // 处理16位/32位
        if md5Length == .md5_16 {
            let startIndex = hashString.index(hashString.startIndex, offsetBy: 8)
            let endIndex = hashString.index(startIndex, offsetBy: 16)
            hashString = String(hashString[startIndex..<endIndex])
        }
        
        // 处理反转
        if isReversed {
            hashString = String(hashString.reversed())
        }
        
        outputText = hashString
    }
}

#Preview {
    MD5View()
}
