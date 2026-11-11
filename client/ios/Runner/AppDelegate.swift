import AppIntents
import Flutter
import PushKit
import UIKit
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
  }
}

// MARK: - Shortcuts (D-111): "Ask a bot" and "Run a routine" for Siri, Spotlight and Shortcuts.
// The app keeps its bots and routines in shared preferences (flutter.casama.shortcuts); an intent
// hands a path to Flutter over the casama/shortcuts channel, queued until Flutter is ready.

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
