import Foundation
import CryptoKit

class AccountStorage {
    private static let accountsKey = "mfa_accounts"
    private static let keychainService = "com.example.mfa"
    
    static func saveAccounts(_ accounts: [MFAAccount]) throws {
        // 将账户数据编码为JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(accounts)
        
        // 加密数据
        let key = try getOrCreateEncryptionKey()
        let encryptedData = try encrypt(data: data, using: key)
        
        // 保存到UserDefaults
        UserDefaults.standard.set(encryptedData, forKey: accountsKey)
    }
    
    static func loadAccounts() throws -> [MFAAccount] {
        guard let encryptedData = UserDefaults.standard.data(forKey: accountsKey) else {
            return []
        }
        
        // 解密数据
        let key = try getOrCreateEncryptionKey()
        let data = try decrypt(data: encryptedData, using: key)
        
        // 解码JSON
        let decoder = JSONDecoder()
        return try decoder.decode([MFAAccount].self, from: data)
    }
    
    // MARK: - 加密相关
    
    private static func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let keyData = loadKeyFromKeychain() {
            return SymmetricKey(data: keyData)
        }
        
        // 创建新密钥
        let key = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(key: key)
        return key
    }
    
    private static func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "encryption_key",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    private static func saveKeyToKeychain(key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "encryption_key",
            kSecValueData as String: keyData
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
    
    private static func encrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let nonce = try AES.GCM.Nonce(data: Data(count: 12))
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        return sealedBox.combined!
    }
    
    private static func decrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

// MARK: - AppState 扩展
extension AppState {
    func loadAccountsFromDisk() {
        do {
            accounts = try AccountStorage.loadAccounts()
        } catch {
            print("Failed to load accounts: \(error)")
            // TODO: 显示错误提示
        }
    }
    
    func saveAccountsToDisk() {
        do {
            try AccountStorage.saveAccounts(accounts)
        } catch {
            print("Failed to save accounts: \(error)")
            // TODO: 显示错误提示
        }
    }
} 
