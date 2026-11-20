import ApplicationServices
import AuthenticationServices
import AVFoundation
import Cocoa
import FlutterMacOS
import ServiceManagement
import Speech
import UserNotifications
import WidgetKit

class MainFlutterWindow: NSWindow {
  private static let frameName = "CasamaMainWindow"

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame
    // First launch: sized for the sidebar, chat and computer panel on this screen's usable area
    // (menu bar and dock excluded), centered. After that macOS restores where it was left, and
    // keeps it on a screen that's still connected.
    self.minSize = NSSize(width: 420, height: 560)
    if let area = NSScreen.main?.visibleFrame, !self.setFrameUsingName(Self.frameName) {
      let width = min(min(max(area.width - 80, 960), 1440), area.width)
      let height = min(min(max(area.height - 60, 640), 960), area.height)
      windowFrame = NSRect(x: area.midX - width / 2, y: area.midY - height / 2, width: width, height: height)
    } else if self.setFrameUsingName(Self.frameName) {
      windowFrame = self.frame
    }
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.setFrameAutosaveName(Self.frameName)

    RegisterGeneratedPlugins(registry: flutterViewController)
    ShortcutBridge.shared.attach(flutterViewController.engine.binaryMessenger)
    MacBridge.shared.attach(flutterViewController.engine.binaryMessenger)
    WebAuthBridge.shared.attach(flutterViewController.engine.binaryMessenger)
    IslandController.shared.attach(flutterViewController.engine.binaryMessenger)
    NotificationsBridge.shared.attach(flutterViewController.engine.binaryMessenger)
    PermissionsBridge.shared.attach(flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  // The close button and Cmd+W hide the window instead of closing it, so the Flutter engine, the
  // live connection and the desktop companion keep running (D-324). The Dock icon, the menu bar
  // and the notch bring it back; Cmd+Q quits.
  override func performClose(_ sender: Any?) {
    orderOut(sender)
  }
}

// MARK: - casama/notifications (D-325): Approve / Deny on approval notifications, and clearing a
// chat's delivered notifications (aps.thread-id = the conversation) once it's open. The dock badge
// stays on casama/mac.

final class NotificationsBridge {
  static let shared = NotificationsBridge()
  private var channel: FlutterMethodChannel?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationCategories { existing in
      var categories = existing.filter { $0.identifier != "APPROVAL" }
      categories.insert(
        UNNotificationCategory(
          identifier: "APPROVAL",
          actions: [
            UNNotificationAction(identifier: "approve", title: "Approve", options: [.foreground, .authenticationRequired]),
            UNNotificationAction(identifier: "deny", title: "Deny", options: [.foreground, .authenticationRequired, .destructive]),
          ],
          intentIdentifiers: [],
          options: []))
      center.setNotificationCategories(categories)
    }
    let channel = FlutterMethodChannel(name: "casama/notifications", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "clear":
        guard let conversation = args["conversation_id"] as? String, !conversation.isEmpty else { return result(nil) }
        center.getDeliveredNotifications { delivered in
          let ids = delivered.filter { $0.request.content.threadIdentifier == conversation }.map { $0.request.identifier }
          if !ids.isEmpty { center.removeDeliveredNotifications(withIdentifiers: ids) }
        }
        result(nil)
      case "badge", "takeAction":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }
}

// MARK: - Mac integration over the casama/mac channel: the menu bar (File, Go, Settings…, Help)
// sends its actions to Flutter; Flutter sets the dock badge and launch at login.

final class MacBridge: NSObject {
  static let shared = MacBridge()
  private var channel: FlutterMethodChannel?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/mac", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "badge":
        let count = call.arguments as? Int ?? 0
        NSApp.dockTile.badgeLabel = count <= 0 ? nil : (count > 99 ? "99+" : "\(count)")
        result(nil)
      case "launchAtLogin":
        if #available(macOS 13.0, *) {
          result(SMAppService.mainApp.status == .enabled)
        } else {
          result(nil)
        }
      case "setLaunchAtLogin":
        guard #available(macOS 13.0, *) else { return result(nil) }
        do {
          if call.arguments as? Bool == true {
            try SMAppService.mainApp.register()
          } else {
            try SMAppService.mainApp.unregister()
          }
          result(SMAppService.mainApp.status == .enabled)
        } catch {
          result(FlutterError(code: "launch_at_login", message: error.localizedDescription, details: nil))
        }
      case "autoUpdateChecks":
        result(UserDefaults.standard.object(forKey: "SUEnableAutomaticChecks") as? Bool ?? true)
      case "setAutoUpdateChecks":
        // Sparkle reads this user default over the Info.plist value.
        UserDefaults.standard.set(call.arguments as? Bool ?? true, forKey: "SUEnableAutomaticChecks")
        result(nil)
      case "glance":
        result(Self.writeGlance(call.arguments as? [String: Any] ?? [:]))
      case "canvases":
        let args = call.arguments as? [String: Any] ?? [:]
        DispatchQueue.global(qos: .utility).async {
          Self.writeCanvases(args)
          DispatchQueue.main.async { result(nil) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
    DispatchQueue.main.async { self.installMenus() }
  }

  /// The widgets' data (D-405 §8.3, §17): `glance {glance, words, server, signed_in, key,
  /// unsupported?, checked_at?}` writes
  /// the glance, its words and the server's address where the Mac widget extension reads them (the
  /// Team-ID-named app group, which a sandboxed extension can share with this unsandboxed app),
  /// keeps the widget key in the keychain group they share, and redraws the widgets. Signed out,
  /// it wipes all of it. Answers whether the key was stored (false where signing doesn't grant the
  /// keychain group; the widgets then show what this writes and don't fetch for themselves).
  private static let widgetGroup = "V8V5US964Z.ai.casama.app"

  private static func writeGlance(_ args: [String: Any]) -> Bool {
    let signedIn = args["signed_in"] as? Bool ?? false
    if let defaults = UserDefaults(suiteName: widgetGroup) {
      func put(_ key: String, _ value: String?) {
        if let value, !value.isEmpty, signedIn { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
      }
      put("glance", args["glance"] as? String)
      // The words stay when signed out: the signed-out widget still says "Open Casama to sign in".
      if let words = args["words"] as? String, !words.isEmpty { defaults.set(words, forKey: "glance_words") }
      put("glance_server", args["server"] as? String)
      put("glance_signed_in", signedIn ? "1" : nil)
      // Optional, as on Android and iPhone: `unsupported` (the server has no /v1/glance, §6.6)
      // and `checked_at` (epoch ms of the last 200 or 304, the data's age for the "as of" line).
      put("glance_unsupported", (args["unsupported"] as? Bool ?? false) ? "1" : nil)
      if let ms = args["checked_at"] as? NSNumber {
        put("glance_checked_at", ms.int64Value > 0 ? String(ms.int64Value) : nil)
      } else if let ms = args["checked_at"] as? String {
        put("glance_checked_at", ms)
      } else if args["glance"] as? String != nil {
        // The app calls this after each fetch (200 or 304), so the call itself is the check.
        put("glance_checked_at", String(Int64(Date().timeIntervalSince1970 * 1000)))
      }
      if !signedIn {
        for key in ["glance_checked_at", "glance_started", "glance_push_token_sent"] { defaults.removeObject(forKey: key) }
      }
    }
    let stored = WidgetKey.write(signedIn ? args["key"] as? String : nil)
    WidgetCenter.shared.reloadAllTimelines()
    return stored
  }

  /// The Canvas widget's data (docs/BOT-WIDGET-PLAN.md §10.1): `canvases {canvases: String?
  /// (CanvasList JSON, null when signed out), pictures: {hash: JPEG bytes}}` writes the list to
  /// `canvases.json` and each picture to `canvas-pictures/<hash>.jpg` in the app group the glance
  /// uses (the Mac widget doesn't fetch), deletes the pictures neither sent nor drawn by the list,
  /// and redraws the widgets. Null wipes all of it.
  private static func writeCanvases(_ args: [String: Any]) {
    let fm = FileManager.default
    guard let container = fm.containerURL(forSecurityApplicationGroupIdentifier: widgetGroup) else { return }
    let listFile = container.appendingPathComponent("canvases.json")
    let dir = container.appendingPathComponent("canvas-pictures", isDirectory: true)
    var keep = Set<String>()
    if let json = args["canvases"] as? String, !json.isEmpty, let data = json.data(using: .utf8) {
      try? data.write(to: listFile, options: .atomic)
      try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
      keep = canvasPictureHashes(data)
      for (hash, value) in args["pictures"] as? [String: Any] ?? [:] {
        guard isSafeHash(hash), let bytes = (value as? FlutterStandardTypedData)?.data, !bytes.isEmpty else { continue }
        if (try? bytes.write(to: dir.appendingPathComponent("\(hash).jpg"), options: .atomic)) != nil { keep.insert(hash) }
      }
    } else {
      try? fm.removeItem(at: listFile)
    }
    // The widget extension never writes the list on the Mac; drop any copy so the file is the one.
    UserDefaults(suiteName: widgetGroup)?.removeObject(forKey: "canvases")
    if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      for f in files where !keep.contains(f.deletingPathExtension().lastPathComponent) { try? fm.removeItem(at: f) }
    }
    WidgetCenter.shared.reloadTimelines(ofKind: "CanvasWidget")
  }

  /// A picture hash that is safe as a file name (`painting-night_sky`, hex digests).
  private static func isSafeHash(_ hash: String) -> Bool {
    !hash.isEmpty && hash.count <= 80
      && hash.unicodeScalars.allSatisfy { $0.isASCII && (CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_") }
  }

  /// Every picture hash a CanvasList draws: entries' own pictures and picture backgrounds.
  private static func canvasPictureHashes(_ data: Data) -> Set<String> {
    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
    var out = Set<String>()
    for item in root["items"] as? [[String: Any]] ?? [] {
      for entry in item["entries"] as? [[String: Any]] ?? [] {
        if let p = entry["picture"] as? String, isSafeHash(p) { out.insert(p) }
        let bg = (entry["look"] as? [String: Any])?["background"] as? [String: Any]
        if let p = bg?["picture"] as? String, isSafeHash(p) { out.insert(p) }
      }
    }
    return out
  }

  @objc private func menuAction(_ sender: NSMenuItem) {
    channel?.invokeMethod("menu", arguments: sender.representedObject as? String)
  }

  private func item(_ title: String, _ key: String, _ modifiers: NSEvent.ModifierFlags, _ action: String) -> NSMenuItem {
    let i = NSMenuItem(title: title, action: #selector(menuAction(_:)), keyEquivalent: key)
    i.keyEquivalentModifierMask = modifiers
    i.target = self
    i.representedObject = action
    return i
  }

  private func installMenus() {
    guard let main = NSApp.mainMenu, main.items.first(where: { $0.submenu?.title == "File" }) == nil else { return }
    // The template's "About APP_NAME", "Hide APP_NAME", "Quit APP_NAME" say Casama.
    for menuItem in main.items {
      if menuItem.title.contains("APP_NAME") { menuItem.title = menuItem.title.replacingOccurrences(of: "APP_NAME", with: "Casama") }
      for sub in menuItem.submenu?.items ?? [] where sub.title.contains("APP_NAME") {
        sub.title = sub.title.replacingOccurrences(of: "APP_NAME", with: "Casama")
      }
    }
    // Direct download only (the Mac App Store updates the app itself): Check for Updates….
    if Bundle.main.object(forInfoDictionaryKey: "CasamaDistribution") as? String != "appstore",
       let appMenu = main.items.first?.submenu, appMenu.items.first(where: { $0.representedObject as? String == "checkUpdates" }) == nil {
      appMenu.insertItem(item("Check for Updates…", "", [], "checkUpdates"), at: 1)
    }
    // "Preferences…" from the template becomes a working Settings… (⌘,).
    if let appMenu = main.items.first?.submenu, let prefs = appMenu.items.first(where: { $0.keyEquivalent == "," }) {
      prefs.title = "Settings…"
      prefs.target = self
      prefs.action = #selector(menuAction(_:))
      prefs.representedObject = "settings"
    }
    let file = NSMenu(title: "File")
    file.addItem(item("New Chat", "n", [.command], "newChat"))
    file.addItem(item("New Bot…", "n", [.command, .shift], "newBot"))
    file.addItem(item("Search…", "k", [.command], "search"))
    file.addItem(.separator())
    file.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
    let fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
    fileItem.submenu = file
    main.insertItem(fileItem, at: 1)

    let go = NSMenu(title: "Go")
    go.addItem(item("Bots", "1", [.command], "go:/bots"))
    go.addItem(item("Inbox", "2", [.command], "go:/inbox"))
    go.addItem(item("Board", "3", [.command], "go:/tasks"))
    go.addItem(item("Computer", "4", [.command], "go:/computer"))
    go.addItem(item("Pages", "5", [.command], "go:/pages"))
    let goItem = NSMenuItem(title: "Go", action: nil, keyEquivalent: "")
    goItem.submenu = go
    let viewIndex = main.items.firstIndex(where: { $0.submenu?.title == "View" }) ?? 3
    main.insertItem(goItem, at: min(viewIndex + 1, main.items.count))

    if let help = main.items.first(where: { $0.submenu?.title == "Help" })?.submenu {
      help.removeAllItems()
      help.addItem(item("Casama Help", "?", [.command], "help"))
    }
  }
}

// MARK: - Browser sign-in in the system's sign-in window (ASWebAuthenticationSession) over the
// casama/web_auth channel: opens over the app instead of switching to the browser, shares the
// browser's cookies and passkeys, and hands the casama:// link back here instead of to the app's
// URL handler.

final class WebAuthBridge: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = WebAuthBridge()
  private var channel: FlutterMethodChannel?
  private var session: ASWebAuthenticationSession?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/web_auth", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "authenticate" else { return result(FlutterMethodNotImplemented) }
      guard let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String, let url = URL(string: urlString),
            let scheme = args["scheme"] as? String else {
        return result(FlutterError(code: "bad_args", message: "url and scheme are needed", details: nil))
      }
      self?.authenticate(url, scheme: scheme, result: result)
    }
    self.channel = channel
  }

  private func authenticate(_ url: URL, scheme: String, result: @escaping FlutterResult) {
    // A second tap replaces the window still open; its caller hears it was cancelled.
    session?.cancel()
    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { [weak self] callback, error in
      DispatchQueue.main.async {
        self?.session = nil
        if let callback = callback {
          result(callback.absoluteString)
        } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
          result(FlutterError(code: "canceled", message: nil, details: nil))
        } else {
          result(FlutterError(code: "failed", message: error?.localizedDescription, details: nil))
        }
      }
    }
    session.presentationContextProvider = self
    // Keep the browser's cookies, so someone already signed in there isn't asked again.
    session.prefersEphemeralWebBrowserSession = false
    self.session = session
    if !session.start() {
      self.session = nil
      result(FlutterError(code: "unavailable", message: "The sign-in window could not open.", details: nil))
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    NSApp.mainWindow ?? NSApp.windows.first(where: { $0 is MainFlutterWindow }) ?? ASPresentationAnchor()
  }
}

// MARK: - casama/permissions (D-376): system permissions a bot needs on this Mac, checked without
// prompting, asked for when the person taps Turn on, and a restart after Screen Recording.
// `check {ids}` → {id: state}; `request {id}` → state; `relaunch`. States: granted, denied,
// not_asked, restricted, unknown. Accessibility and Screen Recording can't tell "never asked" from
// "said no", so a prompt shown once is remembered in UserDefaults.

final class PermissionsBridge {
  static let shared = PermissionsBridge()
  private var channel: FlutterMethodChannel?
  private static let promptedKey = "casama.permissions.prompted."

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/permissions", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return result(nil) }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "check":
        let ids = args["ids"] as? [String] ?? []
        // Automation's check talks to System Events: off the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
          var out: [String: String] = [:]
          for id in ids { out[id] = self.state(id) }
          DispatchQueue.main.async { result(out) }
        }
      case "request":
        guard let id = args["id"] as? String else { return result(FlutterError(code: "bad_args", message: "id is needed", details: nil)) }
        self.request(id) { state in DispatchQueue.main.async { result(state) } }
      case "relaunch":
        self.relaunch()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  private func prompted(_ id: String) -> Bool { UserDefaults.standard.bool(forKey: Self.promptedKey + id) }
  private func markPrompted(_ id: String) { UserDefaults.standard.set(true, forKey: Self.promptedKey + id) }

  private func state(_ id: String) -> String {
    switch id {
    case "accessibility":
      return AXIsProcessTrusted() ? "granted" : (prompted(id) ? "denied" : "not_asked")
    case "screen_recording":
      return CGPreflightScreenCaptureAccess() ? "granted" : (prompted(id) ? "denied" : "not_asked")
    case "automation":
      return automation(ask: false)
    case "full_disk":
      return fullDisk()
    case "microphone":
      return Self.avState(AVCaptureDevice.authorizationStatus(for: .audio))
    case "speech":
      switch SFSpeechRecognizer.authorizationStatus() {
      case .authorized: return "granted"
      case .denied: return "denied"
      case .restricted: return "restricted"
      case .notDetermined: return "not_asked"
      @unknown default: return "unknown"
      }
    default:
      return "unknown"
    }
  }

  static func avState(_ s: AVAuthorizationStatus) -> String {
    switch s {
    case .authorized: return "granted"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not_asked"
    @unknown default: return "unknown"
    }
  }

  private func request(_ id: String, done: @escaping (String) -> Void) {
    switch id {
    case "accessibility":
      markPrompted(id)
      // Shows "Casama would like to control this computer" with a button to the pane.
      let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
      done(AXIsProcessTrustedWithOptions(options) ? "granted" : "denied")
    case "screen_recording":
      markPrompted(id)
      // The first call shows the system's prompt; it returns at once, before any answer.
      done(CGRequestScreenCaptureAccess() ? "granted" : "denied")
    case "automation":
      DispatchQueue.global(qos: .userInitiated).async { done(self.automation(ask: true)) }
    default:
      done(state(id))
    }
  }

  /// Apple Events to System Events, which agent-desktop and AppleScript use.
  private func automation(ask: Bool) -> String {
    let bundle = "com.apple.systemevents"
    var status = Self.automationStatus(bundle, ask: ask)
    // procNotFound: System Events isn't running, and only a running target can answer.
    if status == OSStatus(procNotFound) && ask {
      let open = Process()
      open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
      open.arguments = ["-g", "-j", "-b", bundle]
      try? open.run()
      open.waitUntilExit()
      Thread.sleep(forTimeInterval: 1)
      status = Self.automationStatus(bundle, ask: ask)
    }
    switch status {
    case noErr: return "granted"
    case OSStatus(errAEEventNotPermitted): return "denied"
    case OSStatus(errAEEventWouldRequireUserConsent): return "not_asked"
    default: return "unknown"
    }
  }

  private static func automationStatus(_ bundle: String, ask: Bool) -> OSStatus {
    let target = NSAppleEventDescriptor(bundleIdentifier: bundle)
    guard let desc = target.aeDesc else { return OSStatus(procNotFound) }
    return AEDeterminePermissionToAutomateTarget(desc, AEEventClass(typeWildCard), AEEventID(typeWildCard), ask)
  }

  /// Full Disk Access has no API: the usual probe is opening the user's TCC database, which only
  /// an app with Full Disk Access may read. It always exists, and without access even looking it up
  /// can fail, so a failed open is the answer (no existence check first).
  private func fullDisk() -> String {
    let path = NSHomeDirectory() + "/Library/Application Support/com.apple.TCC/TCC.db"
    if let handle = FileHandle(forReadingAtPath: path) {
      handle.closeFile()
      return "granted"
    }
    return "denied"
  }

  /// Quits and opens Casama again a second later (Screen Recording applies from the next launch).
  private func relaunch() {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", "sleep 1; /usr/bin/open -n \"$0\"", Bundle.main.bundlePath]
    do {
      try task.run()
    } catch {
      return
    }
    NSApp.terminate(nil)
  }
}
