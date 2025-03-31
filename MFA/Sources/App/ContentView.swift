import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            // 左侧边栏
            SidebarView(searchText: $searchText)
                .frame(minWidth: 250, maxWidth: .infinity)
        } detail: {
            // 右侧主内容区
            if let account = appState.selectedAccount {
                AccountDetailView(account: account)
            } else {
                EmptyStateView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// 空状态视图
private struct EmptyStateView: View {
    var body: some View {
        VStack {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("选择一个账户或添加新账户")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
} 