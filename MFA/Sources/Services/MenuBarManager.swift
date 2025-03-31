import SwiftUI
import AppKit

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "key.fill", accessibilityDescription: "MFA")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
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
    }
} 
