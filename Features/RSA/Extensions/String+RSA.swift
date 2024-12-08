import Foundation

extension String {
    func chunks(ofCount count: Int) -> [String] {
        var chunks: [String] = []
        var remaining = self
        while !remaining.isEmpty {
            let chunk = String(remaining.prefix(count))
            chunks.append(chunk)
            remaining = String(remaining.dropFirst(count))
        }
        return chunks
    }
    
    func hexadecimalToData() throws -> Data {
        var data = Data()
        var temp = ""
        
        for char in self {
            temp += String(char)
            if temp.count == 2 {
                guard let num = UInt8(temp, radix: 16) else {
                    throw RSAError.invalidInput
                }
                data.append(num)
                temp = ""
            }
        }
        
        if !temp.isEmpty {
            throw RSAError.invalidInput
        }
        return data
    }
} 