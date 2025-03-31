import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
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
    
    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            securitySettings
                .tabItem {
                    Label("安全", systemImage: "lock")
                }
            
            shortcutSettings
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }
            
            aboutView
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 300)
        .padding()
    }
    
    // 通用设置
    private var generalSettings: some View {
        Form {
            Section {
                Toggle("在菜单栏显示", isOn: $showInMenuBar)
                    .onChange(of: showInMenuBar) { oldValue, newValue in
                        // TODO: 更新菜单栏状态
                    }
                
                Toggle("开机时启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        // TODO: 配置开机启动
                    }
                
                Picker("验证码复制后清除", selection: $copyTimeout) {
                    ForEach(copyTimeoutOptions, id: \.0) { timeout, label in
                        Text(label).tag(timeout)
                    }
                }
            }
            
            Section {
                Picker("外观", selection: $appState.colorScheme) {
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
                Toggle("使用 Touch ID 解锁", isOn: $useTouchID)
                    .onChange(of: useTouchID) { oldValue, newValue in
                        // TODO: 配置 Touch ID
                    }
                
                Picker("自动锁定", selection: $autoLockTimeout) {
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
    
    // 快捷键设置
    private var shortcutSettings: some View {
        Form {
            Section {
                HStack {
                    Text("显示/隐藏窗口")
                    Spacer()
                    KeyboardShortcutView(shortcut: .init("⌘⇧M"))
                }
                
                HStack {
                    Text("显示/隐藏菜单栏")
                    Spacer()
                    KeyboardShortcutView(shortcut: .init("⌘⇧K"))
                }
                
                HStack {
                    Text("添加新账户")
                    Spacer()
                    KeyboardShortcutView(shortcut: .init("⌘N"))
                }
                
                HStack {
                    Text("复制选中账户验证码")
                    Spacer()
                    KeyboardShortcutView(shortcut: .init("⌘⇧C"))
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // 关于页面
    private var aboutView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("MFA 验证器")
                .font(.title)
            
            Text("版本 1.0.0")
                .foregroundColor(.secondary)
            
            Text("© 2024 Your Company")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("检查更新") {
                // TODO: 检查更新
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
