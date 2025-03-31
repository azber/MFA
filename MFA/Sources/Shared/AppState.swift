import SwiftUI
import ServiceManagement
import LocalAuthentication

/// 全局应用状态管理
public class AppState: ObservableObject {
    /// 应用主题设置
    @Published public var colorScheme: ColorScheme = .light {
        didSet {
            UserDefaults.standard.set(colorScheme == .dark, forKey: "isDarkMode")
        }
    }
    
    /// 当前选中的账户
    @Published public var selectedAccount: MFAAccount? {
        didSet {
            if selectedAccount != oldValue {
                objectWillChange.send()
            }
        }
    }
    
    /// 所有MFA账户列表
    @Published public var accounts: [MFAAccount] = [] {
        didSet {
            saveAccountsToDisk()
        }
    }
    
    // MARK: - 初始化
    
    public init() {
        // 加载颜色主题
        if UserDefaults.standard.bool(forKey: "isDarkMode") {
            colorScheme = .dark
        }
        
        // 加载账户数据
        loadAccountsFromDisk()
        
        // 配置自动锁定
        setupAutoLock()
        
        // 配置开机启动
        setupLaunchAtLogin()
    }
    
    // MARK: - 账户管理
    
    /// 添加新账户
    /// - Parameter account: 要添加的MFA账户
    public func addAccount(_ account: MFAAccount) {
        accounts.append(account)
    }
    
    /// 删除账户
    /// - Parameter account: 要删除的MFA账户
    public func removeAccount(_ account: MFAAccount) {
        accounts.removeAll { $0.id == account.id }
        if selectedAccount?.id == account.id {
            selectedAccount = nil
        }
    }
    
    /// 更新账户信息
    /// - Parameter account: 要更新的MFA账户
    public func updateAccount(_ account: MFAAccount) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            if selectedAccount?.id == account.id {
                selectedAccount = account
            }
        }
    }
    
    // MARK: - 安全功能
    
    private func setupAutoLock() {
        // 获取自动锁定超时时间
        let timeout = UserDefaults.standard.integer(forKey: "autoLockTimeout")
        guard timeout > 0 else { return }
        
        // TODO: 实现自动锁定逻辑
    }
    
    public func checkTouchID(completion: @escaping (Bool) -> Void) {
        guard UserDefaults.standard.bool(forKey: "useTouchID") else {
            completion(true)
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "验证身份以访问 MFA 验证器") { success, error in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }
    
    // MARK: - 系统集成
    
    private func setupLaunchAtLogin() {
        if UserDefaults.standard.bool(forKey: "launchAtLogin") {
            enableLaunchAtLogin()
        } else {
            disableLaunchAtLogin()
        }
    }
    
    public func enableLaunchAtLogin() {
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.register()
            } else {
                // Fallback on earlier versions
                // TODO: 使用旧版API
            }
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }
    
    public func disableLaunchAtLogin() {
        do {
            if #available(macOS 13.0, *) {
                try SMAppService.mainApp.unregister()
            } else {
                // Fallback on earlier versions
                // TODO: 使用旧版API
            }
        } catch {
            print("Failed to disable launch at login: \(error)")
        }
    }
    
    // MARK: - 导入导出
    
    public func importAccounts(from url: URL) throws {
        // TODO: 实现导入逻辑
    }
    
    public func exportAccounts(to url: URL) throws {
        // TODO: 实现导出逻辑
    }
    
    // MARK: - 设置管理
    
    public func resetAllSettings() {
        // 重置所有设置
        let defaults = UserDefaults.standard
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        
        // 重新加载默认值
        colorScheme = .light
        accounts = []
        selectedAccount = nil
        
        // 重置其他设置...
    }
} 