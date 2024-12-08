import Foundation
import Security

struct RSAKeyValidator {
    static func validateKeyPair(publicKey: SecKey, privateKey: SecKey) throws {
        let testString = "RSA Key Pair Validation Test"
        guard let testData = testString.data(using: .utf8) else {
            throw RSAError.validationFailed
        }
        
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionPKCS1,
            testData as CFData,
            &error
        ) as Data? else {
            throw RSAError.validationFailed
        }
        
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .rsaEncryptionPKCS1,
            encryptedData as CFData,
            &error
        ) as Data? else {
            throw RSAError.validationFailed
        }
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8),
              decryptedString == testString else {
            throw RSAError.validationFailed
        }
    }
} 