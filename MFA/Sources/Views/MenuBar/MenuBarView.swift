import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    
    private var filteredAccounts: [MFAAccount] {
        if searchText.isEmpty {
            return appState.accounts
        }
        return appState.accounts.filter { account in
            account.name.localizedCaseInsensitiveContains(searchText) ||
            account.issuer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchBar
            
            // 账户列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredAccounts) { account in
                        MenuBarAccountRow(account: account)
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 底部按钮
            bottomButtons
        }
        .frame(height: 400)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索账户...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(6)
        .padding()
    }
    
    private var bottomButtons: some View {
        HStack {
            Button(action: openMainWindow) {
                Label("打开主窗口", systemImage: "macwindow")
            }
            
            Spacer()
            
//            Button(action: NSApplication.shared.terminate) {
//                Label("退出", systemImage: "power")
//            }
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .padding()
    }
    
    private func openMainWindow() {
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}

// 菜单栏账户行视图
struct MenuBarAccountRow: View {
    let account: MFAAccount
    @State private var code = ""
    @State private var timeRemaining: Int = 30
    @State private var isCopied = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            // 账户信息
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                Text(account.issuer)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 验证码
            if account.type == .totp {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                            .bold()
                        
                        Button(action: copyCode) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .foregroundColor(isCopied ? .green : .accentColor)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: geometry.size.width, height: 2)
                            
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: geometry.size.width * progress, height: 2)
                        }
                    }
                    .frame(width: 50, height: 2)
                }
            } else {
                Button(action: copyCode) {
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .bold()
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onAppear {
            updateCode()
            if account.type == .totp {
                updateTimeRemaining()
            }
        }
        .onReceive(timer) { _ in
            if account.type == .totp {
                updateTimeRemaining()
                if timeRemaining == account.period {
                    updateCode()
                }
            }
        }
    }
    
    private var progress: Double {
        Double(timeRemaining) / Double(account.period)
    }
    
    private func updateTimeRemaining() {
        timeRemaining = account.period - Int(Date().timeIntervalSince1970) % account.period
    }
    
    private func updateCode() {
        code = account.generateCode()
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        
        withAnimation {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState())
} 
