import SwiftUI
import AppKit

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        
        // 检查用户设置
        if UserDefaults.standard.bool(forKey: "showInMenuBar") {
            setupStatusItem()
            setupPopover()
            setupEventMonitor()
        }
        
        // 监听设置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleSettingsChange() {
        let shouldShow = UserDefaults.standard.bool(forKey: "showInMenuBar")
        
        if shouldShow && statusItem == nil {
            // 启用菜单栏图标
            setupStatusItem()
            setupPopover()
            setupEventMonitor()
        } else if !shouldShow && statusItem != nil {
            // 禁用菜单栏图标
            removeStatusItem()
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "key.fill", accessibilityDescription: "MFA")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    private func removeStatusItem() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        popover = nil
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(appState)
        )
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePopover()
        }
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                hidePopover()
            } else {
                showPopover(button)
            }
        }
    }
    
    private func showPopover(_ button: NSStatusBarButton) {
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // 确保弹出窗口在最前面
        if let window = popover?.contentViewController?.view.window {
            window.level = .statusBar
        }
    }
    
    private func hidePopover() {
        popover?.performClose(nil)
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
}
