import SwiftUI

struct ModulusView: View {
    let modulus: String
    let privateExponent: String
    let onCopyModulus: () -> Void
    let onCopyExponent: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 公模显示
            HStack {
                Label("公模 Modulus", systemImage: "number.circle")
                    .foregroundColor(.secondary)
                    .font(.headline)
                
                Spacer()
                
                Button("复制") { onCopyModulus() }
                    .buttonStyle(.bordered)
                    .disabled(modulus.isEmpty)
            }
            
            Text(modulus)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
            
            // 私模显示
            HStack {
                Label("私模 Private Exponent", systemImage: "number.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.headline)
                
                Spacer()
                
                Button("复制") { onCopyExponent() }
                    .buttonStyle(.bordered)
                    .disabled(privateExponent.isEmpty)
            }
            
            Text(privateExponent)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
        }
    }
} 