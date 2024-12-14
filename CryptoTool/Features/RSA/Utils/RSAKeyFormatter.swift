import Foundation

struct RSAKeyFormatter {
    static func formatPublicKey(_ key: String) -> String {
        let cleanKey = key
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        var formatted = "-----BEGIN PUBLIC KEY-----\n"
        formatted += cleanKey.chunks(ofCount: 64).joined(separator: "\n")
        formatted += "\n-----END PUBLIC KEY-----"
        return formatted
    }
    
    static func formatPrivateKey(_ key: String) -> String {
        let cleanKey = key
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        var formatted = "-----BEGIN PRIVATE KEY-----\n"
        formatted += cleanKey.chunks(ofCount: 64).joined(separator: "\n")
        formatted += "\n-----END PRIVATE KEY-----"
        return formatted
    }
    
    static func compressKey(_ key: String) -> String {
        key.replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
           .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
           .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
           .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
           .replacingOccurrences(of: "\n", with: "")
    }
} 