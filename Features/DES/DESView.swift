import SwiftUI
import CryptoKit
import CommonCrypto

struct DESView: View {
    @State private var inputText: String = ""
    @State private var key: String = ""
    @State private var iv: String = ""
    @State private var outputText: String = ""
    @State private var isEncrypting: Bool = true
    @State private var selectedMode: String = "CBC"
    @State private var selectedKeyType: String = "DES"
    @State private var selectedPadding: String = "PKCS7"
    @State private var selectedKeyEncoding: String = "UTF8"
    @State private var selectedIVEncoding: String = "UTF8"
    @Environment(\.colorScheme) var colorScheme
    
    private let modes = ["ECB", "CBC", "CFB", "OFB"]
    private let keyTypes = ["DES", "3DES"]
    private let paddings = ["PKCS7", "Zero", "None"]
    private let encodings = ["UTF8", "HEX", "Base64"]
    
    private var keySize: Int {
        switch selectedKeyType {
        case "3DES":
            return kCCKeySize3DES
        default:
            return kCCKeySizeDES
        }
    }
    
    private var algorithm: CCAlgorithm {
        switch selectedKeyType {
        case "3DES":
            return CCAlgorithm(kCCAlgorithm3DES)
        default:
            return CCAlgorithm(kCCAlgorithmDES)
        }
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
                
                Picker("算法", selection: $selectedKeyType) {
                    ForEach(keyTypes, id: \.self) { type in
                        Text(type).tag(type)
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
            
            // 输入区域
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
                    
                    HStack {
                        Label("密钥 (\(selectedKeyType == "3DES" ? "24" : "8")字节)", systemImage: "key")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            let randomKey = generateRandomBytes(count: keySize)
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
                    
                    if selectedMode != "ECB" {
                        HStack {
                            Label("初始向量(IV) (8字节)", systemImage: "number")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                let randomIV = generateRandomBytes(count: kCCBlockSizeDES)
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
                }
            }
            
            // 控制按钮
            HStack(spacing: 12) {
                Button(action: { processDES() }) {
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
        .onChange(of: [selectedMode, selectedKeyType, selectedPadding]) { _ in
            outputText = ""
        }
    }
    
    private func processDES() {
        guard !inputText.isEmpty && !key.isEmpty else {
            outputText = ""
            return
        }
        
        do {
            if isEncrypting {
                outputText = try encryptDES(text: inputText, key: key, iv: iv)
            } else {
                outputText = try decryptDES(text: inputText, key: key, iv: iv)
            }
        } catch {
            outputText = "处理失败: \(error.localizedDescription)"
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
    
    private func encryptDES(text: String, key: String, iv: String) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw DESError.invalidInput
        }
        
        // 转换密钥和IV
        let keyData = try convertFromEncoding(key, encoding: selectedKeyEncoding)
        let ivData = selectedMode != "ECB" ? try convertFromEncoding(iv, encoding: selectedIVEncoding) : Data(count: kCCBlockSizeDES)
        
        // 检查密钥长度
        guard keyData.count == keySize else {
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
            throw DESError.encryptionFailed
        }
        
        let encryptedData = Data(buffer.prefix(numBytesEncrypted))
        return encryptedData.base64EncodedString()
    }
    
    private func decryptDES(text: String, key: String, iv: String) throws -> String {
        guard let data = Data(base64Encoded: text) else {
            throw DESError.invalidInput
        }
        
        // 转换密钥和IV
        let keyData = try convertFromEncoding(key, encoding: selectedKeyEncoding)
        let ivData = selectedMode != "ECB" ? try convertFromEncoding(iv, encoding: selectedIVEncoding) : Data(count: kCCBlockSizeDES)
        
        // 检查密钥长度
        guard keyData.count == keySize else {
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
