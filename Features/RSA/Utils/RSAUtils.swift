import Foundation

struct RSAUtils {
    static func formatHexString(_ hex: String, withSpaces: Bool = true) -> String {
        if withSpaces {
            return hex.map { String($0) }.chunked(into: 2).map { $0.joined() }.joined(separator: " ")
        }
        return hex
    }
    
    static func validateKeySize(_ size: Int) -> Bool {
        return size >= RSAConstants.minimumKeySize && 
               size <= RSAConstants.maximumKeySize && 
               size % 8 == 0
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
} 