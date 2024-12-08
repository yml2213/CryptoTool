import SwiftUI
import CryptoKit
import CommonCrypto
import Security

// 添加RSA相关的错误类型
enum RSAError: Error, LocalizedError {
    case invalidKey
    case invalidKeyFormat
    case invalidKeySize
    case conversionFailed
    case extractionFailed
    case validationFailed
    case invalidInput
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "无效的密钥"
        case .invalidKeyFormat:
            return "密钥格式错误"
        case .invalidKeySize:
            return "密钥长度不正确"
        case .conversionFailed:
            return "密钥转换失败"
        case .extractionFailed:
            return "密钥提取失败"
        case .validationFailed:
            return "密钥对验证失败"
        case .invalidInput:
            return "输入数据格式错误"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        }
    }
}

struct RSAView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var publicKey: String = ""
    @State private var privateKey: String = ""
    @State private var isEncrypting: Bool = true
    @State private var selectedKeySize: Int = 1024
    @State private var selectedOutputEncoding: String = "Base64"
    @State private var publicExponent: String = "10001" // 默认值 65537
    
    private let keySizes = [1024, 2048, 4096]
    private let outputEncodings = ["Base64", "HEX", "HEX(无空格)"]
    private let paddingModes = ["PKCS1Padding", "Base64"]
    
    var body: some View {
        VStack(spacing: 16) {
            // 模式选择
            HStack(spacing: 20) {
                Picker("操作", selection: $isEncrypting) {
                    Text("加密").tag(true)
                    Text("解密").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .help(isEncrypting ? "使用公钥加密" : "使用私钥解密")
                
                Picker("密钥长度", selection: $selectedKeySize) {
                    ForEach(keySizes, id: \.self) { size in
                        Text("\(size)位").tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .help("选择RSA密钥长度")
            }
            .padding(.horizontal)
            
            // 密钥区域
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    // 公钥部分
                    HStack {
                        Label("公钥 Public Key", systemImage: "key")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            formatPublicKey()
                        }) {
                            Label("格式化", systemImage: "text.alignleft")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            compressPublicKey()
                        }) {
                            Label("压缩", systemImage: "arrow.down.right.and.arrow.up.left")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(publicKey, forType: .string)
                        }) {
                            Label("复制", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            publicKey = ""
                        }) {
                            Label("清空", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    TextEditor(text: $publicKey)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                    
                    // 私钥部分
                    HStack {
                        Label("私钥 Private Key", systemImage: "key.fill")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            formatPrivateKey()
                        }) {
                            Label("格式��", systemImage: "text.alignleft")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            compressPrivateKey()
                        }) {
                            Label("压缩", systemImage: "arrow.down.right.and.arrow.up.left")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(privateKey, forType: .string)
                        }) {
                            Label("复制", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            privateKey = ""
                        }) {
                            Label("清空", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    TextEditor(text: $privateKey)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                }
            }
            
            // 生成密钥对按钮
            Button(action: {
                generateKeyPair()
            }) {
                Label("生成密钥对", systemImage: "key.horizontal")
            }
            .buttonStyle(.bordered)
            .help("生成新的RSA密钥对")
            
            // 输入输出区域
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(isEncrypting ? "明文" : "密文", systemImage: "text.alignleft")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("输入需要\(isEncrypting ? "加密" : "解密")的文本")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                }
            }
            
            // 控制按钮
            HStack(spacing: 12) {
                // 左侧按钮组
                HStack(spacing: 12) {
                    Button(action: {
                        processRSA()
                    }) {
                        Label(isEncrypting ? "加密" : "解密", 
                              systemImage: "arrow.right.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .help(isEncrypting ? "使用公钥加密数据" : "使用私钥解密数据")
                    
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
                }
                
                Spacer()
                
                // 右侧格式选择器
                Picker("输出格式", selection: $selectedOutputEncoding) {
                    ForEach(outputEncodings, id: \.self) { encoding in
                        Text(encoding).tag(encoding)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }
            .padding(.horizontal)
            
            // 输出区域
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(isEncrypting ? "密文" : "明文", systemImage: "key.fill")
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
            
            // 修改密钥对校验按钮的位置和实现
            HStack(spacing: 12) {
                Button(action: {
                    do {
                        try validateKeyPair()
                    } catch {
                        outputText = "校验失败: \(error.localizedDescription)"
                    }
                }) {
                    Label("校验密钥对", systemImage: "checkmark.shield")
                }
                .buttonStyle(.bordered)
                .help("验证当前密钥对是否匹配")
                
                Button(action: {
                    do {
                        let privateKey = try parsePrivateKey()
                        let publicKey = try extractPublicKey(from: privateKey)
                        
                        // 导出公钥数据
                        var error: Unmanaged<CFError>?
                        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
                            throw RSAError.extractionFailed
                        }
                        
                        // 转换为PEM格式
                        var publicPEM = "-----BEGIN PUBLIC KEY-----\n"
                        publicPEM += publicKeyData.base64EncodedString().chunks(ofCount: 64).joined(separator: "\n")
                        publicPEM += "\n-----END PUBLIC KEY-----"
                        
                        self.publicKey = publicPEM
                        outputText = "从私钥提取公钥成功"
                    } catch {
                        outputText = "提取失败: \(error.localizedDescription)"
                    }
                }) {
                    Label("提取公钥", systemImage: "arrow.up.doc")
                }
                .buttonStyle(.bordered)
                .help("从私钥中提取对应的公钥")
                .disabled(privateKey.isEmpty)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onChange(of: selectedOutputEncoding) { _, _ in
            // 如果有输出内容，尝试转换格式
            guard !outputText.isEmpty else { return }
            do {
                // 先将当前输出转换为Data
                let data: Data
                switch selectedOutputEncoding {
                case "HEX", "HEX(无空格)":
                    let hex = outputText.replacingOccurrences(of: " ", with: "")
                    var tempData = Data()
                    var temp = ""
                    for char in hex {
                        temp += String(char)
                        if temp.count == 2 {
                            guard let num = UInt8(temp, radix: 16) else {
                                return
                            }
                            tempData.append(num)
                            temp = ""
                        }
                    }
                    if !temp.isEmpty {
                        return
                    }
                    data = tempData
                default: // Base64
                    guard let base64Data = Data(base64Encoded: outputText) else {
                        return
                    }
                    data = base64Data
                }
                
                // 转换为新格式
                switch selectedOutputEncoding {
                case "HEX":
                    outputText = data.map { String(format: "%02x", $0) }.joined(separator: " ")
                case "HEX(无空格)":
                    outputText = data.map { String(format: "%02x", $0) }.joined()
                default: // Base64
                    outputText = data.base64EncodedString()
                }
            } catch {
                // 转换失败时保持原样
            }
        }
        .onChange(of: selectedKeySize) { _, _ in
            // 清空现有密钥
            publicKey = ""
            privateKey = ""
            outputText = "密钥长度已更改，请重新生成密钥对"
        }
    }
    
    // 解析公钥
    private func parsePublicKey() throws -> SecKey {
        // 移除PEM格式的头尾和换行符
        var keyString = publicKey
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        // Base64解码
        guard let keyData = Data(base64Encoded: keyString) else {
            throw RSAError.invalidKeyFormat
        }
        
        // 创建密钥属性字典
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: selectedKeySize
        ]
        
        // 创建SecKey对象
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyData as CFData,
                                           attributes as CFDictionary,
                                           &error) else {
            throw RSAError.invalidKey
        }
        
        return key
    }
    
    // 解析私钥
    private func parsePrivateKey() throws -> SecKey {
        // 移除PEM格式的头尾和换行符
        var keyString = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        // Base64解码
        guard let keyData = Data(base64Encoded: keyString) else {
            throw RSAError.invalidKeyFormat
        }
        
        // 创建密钥属性字典
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: selectedKeySize
        ]
        
        // 创建SecKey对象
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyData as CFData,
                                           attributes as CFDictionary,
                                           &error) else {
            throw RSAError.invalidKey
        }
        
        return key
    }
    
    // 从私钥提取公钥
    private func extractPublicKey(from privateKey: SecKey) throws -> SecKey {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw RSAError.extractionFailed
        }
        return publicKey
    }
    
    // 验证密钥对
    private func validateKeyPair() throws {
        let privateKey = try parsePrivateKey()
        let publicKey = try parsePublicKey()
        
        // 生成测试数据
        let testString = "RSA Key Pair Validation Test"
        guard let testData = testString.data(using: .utf8) else {
            throw RSAError.validationFailed
        }
        
        // 使用公钥加密
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionPKCS1,
            testData as CFData,
            &error
        ) as Data? else {
            throw RSAError.validationFailed
        }
        
        // 使用私钥解密
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .rsaEncryptionPKCS1,
            encryptedData as CFData,
            &error
        ) as Data? else {
            throw RSAError.validationFailed
        }
        
        // 验证结果
        guard let decryptedString = String(data: decryptedData, encoding: .utf8),
              decryptedString == testString else {
            throw RSAError.validationFailed
        }
        
        outputText = "密钥对验证成功"
    }
    
    // 格式化密钥为PEM格式
    private func formatPublicKey() {
        var formatted = "-----BEGIN PUBLIC KEY-----\n"
        let chunks = publicKey.chunks(ofCount: 64)
        formatted += chunks.joined(separator: "\n")
        formatted += "\n-----END PUBLIC KEY-----"
        publicKey = formatted
    }
    
    // 格式化私钥为PEM格式
    private func formatPrivateKey() {
        var formatted = "-----BEGIN PRIVATE KEY-----\n"
        let chunks = privateKey.chunks(ofCount: 64)
        formatted += chunks.joined(separator: "\n")
        formatted += "\n-----END PRIVATE KEY-----"
        privateKey = formatted
    }
    
    // 压缩公钥（移除PEM格式和换行符）
    private func compressPublicKey() {
        publicKey = publicKey
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
    
    // 压缩私钥（移除PEM格式和换行符）
    private func compressPrivateKey() {
        privateKey = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
    
    // 在RSAView中添加生成密钥对的函数
    private func generateKeyPair() {
        // 创建密钥对属性字典
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: selectedKeySize,
            kSecPublicKeyAttrs as String: [
                kSecAttrIsPermanent as String: false
            ],
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: false
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let keyPair = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
              let publicKey = SecKeyCopyPublicKey(keyPair) else {
            outputText = "生成密钥对失败: \(error?.takeRetainedValue().localizedDescription ?? "未知错误")"
            return
        }
        
        // 导出公钥
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            outputText = "导出公钥失败: \(error?.takeRetainedValue().localizedDescription ?? "未知错误")"
            return
        }
        
        // 导出私钥
        guard let privateKeyData = SecKeyCopyExternalRepresentation(keyPair, &error) as Data? else {
            outputText = "导出私钥失败: \(error?.takeRetainedValue().localizedDescription ?? "未���错误")"
            return
        }
        
        // 转换为PEM格式
        var publicPEM = "-----BEGIN PUBLIC KEY-----\n"
        publicPEM += publicKeyData.base64EncodedString().chunks(ofCount: 64).joined(separator: "\n")
        publicPEM += "\n-----END PUBLIC KEY-----"
        
        var privatePEM = "-----BEGIN PRIVATE KEY-----\n"
        privatePEM += privateKeyData.base64EncodedString().chunks(ofCount: 64).joined(separator: "\n")
        privatePEM += "\n-----END PRIVATE KEY-----"
        
        // 更新UI
        DispatchQueue.main.async {
            self.publicKey = publicPEM
            self.privateKey = privatePEM
            self.outputText = "密钥对生成成功"
        }
    }
    
    // 添加processRSA函数
    private func processRSA() {
        do {
            if isEncrypting {
                // 加密流程
                let publicKey = try parsePublicKey()
                guard let data = inputText.data(using: .utf8) else {
                    throw RSAError.invalidInput
                }
                
                var error: Unmanaged<CFError>?
                guard let encryptedData = SecKeyCreateEncryptedData(
                    publicKey,
                    .rsaEncryptionPKCS1,
                    data as CFData,
                    &error
                ) as Data? else {
                    throw RSAError.encryptionFailed
                }
                
                // 根据选择的输出格式返回结果
                switch selectedOutputEncoding {
                case "HEX":
                    outputText = encryptedData.map { String(format: "%02x", $0) }.joined(separator: " ")
                case "HEX(无空格)":
                    outputText = encryptedData.map { String(format: "%02x", $0) }.joined()
                default: // Base64
                    outputText = encryptedData.base64EncodedString()
                }
            } else {
                // 解密流程
                let privateKey = try parsePrivateKey()
                
                // 根据输入格式解析数据
                let encryptedData: Data
                switch selectedOutputEncoding {
                case "HEX", "HEX(无空格)":
                    let hex = inputText.replacingOccurrences(of: " ", with: "").lowercased()
                    var data = Data()
                    var temp = ""
                    for char in hex {
                        temp += String(char)
                        if temp.count == 2 {
                            guard let num = UInt8(temp, radix: 16) else {
                                throw RSAError.invalidInput
                            }
                            data.append(num)
                            temp = ""
                        }
                    }
                    if !temp.isEmpty {
                        throw RSAError.invalidInput
                    }
                    encryptedData = data
                default: // Base64
                    guard let data = Data(base64Encoded: inputText) else {
                        throw RSAError.invalidInput
                    }
                    encryptedData = data
                }
                
                var error: Unmanaged<CFError>?
                guard let decryptedData = SecKeyCreateDecryptedData(
                    privateKey,
                    .rsaEncryptionPKCS1,
                    encryptedData as CFData,
                    &error
                ) as Data? else {
                    throw RSAError.decryptionFailed
                }
                
                guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                    throw RSAError.decryptionFailed
                }
                
                outputText = decryptedString
            }
        } catch {
            outputText = "处理失败: \(error.localizedDescription)"
        }
    }
    
    // 添加密钥格式化和压缩功能
    private func formatKey(_ key: String, isPublic: Bool) -> String {
        let header = isPublic ? "-----BEGIN PUBLIC KEY-----" : "-----BEGIN PRIVATE KEY-----"
        let footer = isPublic ? "-----END PUBLIC KEY-----" : "-----END PRIVATE KEY-----"
        
        let cleanKey = key
            .replacingOccurrences(of: header, with: "")
            .replacingOccurrences(of: footer, with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        var formatted = header + "\n"
        formatted += cleanKey.chunks(ofCount: 64).joined(separator: "\n")
        formatted += "\n" + footer
        return formatted
    }
    
    private func compressKey(_ key: String, isPublic: Bool) -> String {
        let header = isPublic ? "-----BEGIN PUBLIC KEY-----" : "-----BEGIN PRIVATE KEY-----"
        let footer = isPublic ? "-----END PUBLIC KEY-----" : "-----END PRIVATE KEY-----"
        
        return key
            .replacingOccurrences(of: header, with: "")
            .replacingOccurrences(of: footer, with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

// 辅助扩展，用于分割字符串
extension String {
    func chunks(ofCount count: Int) -> [String] {
        var chunks: [String] = []
        var remaining = self
        while !remaining.isEmpty {
            let chunk = String(remaining.prefix(count))
            chunks.append(chunk)
            remaining = String(remaining.dropFirst(count))
        }
        return chunks
    }
} 


#Preview {
    RSAView()
}
