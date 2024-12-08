import SwiftUI
import CryptoKit
import Security

struct RSAView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var publicKey: String = ""
    @State private var privateKey: String = ""
    @State private var selectedKeySize: Int = 1024
    @State private var selectedOutputEncoding: String = "Base64"
    @State private var publicExponent: String = "10001" // 默认值 65537
    @State private var modulus: String = ""  // 公模
    @State private var privateExponent: String = ""  // 私模
    @State private var showModulus: Bool = false  // 控制模数显示
    @State private var showToast = false  // 替换原来的showAlert
    @State private var toastMessage = ""  // 替换原来的alertTitle和alertMessage
    
    private let keySizes = [1024, 2048, 4096]
    private let outputEncodings = ["Base64", "HEX", "HEX(无空格)"]
    private let paddingModes = ["PKCS1Padding", "Base64"]
    
    // 添加一个计算属性来监听所有需要触发处理的值
    private var allProcessValues: String {
        [
            inputText,
            publicKey,
            privateKey,
            selectedOutputEncoding
        ].joined()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 模式选择 - 只保留密钥长度选择
            HStack(spacing: 20) {
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
                    HStack(spacing: 20) {
                        // 公钥部分
                        VStack(alignment: .leading, spacing: 8) {
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
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 私钥部分
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("私钥 Private Key", systemImage: "key.fill")
                                    .foregroundColor(.secondary)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    formatPrivateKey()
                                }) {
                                    Label("格式化", systemImage: "text.alignleft")
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
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            // 生成密钥对和相关操作按钮
            HStack(spacing: 12) {
                Button(action: {
                    generateKeyPair()
                }) {
                    Label("生成密钥对", systemImage: "key.horizontal")
                }
                .buttonStyle(.bordered)
                .help("生成新的RSA密钥对")
                
                Button(action: {
                    do {
                        try validateKeyPair()
                        showMessage("密钥对验证成功")
                    } catch {
                        showMessage("校验失败: \(error.localizedDescription)")
                    }
                }) {
                    Label("校验密钥对", systemImage: "checkmark.shield")
                }
                .buttonStyle(.bordered)
                .help("验证当前密钥对是否匹配")
                .disabled(publicKey.isEmpty || privateKey.isEmpty)
                
                Button(action: {
                    do {
                        let privateKey = try parsePrivateKey()
                        let publicKey = try extractPublicKey(from: privateKey)
                        
                        // 出公钥数据
                        var error: Unmanaged<CFError>?
                        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
                            throw RSAError.extractionFailed
                        }
                        
                        // 转换为PEM格式
                        var publicPEM = "-----BEGIN PUBLIC KEY-----\n"
                        publicPEM += publicKeyData.base64EncodedString().chunks(ofCount: 64).joined(separator: "\n")
                        publicPEM += "\n-----END PUBLIC KEY-----"
                        
                        self.publicKey = publicPEM
                        showMessage("从私钥提取公钥成功")
                    } catch {
                        showMessage("提取失败: \(error.localizedDescription)")
                    }
                }) {
                    Label("提取公钥", systemImage: "arrow.up.doc")
                }
                .buttonStyle(.bordered)
                .help("从私钥中提取对应的公钥")
                .disabled(privateKey.isEmpty)
                
                Spacer()
                
                addModulusButtons()
            }
            .padding(.horizontal)
            
            // 添加模数显示区域
            modulusSection()
            
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
                }
            }
            
            // 控制按钮
            HStack(spacing: 12) {
                // 左侧按钮组
                HStack(spacing: 12) {
                    // 加密按钮
                    Button(action: {
                        encryptRSA()
                    }) {
                        Label("加密", systemImage: "lock.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .help("使用公钥加密数据")
                    
                    // 解密按钮
                    Button(action: {
                        decryptRSA()
                    }) {
                        Label("解密", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .help("使用私钥解密数据")
                    
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
            
            // 输出区域
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
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
        .overlay(
            // 添加Toast提示
            GeometryReader { geometry in
                if showToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
        // 添加onChange监听
        .onChange(of: allProcessValues) { _, _ in
            // 只有在有输入内容时才处理
            if !inputText.isEmpty {
                encryptRSA()
            } else {
                // 如果输入为空，清空输出
                outputText = ""
            }
        }
    }
    
    // 添加模数解析按钮
    private func addModulusButtons() -> some View {
        HStack(spacing: 12) {
            Button(action: {
                showModulus.toggle()
            }) {
                Label(showModulus ? "隐藏模数" : "显示模数", 
                      systemImage: showModulus ? "eye.slash" : "eye")
            }
            .buttonStyle(.bordered)
            .help("显示或隐藏RSA密钥的模数信息")
            
            if showModulus {
                Button(action: {
                    do {
                        try parseModulus()
                    } catch {
                        outputText = "解析模数失败: \(error.localizedDescription)"
                    }
                }) {
                    Label("解析模数", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(.bordered)
                .help("从当前密钥中解析模数信息")
                .disabled(publicKey.isEmpty && privateKey.isEmpty)
            }
        }
    }
    
    // 添加模数显示区域
    private func modulusSection() -> some View {
        Group {
            if showModulus {
                SharedViews.GroupBoxView {
                    ModulusView(
                        modulus: modulus,
                        privateExponent: privateExponent,
                        onCopyModulus: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(modulus, forType: .string)
                        },
                        onCopyExponent: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(privateExponent, forType: .string)
                        }
                    )
                }
            }
        }
    }
    
    // 添加模数解析功能
    private func parseModulus() throws {
        if !publicKey.isEmpty {
            let key = try parsePublicKey()
            let keyData = try getKeyData(from: key)
            let (mod, exp) = try extractModulusAndExponent(from: keyData)
            modulus = mod
            publicExponent = exp
        }
        
        if !privateKey.isEmpty {
            let key = try parsePrivateKey()
            let keyData = try getKeyData(from: key)
            let (mod, exp) = try extractModulusAndExponent(from: keyData)
            modulus = mod
            privateExponent = exp
        }
    }
    
    // 获取密钥数据
    private func getKeyData(from key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            throw RSAError.extractionFailed
        }
        return data
    }
    
    // 从数据中提取模数和指数
    private func extractModulusAndExponent(from data: Data) throws -> (modulus: String, exponent: String) {
        guard let result = ASN1Parser.extractModulusAndExponent(from: data) else {
            throw RSAError.extractionFailed
        }
        return result
    }
    
    // 修改提示方法
    private func showMessage(_ message: String) {
        // 如果已经有提示在显示，先隐藏它
        if showToast {
            showToast = false
        }
        
        // 显示新提示
        toastMessage = message
        withAnimation {
            showToast = true
        }
        
        // 1秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                showToast = false
            }
        }
    }
    
    // 修改RSAView中的方法调用，使用新的工具类
    private func formatPublicKey() {
        publicKey = RSAKeyFormatter.formatPublicKey(publicKey)
    }
    
    private func formatPrivateKey() {
        privateKey = RSAKeyFormatter.formatPrivateKey(privateKey)
    }
    
    private func compressPublicKey() {
        publicKey = RSAKeyFormatter.compressKey(publicKey)
    }
    
    private func compressPrivateKey() {
        privateKey = RSAKeyFormatter.compressKey(privateKey)
    }
    
    private func generateKeyPair() {
        do {
            let (pub, priv) = try RSACrypto.generateKeyPair(keySize: selectedKeySize)
            publicKey = pub
            privateKey = priv
            showMessage("密钥对生成成功")
        } catch {
            showMessage("生成失败: \(error.localizedDescription)")
        }
    }
    
    private func validateKeyPair() throws {
        let publicKey = try RSACrypto.parsePublicKey(publicKey, keySize: selectedKeySize)
        let privateKey = try RSACrypto.parsePrivateKey(privateKey, keySize: selectedKeySize)
        try RSACrypto.validateKeyPair(publicKey: publicKey, privateKey: privateKey)
    }
    
    private func encryptRSA() {
        do {
            let publicKey = try RSACrypto.parsePublicKey(publicKey, keySize: selectedKeySize)
            outputText = try RSACryptoHelper.encrypt(
                text: inputText,
                withPublicKey: publicKey,
                outputEncoding: selectedOutputEncoding
            )
        } catch {
            outputText = "加密失败: \(error.localizedDescription)"
        }
    }
    
    private func decryptRSA() {
        do {
            let privateKey = try RSACrypto.parsePrivateKey(privateKey, keySize: selectedKeySize)
            outputText = try RSACryptoHelper.decrypt(
                text: inputText,
                withPrivateKey: privateKey,
                inputEncoding: selectedOutputEncoding
            )
        } catch {
            outputText = "解密失败: \(error.localizedDescription)"
        }
    }
    
    private func parsePublicKey() throws -> SecKey {
        return try RSACrypto.parsePublicKey(publicKey, keySize: selectedKeySize)
    }
    
    private func parsePrivateKey() throws -> SecKey {
        return try RSACrypto.parsePrivateKey(privateKey, keySize: selectedKeySize)
    }
    
    private func extractPublicKey(from privateKey: SecKey) throws -> SecKey {
        return try RSACrypto.extractPublicKey(from: privateKey)
    }
}

#Preview {
    RSAView()
}
