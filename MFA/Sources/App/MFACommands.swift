import SwiftUI

struct MFACommands: Commands {
    let appState: AppState
    
    var body: some Commands {
        // 文件菜单
        CommandGroup(after: .newItem) {
            Button("添加账户...") {
                // TODO: 显示添加账户窗口
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Divider()
            
            Button("导入账户...") {
                // TODO: 导入功能
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            
            Button("导出账户...") {
                // TODO: 导出功能
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
        
        // 编辑菜单
        CommandGroup(after: .pasteboard) {
            Button("复制验证码") {
                if let account = appState.selectedAccount {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(account.generateCode(), forType: .string)
                }
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(appState.selectedAccount == nil)
        }
        
        // 视图菜单
        CommandGroup(after: .sidebar) {
            Button(action: {
                // TODO: 切换深色模式
                appState.colorScheme = appState.colorScheme == .dark ? .light : .dark
            }) {
                Text(appState.colorScheme == .dark ? "浅色模式" : "深色模式")
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
        }
        
        // 帮助菜单
        CommandGroup(after: .help) {
            Button("MFA 验证器帮助") {
                // TODO: 打开帮助文档
                if let url = URL(string: "https://support.example.com/mfa-help") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
} 