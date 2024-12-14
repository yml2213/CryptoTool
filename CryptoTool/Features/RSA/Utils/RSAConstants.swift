import Foundation

enum RSAConstants {
    static let defaultPublicExponent = "10001" // 65537 in hex
    static let defaultKeySize = 2048
    static let minimumKeySize = 1024
    static let maximumKeySize = 4096
    
    static let publicKeyHeader = "-----BEGIN PUBLIC KEY-----"
    static let publicKeyFooter = "-----END PUBLIC KEY-----"
    static let privateKeyHeader = "-----BEGIN PRIVATE KEY-----"
    static let privateKeyFooter = "-----END PRIVATE KEY-----"
} 