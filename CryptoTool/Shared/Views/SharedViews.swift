import SwiftUI

public struct SharedViews {
    // MARK: - InputTextEditor
    public struct InputTextEditor: View {
        let title: String
        let placeholder: String
        @Binding var text: String
        var onChange: (() -> Void)? = nil
        
        public init(title: String, placeholder: String, text: Binding<String>, onChange: (() -> Void)? = nil) {
            self.title = title
            self.placeholder = placeholder
            self._text = text
            self.onChange = onChange
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(title, systemImage: "text.alignleft")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .onChange(of: text, { _, newValue in
                        onChange?()
                    })
            }
        }
    }
    
    // MARK: - KeyInput
    public struct KeyInput: View {
        let title: String
        let systemImage: String
        @Binding var text: String
        let placeholder: String
        let help: String
        
        public init(title: String, systemImage: String, text: Binding<String>, placeholder: String = "请输入密钥", help: String = "") {
            self.title = title
            self.systemImage = systemImage
            self._text = text
            self.placeholder = placeholder
            self.help = help
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .foregroundColor(.secondary)
                    .font(.headline)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .help(help)
            }
        }
    }
    
    // MARK: - ActionButtons
    public struct ActionButtons: View {
        let primaryAction: () -> Void
        let primaryLabel: String
        let primaryIcon: String
        let secondaryAction: (() -> Void)?
        let secondaryLabel: String?
        let secondaryIcon: String?
        let clearAction: () -> Void
        let copyAction: () -> Void
        let swapAction: (() -> Void)?
        let isOutputEmpty: Bool
        
        public init(primaryAction: @escaping () -> Void,
                   primaryLabel: String,
                   primaryIcon: String,
                   secondaryAction: (() -> Void)? = nil,
                   secondaryLabel: String? = nil,
                   secondaryIcon: String? = nil,
                   clearAction: @escaping () -> Void,
                   copyAction: @escaping () -> Void,
                   swapAction: (() -> Void)?,
                   isOutputEmpty: Bool) {
            self.primaryAction = primaryAction
            self.primaryLabel = primaryLabel
            self.primaryIcon = primaryIcon
            self.secondaryAction = secondaryAction
            self.secondaryLabel = secondaryLabel
            self.secondaryIcon = secondaryIcon
            self.clearAction = clearAction
            self.copyAction = copyAction
            self.swapAction = swapAction
            self.isOutputEmpty = isOutputEmpty
        }
        
        public var body: some View {
            HStack(spacing: 12) {
                // 左侧按钮组
                HStack(spacing: 12) {
                    Button(action: primaryAction) {
                        Label(primaryLabel, systemImage: primaryIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if let secondaryAction = secondaryAction,
                       let secondaryLabel = secondaryLabel,
                       let secondaryIcon = secondaryIcon {
                        Button(action: secondaryAction) {
                            Label(secondaryLabel, systemImage: secondaryIcon)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button(action: clearAction) {
                        Label("清空", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .help("清空输入输出")
                    
                    Button(action: copyAction) {
                        Label("复制结果", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isOutputEmpty)
                    .help("将结果复制到剪贴板")
                    
                    if let swapAction = swapAction {
                        Button(action: swapAction) {
                            Label("互换", systemImage: "arrow.up.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .help("交换输入和输出的位置")
                        .disabled(isOutputEmpty)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - ResultView
    public struct ResultView: View {
        let title: String
        let value: String
        let showStatus: Bool
        
        public init(title: String, value: String, showStatus: Bool) {
            self.title = title
            self.value = value
            self.showStatus = showStatus
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(title, systemImage: "text.alignleft")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    
                    Spacer()
                    
                    if showStatus && !value.isEmpty {
                        Text("处理完成")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
            }
        }
    }
    
    // MARK: - GroupBoxView
    public struct GroupBoxView<Content: View>: View {
        let content: Content
        
        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        public var body: some View {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    content
                }
            }
        }
    }
    
    // MARK: - EncodingPicker
    public struct EncodingPicker: View {
        let title: String
        @Binding var selection: String
        let options: [String]
        let width: CGFloat
        
        public init(title: String, selection: Binding<String>, options: [String], width: CGFloat = 250) {
            self.title = title
            self._selection = selection
            self.options = options
            self.width = width
        }
        
        public var body: some View {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: width)
        }
    }
    
    // MARK: - ModePicker
    public struct ModePicker: View {
        let title: String
        @Binding var selection: String
        let options: [String]
        let help: String?
        
        public init(title: String, selection: Binding<String>, options: [String], help: String? = nil) {
            self.title = title
            self._selection = selection
            self.options = options
            self.help = help
        }
        
        public var body: some View {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .help(help ?? "")
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        SharedViews.InputTextEditor(
            title: "测试输入",
            placeholder: "请输入文本",
            text: .constant("Hello World")
        )
        
        SharedViews.KeyInput(
            title: "测试密钥",
            systemImage: "key",
            text: .constant("test key")
        )
        
        SharedViews.ActionButtons(
            primaryAction: {},
            primaryLabel: "测试",
            primaryIcon: "play",
            secondaryAction: {},
            secondaryLabel: "测试2",
            secondaryIcon: "play",
            clearAction: {},
            copyAction: {},
            swapAction: {},
            isOutputEmpty: false
        )
        
        SharedViews.ResultView(
            title: "测试结果",
            value: "Test Result",
            showStatus: true
        )
    }
    .padding()
} 