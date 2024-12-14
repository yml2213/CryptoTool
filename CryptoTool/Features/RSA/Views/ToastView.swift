import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Group {
                Group {
                    if message.contains("成功") {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if message.contains("失败") {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .imageScale(.large)
                .frame(width: 20, height: 20)
                
                Text(message)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
    }
} 