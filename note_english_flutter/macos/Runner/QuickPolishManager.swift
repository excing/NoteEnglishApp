import Cocoa
import FlutterMacOS
import UserNotifications

/// macOS 原生菜单栏常驻与全局快捷键文本润色管理器
class QuickPolishManager: NSObject, UNUserNotificationCenterDelegate {
  static let shared = QuickPolishManager()

  private var statusItem: NSStatusItem?
  private var methodChannel: FlutterMethodChannel?
  private weak var mainWindow: NSWindow?
  private var globalMonitor: Any?
  private var localMonitor: Any?
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var isEnabled: Bool = false

  func setup(flutterViewController: FlutterViewController, window: NSWindow) {
    self.mainWindow = window
    self.methodChannel = FlutterMethodChannel(
      name: "io.github.excing.otterjot/quick_polish",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    setupMethodCallHandler()
    setupNotifications()
    // 默认关闭桌面菜单栏常驻与全局热键，由 Flutter 端根据持久化配置驱动 setQuickPolishEnabled 激活
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

    let openItem = NSMenuItem(title: "打开 OtterJot 主窗口", action: #selector(openMainWindow), keyEquivalent: "")
    openItem.target = self
    menu.addItem(openItem)

    let quickPolishItem = NSMenuItem(title: "润色选中内容 (fn + 空格 / ⌥ + 空格)", action: #selector(triggerQuickPolishFromMenu), keyEquivalent: "")
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

  // MARK: - Global Hotkey Listener (Dual-Engine: CGEventTap + NSEvent Monitor)
  private func setupGlobalHotkeys() {
    teardownGlobalHotkeys()

    // 引擎 1: CGEventTap (底层内核驱动级按键拦截，灵敏度最高且能精准捕获 fn 与 option)
    setupEventTap()

    // 引擎 2: NSEvent Monitors (兼容兜底)
    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      self?.handleKeyEvent(event)
    }

    localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if self?.handleKeyEvent(event) == true {
        return nil
      }
      return event
    }
  }

  func teardownGlobalHotkeys() {
    teardownEventTap()

    if let gm = globalMonitor {
      NSEvent.removeMonitor(gm)
      globalMonitor = nil
    }
    if let lm = localMonitor {
      NSEvent.removeMonitor(lm)
      localMonitor = nil
    }
  }

  // MARK: - CGEventTap Implementation
  private func setupEventTap() {
    teardownEventTap()
    guard isAccessibilityGranted() else { return }

    let eventMask = (1 << CGEventType.keyDown.rawValue)
    let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

    guard let tap = CGEvent.tapCreate(
      tap: .cghidEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        guard let refcon = refcon else { return Unmanaged.passRetained(event) }
        let manager = Unmanaged<QuickPolishManager>.fromOpaque(refcon).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
          manager.reEnableTap()
          return Unmanaged.passRetained(event)
        }

        if manager.handleCGEvent(event) {
          return nil // 消费该事件，不继续注入当前获得焦点的输入框
        }
        return Unmanaged.passRetained(event)
      },
      userInfo: observer
    ) else {
      NSLog("[OtterJot] Failed to create CGEventTap")
      return
    }

    eventTap = tap
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
  }

  func reEnableTap() {
    if let tap = eventTap {
      CGEvent.tapEnable(tap: tap, enable: true)
    }
  }

  func teardownEventTap() {
    if let tap = eventTap {
      CGEvent.tapEnable(tap: tap, enable: false)
      if let source = runLoopSource {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        runLoopSource = nil
      }
      CFMachPortInvalidate(tap)
      eventTap = nil
    }
  }

  func handleCGEvent(_ event: CGEvent) -> Bool {
    guard isEnabled else { return false }
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags

    // 空格键 keyCode 为 49
    guard keyCode == 49 else { return false }

    let hasFn = flags.contains(.maskSecondaryFn)
    let hasOption = flags.contains(.maskAlternate)
    let hasCommand = flags.contains(.maskCommand)
    let hasControl = flags.contains(.maskControl)

    // 匹配 fn + 空格 或 ⌥ (Option) + 空格，排除 Cmd/Ctrl
    if (hasFn || hasOption) && !hasCommand && !hasControl {
      DispatchQueue.main.async { [weak self] in
        self?.triggerQuickPolish()
      }
      return true
    }
    return false
  }

  @discardableResult
  private func handleKeyEvent(_ event: NSEvent) -> Bool {
    guard isEnabled else { return false }
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
  @objc func triggerQuickPolishFromMenu() {
    // 隐藏状态栏菜单，让系统将输入焦点归还给原编辑应用
    NSApp.hide(nil)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
      self?.triggerQuickPolish()
    }
  }

  @objc func triggerQuickPolish() {
    guard isEnabled else {
      postNotification(title: "OtterJot 提示", body: "全局快捷润色尚未开启，请在 OtterJot 设置中开启。")
      NSSound.beep()
      return
    }

    guard isAccessibilityGranted() else {
      postNotification(
        title: "OtterJot 权限未就绪",
        body: "请在系统设置中将 OtterJot 右侧开关切换为【开启】，以便抓取文本。"
      )
      NSSound.beep()
      // 温和打开系统偏好设置面板，绝不在每次按键时重复触发系统 Prompt 弹窗
      openAccessibilityPreferencePane()
      return
    }

    // 延时 0.18 秒，等待用户物理手指从 Fn / Option 组合键上松开，避免按键事件掩码冲突
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
      guard let self = self else { return }
      self.extractAndPolish()
    }
  }

  private func extractAndPolish() {
    let pasteboard = NSPasteboard.general
    let previousString = pasteboard.string(forType: .string)
    let previousChangeCount = pasteboard.changeCount

    // 1. 模拟 Cmd + C 抓取选中文本 (采用独立 hidSystemState 源，防止物理修饰键叠加)
    simulateCopy()

    // 稍作等待以确保目标应用处理写入剪贴板
    usleep(120_000) // 120ms

    var capturedText: String?
    if pasteboard.changeCount != previousChangeCount {
      capturedText = pasteboard.string(forType: .string)
    } else {
      // 若剪贴板变更未检测到，尝试 Accessibility 原生读取
      capturedText = getSelectedTextViaAccessibility()
      if capturedText == nil || capturedText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
        capturedText = pasteboard.string(forType: .string)
      }
    }

    guard let text = capturedText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      postNotification(
        title: "OtterJot 提示",
        body: "未检测到选中文本。请先在任意应用中用光标选中一段文字后再试。"
      )
      NSSound.beep()
      return
    }

    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let preview = trimmed.count > 25 ? "\(trimmed.prefix(25))..." : trimmed
    postNotification(title: "OtterJot 正在润色...", body: "\"\(preview)\" 正在重塑为母语级地道表达")

    // 3. 调用 Flutter 领域的 QuickPolishService 进行母语级重塑
    methodChannel?.invokeMethod("performQuickPolish", arguments: ["selectedText": text]) { [weak self] response in
      guard let self = self else { return }
      guard let dict = response as? [String: Any],
            let polishedText = dict["polishedText"] as? String,
            !polishedText.isEmpty else {
        self.postNotification(title: "OtterJot 提示", body: "润色服务未响应，请检查网络或设置。")
        return
      }

      // 如果返回内容与原文完全一致，说明发生异常已退回原文
      if polishedText == text {
        return
      }

      // 4. 将润色后的文本写入剪贴板并回填
      pasteboard.clearContents()
      pasteboard.setString(polishedText, forType: .string)

      // 5. 模拟 Cmd + V 在原位置无缝就地替换
      self.simulatePaste()

      // 6. 延时将剪贴板内容还原，避免污染用户历史剪贴板
      DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
        if let prev = previousString {
          pasteboard.clearContents()
          pasteboard.setString(prev, forType: .string)
        }
      }
    }
  }

  // MARK: - Native Accessibility Text Reader
  private func getSelectedTextViaAccessibility() -> String? {
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

  private func simulateCopy() {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
    keyDown?.flags = .maskCommand
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
    keyUp?.flags = []

    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
  }

  private func simulatePaste() {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
    keyDown?.flags = .maskCommand
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
    keyUp?.flags = []

    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
  }

  // MARK: - Accessibility Permissions
  func isAccessibilityGranted() -> Bool {
    let trusted = AXIsProcessTrusted()
    if trusted && eventTap == nil && isEnabled {
      setupEventTap()
    }
    return trusted
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

  // MARK: - Modern User Notifications
  func postNotification(title: String, body: String) {
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
