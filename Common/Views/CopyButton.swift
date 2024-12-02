//
//  CopyButton.swift
//  CryptoTool
//
//  Created by yml on 2024/12/2.
//

import SwiftUI

struct CopyButton: View {
    let text: String
    
    var body: some View {
        Button("复制结果") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }
}
