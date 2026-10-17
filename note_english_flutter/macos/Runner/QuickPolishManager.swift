import Cocoa
import FlutterMacOS

/// macOS 原生菜单栏常驻与全局快捷键文本润色管理器
class QuickPolishManager: NSObject {
  static let shared = QuickPolishManager()

  private var statusItem: NSStatusItem?
  private var methodChannel: FlutterMethodChannel?
  private weak var mainWindow: NSWindow?
  private var globalMonitor: Any?
  private var localMonitor: Any?
  private var isEnabled: Bool = true

  func setup(flutterViewController: FlutterViewController, window: NSWindow) {
    self.mainWindow = window
    self.methodChannel = FlutterMethodChannel(
      name: "io.github.excing.otterjot/quick_polish",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    setupMethodCallHandler()
    setupStatusItem()
    setupGlobalHotkeys()
  }

  // MARK: - Method Channel Handler
  private func setupMethodCallHandler() {
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      switch call.method {
      case "initializeQuickPolish":
        result(true)
      case "setQuickPolishEnabled":
        if let args = call.arguments as? [String: Any],
           let enabled = args["enabled"] as? Bool {
          self.setEnabled(enabled)
        }
        result(true)
      case "isAccessibilityGranted":
        result(self.isAccessibilityGranted())
      case "requestAccessibilityPermission":
        self.requestAccessibilityPermission()
        result(true)
      case "openAppInFinder":
        self.openAppInFinder()
        result(true)
      case "showNotification":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String,
           let body = args["body"] as? String {
          self.postNotification(title: title, body: body)
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func setEnabled(_ enabled: Bool) {
    self.isEnabled = enabled
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if enabled {
        if self.statusItem == nil {
          self.setupStatusItem()
        }
        self.setupGlobalHotkeys()
      } else {
        self.teardownGlobalHotkeys()
        if let item = self.statusItem {
          NSStatusBar.system.removeStatusItem(item)
          self.statusItem = nil
        }
      }
    }
  }

  func openAppInFinder() {
    let bundleUrl = Bundle.main.bundleURL
    NSWorkspace.shared.activateFileViewerSelecting([bundleUrl])
  }

  // MARK: - Menu Bar Status Item (NSStatusBar)
  private func setupStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = statusItem?.button {
      // 采用系统 SF Symbol 或文字标徽，确保菜单栏高度适配
      if #available(macOS 11.0, *) {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.image = NSImage(systemSymbolName: "character.bubble.fill", accessibilityDescription: "OtterJot")?.withSymbolConfiguration(config)
      } else {
        button.title = "🦦"
      }
      button.toolTip = "OtterJot - 快捷润色 (fn + 空格)"
    }

    let menu = NSMenu()
    let headerItem = NSMenuItem(title: "OtterJot 地道润色 (fn + 空格)", action: nil, keyEquivalent: "")
    headerItem.isEnabled = false
    menu.addItem(headerItem)

    menu.addItem(NSMenuItem.separator())

    let openItem = NSMenuItem(title: "打开主窗口", action: #selector(openMainWindow), keyEquivalent: "o")
    openItem.target = self
    menu.addItem(openItem)

    let quickPolishItem = NSMenuItem(title: "润色选中内容 (fn + 空格)", action: #selector(triggerQuickPolish), keyEquivalent: "")
    quickPolishItem.target = self
    menu.addItem(quickPolishItem)

    let authItem = NSMenuItem(title: "检查辅助功能权限", action: #selector(checkAccessibilityItemClicked), keyEquivalent: "")
    authItem.target = self
    menu.addItem(authItem)

    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: "退出 OtterJot", action: #selector(quitApp), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)

    statusItem?.menu = menu
  }

  @objc private func openMainWindow() {
    NSApp.activate(ignoringOtherApps: true)
    mainWindow?.makeKeyAndOrderFront(nil)
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }

  @objc private func checkAccessibilityItemClicked() {
    if isAccessibilityGranted() {
      postNotification(title: "OtterJot 权限正常", body: "系统辅助功能权限已授予，可随时在任意输入框使用 fn + 空格 润色。")
    } else {
      requestAccessibilityPermission()
    }
  }

  // MARK: - Global Hotkey Listener (fn + Space & Option + Space)
  private func setupGlobalHotkeys() {
    teardownGlobalHotkeys()

    // 监听其他应用获得焦点时的全局按键
    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      self?.handleKeyEvent(event)
    }

    // 监听当前应用自身获得焦点时的按键
    localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if self?.handleKeyEvent(event) == true {
        return nil // 消费该事件，不继续传递
      }
      return event
    }
  }

  func teardownGlobalHotkeys() {
    if let gm = globalMonitor {
      NSEvent.removeMonitor(gm)
      globalMonitor = nil
    }
    if let lm = localMonitor {
      NSEvent.removeMonitor(lm)
      localMonitor = nil
    }
  }

  @discardableResult
  private func handleKeyEvent(_ event: NSEvent) -> Bool {
    let isFunction = event.modifierFlags.contains(.function)
    let isOption = event.modifierFlags.contains(.option)
    let isCommand = event.modifierFlags.contains(.command)
    let isControl = event.modifierFlags.contains(.control)

    // 主快捷键: fn + 空格 (keyCode 49); 同时兼容外接键盘的 ⌥ + 空格
    if (isFunction || isOption) && !isCommand && !isControl {
      if event.keyCode == 49 {
        triggerQuickPolish()
        return true
      }
    }
    return false
  }

  // MARK: - Text Extraction and In-Place Replacement
  @objc func triggerQuickPolish() {
    guard isEnabled else { return }

    guard isAccessibilityGranted() else {
      postNotification(
        title: "OtterJot 权限提示",
        body: "请先在「系统设置 - 隐私与安全性 - 辅助功能」中允许 OtterJot，以便自动读取并替换选中文本。"
      )
      requestAccessibilityPermission()
      return
    }

    let pasteboard = NSPasteboard.general
    let previousString = pasteboard.string(forType: .string)

    // 1. 模拟 Cmd + C 抓取用户在外部应用中光标选中的文本
    simulateKey(keyCode: 8, flags: .maskCommand) // ANSI 'C'

    // 2. 稍作等待给外部应用处理剪贴板写入
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.08) { [weak self] in
      guard let self = self else { return }
      let capturedText = pasteboard.string(forType: .string) ?? ""

      // 如果抓取内容为空或未发生变化且无有效输入，则不触发
      let trimmed = capturedText.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
        return
      }

      // 3. 调用 Flutter 领域的 QuickPolishService 进行母语级重塑
      DispatchQueue.main.async {
        self.methodChannel?.invokeMethod("performQuickPolish", arguments: ["selectedText": capturedText]) { [weak self] response in
          guard let self = self else { return }
          guard let dict = response as? [String: Any],
                let polishedText = dict["polishedText"] as? String,
                !polishedText.isEmpty else {
            return
          }

          // 4. 将润色后的文本写入剪贴板
          pasteboard.clearContents()
          pasteboard.setString(polishedText, forType: .string)

          // 5. 模拟 Cmd + V 在原位置无缝就地替换
          self.simulateKey(keyCode: 9, flags: .maskCommand) // ANSI 'V'

          // 6. 延时将剪贴板内容还原（可选恢复），避免污染用户剪贴板
          DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            if let prev = previousString {
              pasteboard.clearContents()
              pasteboard.setString(prev, forType: .string)
            }
          }
        }
      }
    }
  }

  private func simulateKey(keyCode: CGKeyCode, flags: CGEventFlags) {
    let source = CGEventSource(stateID: .combinedSessionState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    keyDown?.flags = flags
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    keyUp?.flags = flags

    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
  }

  // MARK: - Accessibility Permissions
  func isAccessibilityGranted() -> Bool {
    return AXIsProcessTrusted()
  }

  func requestAccessibilityPermission() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    AXIsProcessTrustedWithOptions(options)

    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
      NSWorkspace.shared.open(url)
    }
  }

  // MARK: - User Notifications
  func postNotification(title: String, body: String) {
    let notification = NSUserNotification()
    notification.title = title
    notification.informativeText = body
    notification.soundName = NSUserNotificationDefaultSoundName
    NSUserNotificationCenter.default.deliver(notification)
  }

  deinit {
    if let gm = globalMonitor {
      NSEvent.removeMonitor(gm)
    }
    if let lm = localMonitor {
      NSEvent.removeMonitor(lm)
    }
  }
}
