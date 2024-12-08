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
            // 模式选择
            HStack(spacing: 20) {
                SharedViews.ModePicker(
                    title: "密钥长度",
                    selection: .init(
                        get: { String(selectedKeySize) },
                        set: { selectedKeySize = Int($0) ?? RSAConstants.defaultKeySize }
                    ),
                    options: keySizes.map(String.init),
                    help: "选择RSA密钥长度"
                )
            }
            .padding(.horizontal)
            
            // 密钥区域
            SharedViews.GroupBoxView {
                HStack(spacing: 20) {
                    // 公钥部分
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("公钥 Public Key", systemImage: "key")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("格式化") { formatPublicKey() }
                                .buttonStyle(.bordered)
                            
                            Button("压缩") { compressPublicKey() }
                                .buttonStyle(.bordered)
                            
                            Button("复制") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(publicKey, forType: .string)
                            }
                            .buttonStyle(.bordered)
                            
                            Button("清空") { publicKey = "" }
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
                            
                            Button("格式化") { formatPrivateKey() }
                                .buttonStyle(.bordered)
                            
                            Button("压缩") { compressPrivateKey() }
                                .buttonStyle(.bordered)
                            
                            Button("复制") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(privateKey, forType: .string)
                            }
                            .buttonStyle(.bordered)
                            
                            Button("清空") { privateKey = "" }
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
            
            // 密钥操作按钮
            HStack(spacing: 12) {
                SharedViews.ActionButtons(
                    primaryAction: { generateKeyPair() },
                    primaryLabel: "生成密钥对",
                    primaryIcon: "key.horizontal",
                    clearAction: {
                        publicKey = ""
                        privateKey = ""
                    },
                    copyAction: {
                        do {
                            try validateKeyPair()
                            showMessage("密钥对验证成功")
                        } catch {
                            showMessage("校验失败: \(error.localizedDescription)")
                        }
                    },
                    swapAction: nil,
                    isOutputEmpty: publicKey.isEmpty || privateKey.isEmpty
                )
                
                Button(action: {
                    do {
                        let privateKey = try parsePrivateKey()
                        let publicKey = try extractPublicKey(from: privateKey)
                        self.publicKey = try RSAKeyManager.extractPublicKey(from: privateKey)
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
            
            // 模数显示区域
            modulusSection()
            
            // 输入输出区域
            SharedViews.GroupBoxView {
                SharedViews.InputTextEditor(
                    title: "输入文本",
                    placeholder: "输入需要处理的文本",
                    text: $inputText
                )
                
                HStack {
                    SharedViews.ActionButtons(
                        primaryAction: { encryptRSA() },
                        primaryLabel: "加密",
                        primaryIcon: "lock.fill",
                        clearAction: {
                            inputText = ""
                            outputText = ""
                        },
                        copyAction: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(outputText, forType: .string)
                        },
                        swapAction: {
                            let temp = inputText
                            inputText = outputText
                            outputText = temp
                        },
                        isOutputEmpty: outputText.isEmpty
                    )
                    
                    Spacer()
                    
                    Button(action: { decryptRSA() }) {
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
        .overlay(
            // Toast提示
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
        .onChange(of: allProcessValues) { _, _ in
            if !inputText.isEmpty {
                encryptRSA()
            } else {
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
    
    // 从数据中提取模���和指数
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
