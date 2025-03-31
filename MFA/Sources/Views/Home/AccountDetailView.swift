import SwiftUI

struct AccountDetailView: View {
    let account: MFAAccount
    @State private var timeRemaining: Int = 30
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var deleteConfirmationText = ""
    @State private var showingDeleteConfirmationError = false
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    // 定时器，用于更新验证码
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            // 账户信息区域
            accountHeader
            
            // 验证码显示区域
            codeDisplay
            
            // 管理按钮
            managementButtons
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
        .sheet(isPresented: $showingEditSheet) {
            AddAccountView(editingAccount: account)
                .environmentObject(appState)
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            TextField("输入 \"DELETE\" 确认", text: $deleteConfirmationText)
                .autocorrectionDisabled()
            
            Button("删除", role: .destructive) {
                if deleteConfirmationText == "DELETE" {
                    deleteAccount()
                } else {
                    showingDeleteConfirmationError = true
                    deleteConfirmationText = ""
                }
            }
            .disabled(deleteConfirmationText != "DELETE")
            
            Button("取消", role: .cancel) {
                deleteConfirmationText = ""
            }
        } message: {
            Text("⚠️ 警告：此操作将永久删除 \"\(account.name)\" 账户及其验证码。\n\n删除后，您将无法再生成此账户的验证码，可能导致无法登录相关服务。\n\n请输入 \"DELETE\" 确认删除。")
        }
        .alert("确认失败", isPresented: $showingDeleteConfirmationError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("您需要输入 \"DELETE\" 才能确认删除操作。")
        }
    }
    
    private var accountHeader: some View {
        VStack(spacing: 16) {
            // 账户图标
            Group {
                if let iconName = account.iconName {
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                }
            }
            .frame(width: 80, height: 80)
            
            // 账户信息
            VStack(spacing: 8) {
                Text(account.name)
                    .font(.title)
                    .bold()
                Text(account.issuer)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var codeDisplay: some View {
        VStack(spacing: 20) {
            // 验证码
            let code = account.generateCode()
            Text(code)
                .font(.system(size: 48, weight: .medium, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.textBackgroundColor).opacity(0.3) : Color(.textBackgroundColor).opacity(0.1))
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    copyCode()
                }
            
            // 进度条和倒计时
            HStack(spacing: 8) {
                // 圆形进度条
                CircularProgressView(progress: Double(timeRemaining) / Double(account.period))
                    .frame(width: 20, height: 20)
                
                Text("\(timeRemaining)秒后更新")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Spacer()
                
                // 复制状态提示
                Text("点击复制")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.windowBackgroundColor) : .white)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .frame(maxWidth: 500) // 限制最大宽度，与按钮区域保持一致
    }
    
    private var managementButtons: some View {
        VStack(spacing: 12) {
            // 主要按钮 - 编辑
            Button(action: { showingEditSheet = true }) {
                Label("编辑账户", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // 次要操作菜单
            Menu {
                // 复制密钥选项
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(account.secret, forType: .string)
                }) {
                    Label("复制密钥", systemImage: "doc.on.doc")
                }
                
                // 删除选项 - 放在菜单的最底部
                Divider()
                
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("删除账户", systemImage: "trash")
                }
            } label: {
                Label("更多操作", systemImage: "ellipsis.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = account.period - Int(Date().timeIntervalSince1970) % account.period
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(account.generateCode(), forType: .string)
    }
    
    private func deleteAccount() {
        appState.removeAccount(account)
    }
}

// 圆形进度条视图
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 1), value: progress)
    }
}

// String 扩展，用于分割验证码
extension String {
    subscript(range: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
}

#Preview {
    AccountDetailView(account: MFAAccount(
        name: "示例账户",
        issuer: "Example.com",
        secret: "ABCDEF123456"
    ))
    .environmentObject(AppState())
}
