import Cocoa
import FlutterMacOS
import ServiceManagement

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

    super.awakeFromNib()
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
    DispatchQueue.main.async { self.installMenus() }
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
