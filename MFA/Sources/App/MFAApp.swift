import SwiftUI

@main
struct MFAApp: App {
    @StateObject private var appState: AppState
    @StateObject private var menuBarManager: MenuBarManager
    
    init() {
        let state = AppState()
        self._appState = StateObject(wrappedValue: state)
        self._menuBarManager = StateObject(wrappedValue: MenuBarManager(appState: state))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(appState.colorScheme)
        }
        .windowStyle(.hiddenTitleBar) // 使用现代的无标题栏样式
        .commands {
            MFACommands(appState: appState)
        }
        
        // 设置菜单栏
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
} 