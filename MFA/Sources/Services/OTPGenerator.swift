import Foundation
import CryptoKit

enum OTPError: Error {
    case invalidBase32String
    case invalidHMACAlgorithm
}

struct OTPGenerator {
    // HOTP 算法实现 (RFC 4226)
    static func generateHOTP(secret: String, counter: UInt64, digits: Int = 6, algorithm: MFAAccount.Algorithm = .sha1) throws -> String {
        // 解码Base32密钥
        let keyData = try base32Decode(secret)
        
        // 计数器转为大端字节序
        var counterBytes = counter.bigEndian
        let counterData = Data(bytes: &counterBytes, count: MemoryLayout<UInt64>.size)
        
        // 计算HMAC
        let hmac = try calculateHMAC(key: keyData, message: counterData, algorithm: algorithm)
        
        // 生成验证码
        return truncate(hmac: hmac, digits: digits)
    }
    
    // TOTP 算法实现 (RFC 6238)
    static func generateTOTP(secret: String, time: Date = Date(), period: Int = 30, digits: Int = 6, algorithm: MFAAccount.Algorithm = .sha1) throws -> String {
        // 计算时间计数器
        let counter = UInt64(time.timeIntervalSince1970) / UInt64(period)
        
        // 使用HOTP生成验证码
        return try generateHOTP(secret: secret, counter: counter, digits: digits, algorithm: algorithm)
    }
    
    // Base32解码
    private static func base32Decode(_ string: String) throws -> Data {
        let base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var bytes = [UInt8]()
        var buffer = 0
        var bitsRemaining = 0
        
        // 移除空格和连字符
        let cleanString = string.replacingOccurrences(of: "[^A-Za-z2-7]", with: "", options: .regularExpression)
        
        for char in cleanString.uppercased() {
            guard let charValue = base32Chars.firstIndex(of: char)?.utf16Offset(in: base32Chars) else {
                throw OTPError.invalidBase32String
            }
            
            buffer = (buffer << 5) | charValue
            bitsRemaining += 5
            
            while bitsRemaining >= 8 {
                bitsRemaining -= 8
                bytes.append(UInt8(buffer >> bitsRemaining))
                buffer &= (1 << bitsRemaining) - 1
            }
        }
        
        return Data(bytes)
    }
    
    // 计算HMAC
    private static func calculateHMAC(key: Data, message: Data, algorithm: MFAAccount.Algorithm) throws -> Data {
        switch algorithm {
        case .sha1:
            let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: message, using: SymmetricKey(data: key))
            return Data(hmac)
        case .sha256:
            let hmac = HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: key))
            return Data(hmac)
        case .sha512:
            let hmac = HMAC<SHA512>.authenticationCode(for: message, using: SymmetricKey(data: key))
            return Data(hmac)
        }
    }
    
    // 截断HMAC生成验证码
    private static func truncate(hmac: Data, digits: Int) -> String {
        let offset = Int(hmac.last! & 0xf)
        
        let truncatedHMAC = hmac.withUnsafeBytes { ptr -> UInt32 in
            let offset = ptr.baseAddress!.advanced(by: offset).assumingMemoryBound(to: UInt32.self)
            return UInt32(bigEndian: offset.pointee)
        }
        
        let code = truncatedHMAC & 0x7fffffff
        let modulus = UInt32(pow(10.0, Double(digits)))
        let format = "%0\(digits)d"
        
        return String(format: format, code % modulus)
    }
} 