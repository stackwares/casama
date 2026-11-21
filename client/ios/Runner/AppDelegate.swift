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
#if CASAMA_APP_BROWSER
import WebKit
#endif

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
    // The browser a bot can use on this phone (docs/PHONE-BROWSER-PLAN.md): only in builds with
    // the CASAMA_APP_BROWSER flag (Flutter/AppBrowser.xcconfig, scripts/app-browser-switch.sh).
    #if CASAMA_APP_BROWSER
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CasamaAppBrowser") {
      AppBrowser.shared.attach(registrar)
    }
    #endif
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

// MARK: - The phone browser (docs/PHONE-BROWSER-PLAN.md): one WKWebView a bot can drive while the
// person watches. The contract with Dart is client/lib/features/app_browser/PROTOCOL.md §3.
//
// - Its own data store, so its cookies and storage are apart from everything else (iOS 17+).
// - The page script (assets/app_browser/page_agent.js) runs in its own content world, in every
//   frame, from document start; commands go to it with callAsyncJavaScript in that world.
// - Dart decides every main-frame navigation before it loads, and again where it lands.
// - Script-made clicks only: iOS has no public way to send a real touch into a web view.

#if CASAMA_APP_BROWSER
final class AppBrowser: NSObject, WKNavigationDelegate, WKUIDelegate, FlutterPlatformViewFactory, UIGestureRecognizerDelegate {
  static let shared = AppBrowser()
  /// A fixed id for the bots' own cookie jar.
  private static let store = UUID(uuidString: "6B0F4C1E-5C0A-4A7E-9C2B-CA5A3A0B0751")!
  private var channel: FlutterMethodChannel?
  private var registrar: FlutterPluginRegistrar?
  private var web: WKWebView?
  private weak var holder: UIView?
  private var dialog: ((Bool, String?) -> Void)?

  private var world: WKContentWorld { WKContentWorld.world(name: "casama") }

  func attach(_ registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    let channel = FlutterMethodChannel(name: "casama/app_browser", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    self.channel = channel
    registrar.register(self, withId: "casama/app_browser_view")
  }

  private var unsupported: String? {
    if #available(iOS 17.0, *) { return nil }
    return "needs_ios_17"
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "supported":
      result(["supported": unsupported == nil, "reason": unsupported as Any, "realTaps": false])
    case "load":
      guard let raw = args["url"] as? String, let url = URL(string: raw) else {
        return result(FlutterError(code: "bad_args", message: "url", details: nil))
      }
      guard let w = view() else { return result(FlutterError(code: "unsupported", message: unsupported, details: nil)) }
      approved.insert(raw)
      w.load(URLRequest(url: url))
      result(nil)
    case "command":
      command(args["json"] as? String ?? "{}", timeoutMs: args["timeout_ms"] as? Int ?? 30_000, result)
    case "screenshot":
      guard let w = web else { return result(FlutterError(code: "no_page", message: "No page is open", details: nil)) }
      let quality = CGFloat(min(95, max(30, args["quality"] as? Int ?? 70))) / 100
      let config = WKSnapshotConfiguration()
      // Half size is plenty for a model and for the small card.
      config.snapshotWidth = NSNumber(value: Double(max(1, w.bounds.width / 2)))
      w.takeSnapshot(with: config) { image, error in
        guard let data = image?.jpegData(compressionQuality: quality) else {
          return result(FlutterError(code: "failed", message: error?.localizedDescription, details: nil))
        }
        result(["data": data.base64EncodedString()])
      }
    case "url":
      result([
        "url": web?.url?.absoluteString ?? "about:blank",
        "title": web?.title ?? "",
        "loading": web?.isLoading ?? false,
        "canGoBack": web?.canGoBack ?? false,
        "canGoForward": web?.canGoForward ?? false,
      ])
    case "back": web?.goBack(); result(nil)
    case "forward": web?.goForward(); result(nil)
    case "reload": web?.reload(); result(nil)
    case "stop": web?.stopLoading(); result(nil)
    case "answerDialog":
      let done = dialog
      dialog = nil
      done?(args["accept"] as? Bool ?? false, args["text"] as? String)
      result(nil)
    case "clearData":
      clearData(args["host"] as? String) { result(nil) }
    case "dispose":
      dispose()
      result(nil)
    default:
      // "tap" included: there are no real taps on iOS (supported says realTaps false).
      result(FlutterMethodNotImplemented)
    }
  }

  /// The one web view, made on first use. Nil before iOS 17.
  private func view() -> WKWebView? {
    if let web = web { return web }
    guard #available(iOS 17.0, *), let registrar = registrar else { return nil }
    let config = WKWebViewConfiguration()
    config.websiteDataStore = WKWebsiteDataStore(forIdentifier: AppBrowser.store)
    config.mediaTypesRequiringUserActionForPlayback = .all
    config.preferences.javaScriptCanOpenWindowsAutomatically = false
    let key = registrar.lookupKey(forAsset: "assets/app_browser/page_agent.js")
    if let path = Bundle.main.path(forResource: key, ofType: nil), let source = try? String(contentsOfFile: path, encoding: .utf8) {
      config.userContentController.addUserScript(
        WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: world))
    }
    let w = WKWebView(frame: holder?.bounds ?? .zero, configuration: config)
    w.navigationDelegate = self
    w.uiDelegate = self
    w.allowsBackForwardNavigationGestures = true
    #if DEBUG
    if #available(iOS 16.4, *) { w.isInspectable = true }
    #endif
    // Says when a real finger touches the page (so the bot pauses); it never takes the touch.
    let touch = TouchWatcher(target: self, action: #selector(touched))
    touch.cancelsTouchesInView = false
    touch.delaysTouchesBegan = false
    touch.delaysTouchesEnded = false
    touch.delegate = self
    w.addGestureRecognizer(touch)
    web = w
    if let holder = holder { put(w, into: holder) }
    return w
  }

  @objc private func touched() {}

  func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

  fileprivate func fingerDown() { channel?.invokeMethod("userTouched", arguments: nil) }

  private func put(_ w: UIView, into holder: UIView) {
    w.removeFromSuperview()
    w.frame = holder.bounds
    w.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    holder.addSubview(w)
  }

  // MARK: Page script

  private func command(_ json: String, timeoutMs: Int, _ result: @escaping FlutterResult) {
    guard let w = web else {
      return result("{\"ok\":false,\"code\":\"error\",\"message\":\"No page is open\"}")
    }
    var answered = false
    let finish: (String) -> Void = { text in
      if answered { return }
      answered = true
      result(text)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
      finish("{\"ok\":false,\"code\":\"error\",\"message\":\"The page didn't answer in time\"}")
    }
    let body = "const a = globalThis.__casamaPageAgent; if (!a) return JSON.stringify({ok:false,code:'error',message:'The page is not ready yet'}); return JSON.stringify(await a.handle(JSON.parse(cmd)));"
    w.callAsyncJavaScript(body, arguments: ["cmd": json], in: nil, in: world) { outcome in
      switch outcome {
      case .success(let value):
        finish(value as? String ?? "{\"ok\":false,\"code\":\"error\",\"message\":\"The page gave no answer\"}")
      case .failure(let error):
        let message = error.localizedDescription.replacingOccurrences(of: "\\", with: " ").replacingOccurrences(of: "\"", with: "'")
        finish("{\"ok\":false,\"code\":\"error\",\"message\":\"\(message)\"}")
      }
    }
  }

  // MARK: Navigation

  /// Addresses Dart already allowed, each good for one load.
  private var approved = Set<String>()

  private func ask(_ method: String, _ args: [String: Any], _ done: @escaping (Bool) -> Void) {
    guard let channel = channel else { return done(false) }
    channel.invokeMethod(method, arguments: args) { answer in done((answer as? Bool) == true) }
  }

  func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    // Frames inside a page follow the page; only the page's own address is decided.
    guard action.targetFrame?.isMainFrame ?? true, let url = action.request.url else { return decisionHandler(.allow) }
    let raw = url.absoluteString
    if raw == "about:blank" || approved.remove(raw) != nil { return decisionHandler(.allow) }
    let user = action.navigationType == .linkActivated || action.navigationType == .formSubmitted
    ask("navigate", ["url": raw, "redirect": action.navigationType == .other, "user": user]) { ok in
      decisionHandler(ok ? .allow : .cancel)
    }
  }

  /// A link that wants a new window loads in this one: there is one page.
  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    if action.targetFrame == nil { webView.load(action.request) }
    return nil
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    channel?.invokeMethod("pageStarted", arguments: ["url": webView.url?.absoluteString ?? ""])
  }

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    let raw = webView.url?.absoluteString ?? ""
    if raw.isEmpty || raw == "about:blank" { return }
    // Where the page really landed, after redirects.
    ask("landed", ["url": raw]) { ok in
      if !ok, let blank = URL(string: "about:blank") {
        webView.stopLoading()
        webView.load(URLRequest(url: blank))
      }
    }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    channel?.invokeMethod("pageFinished", arguments: ["url": webView.url?.absoluteString ?? "", "title": webView.title ?? ""])
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    channel?.invokeMethod("gone", arguments: ["reason": "killed"])
  }

  // MARK: Dialogs (Dart answers with answerDialog, or dismisses after 30 seconds)

  private func hold(_ kind: String, _ message: String, _ done: @escaping (Bool, String?) -> Void) {
    dialog?(false, nil)
    var finished = false
    let once: (Bool, String?) -> Void = { accept, text in
      if finished { return }
      finished = true
      done(accept, text)
    }
    dialog = once
    channel?.invokeMethod("dialog", arguments: ["kind": kind, "message": message])
    // The backstop: a completion handler that is never called crashes the web view.
    DispatchQueue.main.asyncAfter(deadline: .now() + 60) { once(false, nil) }
  }

  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
    hold("alert", message) { _, _ in completionHandler() }
  }

  func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
    hold("confirm", message) { accept, _ in completionHandler(accept) }
  }

  func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
    hold("prompt", prompt) { accept, text in completionHandler(accept ? (text ?? "") : nil) }
  }

  // MARK: Data

  private func clearData(_ host: String?, _ done: @escaping () -> Void) {
    guard #available(iOS 17.0, *) else { return done() }
    let store = WKWebsiteDataStore(forIdentifier: AppBrowser.store)
    let types = WKWebsiteDataStore.allWebsiteDataTypes()
    guard let host = host else {
      return store.removeData(ofTypes: types, modifiedSince: .distantPast, completionHandler: done)
    }
    store.fetchDataRecords(ofTypes: types) { records in
      let mine = records.filter { host == $0.displayName || host.hasSuffix("." + $0.displayName) || $0.displayName.hasSuffix("." + host) }
      store.removeData(ofTypes: types, for: mine, completionHandler: done)
    }
  }

  private func dispose() {
    dialog?(false, nil)
    dialog = nil
    approved.removeAll()
    web?.stopLoading()
    web?.removeFromSuperview()
    web = nil
  }

  // MARK: The view

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    let box = AppBrowserBox(frame: frame)
    holder = box.container
    if let w = view() { put(w, into: box.container) }
    return box
  }
}

/// The frame a screen shows the page in. The page outlives it: the web view moves to the next one.
private final class AppBrowserBox: NSObject, FlutterPlatformView {
  let container: UIView
  init(frame: CGRect) {
    container = UIView(frame: frame)
    container.clipsToBounds = true
  }
  func view() -> UIView { container }
}

/// Notices a finger going down on the page, then steps aside so the page gets the touch.
private final class TouchWatcher: UIGestureRecognizer {
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    AppBrowser.shared.fingerDown()
    state = .failed
  }
}
#endif
