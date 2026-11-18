import Cocoa
import FlutterMacOS
import SwiftUI

// MARK: - The island on the Mac (D-324, docs/ISLAND-AND-MENU-BAR-PLAN.md §6 B and C, §8.4)
//
// Two surfaces draw the island feed that Dart builds (client/lib/features/island/): the notch, a
// borderless non-activating panel above the menu bar, and the menu bar item with its panel.
// Native code only draws and reports clicks; Dart decides what a run is doing. Everything comes
// over the casama/island channel: `state` in, `action` out. Words come from Dart too.

/// One row of the feed, as Dart sends it (island_feed.dart, IslandItem.toJson).
struct IslandItem: Identifiable, Equatable {
  let id: String
  let phase: String
  let botId: String
  let bot: String
  /// The bot's icon as it stores it (`mascot:<name>`); nil draws its initials.
  let botAvatar: String?
  let step: String
  let detail: String?
  let runId: String?
  let approvalId: String?
  let risk: String?
  let startedAt: Date
  let endedAt: Date?
  let here: Bool
  let link: String
  /// A voice call's microphone is muted (phase "call" only).
  let muted: Bool

  init?(_ d: [String: Any]) {
    guard let id = d["id"] as? String, let phase = d["phase"] as? String, let link = d["link"] as? String else { return nil }
    self.id = id
    self.phase = phase
    self.botId = d["bot_id"] as? String ?? ""
    self.bot = d["bot"] as? String ?? ""
    self.botAvatar = (d["bot_avatar"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    self.step = d["step"] as? String ?? ""
    self.detail = d["detail"] as? String
    self.runId = d["run_id"] as? String
    self.approvalId = d["approval_id"] as? String
    self.risk = d["risk"] as? String
    self.startedAt = Date(timeIntervalSince1970: (d["started_at"] as? NSNumber)?.doubleValue ?? Date().timeIntervalSince1970)
    self.endedAt = (d["ended_at"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) }
    self.here = d["here"] as? Bool ?? false
    self.link = link
    self.muted = d["muted"] as? Bool ?? false
  }

  /// A voice call on this Mac (D-324, Phase 6): drawn first, with a level meter, Mute and End.
  var isCall: Bool { phase == "call" }

  var needsPerson: Bool { phase == "needsOk" || phase == "takeOver" }
  var ended: Bool { phase == "finished" || phase == "problem" }
}

enum NotchMode: Equatable {
  /// Nothing to show: the shape sits behind the notch and the panel is off screen.
  case hidden
  /// Something runs: the notch widens a little on each side.
  case compact
  /// The list, on hover or by itself for a request that needs an OK.
  case open
  /// A two-second look at one row: a run ended, a bot started using this Mac.
  case peek(String)
  /// Files are being dragged over it: it opens as a drop target for Quick ask.
  case drop
}

/// A bot the ask field can go to.
struct IslandBot: Identifiable, Equatable {
  let id: String
  let name: String
}

/// How loud a voice call is (0 to 1), ten times a second: its own object, so only the meter
/// redraws.
final class CallLevel: ObservableObject {
  @Published var value: Double = 0
}

/// What both surfaces draw.
final class IslandModel: ObservableObject {
  let level = CallLevel()
  @Published var items: [IslandItem] = []
  @Published var labels: [String: String] = [:]
  @Published var inbox = 0
  @Published var mode: NotchMode = .hidden
  /// The black shape's size; the panel's frame follows it.
  @Published var shape = CGSize(width: 0, height: 0)
  @Published var notchWidth: CGFloat = 0
  @Published var notchHeight: CGFloat = 32
  @Published var bots: [IslandBot] = []
  /// Where the ask field goes: the bot talked to last (from Dart), changeable here.
  @Published var askBot: String?
  /// Settings → App: Show bots in the notch, Open the notch on hover.
  @Published var notchOn = true
  @Published var hoverOpens = true
  /// The ask field is in use: the panel is key until it's sent or left.
  @Published var typing = false

  var askBotName: String { bots.first { $0.id == askBot }?.name ?? "" }

  func label(_ key: String) -> String { labels[key] ?? "" }

  var needsPerson: Bool { inbox > 0 || items.contains { $0.needsPerson } }
}

/// The notch's place on a screen. A display without one (an external screen, a closed lid) gets
/// the same shape hanging from the top centre, as tall as the menu bar.
struct NotchGeometry {
  let screen: NSScreen
  let midX: CGFloat
  let top: CGFloat
  let width: CGFloat
  let height: CGFloat
  let hasNotch: Bool

  /// Debug builds: draw as on a display without a notch (the on-device check has no external one).
  static var forceNoNotch = false

  static func current() -> NotchGeometry? {
    let notched = forceNoNotch ? nil : NSScreen.screens.first { $0.safeAreaInsets.top > 0 }
    guard let screen = notched ?? NSScreen.main ?? NSScreen.screens.first else { return nil }
    let frame = screen.frame
    if !forceNoNotch, screen.safeAreaInsets.top > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
      let minX = frame.minX + left.width
      let maxX = frame.maxX - right.width
      return NotchGeometry(screen: screen, midX: (minX + maxX) / 2, top: frame.maxY, width: max(0, maxX - minX), height: screen.safeAreaInsets.top, hasNotch: true)
    }
    return NotchGeometry(screen: screen, midX: frame.midX, top: frame.maxY, width: 0, height: max(24, NSStatusBar.system.thickness), hasNotch: false)
  }
}

final class NotchPanel: NSPanel {
  init() {
    super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    isFloatingPanel = true
    // One level above the menu bar, on every Space and over full-screen apps.
    level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 1)
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    backgroundColor = .clear
    isOpaque = false
    hasShadow = false
    hidesOnDeactivate = false
    isMovable = false
    isReleasedWhenClosed = false
    becomesKeyOnlyIfNeeded = true
    // Cmd+H hides Casama's window, not the bots' state in the notch.
    canHide = false
    // Left out of screenshots and screen recordings, including those a bot takes of this Mac.
    sharingType = .none
  }

  /// It takes focus from the app in front only while the ask field is in use, or after a click
  /// opened it (so the list is keyboard reachable); hovering never does.
  var allowsKey = false
  override var canBecomeKey: Bool { allowsKey }
  override var canBecomeMain: Bool { false }
}

/// Takes the first click, so a button works without the panel being key; reports the pointer.
final class NotchHostingView<Content: View>: NSHostingView<Content> {
  var onHover: ((Bool) -> Void)?
  private var area: NSTrackingArea?

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let area = area { removeTrackingArea(area) }
    let a = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
    addTrackingArea(a)
    area = a
  }

  override func mouseEntered(with event: NSEvent) { onHover?(true) }
  override func mouseExited(with event: NSEvent) { onHover?(false) }

  // Files dragged onto the notch go to Quick ask.
  var onDrag: ((Bool) -> Void)?
  var onDrop: (([String]) -> Void)?

  private func files(_ info: NSDraggingInfo) -> [String] {
    let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    return urls.map { $0.path }
  }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    guard !files(sender).isEmpty else { return [] }
    onDrag?(true)
    return .copy
  }

  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    files(sender).isEmpty ? [] : .copy
  }

  override func draggingExited(_ sender: NSDraggingInfo?) { onDrag?(false) }

  override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { true }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let paths = files(sender)
    guard !paths.isEmpty else {
      onDrag?(false)
      return false
    }
    onDrop?(paths)
    return true
  }
}

final class IslandController: NSObject {
  static let shared = IslandController()

  /// The short pause before the notch opens on hover (decision 4).
  static let hoverDelay = 0.3
  static let peekFor = 2.0
  static let settle = 0.4
  static let wing: CGFloat = 78
  static let rowHeight: CGFloat = 62
  static let askHeight: CGFloat = 48
  static let maxRows = 5

  let model = IslandModel()
  private var channel: FlutterMethodChannel?
  private var panel: NotchPanel?
  private var host: NotchHostingView<NotchView>?
  private var statusItem: NSStatusItem?
  private var popover: NSPopover?
  private var seen = Set<String>()
  private var autoOpened = false
  private var hovering = false
  private var hoverWork: DispatchWorkItem?
  private var peekWork: DispatchWorkItem?
  private var shrinkWork: DispatchWorkItem?
  private var monitors: [Any] = []
  private var activity: NSObjectProtocol?
  private var lastAskBot: String?

  #if DEBUG
  var debugPanel: NSPanel? { panel }
  var debugStatusVisible: Bool { statusItem?.isVisible ?? false }
  var debugPopoverShown: Bool { popoverOpen }
  var debugAwake: Bool { activity != nil }
  func debugHover(_ inside: Bool) { hover(inside) }
  func debugTogglePopover() { togglePopover(nil) }
  func debugDrag(_ inside: Bool) { dragging(inside) }
  func debugRelayout() { screensChanged() }
  #endif

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/island", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return result(nil) }
      switch call.method {
      case "level":
        self.model.level.value = (call.arguments as? NSNumber)?.doubleValue ?? 0
        result(nil)
      case "state":
        self.apply(call.arguments as? [String: Any] ?? [:])
        // Whether the notch can be on screen, so Dart knows D-066's on-top window isn't needed.
        result(self.model.notchOn && NotchGeometry.current() != nil)
      #if DEBUG
      case "debug":
        let args = call.arguments as? [String: Any] ?? [:]
        Task { @MainActor in result(self.debug(args)) }
      #endif
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
    DispatchQueue.main.async {
      self.installStatusItem()
      self.installMonitors()
      NotificationCenter.default.addObserver(self, selector: #selector(self.screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
      self.setMode(self.model.mode)
    }
    NotificationCenter.default.addObserver(self, selector: #selector(launched), name: NSApplication.didFinishLaunchingNotification, object: nil)
  }

  /// Open at Login starts Casama in the menu bar, without the window (§6 C).
  @objc private func launched() {
    let event = NSAppleEventManager.shared().currentAppleEvent
    let atLogin = event?.eventID == AEEventID(kAEOpenApplication)
      && event?.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?.enumCodeValue == OSType(keyAELaunchedAsLogInItem)
    if atLogin { hideAtLogin() }
  }

  func hideAtLogin() {
    NSApp.windows.first { $0 is MainFlutterWindow }?.orderOut(nil)
  }

  // MARK: Actions

  func send(_ kind: String, _ args: [String: Any] = [:]) {
    var payload = args
    payload["kind"] = kind
    channel?.invokeMethod("action", arguments: payload)
  }

  /// Brings the main window back: from the Dock icon, the menu bar or the notch.
  func showMainWindow() {
    let window = NSApp.windows.first { $0 is MainFlutterWindow }
    if let window = window {
      if window.isMiniaturized { window.deminiaturize(nil) }
      window.makeKeyAndOrderFront(nil)
    }
    NSApp.activate(ignoringOtherApps: true)
  }

  func open(_ item: IslandItem) {
    closeList()
    popover?.close()
    showMainWindow()
    send("open", ["link": item.link])
  }

  func openLink(_ link: String) {
    popover?.close()
    showMainWindow()
    send("open", ["link": link])
  }

  func stop(_ item: IslandItem) {
    guard let run = item.runId else { return }
    send("stop", ["run_id": run])
  }

  /// The call's Mute and Hang up: the call screen does them, as if its own buttons were pressed.
  func callMute() { send("call_mute") }
  func callEnd() { send("call_end") }
  /// The call row clicked: the window, on the call screen.
  func callOpen() {
    closeList()
    popover?.close()
    showMainWindow()
    send("call_open")
  }

  func decide(_ item: IslandItem, allow: Bool) {
    guard let approval = item.approvalId else { return }
    send(allow ? "allow" : "deny", ["approval_id": approval])
  }

  /// Enter in an ask field: a new chat with the chosen bot, without opening the window. The run
  /// shows in the notch as soon as Dart has sent it.
  func ask(_ text: String, fromMenu: Bool = false) {
    send("ask", ["text": text, "bot_id": model.askBot ?? ""])
    if fromMenu { popover?.close() }
    releaseKeyboard()
    closeList()
  }

  /// The notch's ask field was clicked: the panel takes the keyboard until it's sent or left.
  func beginTyping() {
    hoverWork?.cancel()
    model.typing = true
    takeKeyboard()
  }

  func cancelTyping() {
    releaseKeyboard()
    closeList()
  }

  /// A click on the notch opens it (the only way when hovering doesn't), with the keyboard, so
  /// Tab reaches its buttons.
  func clicked() {
    guard model.notchOn else { return }
    hoverWork?.cancel()
    if model.mode != .open {
      peekWork?.cancel()
      setMode(.open)
      send("seen", ["what": "notch"])
    }
    takeKeyboard()
  }

  private func takeKeyboard() {
    guard let panel = panel else { return }
    panel.allowsKey = true
    panel.makeKey()
  }

  /// Gives the keyboard back to the app in front.
  private func releaseKeyboard() {
    model.typing = false
    guard let panel = panel, panel.allowsKey else { return }
    panel.allowsKey = false
    if panel.isKeyWindow {
      panel.resignKey()
      // Ordering it out and back hands key status back to the active app's window.
      let shown = panel.isVisible
      panel.orderOut(nil)
      if shown { panel.orderFrontRegardless() }
    }
  }

  private var dropFrom: NotchMode?

  private func dragging(_ inside: Bool) {
    if inside {
      if model.mode != .drop { dropFrom = model.mode }
      hoverWork?.cancel()
      peekWork?.cancel()
      setMode(.drop)
    } else if model.mode == .drop {
      setMode(model.items.isEmpty ? .hidden : .compact)
    }
  }

  func dropped(_ paths: [String]) {
    setMode(model.items.isEmpty ? .hidden : .compact)
    showMainWindow()
    send("drop", ["paths": paths])
  }

  // MARK: State

  private func apply(_ state: [String: Any]) {
    var items = (state["items"] as? [Any] ?? []).compactMap { ($0 as? [String: Any]).flatMap(IslandItem.init) }
    if let labels = state["labels"] as? [String: String] { model.labels = labels }
    // A voice call on this Mac leads the list while it lasts.
    if var call = state["call"] as? [String: Any] {
      call["id"] = "call"
      call["phase"] = "call"
      call["link"] = "/"
      call["step"] = model.labels["on_a_call"] ?? ""
      if let item = IslandItem(call) { items.insert(item, at: 0) }
    } else {
      model.level.value = 0
    }
    model.inbox = state["inbox"] as? Int ?? 0
    model.notchOn = state["notch"] as? Bool ?? true
    model.hoverOpens = state["hover"] as? Bool ?? true
    model.bots = (state["bots"] as? [Any] ?? []).compactMap {
      guard let d = $0 as? [String: Any], let id = d["id"] as? String else { return nil }
      return IslandBot(id: id, name: d["name"] as? String ?? "")
    }
    // The bot talked to last, unless one was picked here since it last changed.
    let ask = state["ask_bot"] as? String
    if ask != lastAskBot || !model.bots.contains(where: { $0.id == model.askBot }) {
      model.askBot = ask
      lastAskBot = ask
    }
    let fresh = items.filter { !seen.contains($0.id + ":" + $0.phase) }
    for i in items { seen.insert(i.id + ":" + i.phase) }
    if seen.count > 400 { seen = Set(items.map { $0.id + ":" + $0.phase }) }
    model.items = items
    updateStatusIcon()
    keepAwake(!items.isEmpty)

    if !model.notchOn {
      autoOpened = false
      releaseKeyboard()
      setMode(.hidden)
      return
    }
    // The pointer or the keyboard is on it: leave it as it is.
    if model.typing || model.mode == .drop { return }
    if items.isEmpty {
      autoOpened = false
      // Open with only the ask field while the pointer is on it; otherwise back to rest.
      if model.mode != .open || !hovering { setMode(.hidden) } else { setMode(.open) }
      return
    }
    // A request that needs an OK opens the notch by itself, unless Casama is in front (the chat
    // shows the card there).
    if fresh.contains(where: { $0.phase == "needsOk" }), !NSApp.isActive {
      autoOpened = true
      setMode(.open)
      return
    }
    // Opened by itself for a request that has been answered: fold back, unless the pointer is on it.
    var mode = model.mode
    if mode == .open, autoOpened, !hovering, !items.contains(where: { $0.phase == "needsOk" }) {
      autoOpened = false
      mode = .compact
    }
    switch mode {
    case .open:
      setMode(.open)
    case .peek(let id) where items.contains(where: { $0.id == id }):
      setMode(model.mode)
    default:
      // A run ended, or a bot started using this Mac: a short look, then back to compact.
      if let p = fresh.first(where: { $0.ended || ($0.here && $0.phase == "working") }) {
        peek(p.id)
      } else {
        setMode(.compact)
      }
    }
  }

  private func peek(_ id: String) {
    peekWork?.cancel()
    setMode(.peek(id))
    let work = DispatchWorkItem { [weak self] in
      guard let self = self, case .peek = self.model.mode else { return }
      self.setMode(self.model.items.isEmpty ? .hidden : .compact)
    }
    peekWork = work
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.peekFor, execute: work)
  }

  private func closeList() {
    autoOpened = false
    hoverWork?.cancel()
    releaseKeyboard()
    if model.mode == .open { setMode(model.items.isEmpty ? .hidden : .compact) }
  }

  // MARK: Hover, clicks elsewhere, Esc

  private func hover(_ inside: Bool) {
    hovering = inside
    hoverWork?.cancel()
    if inside {
      // At rest the panel sits behind the notch, so hovering it opens the ask field (§6 B 6).
      guard model.hoverOpens, model.mode != .open, model.mode != .drop else { return }
      if model.mode == .hidden, !(panel?.isVisible ?? false) { return }
      let work = DispatchWorkItem { [weak self] in
        guard let self = self, self.hovering else { return }
        self.peekWork?.cancel()
        self.setMode(.open)
        self.send("seen", ["what": "notch"])
      }
      hoverWork = work
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.hoverDelay, execute: work)
    } else if model.mode == .open {
      // A short grace, so moving across the edge doesn't snap it shut.
      let work = DispatchWorkItem { [weak self] in
        guard let self = self, !self.hovering, !self.model.typing, !(self.panel?.isKeyWindow ?? false) else { return }
        self.closeList()
      }
      hoverWork = work
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
  }

  private func installMonitors() {
    // A click anywhere else closes the open list. Mouse monitors need no permission.
    if let m = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] _ in
      self?.closeList()
      if self?.popoverOpen == true { self?.popover?.close() }
    }) { monitors.append(m) }
    if let m = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown], handler: { [weak self] event in
      guard let self = self else { return event }
      if event.type == .keyDown {
        if event.keyCode == 53, self.model.mode == .open { self.closeList() }
      } else if event.window !== self.panel, event.window !== self.popover?.contentViewController?.view.window {
        self.closeList()
      }
      return event
    }) { monitors.append(m) }
  }

  @objc private func screensChanged() {
    setMode(model.mode)
  }

  // MARK: Layout

  private func size(for mode: NotchMode, _ g: NotchGeometry) -> CGSize {
    let compactWidth = g.width + 2 * Self.wing
    switch mode {
    case .hidden:
      return CGSize(width: g.width, height: g.height)
    case .compact:
      return CGSize(width: compactWidth, height: g.height)
    case .peek:
      return CGSize(width: max(compactWidth, 380), height: g.height + Self.rowHeight + 10)
    case .open:
      let rows = CGFloat(min(model.items.count, Self.maxRows))
      return CGSize(width: max(compactWidth, 400), height: g.height + rows * Self.rowHeight + Self.askHeight + 10)
    case .drop:
      return CGSize(width: max(compactWidth, 360), height: g.height + Self.rowHeight + 8)
    }
  }

  /// At rest the panel stays behind a real notch (black on black), so hovering or dropping on the
  /// notch reaches it. Without a notch there is nothing to hover, and it leaves the screen.
  private func rests(_ g: NotchGeometry) -> Bool { model.notchOn && g.hasNotch }

  private func frame(_ size: CGSize, _ g: NotchGeometry) -> NSRect {
    NSRect(x: (g.midX - size.width / 2).rounded(), y: g.top - size.height, width: size.width, height: size.height)
  }

  private func ensurePanel() -> NotchPanel {
    if let panel = panel { return panel }
    let panel = NotchPanel()
    let view = NotchHostingView(rootView: NotchView(model: model, controller: self))
    view.onHover = { [weak self] inside in self?.hover(inside) }
    view.onDrag = { [weak self] inside in self?.dragging(inside) }
    view.onDrop = { [weak self] paths in self?.dropped(paths) }
    view.registerForDraggedTypes([.fileURL])
    panel.contentView = view
    self.panel = panel
    self.host = view
    return panel
  }

  /// Moves to [mode]. The panel's frame always matches the visible shape: it grows at once and the
  /// shape springs out inside it; it shrinks after the shape has sprung back, so nothing outside
  /// the shape ever swallows a click meant for the menu bar.
  private func setMode(_ mode: NotchMode) {
    guard let g = NotchGeometry.current() else { return }
    model.mode = mode
    model.notchWidth = g.width
    model.notchHeight = g.height
    let target = size(for: mode, g)
    let panel = ensurePanel()
    shrinkWork?.cancel()
    if mode != .open { releaseKeyboard() }
    if mode == .hidden && !rests(g) {
      guard panel.isVisible else { return }
      model.shape = target
      let work = DispatchWorkItem { [weak self] in
        guard let self = self, self.model.mode == .hidden else { return }
        panel.orderOut(nil)
      }
      shrinkWork = work
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.settle, execute: work)
      return
    }
    if !panel.isVisible {
      model.shape = CGSize(width: g.width, height: g.height)
      panel.setFrame(frame(CGSize(width: max(target.width, g.width), height: target.height), g), display: false)
      panel.orderFrontRegardless()
    } else {
      let grown = CGSize(width: max(target.width, model.shape.width), height: max(target.height, model.shape.height))
      panel.setFrame(frame(grown, g), display: true)
    }
    DispatchQueue.main.async { self.model.shape = target }
    let work = DispatchWorkItem { [weak self] in
      guard let self = self, self.model.mode == mode else { return }
      panel.setFrame(self.frame(target, g), display: true)
    }
    shrinkWork = work
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.settle, execute: work)
  }

  /// No App Nap while something runs, so the live connection and the tracker stay on time. Off
  /// when nothing runs (costs nothing when idle).
  private func keepAwake(_ on: Bool) {
    if on, activity == nil {
      activity = ProcessInfo.processInfo.beginActivity(options: [.userInitiatedAllowingIdleSystemSleep], reason: "A bot is working")
    } else if !on, let a = activity {
      ProcessInfo.processInfo.endActivity(a)
      activity = nil
    }
  }

  // MARK: Menu bar item and panel

  private func installStatusItem() {
    guard statusItem == nil else { return }
    // Square, so its width never changes and it isn't pushed behind the notch.
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.target = self
    item.button?.action = #selector(togglePopover(_:))
    item.button?.toolTip = "Casama"
    statusItem = item
    popover = makePopover()
    updateStatusIcon()
  }

  private func makePopover() -> NSPopover {
    let popover = NSPopover()
    popover.behavior = .transient
    // Like a menu: no animation (an animated close never finishes while the app is inactive).
    popover.animates = false
    popover.contentViewController = NSHostingController(rootView: MenuPanelView(model: model, controller: self))
    return popover
  }

  private func updateStatusIcon() {
    guard let button = statusItem?.button else { return }
    let dot = model.needsPerson
    let base = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "Casama") ?? NSImage()
    let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
    let symbol = base.withSymbolConfiguration(config) ?? base
    if !dot {
      symbol.isTemplate = true
      button.image = symbol
      return
    }
    // A dot in the corner when something needs the person; drawn in, so the width stays.
    let size = NSSize(width: 20, height: 16)
    let image = NSImage(size: size, flipped: false) { rect in
      symbol.draw(in: NSRect(x: 1, y: 1, width: 17, height: 13))
      NSColor.black.setFill()
      NSBezierPath(ovalIn: NSRect(x: rect.maxX - 7, y: rect.maxY - 7, width: 6, height: 6)).fill()
      return true
    }
    image.isTemplate = true
    button.image = image
  }

  /// Whether the menu bar panel is on screen. NSPopover.isShown stays true after close() while
  /// another app is in front, though its window is gone, so the window decides.
  private var popoverOpen: Bool {
    guard let popover = popover, popover.isShown else { return false }
    return popover.contentViewController?.view.window?.isVisible ?? false
  }

  @objc private func togglePopover(_ sender: Any?) {
    guard var popover = popover, let button = statusItem?.button else { return }
    if popoverOpen {
      // close(), not performClose(): the latter is refused while another app is in front.
      popover.close()
    } else {
      if popover.isShown {
        // Closed on screen but not in AppKit's books: show() would do nothing, so start afresh.
        popover = makePopover()
        self.popover = popover
      }
      // A transient popover only closes on an outside click while its app is active.
      NSApp.activate(ignoringOtherApps: true)
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      send("seen", ["what": "menu_bar"])
      popover.contentViewController?.view.window?.makeKey()
    }
  }

  func quickAsk() {
    popover?.close()
    send("quickAsk")
  }

  func quit() { NSApp.terminate(nil) }
}

#if DEBUG
// MARK: - Debug hooks (debug builds only): the island's on-device check
// (client/integration_test/island_flow_test.dart) reads what is drawn and presses the same
// handlers the buttons call, since a test can't move the real pointer.

extension IslandController {
  @MainActor
  func debug(_ args: [String: Any]) -> Any? {
    let op = args["op"] as? String ?? ""
    let item = (args["id"] as? String).flatMap { id in model.items.first { $0.id == id } }
    switch op {
    case "state":
      var mode = "hidden"
      switch model.mode {
      case .hidden: mode = "hidden"
      case .compact: mode = "compact"
      case .open: mode = "open"
      case .peek(let id): mode = "peek:" + id
      case .drop: mode = "drop"
      }
      let g = NotchGeometry.current()
      let main = NSApp.windows.first { $0 is MainFlutterWindow }
      var out: [String: Any] = [:]
      out["mode"] = mode
      out["items"] = model.items.map { $0.id }
      out["approvals"] = model.items.compactMap { $0.approvalId }
      out["panelVisible"] = debugPanel?.isVisible ?? false
      out["panelFrame"] = debugPanel.map { NSStringFromRect($0.frame) } ?? ""
      out["panelLevel"] = debugPanel?.level.rawValue ?? 0
      out["panelSpaces"] = debugPanel?.collectionBehavior.contains(.canJoinAllSpaces) ?? false
      out["panelFullScreen"] = debugPanel?.collectionBehavior.contains(.fullScreenAuxiliary) ?? false
      out["panelCanBecomeKey"] = debugPanel?.canBecomeKey ?? true
      out["shape"] = NSStringFromSize(model.shape)
      out["hasNotch"] = g?.hasNotch ?? false
      if let g = g { out["notch"] = "\(g.width)x\(g.height) at \(g.midX)" }
      out["statusItem"] = debugStatusVisible
      out["statusDot"] = model.needsPerson
      out["popoverShown"] = debugPopoverShown
      out["windowVisible"] = main?.isVisible ?? false
      out["appActive"] = NSApp.isActive
      out["appNap"] = debugAwake
      out["labels"] = model.labels.count
      out["panelSize"] = debugPanel.map { NSStringFromSize($0.frame.size) } ?? ""
      out["panelKey"] = debugPanel?.isKeyWindow ?? false
      out["panelSharing"] = debugPanel?.sharingType == NSWindow.SharingType.none ? "none" : "shared"
      out["typing"] = model.typing
      out["askBot"] = model.askBot ?? ""
      out["bots"] = model.bots.count
      out["call"] = model.items.first(where: { $0.isCall }).map { ["bot": $0.bot, "muted": $0.muted, "step": $0.step] } ?? [:]
      out["level"] = model.level.value
      out["notchOn"] = model.notchOn
      out["hoverOpens"] = model.hoverOpens
      return out
    case "ax":
      // What VoiceOver reads in the notch: every element's role and label, depth first.
      var found: [String] = []
      func walk(_ e: Any, _ depth: Int) {
        guard depth < 14, let o = e as? NSObject else { return }
        func read(_ name: String) -> Any? {
          let sel = Selector(name)
          guard o.responds(to: sel) else { return nil }
          return o.perform(sel)?.takeUnretainedValue()
        }
        func legacy(_ attribute: String) -> String {
          let sel = Selector(("accessibilityAttributeValue:"))
          guard o.responds(to: sel) else { return "" }
          return o.perform(sel, with: attribute)?.takeUnretainedValue() as? String ?? ""
        }
        let role = read("accessibilityRole") as? String ?? ""
        let label = read("accessibilityLabel") as? String ?? ""
        let title = read("accessibilityTitle") as? String ?? ""
        let texts = [label, title, legacy("AXDescription"), legacy("AXTitle"), legacy("AXValue"), legacy("AXPlaceholderValue")]
        var seenText = Set<String>()
        let text = texts.filter { !$0.isEmpty && seenText.insert($0).inserted }.joined(separator: " / ")
        if !text.isEmpty || args["all"] as? Bool == true { found.append("\(String(repeating: ".", count: depth))\(role) \(type(of: o)): \(text)") }
        for c in read("accessibilityChildren") as? [Any] ?? [] { walk(c, depth + 1) }
      }
      if let view = debugPanel?.contentView { walk(view, 0) }
      return found
    case "click":
      clicked()
      return true
    case "beginTyping":
      // The ask field clicked: the same call the field makes.
      beginTyping()
      return true
    case "send":
      // Enter in the ask field.
      ask(args["text"] as? String ?? "")
      return true
    case "pickBot":
      model.askBot = args["id"] as? String
      return true
    case "drag":
      debugDrag(args["inside"] as? Bool ?? false)
      return true
    case "drop":
      dropped(args["paths"] as? [String] ?? [])
      return true
    case "noNotch":
      NotchGeometry.forceNoNotch = args["on"] as? Bool ?? false
      debugRelayout()
      return true
    case "loginLaunch":
      hideAtLogin()
      return true
    case "snapshot":
      // Draws the notch (and the menu bar panel) as they look now into PNG files.
      guard let path = args["path"] as? String else { return nil }
      let notch = ImageRenderer(content: NotchView(model: model, controller: self).frame(width: max(model.shape.width, 1) + 40, height: max(model.shape.height, 1) + 10).background(Color(white: 0.92)))
      notch.scale = 2
      let panel = ImageRenderer(content: MenuPanelView(model: model, controller: self).background(Color(nsColor: .windowBackgroundColor)))
      panel.scale = 2
      var written: [String] = []
      for (name, image) in [("notch", notch.nsImage), ("menubar", panel.nsImage)] {
        guard let image = image, let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { continue }
        let file = "\(path)-\(name).png"
        if (try? png.write(to: URL(fileURLWithPath: file))) != nil { written.append(file) }
      }
      // The live panel as drawn on screen (AppKit views included, which ImageRenderer can't draw).
      if let view = debugPanel?.contentView, debugPanel?.isVisible == true, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
        view.cacheDisplay(in: view.bounds, to: rep)
        let file = "\(path)-live.png"
        if let png = rep.representation(using: .png, properties: [:]), (try? png.write(to: URL(fileURLWithPath: file))) != nil { written.append(file) }
      }
      return written
    case "hover":
      debugHover(args["inside"] as? Bool ?? false)
      return true
    case "press":
      guard let item = item else { return false }
      switch args["action"] as? String {
      case "stop": stop(item)
      case "allow": decide(item, allow: true)
      case "deny": decide(item, allow: false)
      case "open": open(item)
      case "mute": callMute()
      case "end": callEnd()
      default: return false
      }
      return true
    case "togglePopover":
      debugTogglePopover()
      return true
    case "closeWindow":
      NSApp.windows.first { $0 is MainFlutterWindow }?.performClose(nil)
      return true
    case "dockClick":
      // What clicking the Dock icon does when no window is visible.
      _ = NSApp.delegate?.applicationShouldHandleReopen?(NSApp, hasVisibleWindows: false)
      return true
    case "deactivate":
      // Another app comes to the front, as when the person switches apps.
      NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == "com.apple.finder" }?.activate()
      return true
    default:
      return nil
    }
  }
}
#endif

// MARK: - Views

/// The notch's shape: square on top (it merges with the menu bar and the notch), rounded below.
struct NotchShape: Shape {
  var radius: CGFloat
  func path(in rect: CGRect) -> Path {
    let r = min(radius, rect.height / 2, rect.width / 2)
    var p = Path()
    p.move(to: CGPoint(x: rect.minX, y: rect.minY))
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
    p.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
    p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
    p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - r), control: CGPoint(x: rect.minX, y: rect.maxY))
    p.closeSubpath()
    return p
  }
}

/// The initials gradients and mascots, as the app has them (client/lib/ui/bot_avatar.dart and
/// mascot.dart): keep in step.
private let initialsPalettes: [(UInt32, UInt32)] = [
  (0x14B8A6, 0x0F766E), (0x6366F1, 0x4338CA), (0xF59E0B, 0xD97706), (0xEC4899, 0xBE185D),
  (0x3B82F6, 0x1D4ED8), (0x8B5CF6, 0x6D28D9), (0x10B981, 0x047857), (0xF97316, 0xC2410C),
]
private let mascotKeys: Set<String> = ["winky", "sleepy", "starry", "lovey", "cool", "thinker", "giggly", "shy", "focused", "wow"]

private func hexColor(_ hex: UInt32) -> Color {
  Color(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
}

/// The mascot's still pose from the app's own Flutter assets (assets/mascots/<name>.png), loaded
/// once each.
private var mascotImages: [String: NSImage] = [:]
func mascotImage(_ key: String) -> NSImage? {
  if let image = mascotImages[key] { return image }
  let url = Bundle.main.bundleURL
    .appendingPathComponent("Contents/Frameworks/App.framework/Resources/flutter_assets/assets/mascots/\(key).png")
  guard let image = NSImage(contentsOf: url) else { return nil }
  mascotImages[key] = image
  return image
}

/// A bot's mark, as the app draws it (bot_avatar.dart): its mascot, or its initials on a rounded
/// square in its gradient, picked from its name as botPalette does.
struct BotMark: View {
  let item: IslandItem
  var size: CGFloat = 20
  var pulse = false
  @State private var on = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var mascot: NSImage? {
    guard let avatar = item.botAvatar, avatar.hasPrefix("mascot:") else { return nil }
    let key = String(avatar.dropFirst("mascot:".count))
    return mascotKeys.contains(key) ? mascotImage(key) : nil
  }

  private var colors: [Color] {
    var h = 0
    for u in item.bot.lowercased().utf16 { h = (h &* 31 &+ Int(u)) & 0x7fffffff }
    let p = initialsPalettes[h % initialsPalettes.count]
    return [hexColor(p.0), hexColor(p.1)]
  }

  private var initials: String {
    let parts = item.bot.split(whereSeparator: { $0.isWhitespace })
    guard let first = parts.first?.first else { return "?" }
    if parts.count == 1 { return String(first).uppercased() }
    return (String(first) + String(parts[1].first!)).uppercased()
  }

  var body: some View {
    Group {
      if let mascot {
        Image(nsImage: mascot)
          .resizable()
          .interpolation(.high)
          .scaledToFit()
          // The art keeps a margin for the cloud's hops (mascot.dart, _zoom).
          .frame(width: size * 1.14, height: size * 1.14)
          .frame(width: size, height: size)
      } else {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
          .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
          .overlay(
            Text(initials)
              .font(.system(size: size * (item.bot.trimmingCharacters(in: .whitespaces).contains(" ") ? 0.36 : 0.44), weight: .heavy, design: .rounded))
              .foregroundColor(.white)
              .minimumScaleFactor(0.5)
              .lineLimit(1)
          )
          .frame(width: size, height: size)
      }
    }
    .overlay(alignment: .bottomTrailing) {
      if item.needsPerson {
        Circle().fill(Color.orange)
          .frame(width: max(6, size * 0.34), height: max(6, size * 0.34))
          .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
          .offset(x: size * 0.08, y: size * 0.08)
      }
    }
    .opacity(pulse && on ? 0.55 : 1)
    .onAppear {
      guard pulse, !reduceMotion else { return }
      withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { on = true }
    }
    .accessibilityHidden(true)
  }
}

/// The small glyph that says how a row stands.
struct PhaseGlyph: View {
  let item: IslandItem
  let model: IslandModel
  var body: some View {
    switch item.phase {
    case "needsOk", "takeOver":
      Image(systemName: "hand.raised.fill").foregroundColor(.orange)
    case "finished":
      Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
    case "problem":
      Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
    case "call":
      LevelMeter(level: model.level, muted: item.muted, height: 12)
    default:
      Text(timerInterval: item.startedAt...Date.distantFuture, countsDown: false)
        .monospacedDigit()
        .foregroundColor(.white.opacity(0.85))
    }
  }
}

/// A voice call's level meter: five bars that follow whoever is speaking, flat while muted.
struct LevelMeter: View {
  @ObservedObject var level: CallLevel
  let muted: Bool
  var height: CGFloat = 12
  var dark = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private static let shape: [Double] = [0.55, 0.85, 1, 0.75, 0.5]

  var body: some View {
    HStack(alignment: .center, spacing: 2) {
      if muted {
        Image(systemName: "mic.slash.fill").font(.system(size: height * 0.8)).foregroundColor(.orange)
      } else {
        ForEach(0..<Self.shape.count, id: \.self) { i in
          Capsule()
            .fill(dark ? Color.white : Color.primary)
            .frame(width: 2.5, height: max(2.5, height * min(1, level.value * 1.6) * Self.shape[i]))
        }
      }
    }
    .frame(height: height)
    .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: level.value)
    .accessibilityHidden(true)
  }
}

/// A small pill button. It acts on a click only, never on hover.
struct PillButton: View {
  let title: String
  var prominent = false
  var destructive = false
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 11, weight: .semibold))
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(prominent ? Color.white : Color.white.opacity(destructive ? 0.12 : 0.16)))
        .foregroundColor(prominent ? .black : (destructive ? Color(red: 1, green: 0.55, blue: 0.5) : .white))
    }
    .buttonStyle(.plain)
  }
}

/// One row: the bot, what it's doing, and the row's actions.
struct IslandRow: View {
  let item: IslandItem
  let model: IslandModel
  let controller: IslandController
  var dark = true
  var showActions = true

  private var primary: Color { dark ? .white : .primary }
  private var secondary: Color { dark ? .white.opacity(0.65) : .secondary }

  var body: some View {
    HStack(spacing: 10) {
      BotMark(item: item, size: 28, pulse: item.phase == "working")
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(item.bot).font(.system(size: 12, weight: .semibold)).foregroundColor(primary).lineLimit(1)
          if item.here {
            Text(model.label("on_this_mac")).font(.system(size: 10, weight: .medium)).foregroundColor(.orange).lineLimit(1)
          }
          if item.phase == "working" || item.needsPerson || item.isCall {
            Text(timerInterval: item.startedAt...Date.distantFuture, countsDown: false)
              .font(.system(size: 10)).monospacedDigit().foregroundColor(secondary)
          }
        }
        if item.isCall {
          HStack(spacing: 6) {
            Text(item.step).font(.system(size: 12)).foregroundColor(primary.opacity(0.9)).lineLimit(1)
            LevelMeter(level: model.level, muted: item.muted, height: 12, dark: dark)
          }
        } else {
          Text(item.step).font(.system(size: 12)).foregroundColor(primary.opacity(0.9)).lineLimit(1)
        }
        if let detail = item.detail, !detail.isEmpty {
          Text(detail).font(.system(size: 11)).foregroundColor(secondary).lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
      .onTapGesture {
        if item.isCall { controller.callOpen() } else if item.phase != "needsOk" { controller.open(item) }
      }
      if showActions { actions }
    }
    .padding(.horizontal, 12)
    .frame(height: IslandController.rowHeight)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("\(item.bot), \(item.step)")
  }

  @ViewBuilder private var actions: some View {
    HStack(spacing: 6) {
      switch item.phase {
      case "needsOk":
        if item.approvalId != nil {
          PillButton(title: model.label("deny"), destructive: true) { controller.decide(item, allow: false) }
          PillButton(title: model.label("allow"), prominent: true) { controller.decide(item, allow: true) }
          // A high-risk request can be read in full first.
          if item.risk == "high" { PillButton(title: model.label("open")) { controller.open(item) } }
        } else {
          PillButton(title: model.label("open")) { controller.open(item) }
        }
      case "takeOver":
        PillButton(title: model.label("open"), prominent: true) { controller.open(item) }
      case "call":
        PillButton(title: model.label(item.muted ? "unmute" : "mute"), prominent: item.muted) { controller.callMute() }
        PillButton(title: model.label("hang_up"), destructive: true) { controller.callEnd() }
      case "working":
        // Stop is always one step away (D-066).
        PillButton(title: model.label("stop"), destructive: true) { controller.stop(item) }
      default:
        PillButton(title: model.label("open")) { controller.open(item) }
      }
    }
  }
}

/// The notch: compact wings around the hardware notch, the open list, or a peek.
struct NotchView: View {
  @ObservedObject var model: IslandModel
  let controller: IslandController
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .top) {
        NotchShape(radius: model.mode == .compact || model.mode == .hidden ? 10 : 18).fill(Color.black)
        content.clipped()
      }
      .frame(width: model.shape.width, height: model.shape.height)
      .contentShape(Rectangle())
      .onTapGesture { if model.mode == .compact || model.mode == .hidden { controller.clicked() } }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.36, dampingFraction: 0.82), value: model.shape)
  }

  @ViewBuilder private var content: some View {
    switch model.mode {
    case .hidden:
      EmptyView()
    case .compact:
      compact
    case .open:
      VStack(spacing: 0) {
        Color.clear.frame(height: model.notchHeight)
        ForEach(model.items.prefix(IslandController.maxRows)) { item in
          IslandRow(item: item, model: model, controller: controller)
        }
        AskBar(model: model, controller: controller)
      }
      .transition(.opacity)
    case .drop:
      VStack(spacing: 0) {
        Color.clear.frame(height: model.notchHeight)
        HStack(spacing: 10) {
          Image(systemName: "tray.and.arrow.down.fill").font(.system(size: 18)).foregroundColor(.white)
          Text(model.label("drop_here")).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: IslandController.rowHeight)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])).padding(.horizontal, 10).padding(.vertical, 6))
        .accessibilityElement(children: .combine)
      }
      .transition(.opacity)
    case .peek(let id):
      VStack(spacing: 0) {
        Color.clear.frame(height: model.notchHeight)
        if let item = model.items.first(where: { $0.id == id }) {
          IslandRow(item: item, model: model, controller: controller, showActions: item.here)
        }
      }
      .transition(.opacity)
    }
  }

  private var compact: some View {
    let lead = model.items.first
    return HStack(spacing: 0) {
      HStack {
        if let lead = lead { BotMark(item: lead, size: 18, pulse: lead.phase == "working") }
        Spacer(minLength: 0)
      }
      .padding(.leading, 12)
      .frame(width: IslandController.wing)
      Color.clear.frame(width: model.notchWidth)
      HStack(spacing: 4) {
        Spacer(minLength: 0)
        if model.items.count > 1 {
          Text("\(model.items.count)")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .background(Capsule().fill(lead?.needsPerson == true ? Color.orange : Color.white))
        } else if let lead = lead {
          PhaseGlyph(item: lead, model: model).font(.system(size: 11, weight: .medium))
        }
      }
      .padding(.trailing, 12)
      .frame(width: IslandController.wing)
    }
    .frame(height: model.notchHeight)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(compactLabel(lead))
    .accessibilityAddTraits(.isButton)
    .accessibilityAction { controller.clicked() }
  }

  private func compactLabel(_ lead: IslandItem?) -> String {
    guard let lead = lead else { return "Casama" }
    let others = model.items.count > 1 ? ", +\(model.items.count - 1)" : ""
    return "\(lead.bot), \(lead.step)\(others)"
  }
}

/// Typing into an ask field. A plain AppKit field, so a click can hand the notch the keyboard
/// first (the panel isn't key until then); Enter sends, Esc leaves.
final class AskTextField: NSTextField {
  var onFocus: (() -> Void)?
  override func mouseDown(with event: NSEvent) {
    onFocus?()
    window?.makeFirstResponder(self)
    super.mouseDown(with: event)
  }
}

struct AskField: NSViewRepresentable {
  let placeholder: String
  var dark = true
  var onFocus: () -> Void = {}
  let onSubmit: (String) -> Void
  var onCancel: () -> Void = {}

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  func makeNSView(context: Context) -> AskTextField {
    let f = AskTextField()
    f.isBordered = false
    f.drawsBackground = false
    f.focusRingType = .none
    f.font = .systemFont(ofSize: 12)
    f.lineBreakMode = .byTruncatingTail
    f.cell?.usesSingleLineMode = true
    f.delegate = context.coordinator
    configure(f)
    return f
  }

  func updateNSView(_ f: AskTextField, context: Context) {
    context.coordinator.parent = self
    configure(f)
  }

  private func configure(_ f: AskTextField) {
    f.textColor = dark ? .white : .labelColor
    let hint = dark ? NSColor.white.withAlphaComponent(0.45) : NSColor.placeholderTextColor
    f.placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [.foregroundColor: hint, .font: NSFont.systemFont(ofSize: 12)])
    f.setAccessibilityLabel(placeholder)
    f.cell?.setAccessibilityLabel(placeholder)
    f.cell?.setAccessibilityPlaceholderValue(placeholder)
    f.onFocus = onFocus
  }

  final class Coordinator: NSObject, NSTextFieldDelegate {
    var parent: AskField
    init(_ parent: AskField) { self.parent = parent }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
      if selector == #selector(NSResponder.insertNewline(_:)) {
        let text = control.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return true }
        control.stringValue = ""
        parent.onSubmit(text)
        return true
      }
      if selector == #selector(NSResponder.cancelOperation(_:)) {
        control.stringValue = ""
        parent.onCancel()
        return true
      }
      return false
    }
  }
}

/// The ask field, the bot it goes to, and the Needs you count (§6 B 6).
struct AskBar: View {
  @ObservedObject var model: IslandModel
  let controller: IslandController
  var dark = true

  var body: some View {
    HStack(spacing: 8) {
      if !model.bots.isEmpty { picker }
      AskField(
        placeholder: model.label("ask_hint"),
        dark: dark,
        onFocus: { if dark { controller.beginTyping() } },
        onSubmit: { controller.ask($0, fromMenu: !dark) },
        onCancel: { if dark { controller.cancelTyping() } }
      )
      .frame(height: 20)
      if model.inbox > 0 {
        Button { controller.openLink("/inbox") } label: {
          Text("\(model.label("needs_you")) \(model.inbox)")
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.orange))
            .foregroundColor(.black)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 10)
    .frame(height: 34)
    .background(RoundedRectangle(cornerRadius: 10).fill(dark ? Color.white.opacity(0.1) : Color.primary.opacity(0.06)))
    .padding(.horizontal, 10)
    .frame(height: IslandController.askHeight)
  }

  private var picker: some View {
    Menu {
      ForEach(model.bots) { b in
        Button(b.name) { model.askBot = b.id }
      }
    } label: {
      // A borderless menu draws its label as plain text: the bot's name.
      Text(model.askBotName).font(.system(size: 12, weight: .semibold)).lineLimit(1)
    }
    .menuStyle(.borderlessButton)
    .menuIndicator(.visible)
    .fixedSize()
    .tint(dark ? .white : .primary)
    .modifier(DarkIf(on: dark))
    .accessibilityLabel(model.askBotName)
  }
}

/// Dark on the black notch; the system's appearance elsewhere.
struct DarkIf: ViewModifier {
  let on: Bool
  func body(content: Content) -> some View {
    if on { content.environment(\.colorScheme, .dark) } else { content }
  }
}

/// What the menu bar icon opens: the same list, Quick ask, Open Casama, Settings, Quit.
struct MenuPanelView: View {
  @ObservedObject var model: IslandModel
  let controller: IslandController

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if model.items.isEmpty {
        Text(model.label("nothing"))
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .padding(14)
      } else {
        VStack(spacing: 4) {
          ForEach(model.items) { item in
            IslandRow(item: item, model: model, controller: controller)
              .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.85)))
          }
        }
        .padding(8)
      }
      AskBar(model: model, controller: controller, dark: false)
      Divider()
      VStack(alignment: .leading, spacing: 0) {
        menuButton(model.label("quick_ask"), "bubble.left") { controller.quickAsk() }
        menuButton(model.label("open_casama"), "macwindow") {
          controller.showMainWindow()
        }
        menuButton(model.label("settings"), "gearshape") { controller.openLink("/settings") }
        Divider().padding(.vertical, 4)
        menuButton(model.label("quit"), "power") { controller.quit() }
      }
      .padding(.vertical, 6)
    }
    .frame(width: 360)
  }

  private func menuButton(_ title: String, _ symbol: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: symbol).frame(width: 16)
        Text(title)
        Spacer()
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 14)
      .padding(.vertical, 5)
    }
    .buttonStyle(.plain)
  }
}
