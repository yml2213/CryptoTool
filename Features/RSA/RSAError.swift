import Foundation

enum RSAError: Error, LocalizedError {
    case invalidKey
    case invalidKeyFormat
    case invalidKeySize
    case conversionFailed
    case extractionFailed
    case validationFailed
    case invalidInput
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "无效的密钥"
        case .invalidKeyFormat:
            return "密钥格式错误"
        case .invalidKeySize:
            return "密钥长度不正确"
        case .conversionFailed:
            return "密钥转换失败"
        case .extractionFailed:
            return "密钥提取失败"
        case .validationFailed:
            return "密钥对验证失败"
        case .invalidInput:
            return "输入数据格式错误"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        }
    }
} 