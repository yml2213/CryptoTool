import SwiftUI
import CryptoKit
import CommonCrypto

struct AESView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var key: String = "0123456789abcdef"  // 16字节默认密钥
    @State private var iv: String = "0123456789abcdef"   // 16字节默认IV
    @State private var selectedMode: String = "CBC"      // 默认CBC模式
    @State private var selectedKeySize: Int = 128        // 默认128位
    @State private var selectedPadding: String = "PKCS7" // 默认PKCS7
    @State private var selectedKeyEncoding: String = "UTF8"
    @State private var selectedIVEncoding: String = "UTF8"
    @State private var selectedOutputEncoding: String = "Base64"
    @Environment(\.colorScheme) var colorScheme
    
    private let modes = ["ECB", "CBC"]
    private let keySizes = [128, 192, 256]
    private let paddings = ["PKCS7", "Zero", "None"]
    private let encodings = ["UTF8", "HEX", "Base64"]
    private let outputEncodings = ["Base64", "HEX", "HEX(无空格)"]
    
    private let tooltips = [
        "ecb": "ECB模式安全性较低，不推荐在实际应用中使用",
        "cbc": "CBC模式需要初始向量(IV)，安全性较高",
        "key128": "128位密钥(16字节)，适用于大多数场景",
        "key192": "192位密钥(24字节)，提供更高安全性",
        "key256": "256位密钥(32字节)，提供最高安全性",
        "pkcs7": "PKCS7填充是最常用的填充方式",
        "zero": "零填充会在末尾补0",
        "none": "无填充要求数据长度必须是16的倍数"
    ]
    
    private var allValues: String {
        [
            inputText,
            key,
            iv,
            selectedMode,
            selectedKeySize.description,
            selectedPadding,
            selectedKeyEncoding,
            selectedIVEncoding,
            selectedOutputEncoding
        ].joined()
    }
    
    // 添加临时数据存储
    private let tempDataKey = "AESView_TempData"
    
    init() {
        if let savedData = TempDataManager.shared.getData(forKey: tempDataKey) as? [String: String] {
            _inputText = State(initialValue: savedData["inputText"] ?? "")
            _key = State(initialValue: savedData["key"] ?? "")
            _iv = State(initialValue: savedData["iv"] ?? "")
            _selectedMode = State(initialValue: savedData["mode"] ?? "CBC")
            _selectedKeySize = State(initialValue: Int(savedData["keySize"] ?? "") ?? 128)
        }
    }
    
    private func saveCurrentData() {
        let dataToSave: [String: String] = [
            "inputText": inputText,
            "key": key,
            "iv": iv,
            "mode": selectedMode,
            "keySize": String(selectedKeySize)
        ]
        TempDataManager.shared.saveData(dataToSave, forKey: tempDataKey)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 模式选择区域 - 添加 GroupBoxView
            SharedViews.GroupBoxView {
                HStack(spacing: 20) {
                    SharedViews.ModePicker(
                        title: "密钥长度",
                        selection: .init(
                            get: { String(selectedKeySize) },
                            set: { selectedKeySize = Int($0) ?? 128 }
                        ),
                        options: keySizes.map(String.init),
                        help: "选择AES密钥长度"
                    )
                    
                    SharedViews.ModePicker(
                        title: "加密模式",
                        selection: $selectedMode,
                        options: modes,
                        help: tooltips[selectedMode.lowercased()]
                    )
                    
                    SharedViews.ModePicker(
                        title: "填充模式",
                        selection: $selectedPadding,
                        options: paddings,
                        help: tooltips[selectedPadding.lowercased()]
                    )
                }
            }  // 添加 GroupBoxView 的结束括号
            
            // 密钥和IV设置区域
            SharedViews.GroupBoxView {
                VStack(alignment: .leading, spacing: 12) {
                    // 密钥部分
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("密钥 (\(selectedKeySize/8)字节)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "key")
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)
                                
                                TextField("输入\(selectedKeySize/8)字节的密钥", text: $key)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(minWidth: 100)
                                    .onChange(of: key) { _, newValue in
                                        let detectedEncoding = detectEncoding(newValue)
                                        if detectedEncoding != selectedKeyEncoding {
                                            selectedKeyEncoding = detectedEncoding
                                        }
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("随机key")  // 空占位符，用于对齐
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                let randomKey = generateRandomUTF8String(count: selectedKeySize/8)
                                key = randomKey
                            }) {
                                Image(systemName: "wand.and.stars")
                                    .frame(width: 20)
                            }
                            .buttonStyle(.bordered)
                            .frame(width: 32)
                            .help("生成随机的\(selectedKeySize/8)字节密钥")
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("")  // 空占位符，用于对齐
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            SharedViews.EncodingPicker(
                                title: "密钥编码",
                                selection: $selectedKeyEncoding,
                                options: encodings
                            )
                            .frame(width: 300)
                        }
                    }
                    
                    // IV部分
                    if selectedMode != "ECB" {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("初始向量(IV) (16字节)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "number")
                                        .foregroundColor(.secondary)
                                        .frame(width: 16)
                                    
                                    TextField("输入16字节的初始向量", text: $iv)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(minWidth: 100)
                                        .onChange(of: iv) { _, newValue in
                                            let detectedEncoding = detectEncoding(newValue)
                                            if detectedEncoding != selectedIVEncoding {
                                                selectedIVEncoding = detectedEncoding
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("随机iv")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    let randomIV = generateRandomUTF8String(count: 16)
                                    iv = randomIV
                                }) {
                                    Image(systemName: "wand.and.stars")
                                        .frame(width: 20)
                                }
                                .buttonStyle(.bordered)
                                .frame(width: 32)
                                .help("生成随机的16字节IV")
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(" ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                SharedViews.EncodingPicker(
                                    title: "IV编码",
                                    selection: $selectedIVEncoding,
                                    options: encodings
                                )
                                .frame(width: 300)
                            }
                        }
                    }
                }
            }
            
            // 输入输出区域
            SharedViews.GroupBoxView {
                SharedViews.InputTextEditor(
                    title: "输入文本",
                    placeholder: "输入需要处理的文本",
                    text: $inputText
                )
                
                HStack {
                    Button(action: {
                        do {
                            outputText = try encryptAES(text: inputText, key: key, iv: iv)
                        } catch {
                            outputText = "加密失败: \(error.localizedDescription)"
                        }
                    }) {
                        Label("加密", systemImage: "lock.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        inputText = ""
                        outputText = ""
                    }) {
                        Label("清空", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(outputText, forType: .string)
                    }) {
                        Label("复制结果", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(outputText.isEmpty)
                    
                    Button(action: {
                        let temp = inputText
                        inputText = outputText
                        outputText = temp
                    }) {
                        Label("互换", systemImage: "arrow.up.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(outputText.isEmpty)
                    
                    Spacer()
                    
                    Button(action: {
                        do {
                            outputText = try decryptAES(text: inputText, key: key, iv: iv)
                        } catch {
                            outputText = "解密失败: \(error.localizedDescription)"
                        }
                    }) {
                        Label("解密", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    SharedViews.EncodingPicker(
                        title: "输出格式",
                        selection: $selectedOutputEncoding,
                        options: outputEncodings
                    )
                }
                
                SharedViews.ResultView(
                    title: "处理结果",
                    value: outputText,
                    showStatus: true
                )
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: allValues, { _, newValue in
            if !inputText.isEmpty {
                do {
                    outputText = try encryptAES(text: inputText, key: key, iv: iv)
                } catch {
                    outputText = "处理失败: \(error.localizedDescription)"
                }
            } else {
                outputText = ""
            }
        })
        .onChange(of: inputText) {
            saveCurrentData()
        }
        .onChange(of: key) {
            saveCurrentData()
        }
        .onChange(of: iv) {
            saveCurrentData()
        }
        .onChange(of: selectedMode) {
            saveCurrentData()
        }
        .onChange(of: selectedKeySize) {
            saveCurrentData()
        }
        .onChange(of: selectedKeyEncoding) { _, newValue in
            if !key.isEmpty {
                do {
                    // 先将当前内容转换为二进制数据
                    let keyData = try convertFromEncoding(key, encoding: selectedKeyEncoding)
                    // 然后按新格式转换
                    key = formatToEncoding(keyData, encoding: newValue)
                } catch {
                    // 如果转换失败，保持原有内容
                    print("Key encoding conversion failed")
                }
            }
        }
        .onChange(of: selectedIVEncoding) { _, newValue in
            if !iv.isEmpty {
                do {
                    let ivData = try convertFromEncoding(iv, encoding: selectedIVEncoding)
                    iv = formatToEncoding(ivData, encoding: newValue)
                } catch {
                    print("IV encoding conversion failed")
                }
            }
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
                // 自动切换到HEX格式并更新选器
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
    
    // 添加码转换函数
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
            outputText = try encryptAES(text: inputText, key: key, iv: iv)
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
        
        // 置填充
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
        
        // 择AES算法
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
    
    private func decryptAES(text: String, key: String, iv: String) throws -> String {
        // 根据当前输出格式解析输入
        let data: Data
        switch selectedOutputEncoding {
        case "HEX", "HEX(无空格)":
            let hex = text.replacingOccurrences(of: " ", with: "")
            var tempData = Data()
            var temp = ""
            
            for char in hex {
                temp += String(char)
                if temp.count == 2 {
                    guard let num = UInt8(temp, radix: 16) else {
                        throw AESError.invalidInput
                    }
                    tempData.append(num)
                    temp = ""
                }
            }
            
            if !temp.isEmpty {
                throw AESError.invalidInput
            }
            data = tempData
        default: // Base64
            guard let base64Data = Data(base64Encoded: text) else {
                throw AESError.invalidInput
            }
            data = base64Data
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
    
    // 添加生成随机UTF8字符串的函数
    private func generateRandomUTF8String(count: Int) -> String {
        // 使用可打印的ASCII字符范围（33-126）
        let allowedChars = (33...126).map { Character(UnicodeScalar($0)) }
        return String((0..<count).map { _ in
            allowedChars[Int.random(in: 0..<allowedChars.count)]
        })
    }
    
    // 添加自动识别格式的函数
    private func detectEncoding(_ text: String) -> String {
        // Base64格式检测
        if let _ = Data(base64Encoded: text) {
            return "Base64"
        }
        
        // HEX格式检测
        let hexPattern = "^[0-9A-Fa-f ]+$"
        if let regex = try? NSRegularExpression(pattern: hexPattern),
           regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
            return "HEX"
        }
        
        // 默认为UTF8
        return "UTF8"
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
