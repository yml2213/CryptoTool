import SwiftUI

struct Base64View: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    // 添加临时数据存储
    private let tempDataKey = "Base64View_TempData"
    
    init() {
        if let savedData = TempDataManager.shared.getData(forKey: tempDataKey) as? [String: String] {
            _inputText = State(initialValue: savedData["inputText"] ?? "")
        }
    }
    
    private func saveCurrentData() {
        let dataToSave: [String: String] = [
            "inputText": inputText
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
                    text: $inputText
                )
                
                // 控制按钮
                SharedViews.ActionButtons(
                    primaryAction: { encode() },
                    primaryLabel: "编码",
                    primaryIcon: "arrow.right.circle.fill",
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
                
                // 输出结果
                SharedViews.ResultView(
                    title: "处理结果",
                    value: outputText,
                    showStatus: true
                )
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: inputText) { _, _ in
            encode()
            saveCurrentData()
        }
    }
    
    private func encode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        guard let data = inputText.data(using: .utf8) else {
            outputText = "编码失败"
            return
        }
        outputText = data.base64EncodedString()
    }
}

#Preview {
    Base64View()
} 
