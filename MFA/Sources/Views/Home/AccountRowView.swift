import SwiftUI

struct AccountRowView: View {
    let account: MFAAccount
    @State private var currentCode: String = ""
    @State private var timeRemaining: Int = 30
    @EnvironmentObject private var appState: AppState
    
    // 定时器用于更新验证码
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            // 账户图标
            accountIcon
            
            // 账户信息
            accountInfo
            
            Spacer()
            
            // 验证码显示
            if account.type == .totp {
                codeDisplay
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // 使整行可点击
        .onTapGesture {
            appState.selectedAccount = account
        }
        .onAppear {
            updateCode()
        }
        .onReceive(timer) { _ in
            updateTimeRemaining()
            if timeRemaining == account.period {
                updateCode()
            }
        }
    }
    
    private var accountIcon: some View {
        Group {
            if let iconName = account.iconName {
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: 32, height: 32)
        .background(Color(.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var accountInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(account.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(account.issuer)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
    
    private var codeDisplay: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // 验证码
            Text(currentCode)
                .font(.system(.body, design: .monospaced))
                .bold()
            
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
    }
    
    private var progress: Double {
        Double(timeRemaining) / Double(account.period)
    }
    
    private func updateTimeRemaining() {
        timeRemaining = account.period - Int(Date().timeIntervalSince1970) % account.period
    }
    
    private func updateCode() {
        currentCode = account.generateCode()
    }
}

// 预览
#Preview {
    List {
        AccountRowView(account: MFAAccount(
            name: "个人账户",
            issuer: "GitHub",
            secret: "ABCDEF123456"
        ))
        AccountRowView(account: MFAAccount(
            name: "工作账户",
            issuer: "Google",
            secret: "GHIJKL789012",
            type: .hotp
        ))
    }
    .frame(width: 300)
    .environmentObject(AppState())
}