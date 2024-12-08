import Foundation

class TempDataManager {
    static let shared = TempDataManager()
    private var tempStorage: [String: Any] = [:]
    
    private init() {}
    
    func saveData(_ data: Any, forKey key: String) {
        tempStorage[key] = data
    }
    
    func getData(forKey key: String) -> Any? {
        return tempStorage[key]
    }
    
    func clearData(forKey key: String) {
        tempStorage.removeValue(forKey: key)
    }
    
    func clearAllData() {
        tempStorage.removeAll()
    }
} 