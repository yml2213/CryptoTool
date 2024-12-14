import Foundation
import Security

class RSAKeyManager {
    static func generateKeyPair(keySize: Int) throws -> (publicKey: String, privateKey: String) {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: keySize,
            kSecPublicKeyAttrs as String: [
                kSecAttrIsPermanent as String: false
            ],
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: false
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let keyPair = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
              let publicKey = SecKeyCopyPublicKey(keyPair) else {
            throw RSAError.conversionFailed
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?,
              let privateKeyData = SecKeyCopyExternalRepresentation(keyPair, &error) as Data? else {
            throw RSAError.extractionFailed
        }
        
        let publicPEM = RSAKeyFormatter.formatPublicKey(publicKeyData.base64EncodedString())
        let privatePEM = RSAKeyFormatter.formatPrivateKey(privateKeyData.base64EncodedString())
        
        return (publicPEM, privatePEM)
    }
    
    static func extractPublicKey(from privateKey: SecKey) throws -> String {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw RSAError.extractionFailed
        }
        
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw RSAError.extractionFailed
        }
        
        return RSAKeyFormatter.formatPublicKey(publicKeyData.base64EncodedString())
    }
} 