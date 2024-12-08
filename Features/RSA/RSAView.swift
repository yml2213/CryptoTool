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
    @State private var publicExponent: String = "10001"
    @State private var modulus: String = ""
    @State private var privateExponent: String = ""
    @State private var showModulus: Bool = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    private let keySizes = [1024, 2048, 4096]
    private let outputEncodings = ["Base64", "HEX", "HEX(无空格)"]
    
    private var allProcessValues: String {
        [inputText, publicKey, privateKey, selectedOutputEncoding].joined()
    }
    
    // 添加临时数据存储
    private let tempDataKey = "RSAView_TempData"
    
    init() {
        if let savedData = TempDataManager.shared.getData(forKey: tempDataKey) as? [String: String] {
            _inputText = State(initialValue: savedData["inputText"] ?? "")
            _publicKey = State(initialValue: savedData["publicKey"] ?? "")
            _privateKey = State(initialValue: savedData["privateKey"] ?? "")
        }
    }
    
    private func saveCurrentData() {
        let dataToSave: [String: String] = [
            "inputText": inputText,
            "publicKey": publicKey,
            "privateKey": privateKey
        ]
        TempDataManager.shared.saveData(dataToSave, forKey: tempDataKey)
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
                            
                            Button("格式化") { publicKey = RSAKeyFormatter.formatPublicKey(publicKey) }
                                .buttonStyle(.bordered)
                            
                            Button("压缩") { publicKey = RSAKeyFormatter.compressKey(publicKey) }
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
                            
                            Button("格式化") { privateKey = RSAKeyFormatter.formatPrivateKey(privateKey) }
                                .buttonStyle(.bordered)
                            
                            Button("压缩") { privateKey = RSAKeyFormatter.compressKey(privateKey) }
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
                Button(action: {
                    do {
                        let (pub, priv) = try RSACrypto.generateKeyPair(keySize: selectedKeySize)
                        publicKey = pub
                        privateKey = priv
                        showMessage("密钥对生成成功")
                    } catch {
                        showMessage("生成失败: \(error.localizedDescription)")
                    }
                }) {
                    Label("生成密钥对", systemImage: "key.horizontal")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    do {
                        let publicKey = try RSACrypto.parsePublicKey(publicKey, keySize: selectedKeySize)
                        let privateKey = try RSACrypto.parsePrivateKey(privateKey, keySize: selectedKeySize)
                        try RSACrypto.validateKeyPair(publicKey: publicKey, privateKey: privateKey)
                        showMessage("密钥对验证成功")
                    } catch {
                        showMessage("校验失败: \(error.localizedDescription)")
                    }
                }) {
                    Label("校验密钥对", systemImage: "checkmark.shield")
                }
                .buttonStyle(.bordered)
                .disabled(publicKey.isEmpty || privateKey.isEmpty)
                
                Button(action: {
                    do {
                        let privateKey = try RSACrypto.parsePrivateKey(privateKey, keySize: selectedKeySize)
                        self.publicKey = try RSAKeyManager.extractPublicKey(from: privateKey)
                        showMessage("从私钥提取公钥成功")
                    } catch {
                        showMessage("提取失败: \(error.localizedDescription)")
                    }
                }) {
                    Label("提取公钥", systemImage: "arrow.up.doc")
                }
                .buttonStyle(.bordered)
                .disabled(privateKey.isEmpty)
                
                Spacer()
                
                Button(action: { showModulus.toggle() }) {
                    Label(showModulus ? "隐藏模数" : "显示模数", 
                          systemImage: showModulus ? "eye.slash" : "eye")
                }
                .buttonStyle(.bordered)
                
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
                    .disabled(publicKey.isEmpty && privateKey.isEmpty)
                }
            }
            .padding(.horizontal)
            
            // 模数显示区域
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
                            let publicKey = try RSACrypto.parsePublicKey(publicKey, keySize: selectedKeySize)
                            outputText = try RSACryptoHelper.encrypt(
                                text: inputText,
                                withPublicKey: publicKey,
                                outputEncoding: selectedOutputEncoding
                            )
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
                            let privateKey = try RSACrypto.parsePrivateKey(privateKey, keySize: selectedKeySize)
                            outputText = try RSACryptoHelper.decrypt(
                                text: inputText,
                                withPrivateKey: privateKey,
                                inputEncoding: selectedOutputEncoding
                            )
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
        .overlay(
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
                do {
                    let publicKey = try RSACrypto.parsePublicKey(publicKey, keySize: selectedKeySize)
                    outputText = try RSACryptoHelper.encrypt(
                        text: inputText,
                        withPublicKey: publicKey,
                        outputEncoding: selectedOutputEncoding
                    )
                } catch {
                    outputText = "处理失败: \(error.localizedDescription)"
                }
            } else {
                outputText = ""
            }
        }
        .onChange(of: inputText) { _ in
            saveCurrentData()
        }
        .onChange(of: publicKey) { _ in
            saveCurrentData()
        }
        .onChange(of: privateKey) { _ in
            saveCurrentData()
        }
    }
    
    private func parseModulus() throws {
        if !publicKey.isEmpty {
            let key = try RSACrypto.parsePublicKey(publicKey, keySize: selectedKeySize)
            let keyData = try RSACrypto.getKeyData(from: key)
            let (mod, exp) = ASN1Parser.extractModulusAndExponent(from: keyData) ?? ("", "")
            modulus = mod
            publicExponent = exp
        }
        
        if !privateKey.isEmpty {
            let key = try RSACrypto.parsePrivateKey(privateKey, keySize: selectedKeySize)
            let keyData = try RSACrypto.getKeyData(from: key)
            let (mod, exp) = ASN1Parser.extractModulusAndExponent(from: keyData) ?? ("", "")
            modulus = mod
            privateExponent = exp
        }
    }
    
    private func showMessage(_ message: String) {
        if showToast { showToast = false }
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation { showToast = false }
        }
    }
}

#Preview {
    RSAView()
}
