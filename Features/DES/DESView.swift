import SwiftUI
import CryptoKit
import CommonCrypto

struct DESView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var key: String = "01234567"  // 8字节默认密钥
    @State private var iv: String = "01234567"   // 8字节默认IV
    @State private var selectedMode: String = "CBC"      // 默认CBC模式
    @State private var selectedPadding: String = "PKCS7" // 默认PKCS7
    @State private var selectedKeyEncoding: String = "UTF8"
    @State private var selectedIVEncoding: String = "UTF8"
    @State private var selectedOutputEncoding: String = "Base64"
    @Environment(\.colorScheme) var colorScheme
    
    private let modes = ["ECB", "CBC"]
    private let paddings = ["PKCS7", "Zero", "None"]
    private let encodings = ["UTF8", "HEX", "Base64"]
    private let outputEncodings = ["Base64", "HEX", "HEX(无空格)"]
    
    private let tooltips = [
        "ecb": "ECB模式安全性较低，不推荐在实际应用中使用",
        "cbc": "CBC模式需要初始向量(IV)，安全性较高",
        "pkcs7": "PKCS7填充是最常用的填充方式",
        "zero": "零填充会在末尾补0",
        "none": "无填充要求数据长度必须是8的倍数"
    ]
    
    private var allValues: String {
        [
            inputText,
            key,
            iv,
            selectedMode,
            selectedPadding,
            selectedKeyEncoding,
            selectedIVEncoding,
            selectedOutputEncoding
        ].joined()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 模式选择
            HStack(spacing: 20) {
                Picker("加密模式", selection: $selectedMode) {
                    ForEach(modes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .help(tooltips[selectedMode.lowercased()] ?? "")
                
                Picker("填充模式", selection: $selectedPadding) {
                    ForEach(paddings, id: \.self) { padding in
                        Text(padding).tag(padding)
                    }
                }
                .pickerStyle(.segmented)
                .help(tooltips[selectedPadding.lowercased()] ?? "")
            }
            .padding(.horizontal)
            
            // 密钥和IV设置区域
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    // 密钥部分
                    HStack {
                        Label("密钥 (8字节)", systemImage: "key")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        
                        Text("当前编码: \(selectedKeyEncoding)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Spacer()
                        
                        Button(action: {
                            let randomKey = generateRandomBytes(count: kCCKeySizeDES)
                            key = formatToEncoding(randomKey, encoding: selectedKeyEncoding)
                        }) {
                            Label("生成随机密钥", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.bordered)
                        .help("生成一个随机的8字节密钥")
                        
                        Picker("密钥编码", selection: $selectedKeyEncoding) {
                            ForEach(encodings, id: \.self) { encoding in
                                Text(encoding).tag(encoding)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 250)
                        .help("选择密钥的编码格式")
                    }
                    
                    TextField("请输入密钥", text: $key)
                        .textFieldStyle(.roundedBorder)
                        .help("输入8字节的密钥")
                    
                    // IV部分
                    VStack(spacing: 12) {
                        HStack {
                            Label("初始向量(IV) (8字节)", systemImage: "number")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            
                            Text("当前编码: \(selectedIVEncoding)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Spacer()
                            
                            Button(action: {
                                let randomIV = generateRandomBytes(count: kCCBlockSizeDES)
                                iv = formatToEncoding(randomIV, encoding: selectedIVEncoding)
                            }) {
                                Label("生成随机IV", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(.bordered)
                            .help("生成一个随机的8字节IV")
                            
                            Picker("IV编码", selection: $selectedIVEncoding) {
                                ForEach(encodings, id: \.self) { encoding in
                                    Text(encoding).tag(encoding)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 250)
                            .help("选择IV的编码格式")
                        }
                        
                        TextField("请输入IV", text: $iv)
                            .textFieldStyle(.roundedBorder)
                            .help("输入8字节的初始向量")
                    }
                    .opacity(selectedMode == "ECB" ? 0 : 1)
                    .allowsHitTesting(selectedMode != "ECB")
                }
            }
            
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
                                    outputText = try encryptDES(text: inputText, key: key, iv: iv)
                                } catch {
                                    outputText = "加密失败: \(error.localizedDescription)"
                                }
                            }) {
                                Label("加密", systemImage: "lock.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .help("使用当前设置加密数据")
                            
                            Button(action: {
                                do {
                                    outputText = try decryptDES(text: inputText, key: key, iv: iv)
                                } catch {
                                    outputText = "解密失败: \(error.localizedDescription)"
                                }
                            }) {
                                Label("解密", systemImage: "lock.open.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .help("使用当前设置解密数据")
                            
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
        .onChange(of: allValues) { _, _ in
            if !inputText.isEmpty {
                do {
                    outputText = try encryptDES(text: inputText, key: key, iv: iv)
                } catch {
                    outputText = "处理失败: \(error.localizedDescription)"
                }
            } else {
                outputText = ""
            }
        }
        .onAppear {
            // 初始化时设置默认值的编码格式
            if let defaultKeyData = key.data(using: .utf8) {
                key = formatToEncoding(defaultKeyData, encoding: selectedKeyEncoding)
            }
            if let defaultIVData = iv.data(using: .utf8) {
                iv = formatToEncoding(defaultIVData, encoding: selectedIVEncoding)
            }
            // 初始化时如果有输入则处理
            if !inputText.isEmpty {
                do {
                    outputText = try encryptDES(text: inputText, key: key, iv: iv)
                } catch {
                    outputText = "处理失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func encryptDES(text: String, key: String, iv: String) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw DESError.invalidInput
        }
        
        // 转换密钥和IV
        let keyData = try convertFromEncoding(key, encoding: selectedKeyEncoding)
        let ivData = selectedMode != "ECB" ? try convertFromEncoding(iv, encoding: selectedIVEncoding) : Data(count: kCCBlockSizeDES)
        
        // 检查密钥长度
        guard keyData.count == kCCKeySizeDES else {
            throw DESError.invalidKeySize
        }
        
        // 检查IV长度
        if selectedMode != "ECB" && ivData.count != kCCBlockSizeDES {
            throw DESError.invalidIV
        }
        
        // 设置加密选项
        var options: CCOptions = 0
        
        // 设置模式
        if selectedMode == "ECB" {
            options |= CCOptions(kCCOptionECBMode)
        }
        
        // 设置填充
        switch selectedPadding {
        case "PKCS7":
            options |= CCOptions(kCCOptionPKCS7Padding)
        case "Zero":
            // Zero padding is handled manually if needed
            break
        case "None":
            if data.count % 8 != 0 {
                throw DESError.invalidInput
            }
        default:
            break
        }
        
        // 创建输出缓冲区
        let bufferSize = size_t(data.count + kCCBlockSizeDES)
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted: size_t = 0
        
        let cryptStatus = keyData.withUnsafeBytes { keyBytes in
            ivData.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    CCCrypt(CCOperation(kCCEncrypt),
                           CCAlgorithm(kCCAlgorithmDES),
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
            throw DESError.encryptionFailed
        }
        
        let encryptedData = Data(buffer.prefix(numBytesEncrypted))
        // 根据选择的输出格式返回结果
        switch selectedOutputEncoding {
        case "HEX":
            return encryptedData.map { String(format: "%02x", $0) }.joined(separator: " ")
        case "HEX(无空格)":
            return encryptedData.map { String(format: "%02x", $0) }.joined()
        default: // Base64
            return encryptedData.base64EncodedString()
        }
    }
    
    private func decryptDES(text: String, key: String, iv: String) throws -> String {
        // 根据当前输出格式解析输入
        let data: Data
        switch selectedOutputEncoding {
        case "HEX", "HEX(无空格)":
            let hex = text.replacingOccurrences(of: " ", with: "").lowercased()
            var tempData = Data()
            var temp = ""
            
            for char in hex {
                temp += String(char)
                if temp.count == 2 {
                    guard let num = UInt8(temp, radix: 16) else {
                        throw DESError.invalidInput
                    }
                    tempData.append(num)
                    temp = ""
                }
            }
            
            if !temp.isEmpty {
                throw DESError.invalidInput
            }
            data = tempData
        default: // Base64
            guard let base64Data = Data(base64Encoded: text) else {
                throw DESError.invalidInput
            }
            data = base64Data
        }
        
        // 转换密钥和IV
        let keyData = try convertFromEncoding(key, encoding: selectedKeyEncoding)
        let ivData = selectedMode != "ECB" ? try convertFromEncoding(iv, encoding: selectedIVEncoding) : Data(count: kCCBlockSizeDES)
        
        // 检查密钥长度
        guard keyData.count == kCCKeySizeDES else {
            throw DESError.invalidKeySize
        }
        
        // 检查IV长度
        if selectedMode != "ECB" && ivData.count != kCCBlockSizeDES {
            throw DESError.invalidIV
        }
        
        // 设置解密选项
        var options: CCOptions = 0
        
        // 设置模式
        if selectedMode == "ECB" {
            options |= CCOptions(kCCOptionECBMode)
        }
        
        // 设置填充
        switch selectedPadding {
        case "PKCS7":
            options |= CCOptions(kCCOptionPKCS7Padding)
        case "Zero", "None":
            if data.count % 8 != 0 {
                throw DESError.invalidInput
            }
        default:
            break
        }
        
        // 创建输出缓冲区
        let bufferSize = size_t(data.count + kCCBlockSizeDES)
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = keyData.withUnsafeBytes { keyBytes in
            ivData.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    CCCrypt(CCOperation(kCCDecrypt),
                           CCAlgorithm(kCCAlgorithmDES),
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
            throw DESError.decryptionFailed
        }
        
        let decryptedData = Data(buffer.prefix(numBytesDecrypted))
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
    
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
        default: // UTF8
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
    
    private func convertFromEncoding(_ text: String, encoding: String) throws -> Data {
        switch encoding {
        case "UTF8":
            guard let data = text.data(using: .utf8) else {
                throw DESError.invalidInput
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
                        throw DESError.invalidInput
                    }
                    data.append(num)
                    temp = ""
                }
            }
            
            if !temp.isEmpty {
                throw DESError.invalidInput
            }
            return data
            
        case "Base64":
            guard let data = Data(base64Encoded: text) else {
                throw DESError.invalidInput
            }
            return data
            
        default:
            throw DESError.invalidInput
        }
    }
}

enum DESError: Error, LocalizedError {
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
            return "IV长度必须为8字节"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        }
    }
}

#Preview {
    DESView()
} 
