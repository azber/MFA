import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @StateObject private var camera = CameraViewModel()
    var onCodeScanned: (String) -> Void
    
    var body: some View {
        ZStack {
            // 摄像头预览
            CameraPreviewView(session: camera.session)
                .overlay {
                    // 扫描框
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 150))
                        .foregroundColor(.white.opacity(0.5))
                }
        }
        .onAppear {
            camera.requestAccess()
            camera.onCodeScanned = onCodeScanned
        }
        .onDisappear {
            camera.stopScanning()
        }
    }
}

// 摄像头预览视图
struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.videoGravity = .resizeAspectFill
        view.layer = previewLayer
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer as? AVCaptureVideoPreviewLayer {
            layer.frame = nsView.bounds
        }
    }
}

// 摄像头控制器
class CameraViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var onCodeScanned: ((String) -> Void)?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func requestAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startScanning()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.startScanning()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            let output = AVCaptureMetadataOutput()
            
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
                
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                if output.availableMetadataObjectTypes.contains(.qr) {
                    output.metadataObjectTypes = [.qr]
                }
            }
        } catch {
            print("Camera setup error: \(error)")
        }
    }
    
    func startScanning() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    // AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else { return }
        
        stopScanning()
        onCodeScanned?(code)
    }
}

#Preview {
    QRScannerView { code in
        print("Scanned code: \(code)")
    }
}