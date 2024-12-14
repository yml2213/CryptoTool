import SwiftUI
import CryptoKit

struct SHAView: View {
    @State private var inputText: String = ""
    @State private var shaResults: [String: String] = [:]
    @State private var selectedAlgorithm: String = "SHA1"
    @Environment(\.colorScheme) var colorScheme
    
    private let resultOrder = [
        "SHA1",
        "SHA256", 
        "SHA384",
        "SHA512"
    ]
    
    private let tempDataKey = "SHAView_TempData"
    
    init() {
        if let savedData = TempDataManager.shared.getData(forKey: tempDataKey) as? [String: String] {
            _inputText = State(initialValue: savedData["inputText"] ?? "")
            _selectedAlgorithm = State(initialValue: savedData["algorithm"] ?? "SHA1")
        }
    }
    
    private func saveCurrentData() {
        let dataToSave: [String: String] = [
            "inputText": inputText,
            "algorithm": selectedAlgorithm
        ]
        TempDataManager.shared.saveData(dataToSave, forKey: tempDataKey)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 输入输出区域
            SharedViews.GroupBoxView {
                // 输入区域
                SharedViews.InputTextEditor(
                    title: "输入文本",
                    placeholder: "输入需要处理的文本",
                    text: $inputText,
                    onChange: { generateSHA() }
                )
                
                // 控制按钮
                SharedViews.ActionButtons(
                    primaryAction: { generateSHA() },
                    primaryLabel: "生成",
                    primaryIcon: "arrow.right.circle.fill",
                    clearAction: {
                        inputText = ""
                        generateSHA()
                    },
                    copyAction: {
                        let allResults = resultOrder.compactMap { key in
                            if let value = shaResults[key] {
                                return "\(key): \(value)"
                            }
                            return nil
                        }.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(allResults, forType: .string)
                    },
                    swapAction: nil,
                    isOutputEmpty: shaResults.isEmpty
                )
                
                // 结果显示
                VStack(alignment: .leading, spacing: 8) {
                    Label("SHA 结果", systemImage: "key.fill")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(resultOrder.enumerated()), id: \.element) { index, key in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(key)
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .rounded))
                                
                                HStack(alignment: .top) {
                                    Text(shaResults[key] ?? "")
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Button(action: {
                                        if let value = shaResults[key] {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(value, forType: .string)
                                        }
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(shaResults[key]?.isEmpty ?? true)
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
        .onChange(of: inputText, { _, newValue in
            saveCurrentData()
        })
        .onChange(of: selectedAlgorithm, { _, newValue in
            saveCurrentData()
        })
        .onAppear {
            generateSHA()
        }
    }
    
    private func generateSHA() {
        guard !inputText.isEmpty else {
            shaResults = Dictionary(uniqueKeysWithValues: resultOrder.map { ($0, "") })
            return
        }
        
        guard let inputData = inputText.data(using: .utf8) else {
            shaResults = Dictionary(uniqueKeysWithValues: resultOrder.map { ($0, "转换失败") })
            return
        }
        
        // 计算各种SHA值
        shaResults = [
            "SHA1": Insecure.SHA1.hash(data: inputData).map { String(format: "%02hhx", $0) }.joined(),
            "SHA256": SHA256.hash(data: inputData).map { String(format: "%02hhx", $0) }.joined(),
            "SHA384": SHA384.hash(data: inputData).map { String(format: "%02hhx", $0) }.joined(),
            "SHA512": SHA512.hash(data: inputData).map { String(format: "%02hhx", $0) }.joined()
        ]
    }
}

#Preview {
    SHAView()
}