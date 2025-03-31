import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var searchText: String
    @State private var isAddingAccount = false
    
    var filteredAccounts: [MFAAccount] {
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
            // 搜索框
            searchField
            
            // 账户列表
            List(filteredAccounts, selection: $appState.selectedAccount) { account in
                AccountRowView(account: account)
            }
            .listStyle(.sidebar)
            
            // 底部工具栏
            bottomToolbar
        }
        .sheet(isPresented: $isAddingAccount) {
            AddAccountView()
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索账户...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .padding()
    }
    
    private var bottomToolbar: some View {
        HStack {
            Button(action: { isAddingAccount = true }) {
                Image(systemName: "plus")
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "gear")
            }
        }
        .padding()
        .buttonStyle(.borderless)
    }
}

#Preview {
    SidebarView(searchText: .constant(""))
        .environmentObject(AppState())
} 
