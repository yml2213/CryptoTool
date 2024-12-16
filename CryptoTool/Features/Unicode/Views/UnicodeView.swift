import SwiftUI

struct UnicodeView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var selectedMode: String = "Unicode转中文"
    
    private let modes = ["Unicode转中文", "中文转Unicode"]
    private let tempDataKey = "UnicodeView_TempData"
    
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
                SharedViews.ModePicker(
                    title: "转换模式",
                    selection: $selectedMode,
                    options: modes
                )
                
                SharedViews.InputTextEditor(
                    title: "输入文本",
                    placeholder: selectedMode == "Unicode转中文" ? 
                        "输入Unicode编码，如：\\u4F60\\u597D" : 
                        "输入中文文本",
                    text: $inputText
                )
                
                SharedViews.ActionButtons(
                    primaryAction: { convert() },
                    primaryLabel: "转换",
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
            convert()
            saveCurrentData()
        }
        .onChange(of: selectedMode) { _, _ in
            convert()
        }
    }
    
    private func convert() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        if selectedMode == "Unicode转中文" {
            outputText = unicodeToChinese(inputText)
        } else {
            outputText = chineseToUnicode(inputText)
        }
    }
    
    private func unicodeToChinese(_ text: String) -> String {
        var result = text
        
        // 匹配 \u 后面跟着4个十六进制数字的模式
        let pattern = "\\\\u([0-9a-fA-F]{4})"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return "转换失败：正则表达式错误"
        }
        
        while let match = regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) {
            guard let range = Range(match.range(at: 1), in: result),
                  let unicodeScalar = UInt32(result[range], radix: 16),
                  let scalar = Unicode.Scalar(unicodeScalar) else {
                continue
            }
            
            let char = String(scalar)
            let fullRange = Range(match.range(at: 0), in: result)!
            result.replaceSubrange(fullRange, with: char)
        }
        
        return result
    }
    
    private func chineseToUnicode(_ text: String) -> String {
        var result = ""
        
        for char in text {
            let unicode = String(format: "\\u%04x", char.unicodeScalars.first?.value ?? 0)
            result += unicode
        }
        
        return result
    }
}

#Preview {
    UnicodeView()
} 