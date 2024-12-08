import SwiftUI
import CryptoKit
import CommonCrypto

struct HMACView: View {
    @State private var inputText: String = ""
    @State private var secretKey: String = "01234567"
    @State private var hmacResults: [String: String] = [:]
    @Environment(\.colorScheme) var colorScheme
    
    private let algorithms = [
        "HMAC-MD5",
        "HMAC-SHA1",
        "HMAC-SHA256",
        "HMAC-SHA384",
        "HMAC-SHA512"
    ]
    
    // 添加计算属性用于监听输入变化
    private var allValues: String {
        [inputText, secretKey].joined()
    }
    
    // 在 struct HMACView 开头添加存储键
    private let tempDataKey = "HMACView_TempData"
    
    init() {
        // 从临时存储中恢复数据
        if let savedData = TempDataManager.shared.getData(forKey: tempDataKey) as? [String: String] {
            _inputText = State(initialValue: savedData["inputText"] ?? "")
            _secretKey = State(initialValue: savedData["key"] ?? "")
            // ... 其他需要恢复的数据
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SharedViews.GroupBoxView {
                SharedViews.InputTextEditor(
                    title: "输入文本",
                    placeholder: "输入需要处理的文本",
                    text: $inputText,
                    onChange: { generateHMAC() }
                )
                
                SharedViews.KeyInput(
                    title: "密钥",
                    systemImage: "key",
                    text: $secretKey,
                    placeholder: "请输入密钥",
                    help: "输入用于HMAC计算的密钥"
                )
                
                HStack {
                    Button(action: { generateHMAC() }) {
                        Label("生成", systemImage: "arrow.right.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        inputText = ""
                        secretKey = ""
                        generateHMAC()
                    }) {
                        Label("清空", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        let allResults = algorithms.compactMap { key in
                            if let value = hmacResults[key] {
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
                    .disabled(hmacResults.isEmpty)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("HMAC 结果", systemImage: "key.fill")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(algorithms.enumerated()), id: \.element) { index, key in
                            HStack {
                                Text(key)
                                    .frame(width: 120, alignment: .leading)
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .rounded))
                                
                                Text(hmacResults[key] ?? "")
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    if let value = hmacResults[key] {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(value, forType: .string)
                                    }
                                }) {
                                    Label("复制", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.borderless)
                                .disabled(hmacResults[key]?.isEmpty ?? true)
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
        .onChange(of: allValues) { _, _ in
            generateHMAC()
        }
        .onChange(of: inputText) { _ in
            saveCurrentData()
        }
        .onChange(of: secretKey) { _ in
            saveCurrentData()
        }
        .onAppear {
            generateHMAC()
        }
    }
    
    private func generateHMAC() {
        guard !inputText.isEmpty && !secretKey.isEmpty else {
            hmacResults = Dictionary(uniqueKeysWithValues: algorithms.map { ($0, "") })
            return
        }
        
        guard let messageData = inputText.data(using: .utf8),
              let keyData = secretKey.data(using: .utf8) else {
            hmacResults = Dictionary(uniqueKeysWithValues: algorithms.map { ($0, "数据转换失败") })
            return
        }
        
        // 计算各种HMAC值
        hmacResults = [
            "HMAC-MD5": HMACMD5(key: keyData, message: messageData),
            "HMAC-SHA1": HMACSHA1(key: keyData, message: messageData),
            "HMAC-SHA256": HMACSHA256(key: keyData, message: messageData),
            "HMAC-SHA384": HMACSHA384(key: keyData, message: messageData),
            "HMAC-SHA512": HMACSHA512(key: keyData, message: messageData)
        ]
    }
    
    // HMAC计算辅助函数
    private func HMACMD5(key: Data, message: Data) -> String {
        var context = CCHmacContext()
        CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgMD5), [UInt8](key), key.count)
        CCHmacUpdate(&context, [UInt8](message), message.count)
        var hmac = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CCHmacFinal(&context, &hmac)
        return hmac.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func HMACSHA1(key: Data, message: Data) -> String {
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: message, using: SymmetricKey(data: key))
        return hmac.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func HMACSHA256(key: Data, message: Data) -> String {
        let hmac = HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: key))
        return hmac.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func HMACSHA384(key: Data, message: Data) -> String {
        let hmac = HMAC<SHA384>.authenticationCode(for: message, using: SymmetricKey(data: key))
        return hmac.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func HMACSHA512(key: Data, message: Data) -> String {
        let hmac = HMAC<SHA512>.authenticationCode(for: message, using: SymmetricKey(data: key))
        return hmac.map { String(format: "%02hhx", $0) }.joined()
    }
    
    // 添加保存数据的方法
    private func saveCurrentData() {
        let dataToSave: [String: String] = [
            "inputText": inputText,
            "key": secretKey
            // ... 其他需要保存的数据
        ]
        TempDataManager.shared.saveData(dataToSave, forKey: tempDataKey)
    }
}

#Preview {
    HMACView()
} 