import SwiftUI

struct AccountDetailView: View {
    let account: MFAAccount
    @State private var timeRemaining: Int = 30
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
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
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                // TODO: 实现删除逻辑
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这个账户吗？此操作无法撤销。")
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
            HStack(spacing: 16) {
                let code = account.generateCode()
                ForEach(0..<2) { index in
                    Text(code[index * 3..<(index + 1) * 3])
                        .font(.system(size: 48, weight: .medium, design: .monospaced))
                        .frame(width: 120)
                }
            }
            
            // 进度条和倒计时
            HStack(spacing: 16) {
                // 圆形进度条
                CircularProgressView(progress: Double(timeRemaining) / Double(account.period))
                    .frame(width: 24, height: 24)
                
                Text("\(timeRemaining)秒后更新")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            // 复制按钮
            Button(action: copyCode) {
                Label("复制验证码", systemImage: "doc.on.doc")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.windowBackgroundColor) : .white)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
    
    private var managementButtons: some View {
        HStack(spacing: 16) {
            Button(action: { showingEditSheet = true }) {
                Label("编辑", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: { showingDeleteAlert = true }) {
                Label("删除", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .controlSize(.large)
    }
    
    private func updateTimeRemaining() {
        timeRemaining = account.period - Int(Date().timeIntervalSince1970) % account.period
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(account.generateCode(), forType: .string)
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
} 