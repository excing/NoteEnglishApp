import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // 限制桌面端窗口最小尺寸（360x520），保证人机工程学体验，防止极端挤压
    self.minSize = NSSize(width: 360, height: 520)
    self.title = "OtterJot"

    RegisterGeneratedPlugins(registry: flutterViewController)
    QuickPolishManager.shared.setup(flutterViewController: flutterViewController, window: self)

    super.awakeFromNib()
  }
}
