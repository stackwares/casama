import AVFoundation
import AppIntents
import AuthenticationServices
import CoreLocation
import Flutter
import Photos
import PushKit
import Speech
import UIKit
import UserNotifications
import flutter_callkit_incoming
import native_geofence

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PKPushRegistryDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Phone-call voice (D-135): bots ring this phone with VoIP pushes.
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry
    // Suggestion pushes (D-247): "Do it" opens the app and accepts; "Not now" just clears it.
    // The server sends them with aps.category = SUGGESTION.
    UNUserNotificationCenter.current().setNotificationCategories([
      UNNotificationCategory(
        identifier: "SUGGESTION",
        actions: [
          UNNotificationAction(identifier: "accept", title: "Do it", options: [.foreground]),
          UNNotificationAction(identifier: "later", title: "Not now", options: []),
        ],
        intentIdentifiers: [],
        options: []),
      // Approvals below high risk (D-325): both open the app, which answers, after Face ID or the
      // passcode. The server sends them with aps.category = APPROVAL.
      UNNotificationCategory(
        identifier: "APPROVAL",
        actions: [
          // "Allow", as the app and the watch say it (D-410); the id stays "approve".
          UNNotificationAction(identifier: "approve", title: "Allow", options: [.foreground, .authenticationRequired]),
          UNNotificationAction(identifier: "deny", title: "Deny", options: [.foreground, .authenticationRequired, .destructive]),
        ],
        intentIdentifiers: [],
        options: []),
      // Replies (D-410): no buttons on the phone; the category lets a paired Apple Watch show its
      // own reply notification with quick replies.
      UNNotificationCategory(identifier: "REPLY", actions: [], intentIdentifiers: [], options: []),
    ])
    // The Apple Watch asks this phone to sign it in (D-410). Active before Flutter, so requests
    // that wake the app in the background are held for Dart.
    WatchBridge.shared.activate()
    // Controls and small widgets that open Casama at a place (D-405, ControlIntents.swift) hand
    // the path over the way Siri's Ask a bot does, queued until Flutter is ready.
    if #available(iOS 17.0, *) {
      MainActor.assumeIsolated { WidgetOpen.open = { ShortcutBridge.shared.open($0) } }
    }
    // Device triggers (D-151): a geofence can wake the app in the background, without a UI scene.
    NativeGeofencePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  // Apple requires every VoIP push to report a call to CallKit right away.
  func pushRegistry(
    _ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    let p = payload.dictionaryPayload
    let id = (p["call_id"] as? String) ?? UUID().uuidString
    let reason = (p["reason"] as? String) ?? ""
    let data = flutter_callkit_incoming.Data(id: id, nameCaller: (p["bot_name"] as? String) ?? "Casama", handle: reason, type: 0)
    data.appName = "Casama"
    data.duration = 45000
    data.extra = [
      "call_id": id,
      "bot_id": (p["bot_id"] as? String) ?? "",
      "bot_name": (p["bot_name"] as? String) ?? "Casama",
      "reason": reason,
      "conversation_id": (p["conversation_id"] as? String) ?? "",
    ]
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true) { _ in completion() }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaShortcuts") {
      ShortcutBridge.shared.attach(registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaSignInSheet") {
      SignInSheet.shared.attach(registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaIsland") {
      IslandActivities.shared.attach(registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaNotifications") {
      NotificationsBridge.shared.attach(registrar.messenger())
    }
    // Live calls (D-327): the screen stays on while the call screen is in front.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaScreenAwake") {
      let channel = FlutterMethodChannel(name: "casama/screen_awake", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "set", let args = call.arguments as? [String: Any], let on = args["on"] as? Bool else {
          result(FlutterMethodNotImplemented)
          return
        }
        UIApplication.shared.isIdleTimerDisabled = on
        result(nil)
      }
    }
    // Live calls (D-327 §9): Mute and End Call on the call's Live Activity.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaCallGlance") {
      CallGlanceBridge.shared.attach(registrar.messenger())
    }
    // Widgets (D-405): the widget key, redraws, which widgets are placed.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaWidgets") {
      WidgetsBridge.shared.attach(registrar.messenger())
    }
    // Apple Watch sign-in and Open on iPhone (D-410).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaWatch") {
      WatchBridge.shared.attach(registrar.messenger())
    }
    // System permissions a bot needs on this phone (D-376).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaPermissions") {
      PermissionsBridge.shared.attach(registrar.messenger())
    }
    // A folding iPhone (D-411): its hinge, fold and status area, and files dropped from the app
    // beside this one.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaFold") {
      FoldBridge.shared.attach(registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaDrop") {
      DropBridge.shared.attach(registrar.messenger())
    }
  }
}

// MARK: - Call buttons on the lock screen (D-327 §9): the widget's CallActionIntent posts a Darwin
// notification (it runs in the widget's process); this passes it to Flutter as an `action`.

final class CallGlanceBridge {
  static let shared = CallGlanceBridge()
  static let actions = ["mute", "unmute", "end"]
  private var channel: FlutterMethodChannel?
  private var observing = false

  func attach(_ messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "casama/call_glance", binaryMessenger: messenger)
    guard !observing else { return }
    observing = true
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    for action in CallGlanceBridge.actions {
      CFNotificationCenterAddObserver(
        center, Unmanaged.passUnretained(self).toOpaque(),
        { _, observer, name, _, _ in
          guard let observer, let raw = name?.rawValue as String? else { return }
          let bridge = Unmanaged<CallGlanceBridge>.fromOpaque(observer).takeUnretainedValue()
          let action = String(raw.dropFirst("ai.casama.app.call.".count))
          DispatchQueue.main.async { bridge.send(action) }
        },
        "ai.casama.app.call.\(action)" as CFString, nil, .deliverImmediately)
    }
  }

  private func send(_ action: String) {
    channel?.invokeMethod("action", arguments: ["action": action])
  }
}

// MARK: - Sign-in sheet (D-243): connecting an app signs in through ASWebAuthenticationSession,
// which shares Safari's sign-ins and closes itself when the server sends the browser to
// casama-auth://done. Answers the URL it ended on, nil when the person closed it, or an error.

final class SignInSheet: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = SignInSheet()
  private var session: ASWebAuthenticationSession?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/sign_in_sheet", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "open", let args = call.arguments as? [String: Any],
            let raw = args["url"] as? String, let url = URL(string: raw),
            let scheme = args["scheme"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.open(url, scheme: scheme, result: result)
    }
  }

  private func open(_ url: URL, scheme: String, result: @escaping FlutterResult) {
    session?.cancel()
    let done: ASWebAuthenticationSession.CompletionHandler = { [weak self] back, error in
      DispatchQueue.main.async {
        self?.session = nil
        if let back = back {
          result(back.absoluteString)
        } else if let e = error as? ASWebAuthenticationSessionError, e.code == .canceledLogin {
          result(nil)
        } else {
          result(FlutterError(code: "failed", message: error?.localizedDescription, details: nil))
        }
      }
    }
    let s: ASWebAuthenticationSession
    if #available(iOS 17.4, *) {
      s = ASWebAuthenticationSession(url: url, callback: .customScheme(scheme), completionHandler: done)
    } else {
      s = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: done)
    }
    s.presentationContextProvider = self
    session = s
    if !s.start() {
      session = nil
      result(FlutterError(code: "failed", message: "The sign-in sheet didn't open", details: nil))
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
    return windows.first { $0.isKeyWindow } ?? windows.first ?? ASPresentationAnchor()
  }
}

// MARK: - Shortcuts (D-111): "Ask a bot" and "Run a routine" for Siri, Spotlight and Shortcuts.
// The app keeps its bots and routines in shared preferences (flutter.casama.shortcuts); an intent
// hands a path to Flutter over the casama/shortcuts channel, queued until Flutter is ready.

/// `casama/notifications` (D-325): the app icon badge, and clearing a chat's delivered
/// notifications (the server sends replies with aps.thread-id = the conversation) once it's open.
final class NotificationsBridge {
  static let shared = NotificationsBridge()
  private var channel: FlutterMethodChannel?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/notifications", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "badge":
        let count = max(0, (args["count"] as? Int) ?? 0)
        if #available(iOS 16.0, *) {
          UNUserNotificationCenter.current().setBadgeCount(count) { _ in }
        } else {
          UIApplication.shared.applicationIconBadgeNumber = count
        }
        result(nil)
      case "clear":
        guard let conversation = args["conversation_id"] as? String, !conversation.isEmpty else {
          result(nil)
          return
        }
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications { delivered in
          let ids = delivered.filter { $0.request.content.threadIdentifier == conversation }.map { $0.request.identifier }
          if !ids.isEmpty { center.removeDeliveredNotifications(withIdentifiers: ids) }
        }
        result(nil)
      case "takeAction":
        // iOS buttons arrive through Firebase Messaging's tap handler.
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }
}

final class ShortcutBridge {
  static let shared = ShortcutBridge()
  private var channel: FlutterMethodChannel?
  private var pending: String?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/shortcuts", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "ready" {
        result(self?.pending)
        self?.pending = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  func open(_ path: String) {
    if let channel = channel {
      channel.invokeMethod("open", arguments: path)
    } else {
      pending = path
    }
  }
}

struct ShortcutItem: Codable {
  let id: String
  let name: String
  let detail: String?
}

enum ShortcutStore {
  static func items(_ key: String) -> [ShortcutItem] {
    guard let raw = UserDefaults.standard.string(forKey: "flutter.casama.shortcuts"),
          let data = raw.data(using: .utf8),
          let all = try? JSONDecoder().decode([String: [ShortcutItem]].self, from: data) else { return [] }
    return all[key] ?? []
  }
}

@available(iOS 16.0, macOS 13.0, *)
struct BotEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Bot"
  static var defaultQuery = BotQuery()
  let id: String
  let name: String
  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

@available(iOS 16.0, macOS 13.0, *)
struct BotQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [BotEntity] {
    ShortcutStore.items("bots").filter { identifiers.contains($0.id) }.map { BotEntity(id: $0.id, name: $0.name) }
  }
  func suggestedEntities() async throws -> [BotEntity] {
    ShortcutStore.items("bots").map { BotEntity(id: $0.id, name: $0.name) }
  }
}

@available(iOS 16.0, macOS 13.0, *)
struct RoutineEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Routine"
  static var defaultQuery = RoutineQuery()
  let id: String
  let name: String
  let bot: String
  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)", subtitle: "\(bot)") }
}

@available(iOS 16.0, macOS 13.0, *)
struct RoutineQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [RoutineEntity] {
    ShortcutStore.items("routines").filter { identifiers.contains($0.id) }.map { RoutineEntity(id: $0.id, name: $0.name, bot: $0.detail ?? "") }
  }
  func suggestedEntities() async throws -> [RoutineEntity] {
    ShortcutStore.items("routines").map { RoutineEntity(id: $0.id, name: $0.name, bot: $0.detail ?? "") }
  }
}

@available(iOS 16.0, macOS 13.0, *)
struct AskBotIntent: AppIntent {
  static var title: LocalizedStringResource = "Ask a bot"
  static var description = IntentDescription("Opens Casama with a question for one of your bots.")
  static var openAppWhenRun = true
  @Parameter(title: "Bot") var bot: BotEntity?
  @Parameter(title: "Question") var question: String?

  @MainActor
  func perform() async throws -> some IntentResult {
    var items = [URLQueryItem(name: "text", value: question ?? "")]
    if let bot = bot { items.append(URLQueryItem(name: "bot", value: bot.id)) }
    var c = URLComponents()
    c.path = "/quick-ask"
    c.queryItems = items
    ShortcutBridge.shared.open(c.string ?? "/quick-ask")
    return .result()
  }
}

@available(iOS 16.0, macOS 13.0, *)
struct RunRoutineIntent: AppIntent {
  static var title: LocalizedStringResource = "Run a routine"
  static var description = IntentDescription("Runs one of your bots' routines now.")
  static var openAppWhenRun = true
  @Parameter(title: "Routine") var routine: RoutineEntity

  @MainActor
  func perform() async throws -> some IntentResult {
    ShortcutBridge.shared.open("/run-routine/\(routine.id)")
    return .result()
  }
}

@available(iOS 16.0, macOS 13.0, *)
struct CasamaShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(intent: AskBotIntent(), phrases: ["Ask \(.applicationName)", "Ask a bot in \(.applicationName)"], shortTitle: "Ask a bot", systemImageName: "bubble.left")
    AppShortcut(intent: RunRoutineIntent(), phrases: ["Run a routine in \(.applicationName)"], shortTitle: "Run a routine", systemImageName: "clock")
  }
}

// MARK: - casama/permissions (D-376): what no plugin the app uses covers on iOS: the camera,
// photos, the microphone, speech recognition and "Always" location, checked without prompting and
// asked for when the person taps Turn on. `check {ids}` → {id: state}; `request {id}` → state afterwards.

final class PermissionsBridge {
  static let shared = PermissionsBridge()
  private var channel: FlutterMethodChannel?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/permissions", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "check":
        let ids = args["ids"] as? [String] ?? []
        var out: [String: String] = [:]
        for id in ids { out[id] = PermissionsBridge.state(id) }
        result(out)
      case "request":
        guard let id = args["id"] as? String else {
          return result(FlutterError(code: "bad_args", message: "id is needed", details: nil))
        }
        PermissionsBridge.request(id) { state in DispatchQueue.main.async { result(state) } }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  private static func av(_ s: AVAuthorizationStatus) -> String {
    switch s {
    case .authorized: return "granted"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not_asked"
    @unknown default: return "unknown"
    }
  }

  static func state(_ id: String) -> String {
    switch id {
    case "camera":
      return av(AVCaptureDevice.authorizationStatus(for: .video))
    case "microphone":
      return av(AVCaptureDevice.authorizationStatus(for: .audio))
    case "photos":
      switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
      case .authorized: return "granted"
      case .limited: return "limited"
      case .denied: return "denied"
      case .restricted: return "restricted"
      case .notDetermined: return "not_asked"
      @unknown default: return "unknown"
      }
    case "speech":
      switch SFSpeechRecognizer.authorizationStatus() {
      case .authorized: return "granted"
      case .denied: return "denied"
      case .restricted: return "restricted"
      case .notDetermined: return "not_asked"
      @unknown default: return "unknown"
      }
    case "location_always":
      return AlwaysLocationAsk.state()
    default:
      return "unknown"
    }
  }

  static func request(_ id: String, done: @escaping (String) -> Void) {
    switch id {
    case "camera":
      AVCaptureDevice.requestAccess(for: .video) { _ in done(state(id)) }
    case "microphone":
      AVCaptureDevice.requestAccess(for: .audio) { _ in done(state(id)) }
    case "photos":
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in done(state(id)) }
    case "speech":
      SFSpeechRecognizer.requestAuthorization { _ in done(state(id)) }
    case "location_always":
      DispatchQueue.main.async { AlwaysLocationAsk.start { done(state(id)) } }
    default:
      done(state(id))
    }
  }
}

/// "Always" location. The geolocator plugin returns at once when any location access exists, so it
/// never asks to go from "While using" to "Always"; this does. iOS shows that upgrade prompt once:
/// after it, "While using" means the person kept it, and the switch is in Casama's Settings page.
final class AlwaysLocationAsk: NSObject, CLLocationManagerDelegate {
  private static let askedKey = "casama.permissions.locationAlwaysAsked"
  private static var current: AlwaysLocationAsk?

  private let manager = CLLocationManager()
  private var done: (() -> Void)?
  private var promptShown = false
  private var observers: [NSObjectProtocol] = []

  static func state() -> String {
    switch CLLocationManager().authorizationStatus {
    case .authorizedAlways: return "granted"
    case .authorizedWhenInUse: return UserDefaults.standard.bool(forKey: askedKey) ? "denied" : "not_asked"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not_asked"
    @unknown default: return "unknown"
    }
  }

  /// Asks, then calls [done] once the prompt is answered, or soon when iOS shows none.
  static func start(_ done: @escaping () -> Void) {
    current?.finish()
    let ask = AlwaysLocationAsk()
    current = ask
    ask.run(done)
  }

  private func run(_ done: @escaping () -> Void) {
    self.done = done
    // Only the upgrade from "While using" uses up iOS's one prompt; a first ask gets "While using"
    // (with provisional "Always") and may still be upgraded later.
    if manager.authorizationStatus == .authorizedWhenInUse {
      UserDefaults.standard.set(true, forKey: AlwaysLocationAsk.askedKey)
    }
    let center = NotificationCenter.default
    observers.append(center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
      self?.promptShown = true
    })
    observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
      guard let self, self.promptShown else { return }
      // The status change lands just after the prompt closes.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.finish() }
    })
    manager.delegate = self
    manager.requestAlwaysAuthorization()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      guard let self, !self.promptShown else { return }
      self.finish()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}

  private func finish() {
    guard let done else { return }
    self.done = nil
    for o in observers { NotificationCenter.default.removeObserver(o) }
    observers = []
    manager.delegate = nil
    if AlwaysLocationAsk.current === self { AlwaysLocationAsk.current = nil }
    done()
  }
}

// MARK: - The fold (D-411): an iPhone Duo's hinge, fold and status area, for lib/core/fold/fold.dart.
// Flutter doesn't report them on iOS yet (flutter/flutter#193025). Everything here is iOS 27.1 and
// later; before that, and on an iPhone without a hinge, the stream stays silent and the app lays
// itself out as on any iPhone.

final class FoldBridge: NSObject, FlutterStreamHandler {
  static let shared = FoldBridge()

  private var sink: FlutterEventSink?
  private var last: [String: Any]?
  private weak var probe: UIView?

  func attach(_ messenger: FlutterBinaryMessenger) {
    FlutterEventChannel(name: "casama/fold", binaryMessenger: messenger).setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    last = nil
    install(tries: 40)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  /// The view Flutter draws in. It may not be on screen yet when Dart first listens.
  static var flutterView: UIView? {
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows {
        if let controller = window.rootViewController as? FlutterViewController, controller.isViewLoaded {
          return controller.view
        }
      }
    }
    return nil
  }

  private func install(tries: Int) {
    guard #available(iOS 27.1, *) else { return }
    if let probe {
      probe.setNeedsLayout()
      return
    }
    guard let host = FoldBridge.flutterView else {
      if tries > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in self?.install(tries: tries - 1) }
      }
      return
    }
    let view = FoldProbe(frame: host.bounds)
    view.report = { [weak self] values in self?.send(values) }
    host.addSubview(view)
    probe = view
  }

  private func send(_ values: [String: Any]) {
    guard let sink else { return }
    if let last {
      // The hinge reports its angle many times a second while it moves. Only the angle changing
      // by less than two degrees is not news.
      var a = last, b = values
      let moved = abs(((a.removeValue(forKey: "angle") as? Double) ?? 0) - ((b.removeValue(forKey: "angle") as? Double) ?? 0))
      if moved < 2, NSDictionary(dictionary: a).isEqual(to: b) { return }
    }
    last = values
    sink(values)
  }
}

/// An invisible view over Flutter's that reads the hinge, the regions iOS reserves and the side of
/// the vertical bar. The fold lags the hinge by up to a second, and UIKit lays a view out again
/// when a region it read during layout changes, so the regions are read in `layoutSubviews`.
@available(iOS 27.1, *)
private final class FoldProbe: UIView {
  var report: (([String: Any]) -> Void)?
  private var hinge: UIHinge?

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    isAccessibilityElement = false
    backgroundColor = .clear
    isOpaque = false
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addInteraction(
      UIHingeInteraction { [weak self] _, update in
        self?.hinge = update.hinge
        self?.setNeedsLayout()
        self?.read()
      })
    registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) { (view: FoldProbe, _: UITraitCollection) in
      view.read()
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    return nil
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    read()
  }

  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    read()
  }

  private func numbers(_ r: CGRect) -> [Double] {
    [Double(r.minX), Double(r.minY), Double(r.width), Double(r.height)]
  }

  private func word(_ status: UIHinge.Status) -> String {
    switch status {
    case .closed: return "closed"
    case .partiallyOpen: return "partlyOpen"
    case .fullyOpen: return "open"
    default: return "unknown"
    }
  }

  /// The vertical bar follows the hardware, so it is reported as a side of the screen.
  private var barSide: String {
    let rightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
    switch traitCollection.verticalBarEdge {
    case .leading: return rightToLeft ? "right" : "left"
    case .trailing: return rightToLeft ? "left" : "right"
    default: return "none"
    }
  }

  func read() {
    // No hinge: an ordinary iPhone. Nothing is sent, and Dart keeps "no fold".
    guard let hinge else { return }
    var values: [String: Any] = [
      "hinge": word(hinge.status),
      "angle": Double(hinge.angle) * 180 / Double.pi,
      "bar": barSide,
      "foldActive": false,
    ]
    if let fold = reservedRegions(kind: .division, options: [.includeInactive]).first {
      values["fold"] = numbers(fold.frame)
      values["foldActive"] = fold.isActive
    }
    values["cameras"] = reservedRegions(kind: .occlusion).filter { $0.isActive }.map { numbers($0.frame) }
    if let scene = window?.windowScene {
      values["fullScreen"] = scene.isFullScreen
      if let status = scene.statusBarManager?.statusBarFrame, !status.isEmpty {
        values["status"] = numbers(convert(status, from: nil))
      }
    }
    report?(values)
  }
}

// MARK: - Dropped files (D-411): beside another app (Split View on an iPhone Duo or an iPad), a
// file, a photo or text dragged onto Casama goes to the chat on screen. Dart says when there is
// one (lib/core/dropped_files.dart); without one the drop is refused.

final class DropBridge: NSObject, UIDropInteractionDelegate {
  static let shared = DropBridge()

  private var channel: FlutterMethodChannel?
  private var accepting = false
  private var installed = false

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/drop", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "accept", let on = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.accepting = on
      self?.install()
      result(nil)
    }
    self.channel = channel
  }

  private func install() {
    guard !installed, let host = FoldBridge.flutterView else { return }
    host.addInteraction(UIDropInteraction(delegate: self))
    installed = true
  }

  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
    accepting
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    UIDropProposal(operation: accepting ? .copy : .forbidden)
  }

  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("dropped/\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let group = DispatchGroup()
    let lock = NSLock()
    var files: [String] = []
    var texts: [String] = []
    for item in session.items {
      let provider = item.itemProvider
      // Plain text and links become text in the message; everything else is a file.
      let isText = provider.hasItemConformingToTypeIdentifier("public.plain-text") || provider.hasItemConformingToTypeIdentifier("public.url")
      let isFile = provider.hasItemConformingToTypeIdentifier("public.file-url") || !isText
      if isFile, let type = provider.registeredTypeIdentifiers.first(where: { $0 != "public.file-url" }) ?? provider.registeredTypeIdentifiers.first {
        group.enter()
        provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
          defer { group.leave() }
          guard let url else { return }
          var name = provider.suggestedName ?? url.lastPathComponent
          if !name.contains("."), !url.pathExtension.isEmpty { name += ".\(url.pathExtension)" }
          let to = folder.appendingPathComponent(name)
          // The file iOS hands over is deleted when this block returns, so it is copied now.
          if (try? FileManager.default.copyItem(at: url, to: to)) != nil {
            lock.lock()
            files.append(to.path)
            lock.unlock()
          }
        }
      } else if provider.canLoadObject(ofClass: NSString.self) {
        group.enter()
        _ = provider.loadObject(ofClass: NSString.self) { text, _ in
          defer { group.leave() }
          if let text = text as? String {
            lock.lock()
            texts.append(text)
            lock.unlock()
          }
        }
      }
    }
    group.notify(queue: .main) { [weak self] in
      self?.channel?.invokeMethod("dropped", arguments: ["files": files, "text": texts.joined(separator: "\n")])
    }
  }
}
