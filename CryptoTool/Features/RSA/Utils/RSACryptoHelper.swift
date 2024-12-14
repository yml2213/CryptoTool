import Foundation
import Security

class RSACryptoHelper {
    static func encrypt(text: String, withPublicKey publicKey: SecKey, outputEncoding: String) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw RSAError.invalidInput
        }
        
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionPKCS1,
            data as CFData,
            &error
        ) as Data? else {
            throw RSAError.encryptionFailed
        }
        
        switch outputEncoding {
        case "HEX":
            return encryptedData.map { String(format: "%02x", $0) }.joined(separator: " ")
        case "HEX(无空格)":
            return encryptedData.map { String(format: "%02x", $0) }.joined()
        default: // Base64
            return encryptedData.base64EncodedString()
        }
    }
    
    static func decrypt(text: String, withPrivateKey privateKey: SecKey, inputEncoding: String) throws -> String {
        let data: Data
        
        switch inputEncoding {
        case "HEX", "HEX(无空格)":
            let hex = text.replacingOccurrences(of: " ", with: "")
            data = try hex.hexadecimalToData()
        default: // Base64
            guard let base64Data = Data(base64Encoded: text) else {
                throw RSAError.invalidInput
            }
            data = base64Data
        }
        
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .rsaEncryptionPKCS1,
            data as CFData,
            &error
        ) as Data? else {
            throw RSAError.decryptionFailed
        }
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw RSAError.decryptionFailed
        }
        
        return decryptedString
    }
} 