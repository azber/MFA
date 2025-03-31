import SwiftUI
import AVFoundation

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var isScanning = false
    @State private var manualAccount = ManualAccountInput()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isValidatingSecret = false
    @State private var isEditMode = false
    @State private var editingAccountId: UUID?
    
    // 初始化方法 - 默认添加模式
    init() {
        self._isEditMode = State(initialValue: false)
    }
    
    // 初始化方法 - 编辑模式
    init(editingAccount: MFAAccount) {
        self._isEditMode = State(initialValue: true)
        self._editingAccountId = State(initialValue: editingAccount.id)
        self._manualAccount = State(initialValue: ManualAccountInput(
            name: editingAccount.name,
            issuer: editingAccount.issuer,
            secret: editingAccount.secret,
            algorithm: editingAccount.algorithm,
            type: editingAccount.type,
            digits: editingAccount.digits,
            period: editingAccount.period,
            counter: 0 // 由于 counter 是私有属性，我们使用默认值
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 选择添加方式 - 仅在非编辑模式下显示
                if !isEditMode {
                    addMethodPicker
                }
                
                if isScanning && !isEditMode {
                    // 扫描QR码视图
                    QRScannerView { code in
                        handleScannedCode(code)
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    // 手动输入表单
                    manualInputForm
                }
            }
            .padding(32)
            .frame(width: 500)
            .navigationTitle(isEditMode ? "编辑账户" : "添加新账户")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { 
                        cancelAndDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !isScanning || isEditMode {
                        Button(isEditMode ? "保存" : "添加") { 
                            if isEditMode {
                                updateAccount()
                            } else {
                                addAccount()
                            }
                        }
                        .disabled(!manualAccount.isValid || isValidatingSecret)
                    }
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var addMethodPicker: some View {
        Picker("添加方式", selection: $isScanning) {
            Text("手动输入").tag(false)
            Text("扫描二维码").tag(true)
        }
        .pickerStyle(.segmented)
    }
    
    private var manualInputForm: some View {
        Form {
            Section {
                TextField("账户名称", text: $manualAccount.name)
                    .textFieldStyle(.roundedBorder)
                TextField("服务提供商", text: $manualAccount.issuer)
                    .textFieldStyle(.roundedBorder)
                SecureField("密钥", text: $manualAccount.secret)
                    .textFieldStyle(.roundedBorder)
                    .help("输入服务提供商给出的密钥，通常是Base32编码的字符串")
                    .onChange(of: manualAccount.secret) { oldValue, newValue in
                        // 自动清除空格和连字符
                        let cleanedValue = newValue.replacingOccurrences(of: "[^A-Za-z2-7]", with: "", options: .regularExpression).uppercased()
                        if cleanedValue != newValue {
                            manualAccount.secret = cleanedValue
                        }
                    }
            }
            
            Section("高级选项") {
                Picker("算法", selection: $manualAccount.algorithm) {
                    Text("SHA1").tag(MFAAccount.Algorithm.sha1)
                    Text("SHA256").tag(MFAAccount.Algorithm.sha256)
                    Text("SHA512").tag(MFAAccount.Algorithm.sha512)
                }
                
                Picker("验证码类型", selection: $manualAccount.type) {
                    Text("基于时间 (TOTP)").tag(MFAAccount.AccountType.totp)
                    Text("基于计数器 (HOTP)").tag(MFAAccount.AccountType.hotp)
                }
                
                Picker("验证码位数", selection: $manualAccount.digits) {
                    Text("6 位").tag(6)
                    Text("7 位").tag(7)
                    Text("8 位").tag(8)
                }
                
                if manualAccount.type == .totp {
                    Stepper("更新周期: \(manualAccount.period)秒", value: $manualAccount.period, in: 30...60, step: 30)
                } else {
                    Stepper("初始计数器值: \(manualAccount.counter)", value: $manualAccount.counter, in: 0...100)
                }
            }
            
            if manualAccount.isValid {
                Section("预览") {
                    VStack(alignment: .center) {
                        Text(previewCode)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .padding(.vertical, 8)
                        
                        if isValidatingSecret {
                            ProgressView()
                                .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // 预览验证码
    private var previewCode: String {
        guard manualAccount.isValid else { return String(repeating: "-", count: manualAccount.digits) }
        
        // 尝试生成预览码
        do {
            if manualAccount.type == .totp {
                return try OTPGenerator.generateTOTP(
                    secret: manualAccount.secret,
                    period: manualAccount.period,
                    digits: manualAccount.digits,
                    algorithm: manualAccount.algorithm
                )
            } else {
                return try OTPGenerator.generateHOTP(
                    secret: manualAccount.secret,
                    counter: UInt64(manualAccount.counter),
                    digits: manualAccount.digits,
                    algorithm: manualAccount.algorithm
                )
            }
        } catch {
            // 如果生成失败，显示占位符
            return String(repeating: "-", count: manualAccount.digits)
        }
    }
    
    private func handleScannedCode(_ code: String) {
        // 解析二维码内容
        guard let url = URL(string: code),
              url.scheme == "otpauth",
              let type = url.host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            showError("无效的二维码格式")
            return
        }
        
        // 解析路径中的账户信息
        let path = url.path.dropFirst() // 移除开头的 "/"
        let accountInfo = path.split(separator: ":", maxSplits: 1).map(String.init)
        
        var issuer = ""
        var name = ""
        
        if accountInfo.count == 2 {
            issuer = accountInfo[0]
            name = accountInfo[1]
        } else if accountInfo.count == 1 {
            name = accountInfo[0]
            // 尝试从查询参数获取issuer
            if let issuerParam = components.queryItems?.first(where: { $0.name == "issuer" })?.value {
                issuer = issuerParam
            }
        } else {
            showError("无效的账户信息")
            return
        }
        
        // 解析查询参数
        let queryItems = components.queryItems ?? []
        guard let secret = queryItems.first(where: { $0.name == "secret" })?.value else {
            showError("缺少密钥信息")
            return
        }
        
        // 验证密钥格式
        isValidatingSecret = true
        
        // 创建账户
        let algorithm = queryItems.first(where: { $0.name == "algorithm" })?.value ?? "SHA1"
        let digits = Int(queryItems.first(where: { $0.name == "digits" })?.value ?? "6") ?? 6
        let period = Int(queryItems.first(where: { $0.name == "period" })?.value ?? "30") ?? 30
        let counter = UInt64(queryItems.first(where: { $0.name == "counter" })?.value ?? "0") ?? 0
        
        // 验证密钥是否有效
        do {
            if type == "totp" {
                _ = try OTPGenerator.generateTOTP(
                    secret: secret,
                    period: period,
                    digits: digits,
                    algorithm: parseAlgorithm(algorithm)
                )
            } else {
                _ = try OTPGenerator.generateHOTP(
                    secret: secret,
                    counter: counter,
                    digits: digits,
                    algorithm: parseAlgorithm(algorithm)
                )
            }
            
            // 创建并添加账户
            let account = MFAAccount(
                name: name,
                issuer: issuer,
                secret: secret,
                algorithm: parseAlgorithm(algorithm),
                digits: digits,
                period: period,
                type: type == "totp" ? .totp : .hotp,
                counter: counter
            )
            
            // 使用AppState的方法添加账户
            appState.addAccount(account)
            appState.selectedAccount = account
            dismiss()
            
        } catch {
            isValidatingSecret = false
            showError("密钥格式无效或无法生成验证码")
        }
    }
    
    private func parseAlgorithm(_ string: String) -> MFAAccount.Algorithm {
        switch string.uppercased() {
        case "SHA256": return .sha256
        case "SHA512": return .sha512
        default: return .sha1
        }
    }
    
    private func addAccount() {
        isValidatingSecret = true
        
        // 验证密钥是否有效
        do {
            if manualAccount.type == .totp {
                _ = try OTPGenerator.generateTOTP(
                    secret: manualAccount.secret,
                    period: manualAccount.period,
                    digits: manualAccount.digits,
                    algorithm: manualAccount.algorithm
                )
            } else {
                _ = try OTPGenerator.generateHOTP(
                    secret: manualAccount.secret,
                    counter: UInt64(manualAccount.counter),
                    digits: manualAccount.digits,
                    algorithm: manualAccount.algorithm
                )
            }
            
            // 创建新账户
            let newAccount = MFAAccount(
                name: manualAccount.name,
                issuer: manualAccount.issuer,
                secret: manualAccount.secret,
                algorithm: manualAccount.algorithm,
                digits: manualAccount.digits,
                period: manualAccount.period,
                type: manualAccount.type,
                counter: UInt64(manualAccount.counter)
            )
            
            // 使用AppState的方法添加账户
            appState.addAccount(newAccount)
            appState.selectedAccount = newAccount
            dismiss()
            
        } catch {
            isValidatingSecret = false
            showError("密钥格式无效或无法生成验证码")
        }
    }
    
    private func updateAccount() {
        isValidatingSecret = true
        
        // 验证密钥是否有效
        do {
            if manualAccount.type == .totp {
                _ = try OTPGenerator.generateTOTP(
                    secret: manualAccount.secret,
                    period: manualAccount.period,
                    digits: manualAccount.digits,
                    algorithm: manualAccount.algorithm
                )
            } else {
                _ = try OTPGenerator.generateHOTP(
                    secret: manualAccount.secret,
                    counter: UInt64(manualAccount.counter),
                    digits: manualAccount.digits,
                    algorithm: manualAccount.algorithm
                )
            }
            
            // 更新账户
            if let editingAccountId = editingAccountId {
                // 创建更新后的账户实例
                let updatedAccount = MFAAccount(
                    id: editingAccountId,
                    name: manualAccount.name,
                    issuer: manualAccount.issuer,
                    secret: manualAccount.secret,
                    algorithm: manualAccount.algorithm,
                    digits: manualAccount.digits,
                    period: manualAccount.period,
                    type: manualAccount.type,
                    counter: UInt64(manualAccount.counter)
                )
                
                // 使用AppState的方法更新账户
                appState.updateAccount(updatedAccount)
                appState.selectedAccount = updatedAccount
                dismiss()
            }
            
        } catch {
            isValidatingSecret = false
            showError("密钥格式无效或无法生成验证码")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        isScanning = false
    }
    
    private func cancelAndDismiss() {
        // 清空表单数据
        manualAccount = ManualAccountInput()
        isScanning = false
        dismiss()
    }
}

// 手动输入的账户信息
private struct ManualAccountInput {
    var name = ""
    var issuer = ""
    var secret = ""
    var algorithm: MFAAccount.Algorithm = .sha1
    var type: MFAAccount.AccountType = .totp
    var digits: Int = 6
    var period: Int = 30
    var counter: Int = 0
    
    var isValid: Bool {
        !name.isEmpty && !issuer.isEmpty && !secret.isEmpty && secret.count >= 16
    }
}

#Preview {
    AddAccountView()
        .environmentObject(AppState())
}
