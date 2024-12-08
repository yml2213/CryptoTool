import SwiftUI
import CryptoKit
import CommonCrypto

struct AESView: View {
    @State private var inputText: String = ""
    @State private var key: String = "0123456789abcdef"  // 16字节默认密钥
    @State private var iv: String = "0123456789abcdef"   // 16字节默认IV
    @State private var outputText: String = ""
    @State private var isEncrypting: Bool = true
    @State private var selectedMode: String = "CBC"      // 默认CBC模式
    @State private var selectedKeySize: Int = 128        // 默认128位
    @State private var selectedPadding: String = "PKCS7" // 默认PKCS7
    @State private var selectedKeyEncoding: String = "UTF8"
    @State private var selectedIVEncoding: String = "UTF8"
    @Environment(\.colorScheme) var colorScheme
    
    private let modes = ["ECB", "CBC"]
    private let keySizes = [128, 192, 256]
    private let paddings = ["PKCS7", "Zero", "None"]
    private let encodings = ["UTF8", "HEX", "Base64"]
    
    private var allValues: String {
        [
            inputText,
            key,
            iv,
            isEncrypting.description,
            selectedMode,
            selectedKeySize.description,
            selectedPadding,
            selectedKeyEncoding,
            selectedIVEncoding
        ].joined()
    }
    
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
                
                Picker("密钥长度", selection: $selectedKeySize) {
                    ForEach(keySizes, id: \.self) { size in
                        Text("\(size)位").tag(size)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("加密模式", selection: $selectedMode) {
                    ForEach(modes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("填充模式", selection: $selectedPadding) {
                    ForEach(paddings, id: \.self) { padding in
                        Text(padding).tag(padding)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            
            // 输入域
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label(isEncrypting ? "明文" : "密文", systemImage: "text.alignleft")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                    
                    // 固定高度的容器
                    VStack(alignment: .leading, spacing: 12) {
                        // 密钥部分
                        HStack {
                            Label("密钥 (\(selectedKeySize/8)字节)", systemImage: "key")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                let randomKey = generateRandomBytes(count: selectedKeySize/8)
                                key = formatToEncoding(randomKey, encoding: selectedKeyEncoding)
                            }) {
                                Label("生成", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(.bordered)
                            
                            Picker("密钥编码", selection: $selectedKeyEncoding) {
                                ForEach(encodings, id: \.self) { encoding in
                                    Text(encoding).tag(encoding)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 250)
                        }
                        
                        TextField("请输入密钥", text: $key)
                            .textFieldStyle(.roundedBorder)
                        
                        // IV部分 - 使用固定高度的容器
                        VStack(spacing: 12) {
                            HStack {
                                Label("初始向量(IV) (16字节)", systemImage: "number")
                                    .foregroundColor(.secondary)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    let randomIV = generateRandomBytes(count: 16)
                                    iv = formatToEncoding(randomIV, encoding: selectedIVEncoding)
                                }) {
                                    Label("生成", systemImage: "wand.and.stars")
                                }
                                .buttonStyle(.bordered)
                                
                                Picker("IV编码", selection: $selectedIVEncoding) {
                                    ForEach(encodings, id: \.self) { encoding in
                                        Text(encoding).tag(encoding)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 250)
                            }
                            
                            TextField("请输入IV", text: $iv)
                                .textFieldStyle(.roundedBorder)
                        }
                        .opacity(selectedMode == "ECB" ? 0 : 1)
                        .allowsHitTesting(selectedMode != "ECB") // 禁用ECB模式下的IV输入
                    }
                    .frame(height: 140) // 固定容器高度
                }
            }
            
            // 控制按钮
            HStack(spacing: 12) {
                Button(action: { processAES() }) {
                    Label(isEncrypting ? "加密" : "解密", 
                          systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    inputText = ""
                    outputText = ""
                    key = ""
                    iv = ""
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
                    Label(isEncrypting ? "密文" : "明文", systemImage: "key.fill")
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
        .onChange(of: allValues) { _, _ in
            processAES()
        }
        .onAppear {
            // 初始化时设置认值的编码格式
            if let defaultKeyData = key.data(using: .utf8) {
                key = formatToEncoding(defaultKeyData, encoding: selectedKeyEncoding)
            }
            if let defaultIVData = iv.data(using: .utf8) {
                iv = formatToEncoding(defaultIVData, encoding: selectedIVEncoding)
            }
            // 初始化时处理一次
            processAES()
        }
    }
    
    // 添加随机生成和格式化函数
    private func generateRandomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }
    
    private func formatToEncoding(_ data: Data, encoding: String) -> String {
        switch encoding {
        case "HEX":
            return data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
        case "Base64":
            return data.base64EncodedString()
        case "UTF8":
            // 如果UTF8转换失败，自动切换到HEX格式
            if let utf8String = String(data: data, encoding: .utf8) {
                return utf8String
            } else {
                // 自动切换到HEX格式并更新选择器
                DispatchQueue.main.async {
                    if selectedKeyEncoding == "UTF8" {
                        selectedKeyEncoding = "HEX"
                    }
                    if selectedIVEncoding == "UTF8" {
                        selectedIVEncoding = "HEX"
                    }
                }
                return data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
            }
        default:
            return data.map { String(format: "%02hhx", $0) }.joined(separator: " ")
        }
    }
    
    // 添加编码转换函数
    private func convertFromEncoding(_ text: String, encoding: String) throws -> Data {
        switch encoding {
        case "UTF8":
            guard let data = text.data(using: .utf8) else {
                throw AESError.invalidInput
            }
            return data
            
        case "HEX":
            let hex = text.replacingOccurrences(of: " ", with: "")
            var data = Data()
            var temp = ""
            
            for char in hex {
                temp += String(char)
                if temp.count == 2 {
                    guard let num = UInt8(temp, radix: 16) else {
                        throw AESError.invalidInput
                    }
                    data.append(num)
                    temp = ""
                }
            }
            
            if !temp.isEmpty {
                throw AESError.invalidInput
            }
            return data
            
        case "Base64":
            guard let data = Data(base64Encoded: text) else {
                throw AESError.invalidInput
            }
            return data
            
        default:
            throw AESError.invalidInput
        }
    }
    
    private func processAES() {
        guard !inputText.isEmpty && !key.isEmpty else {
            outputText = ""
            return
        }
        
        // 实现AES加密/解密逻辑
        do {
            if isEncrypting {
                outputText = try encryptAES(text: inputText, key: key, iv: iv)
            } else {
                outputText = try decryptAES(text: inputText, key: key, iv: iv)
            }
        } catch {
            outputText = "处理失败: \(error.localizedDescription)"
        }
    }
    
    private func encryptAES(text: String, key: String, iv: String) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw AESError.invalidInput
        }
        
        // 转换密钥和IV
        let keyData = try convertFromEncoding(key, encoding: selectedKeyEncoding)
        let ivData = selectedMode != "ECB" ? try convertFromEncoding(iv, encoding: selectedIVEncoding) : Data(count: kCCBlockSizeAES128)
        
        // 检查密钥长度
        guard keyData.count == selectedKeySize / 8 else {
            throw AESError.invalidKeySize
        }
        
        // 检查IV长度
        if selectedMode != "ECB" && ivData.count != kCCBlockSizeAES128 {
            throw AESError.invalidIV
        }
        
        // 设置加选项
        var options: CCOptions = 0
        
        // 设置模式
        switch selectedMode {
        case "ECB":
            options |= CCOptions(kCCOptionECBMode)
        case "CBC":
            break // CBC是默认模式
        default:
            throw AESError.invalidInput
        }
        
        // 设置填充
        switch selectedPadding {
        case "PKCS7":
            options |= CCOptions(kCCOptionPKCS7Padding)
        case "Zero":
            // Zero padding is handled manually if needed
            break
        case "None":
            if data.count % kCCBlockSizeAES128 != 0 {
                throw AESError.invalidInput
            }
        default:
            break
        }
        
        // 创建输出缓冲区
        let bufferSize = size_t(data.count + kCCBlockSizeAES128)
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted: size_t = 0
        
        // 选择AES算法
        let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES)
        
        let cryptStatus = keyData.withUnsafeBytes { keyBytes in
            ivData.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    CCCrypt(CCOperation(kCCEncrypt),
                           algorithm,
                           options,
                           keyBytes.baseAddress, keyData.count,
                           ivBytes.baseAddress,
                           dataBytes.baseAddress, data.count,
                           &buffer, bufferSize,
                           &numBytesEncrypted)
                }
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            throw AESError.encryptionFailed
        }
        
        let encryptedData = Data(buffer.prefix(numBytesEncrypted))
        return encryptedData.base64EncodedString()
    }
    
    private func decryptAES(text: String, key: String, iv: String) throws -> String {
        guard let data = Data(base64Encoded: text) else {
            throw AESError.invalidInput
        }
        
        // 转换密钥和IV
        let keyData = try convertFromEncoding(key, encoding: selectedKeyEncoding)
        let ivData = selectedMode != "ECB" ? try convertFromEncoding(iv, encoding: selectedIVEncoding) : Data(count: kCCBlockSizeAES128)
        
        // 检查密钥长度
        guard keyData.count == selectedKeySize / 8 else {
            throw AESError.invalidKeySize
        }
        
        // 检查IV长度
        if selectedMode != "ECB" && ivData.count != kCCBlockSizeAES128 {
            throw AESError.invalidIV
        }
        
        // 设置解密选项
        var options: CCOptions = 0
        
        // 设置模式
        switch selectedMode {
        case "ECB":
            options |= CCOptions(kCCOptionECBMode)
        case "CBC":
            break // CBC是默认模式
        default:
            throw AESError.invalidInput
        }
        
        // 设置填充
        switch selectedPadding {
        case "PKCS7":
            options |= CCOptions(kCCOptionPKCS7Padding)
        case "Zero", "None":
            if data.count % kCCBlockSizeAES128 != 0 {
                throw AESError.invalidInput
            }
        default:
            break
        }
        
        // 创建输出缓冲区
        let bufferSize = size_t(data.count + kCCBlockSizeAES128)
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted: size_t = 0
        
        // 选择AES算法
        let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES)
        
        let cryptStatus = keyData.withUnsafeBytes { keyBytes in
            ivData.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    CCCrypt(CCOperation(kCCDecrypt),
                           algorithm,
                           options,
                           keyBytes.baseAddress, keyData.count,
                           ivBytes.baseAddress,
                           dataBytes.baseAddress, data.count,
                           &buffer, bufferSize,
                           &numBytesDecrypted)
                }
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            throw AESError.decryptionFailed
        }
        
        let decryptedData = Data(buffer.prefix(numBytesDecrypted))
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
}

// 错误类型定义
enum AESError: Error, LocalizedError {
    case invalidInput
    case invalidKeySize
    case invalidIV
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "输入数据格式错误"
        case .invalidKeySize:
            return "密钥长度不正确"
        case .invalidIV:
            return "IV长度必须为16字节"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        }
    }
}

#Preview {
    AESView()
} 