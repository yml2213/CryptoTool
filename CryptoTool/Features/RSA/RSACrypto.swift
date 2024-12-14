import Foundation
import Security

class RSACrypto {
    static func parsePublicKey(_ publicKey: String, keySize: Int) throws -> SecKey {
        let keyString = publicKey
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        guard let keyData = Data(base64Encoded: keyString) else {
            throw RSAError.invalidKeyFormat
        }
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: keySize
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyData as CFData,
                                           attributes as CFDictionary,
                                           &error) else {
            throw RSAError.invalidKey
        }
        
        return key
    }
    
    static func parsePrivateKey(_ privateKey: String, keySize: Int) throws -> SecKey {
        let keyString = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        guard let keyData = Data(base64Encoded: keyString) else {
            throw RSAError.invalidKeyFormat
        }
        
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: keySize
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyData as CFData,
                                           attributes as CFDictionary,
                                           &error) else {
            throw RSAError.invalidKey
        }
        
        return key
    }
    
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
        
        let publicPEM = "-----BEGIN PUBLIC KEY-----\n" +
            publicKeyData.base64EncodedString().chunks(ofCount: 64).joined(separator: "\n") +
            "\n-----END PUBLIC KEY-----"
        
        let privatePEM = "-----BEGIN PRIVATE KEY-----\n" +
            privateKeyData.base64EncodedString().chunks(ofCount: 64).joined(separator: "\n") +
            "\n-----END PRIVATE KEY-----"
        
        return (publicPEM, privatePEM)
    }
    
    static func extractPublicKey(from privateKey: SecKey) throws -> SecKey {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw RSAError.extractionFailed
        }
        return publicKey
    }
    
    static func validateKeyPair(publicKey: SecKey, privateKey: SecKey) throws {
        try RSAKeyValidator.validateKeyPair(publicKey: publicKey, privateKey: privateKey)
    }
    
    static func getKeyData(from key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            throw RSAError.extractionFailed
        }
        return data
    }
} 