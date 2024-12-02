//
//  ContentView.swift
//  CryptoTool
//
//  Created by yml on 2024/12/2.
//

import SwiftUI
import CryptoKit



struct ContentView: View {
    @State private var selectedTab = "MD5"
    
    let cryptoOptions = [
        "MD5",
        "SHA",
        "HMAC",
        "RC4",
        "AES",
        "DES",
        "3DES",
        "Base64",
        "Rabbit",
        "PBKDF2/EvpKDF"
    ]
    
    var body: some View {
        HSplitView {
            // 左侧导航栏
            List(cryptoOptions, id: \.self) { option in
                Text(option)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
                    .background(selectedTab == option ? Color.blue.opacity(0.2) : Color.clear)
                    .onTapGesture {
                        selectedTab = option
                    }
            }
            .frame(width: 150)
            .listStyle(SidebarListStyle())
            
            // 右侧内容区
            Group {
                switch selectedTab {
                case "MD5":
                    MD5View()
                case "SHA":
                    Text("SHA View - Coming Soon")
                case "HMAC":
                    Text("HMAC View - Coming Soon")
                case "RC4":
                    Text("RC4 View - Coming Soon")
                case "AES":
                    Text("AES View - Coming Soon")
                case "DES":
                    Text("DES View - Coming Soon")
                case "3DES":
                    Text("3DES View - Coming Soon")
                case "Base64":
                    Text("Base64 View - Coming Soon")
                case "Rabbit":
                    Text("Rabbit View - Coming Soon")
                case "PBKDF2/EvpKDF":
                    Text("PBKDF2/EvpKDF View - Coming Soon")
                default:
                    MD5View()
                }
            }
            .padding()
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

// 预览
#Preview {
    ContentView()
}
