import SwiftUI
import CryptoKit
import CommonCrypto

struct HMACView: View {
    @State private var inputText: String = ""
    @State private var secretKey: String = ""
    @State private var hmacResults: [String: String] = [:]
    @Environment(\.colorScheme) var colorScheme
    
    private let algorithms = [
        "HMAC-MD5",
        "HMAC-SHA1",
        "HMAC-SHA256",
        "HMAC-SHA384",
        "HMAC-SHA512"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // 输入区域
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
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
                            generateHMAC()
                        }
                    
                    Label("密钥", systemImage: "key")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    TextField("请输入密钥", text: $secretKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: secretKey) { _, _ in
                            generateHMAC()
                        }
                }
            }
            
            // 控制按钮
            HStack(spacing: 12) {
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
                
                Spacer()
                
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
            .padding(.horizontal)
            
            // 输出区域
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Label("HMAC 结果", systemImage: "key.fill")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(algorithms.enumerated()), id: \.element) { index, key in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(key)
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .rounded))
                                
                                HStack(alignment: .top) {
                                    Text(hmacResults[key] ?? "")
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Button(action: {
                                        if let value = hmacResults[key] {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(value, forType: .string)
                                        }
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(hmacResults[key]?.isEmpty ?? true)
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
                }
            }
            
            Spacer()
        }
        .padding()
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
}

#Preview {
    HMACView()
} 