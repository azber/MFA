import Foundation

public struct MFAAccount: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var issuer: String
    public var secret: String
    public var algorithm: Algorithm
    public var digits: Int
    public var period: Int
    public var type: AccountType
    public var iconName: String?
    
    // HOTP 专用
    private var counter: UInt64 = 0
    
    public enum Algorithm: String, Codable, Hashable {
        case sha1
        case sha256
        case sha512
    }
    
    public enum AccountType: String, Codable, Hashable {
        case totp // 基于时间
        case hotp // 基于计数器
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        issuer: String,
        secret: String,
        algorithm: Algorithm = .sha1,
        digits: Int = 6,
        period: Int = 30,
        type: AccountType = .totp,
        iconName: String? = nil,
        counter: UInt64 = 0
    ) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
        self.type = type
        self.iconName = iconName
        self.counter = counter
    }
    
    // 生成当前验证码
    func generateCode() -> String {
        do {
            switch type {
            case .totp:
                return try OTPGenerator.generateTOTP(
                    secret: secret,
                    period: period,
                    digits: digits,
                    algorithm: algorithm
                )
            case .hotp:
                let code = try OTPGenerator.generateHOTP(
                    secret: secret,
                    counter: counter,
                    digits: digits,
                    algorithm: algorithm
                )
                // TODO: 更新并保存计数器
                return code
            }
        } catch {
            print("Failed to generate code: \(error)")
            return String(repeating: "-", count: digits)
        }
    }
    
    // Hashable 实现
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable 实现
    public static func == (lhs: MFAAccount, rhs: MFAAccount) -> Bool {
        lhs.id == rhs.id
    }
} 