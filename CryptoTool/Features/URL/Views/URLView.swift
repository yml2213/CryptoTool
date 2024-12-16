import SwiftUI

struct URLView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    
    private let tempDataKey = "URLView_TempData"
    
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
            SharedViews.GroupBoxView {
                SharedViews.InputTextEditor(
                    title: "输入文本",
                    placeholder: "输入需要处理的文本",
                    text: $inputText
                )
                
                SharedViews.ActionButtons(
                    primaryAction: { encode() },
                    primaryLabel: "编码",
                    primaryIcon: "arrow.right.circle.fill",
                    secondaryAction: { decode() },
                    secondaryLabel: "解码",
                    secondaryIcon: "arrow.left.circle.fill",
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
        
        if let encoded = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            outputText = encoded
        } else {
            outputText = "编码失败"
        }
    }
    
    private func decode() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        if let decoded = inputText.removingPercentEncoding {
            outputText = decoded
        } else {
            outputText = "解码失败：输入的不是有效的URL编码"
        }
    }
}

#Preview {
    URLView()
} 