import Cocoa
import FlutterMacOS
import UserNotifications

/// macOS 原生菜单栏常驻文本润色管理器
class QuickPolishManager: NSObject, UNUserNotificationCenterDelegate {
  static let shared = QuickPolishManager()

  private var statusItem: NSStatusItem?
  private var methodChannel: FlutterMethodChannel?
  private weak var mainWindow: NSWindow?
  private var isEnabled: Bool = false
  private var lastExternalApp: NSRunningApplication?

  func setup(flutterViewController: FlutterViewController, window: NSWindow) {
    self.mainWindow = window
    self.methodChannel = FlutterMethodChannel(
      name: "io.github.excing.otterjot/quick_polish",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    setupMethodCallHandler()
    setupNotifications()
    setupActiveAppObserver()
    // 默认关闭桌面菜单栏常驻，由 Flutter 端根据持久化配置驱动 setQuickPolishEnabled 激活
  }

  private func setupActiveAppObserver() {
    if let front = NSWorkspace.shared.frontmostApplication,
       front.bundleIdentifier != Bundle.main.bundleIdentifier {
      self.lastExternalApp = front
    }

    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
         app.bundleIdentifier != Bundle.main.bundleIdentifier {
        self?.lastExternalApp = app
      }
    }
  }

  private func setupNotifications() {
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }

  // 保证应用处于活动状态时也能直接在屏幕右上角弹出横幅
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(macOS 11.0, *) {
      completionHandler([.banner, .sound, .list])
    } else {
      completionHandler([.alert, .sound])
    }
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
      case "relaunchApp":
        self.relaunchApp()
        result(true)
      case "showNotification":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String,
           let body = args["body"] as? String {
          let isAlert = title.contains("提示") || title.contains("失败") || body.contains("未设置") || body.contains("错误")
          let icon = isAlert ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
          self.postNotification(title: title, body: body, systemIcon: icon)
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
      } else {
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

  func relaunchApp() {
    let url = Bundle.main.bundleURL
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = ["-n", url.path]
    try? task.run()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      NSApp.terminate(nil)
    }
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
      button.toolTip = "OtterJot - 快捷润色"
    }

    let menu = NSMenu()
    let headerItem = NSMenuItem(title: "OtterJot 地道润色", action: nil, keyEquivalent: "")
    headerItem.isEnabled = false
    menu.addItem(headerItem)

    menu.addItem(NSMenuItem.separator())

    let openItem = NSMenuItem(title: "打开 OtterJot 主窗口", action: #selector(openMainWindow), keyEquivalent: "")
    openItem.target = self
    menu.addItem(openItem)

    let quickPolishItem = NSMenuItem(title: "润色选中内容", action: #selector(triggerQuickPolishFromMenu), keyEquivalent: "")
    quickPolishItem.target = self
    menu.addItem(quickPolishItem)

    let authItem = NSMenuItem(title: "检查辅助功能权限", action: #selector(checkAccessibilityItemClicked), keyEquivalent: "")
    authItem.target = self
    menu.addItem(authItem)

    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: "退出 OtterJot", action: #selector(quitApp), keyEquivalent: "")
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
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    if isAccessibilityGranted() {
      alert.messageText = "辅助功能权限已生效"
      alert.informativeText = "OtterJot 已经拥有 macOS 辅助功能（设备控制）权限。\n您可以在任意应用中选中文本后，点击状态栏菜单「润色选中内容」进行原地地道润色！"
      alert.alertStyle = .informational
      alert.addButton(withTitle: "好的")
    } else {
      alert.messageText = "辅助功能权限尚未生效"
      alert.informativeText = "为了支持跨应用读取选中文本并就地替换，需要在系统设置中授予 OtterJot「辅助功能」（macOS 15 为「设备控制和数据访问」）权限。\n\n【关键说明】若您此前已在系统设置中开启开关但仍显示未生效，这是 macOS 系统的安全机制限制，只需完全退出并重启 OtterJot 一次即可。"
      alert.alertStyle = .warning
      alert.addButton(withTitle: "前往系统设置")
      alert.addButton(withTitle: "退出并重启应用")
      alert.addButton(withTitle: "取消")
    }
    let response = alert.runModal()
    if !isAccessibilityGranted() {
      if response == .alertFirstButtonReturn {
        requestAccessibilityPermission()
      } else if response == .alertSecondButtonReturn {
        relaunchApp()
      }
    }
  }

  // MARK: - Text Extraction and In-Place Replacement
  @objc func triggerQuickPolishFromMenu() {
    // 1. 若有记录到的外部前台应用（如 Chrome、微信等），立刻将输入焦点归还给它
    if let externalApp = lastExternalApp, !externalApp.isTerminated {
      externalApp.activate(options: .activateIgnoringOtherApps)
    }

    // 2. 延时 150ms 等待原应用窗口恢复焦点与文字选区状态，然后执行提取与润色
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
      self?.extractAndPolish()
    }
  }

  private func extractAndPolish() {
    guard isEnabled else {
      postNotification(
        title: "OtterJot 提示",
        body: "快捷润色尚未开启，请在 OtterJot 设置中开启。",
        systemIcon: "exclamationmark.triangle.fill"
      )
      NSSound.beep()
      return
    }

    // 异步非阻塞捕获选中文本，给操作系统与目标应用充分的事件流转时间
    captureSelectedText { [weak self] (capturedText, isAutoCaptured) in
      guard let self = self else { return }

      var textToPolish = capturedText
      let isGranted = self.isAccessibilityGranted()

      // 若未能自动截获选中文本（可能由于系统权限未生效或目标窗口未暴露选区）
      if textToPolish == nil || textToPolish?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
        let currentClipboard = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let clipText = currentClipboard, !clipText.isEmpty {
          // 降级使用剪贴板中的最新内容进行润色
          textToPolish = clipText
          self.postNotification(
            title: "OtterJot 正在润色...",
            body: "已获取剪贴板内容，正在执行母语级地道重塑",
            systemIcon: "doc.on.clipboard.fill"
          )
        } else {
          // 自动抓取失败且剪贴板为空，根据权限真实状态给出明确指引
          if !isGranted {
            self.postNotification(
              title: "辅助功能权限尚未生效",
              body: "请在系统设置中点击【-】删除 OtterJot 并重新添加；或先按 ⌘+C 复制文字后再点润色。",
              systemIcon: "exclamationmark.triangle.fill"
            )
          } else {
            self.postNotification(
              title: "未检测到选中文本",
              body: "请先用光标选中文字，或按 ⌘+C 复制后再试。",
              systemIcon: "exclamationmark.triangle.fill"
            )
          }
          NSSound.beep()
          return
        }
      } else {
        let trimmed = textToPolish!.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = trimmed.count > 25 ? "\(trimmed.prefix(25))..." : trimmed
        self.postNotification(
          title: "OtterJot 正在润色...",
          body: "\"\(preview)\" 正在重塑为母语级地道表达",
          systemIcon: "sparkles"
        )
      }

      guard let validText = textToPolish, !validText.isEmpty else { return }

      // 3. 调用 Flutter 领域的 QuickPolishService 进行母语级重塑与日记落库
      self.methodChannel?.invokeMethod("performQuickPolish", arguments: ["selectedText": validText]) { [weak self] response in
        guard let self = self else { return }
        guard let dict = response as? [String: Any],
              let polishedText = dict["polishedText"] as? String,
              !polishedText.isEmpty else {
          self.postNotification(
            title: "OtterJot 提示",
            body: "润色服务未响应，请检查网络或设置。",
            systemIcon: "exclamationmark.triangle.fill"
          )
          return
        }

        // 如果返回内容与原文完全一致，说明发生异常已退回原文
        if polishedText == validText {
          self.postNotification(
            title: "OtterJot 润色未完成",
            body: "未产生润色变更，请检查 AI 配置是否有效或网络连接。",
            systemIcon: "exclamationmark.circle.fill"
          )
          return
        }

        // 4. 将润色后的文本写入剪贴板
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(polishedText, forType: .string)

        if isAutoCaptured && isGranted {
          // 5. 自动抓取且拥有系统权限：模拟 Cmd + V 在原位置无缝就地替换
          self.simulatePaste()
          self.postNotification(
            title: "OtterJot 润色完成",
            body: "已就地替换为母语级地道英文",
            systemIcon: "checkmark.circle.fill"
          )
          NSSound(named: "Glass")?.play()
        } else {
          // 降级提示：已写入剪贴板，按 Cmd+V 即可粘贴
          self.postNotification(
            title: "OtterJot 润色完成",
            body: "已生成笔记并写入剪贴板，按 ⌘+V 粘贴！",
            systemIcon: "doc.on.clipboard.fill"
          )
          NSSound(named: "Glass")?.play()
        }
      }
    }
  }

  /// 工业级非阻塞剪贴板轮询与选中文本抓取
  private func captureSelectedText(completion: @escaping (String?, Bool) -> Void) {
    let pasteboard = NSPasteboard.general
    let initialChangeCount = pasteboard.changeCount

    // 发送标准 Cmd + C 拷贝按键序列
    simulateCopy()

    // 采用异步轮询机制，避免主线程阻塞导致系统 IPC 僵死
    DispatchQueue.global().async { [weak self] in
      var attempts = 0
      let maxAttempts = 15 // 15 * 20ms = 300ms

      while attempts < maxAttempts {
        usleep(20_000) // 20ms
        attempts += 1

        if pasteboard.changeCount != initialChangeCount {
          // 剪贴板产生了变化，成功提取！
          let text = pasteboard.string(forType: .string)
          DispatchQueue.main.async {
            completion(text, true)
          }
          return
        }
      }

      // 若复制未改变剪贴板，切回主线程进行 Accessibility 兜底查询
      DispatchQueue.main.async {
        if let axText = self?.getSelectedTextViaAccessibility(), !axText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          completion(axText, true)
        } else {
          completion(nil, false)
        }
      }
    }
  }

  // MARK: - Native Accessibility Text Reader
  private func getSelectedTextViaAccessibility() -> String? {
    // 优先从记录的外部前台应用（如 Chrome、Safari）精准抓取选中文本
    if let externalApp = lastExternalApp, !externalApp.isTerminated {
      let appElement = AXUIElementCreateApplication(externalApp.processIdentifier)
      var focusedElement: CFTypeRef?
      let elemResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
      if elemResult == .success, let element = focusedElement {
        var selectedValue: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedValue)
        if textResult == .success, let str = selectedValue as? String {
          let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmed.isEmpty {
            return str
          }
        }
      }
    }

    // 兜底：从系统全局焦点元素获取
    let systemWide = AXUIElementCreateSystemWide()
    var focusedApp: CFTypeRef?
    let appResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
    guard appResult == .success, let app = focusedApp else { return nil }

    var focusedElement: CFTypeRef?
    let elemResult = AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
    guard elemResult == .success, let element = focusedElement else { return nil }

    var selectedValue: CFTypeRef?
    let textResult = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedValue)
    if textResult == .success, let str = selectedValue as? String {
      let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return str
      }
    }
    return nil
  }

  /// 工业级显式模拟 Command + C 按键序列 (支持 Chromium/Chrome/WebKit)
  private func simulateCopy() {
    let source = CGEventSource(stateID: .hidSystemState)
    let cmdKey: CGKeyCode = 0x37 // Left Command
    let cKey: CGKeyCode = 0x08   // 'c'

    let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: cmdKey, keyDown: true)
    let cDown = CGEvent(keyboardEventSource: source, virtualKey: cKey, keyDown: true)
    let cUp = CGEvent(keyboardEventSource: source, virtualKey: cKey, keyDown: false)
    let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: cmdKey, keyDown: false)

    cmdDown?.flags = .maskCommand
    cDown?.flags = .maskCommand
    cUp?.flags = .maskCommand
    cmdUp?.flags = []

    let loc = CGEventTapLocation.cghidEventTap
    cmdDown?.post(tap: loc)
    cDown?.post(tap: loc)
    cUp?.post(tap: loc)
    cmdUp?.post(tap: loc)
  }

  /// 工业级显式模拟 Command + V 按键序列
  private func simulatePaste() {
    let source = CGEventSource(stateID: .hidSystemState)
    let cmdKey: CGKeyCode = 0x37 // Left Command
    let vKey: CGKeyCode = 0x09   // 'v'

    let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: cmdKey, keyDown: true)
    let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
    let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
    let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: cmdKey, keyDown: false)

    cmdDown?.flags = .maskCommand
    vDown?.flags = .maskCommand
    vUp?.flags = .maskCommand
    cmdUp?.flags = []

    let loc = CGEventTapLocation.cghidEventTap
    cmdDown?.post(tap: loc)
    vDown?.post(tap: loc)
    vUp?.post(tap: loc)
    cmdUp?.post(tap: loc)
  }

  // MARK: - Accessibility Permissions
  func isAccessibilityGranted() -> Bool {
    return AXIsProcessTrusted()
  }

  func openAccessibilityPreferencePane() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
      NSWorkspace.shared.open(url)
    }
  }

  func requestAccessibilityPermission() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    AXIsProcessTrustedWithOptions(options)
    openAccessibilityPreferencePane()
  }

  // MARK: - Modern User Notifications & Toast HUD
  func postNotification(title: String, body: String, systemIcon: String = "character.bubble.fill") {
    // 1. 在屏幕顶部显示无死角悬浮 HUD 浮窗（无需系统通知授权，100% 可见反馈）
    ToastHUDWindow.shared.show(title: title, body: body, systemIcon: systemIcon)

    // 2. 发送系统通知（若已开启通知权限）
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        NSLog("[OtterJot] UNUserNotificationCenter add error: \(error.localizedDescription)")
      }
    }
  }

  deinit {
    teardownEventTap()
    if let gm = globalMonitor {
      NSEvent.removeMonitor(gm)
    }
    if let lm = localMonitor {
      NSEvent.removeMonitor(lm)
    }
  }
}

// MARK: - High-Visibility Screen-Top Toast HUD
final class ToastHUDWindow: NSPanel {
  static let shared = ToastHUDWindow()

  private let visualEffectView = NSVisualEffectView()
  private let iconImageView = NSImageView()
  private let titleLabel = NSTextField(labelWithString: "")
  private let bodyLabel = NSTextField(labelWithString: "")
  private var hideTimer: Timer?

  init() {
    super.init(
      contentRect: NSRect(x: 0, y: 0, width: 360, height: 72),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    isOpaque = false
    backgroundColor = .clear
    level = .floating
    isMovableByWindowBackground = false
    ignoresMouseEvents = true
    hidesOnDeactivate = false

    visualEffectView.frame = NSRect(x: 0, y: 0, width: 360, height: 72)
    visualEffectView.material = .hudWindow
    visualEffectView.blendingMode = .behindWindow
    visualEffectView.state = .active
    visualEffectView.wantsLayer = true
    visualEffectView.layer?.cornerRadius = 14
    visualEffectView.layer?.masksToBounds = true
    visualEffectView.layer?.borderWidth = 1
    visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.25).cgColor

    iconImageView.frame = NSRect(x: 16, y: 20, width: 32, height: 32)
    iconImageView.imageScaling = .scaleProportionallyUpOrDown

    titleLabel.frame = NSRect(x: 58, y: 38, width: 286, height: 20)
    titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
    titleLabel.textColor = .white
    titleLabel.lineBreakMode = .byTruncatingTail

    bodyLabel.frame = NSRect(x: 58, y: 14, width: 286, height: 22)
    bodyLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
    bodyLabel.textColor = NSColor.white.withAlphaComponent(0.9)
    bodyLabel.lineBreakMode = .byTruncatingTail

    visualEffectView.addSubview(iconImageView)
    visualEffectView.addSubview(titleLabel)
    visualEffectView.addSubview(bodyLabel)
    contentView = visualEffectView
  }

  func show(title: String, body: String, systemIcon: String = "character.bubble.fill", duration: TimeInterval = 2.8) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.hideTimer?.invalidate()

      self.titleLabel.stringValue = title
      self.bodyLabel.stringValue = body
      if #available(macOS 11.0, *) {
        let config = NSImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        self.iconImageView.image = NSImage(systemSymbolName: systemIcon, accessibilityDescription: nil)?.withSymbolConfiguration(config)
        self.iconImageView.contentTintColor = .white
      }

      // 将浮窗居中置于主屏顶部下方，确保显眼
      if let screen = NSScreen.main {
        let screenRect = screen.visibleFrame
        let x = screenRect.origin.x + (screenRect.width - 360) / 2
        let y = screenRect.origin.y + screenRect.height - 84
        self.setFrameOrigin(NSPoint(x: x, y: y))
      }

      self.alphaValue = 1.0
      self.orderFront(nil)

      self.hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
        NSAnimationContext.runAnimationGroup({ context in
          context.duration = 0.35
          self?.animator().alphaValue = 0.0
        }, completionHandler: {
          self?.orderOut(nil)
        })
      }
    }
  }
}
