import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    // 临时状态变量，用于存储设置
    @State private var tempAutoLockTimeout: Int
    @State private var tempUseTouchID: Bool
    @State private var tempShowInMenuBar: Bool
    @State private var tempLaunchAtLogin: Bool
    @State private var tempCopyTimeout: Int
    @State private var tempColorScheme: ColorScheme?
    
    // 持久化存储
    @AppStorage("autoLockTimeout") private var autoLockTimeout: Int = 5
    @AppStorage("useTouchID") private var useTouchID: Bool = false
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = true
    @AppStorage("copyTimeout") private var copyTimeout: Int = 10
    
    private let timeoutOptions = [
        (0, "从不"),
        (1, "1分钟"),
        (5, "5分钟"),
        (15, "15分钟"),
        (30, "30分钟"),
        (60, "1小时")
    ]
    
    private let copyTimeoutOptions = [
        (5, "5秒"),
        (10, "10秒"),
        (15, "15秒"),
        (30, "30秒"),
        (60, "1分钟")
    ]
    
    init() {
        // 初始化临时状态变量
        _tempAutoLockTimeout = State(initialValue: UserDefaults.standard.integer(forKey: "autoLockTimeout"))
        _tempUseTouchID = State(initialValue: UserDefaults.standard.bool(forKey: "useTouchID"))
        _tempShowInMenuBar = State(initialValue: UserDefaults.standard.bool(forKey: "showInMenuBar"))
        _tempLaunchAtLogin = State(initialValue: UserDefaults.standard.bool(forKey: "launchAtLogin"))
        _tempCopyTimeout = State(initialValue: UserDefaults.standard.integer(forKey: "copyTimeout"))
        
        // 获取当前的颜色方案
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        _tempColorScheme = State(initialValue: isDarkMode ? .dark : .light)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                generalSettings
                    .padding(.horizontal, 16)
                    .tabItem {
                        Label("通用", systemImage: "gear")
                    }
                
                securitySettings
                    .padding(.horizontal, 16)
                    .tabItem {
                        Label("安全", systemImage: "lock")
                    }
                
                aboutView
                    .padding(.horizontal, 16)
                    .tabItem {
                        Label("关于", systemImage: "info.circle")
                    }
            }
            .frame(height: 300)
            
            // 底部按钮
            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                Button("保存") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 12)
        }
        .frame(width: 520)
        .padding(20)
    }
    
    // 保存设置
    private func saveSettings() {
        // 保存到 AppStorage
        autoLockTimeout = tempAutoLockTimeout
        useTouchID = tempUseTouchID
        showInMenuBar = tempShowInMenuBar
        launchAtLogin = tempLaunchAtLogin
        copyTimeout = tempCopyTimeout
        
        // 保存颜色方案
        if let colorScheme = tempColorScheme {
            appState.colorScheme = colorScheme
        }
        
        // 应用设置
        applySettings()
    }
    
    // 应用设置
    private func applySettings() {
        // 应用菜单栏设置 - 通过 UserDefaults 通知机制自动应用
        UserDefaults.standard.set(tempShowInMenuBar, forKey: "showInMenuBar")
        
        // 应用开机启动设置
        if tempLaunchAtLogin {
            appState.enableLaunchAtLogin()
        } else {
            appState.disableLaunchAtLogin()
        }
        
        // 应用 Touch ID 设置
        // 无需额外操作，已通过 AppStorage 自动应用
    }
    
    // 通用设置
    private var generalSettings: some View {
        Form {
            Section {
                Toggle("在菜单栏显示", isOn: $tempShowInMenuBar)
                
                Toggle("开机时启动", isOn: $tempLaunchAtLogin)
                
                Picker("验证码复制后清除", selection: $tempCopyTimeout) {
                    ForEach(copyTimeoutOptions, id: \.0) { timeout, label in
                        Text(label).tag(timeout)
                    }
                }
            }
            
            Section {
                Picker("外观", selection: $tempColorScheme) {
                    Text("浅色").tag(Optional<ColorScheme>.some(.light))
                    Text("深色").tag(Optional<ColorScheme>.some(.dark))
                    Text("跟随系统").tag(Optional<ColorScheme>.none)
                }
            }
            
            Section {
                Button("导入账户...") {
                    // TODO: 导入功能
                }
                
                Button("导出账户...") {
                    // TODO: 导出功能
                }
            }
        }
    }
    
    // 安全设置
    private var securitySettings: some View {
        Form {
            Section {
                Toggle("使用 Touch ID 解锁", isOn: $tempUseTouchID)
                
                Picker("自动锁定", selection: $tempAutoLockTimeout) {
                    ForEach(timeoutOptions, id: \.0) { timeout, label in
                        Text(label).tag(timeout)
                    }
                }
            }
            
            Section {
                Button("更改密码...") {
                    // TODO: 更改密码
                }
                
                Button("重置所有设置") {
                    // TODO: 重置设置
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // 关于页面
    private var aboutView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
                .padding(.top, 20)
            
            Text("MFA 验证器")
                .font(.title2)
            
            Text("版本 \(appVersion)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\u{00A9} 2025 MFA 验证器开发组")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("检查更新") {
                // TODO: 检查更新
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 获取应用版本号
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// 快捷键显示视图
struct KeyboardShortcutView: View {
    let shortcut: String
    
    var body: some View {
        Text(shortcut)
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)
    }
}

// 预览
#Preview {
    SettingsView()
        .environmentObject(AppState())
}
