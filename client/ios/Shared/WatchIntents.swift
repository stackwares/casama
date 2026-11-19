import AppIntents
import Foundation
import WidgetKit

// MARK: - App Intents both watch targets share (D-410 §6.3, §6.4)
//
// Compiled into the watch app and its widget extension: a button on a complication runs its intent
// in the extension, and an intent that opens the app must exist in the app too. The pickers read
// the saved glance, so they work offline and need no call.
//
// App Intents metadata is read at build time, so the titles and parameter names below must be
// string literals; they match the WatchL10n words they stand for. Everything the person sees at
// run time (dialogs, labels, names) comes from WatchL10n.

// MARK: Pickers

struct WatchBotEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Bot"
  static var defaultQuery = WatchBotQuery()
  let id: String
  let name: String
  /// Its mark as the glance holds it, so a picked bot still draws when the glance drops it.
  let avatar: String
  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

  init(id: String, name: String, avatar: String) {
    self.id = id
    self.name = name
    self.avatar = avatar
  }

  init(_ bot: Glance.Bot) { self.init(id: bot.id, name: bot.name, avatar: bot.avatar) }
}

struct WatchBotQuery: EntityQuery {
  private var bots: [WatchBotEntity] { (GlanceCache.glance()?.glance.bots ?? []).map(WatchBotEntity.init) }

  func entities(for identifiers: [String]) async throws -> [WatchBotEntity] {
    bots.filter { identifiers.contains($0.id) }
  }
  func suggestedEntities() async throws -> [WatchBotEntity] { bots }
  func defaultResult() async -> WatchBotEntity? { bots.first }
}

struct WatchRoutineEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Routine"
  static var defaultQuery = WatchRoutineQuery()
  let id: String
  let botId: String
  let name: String
  let bot: String
  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)", subtitle: "\(bot)") }

  init(id: String, botId: String, name: String, bot: String) {
    self.id = id
    self.botId = botId
    self.name = name
    self.bot = bot
  }
}

struct WatchRoutineQuery: EntityStringQuery {
  private var routines: [WatchRoutineEntity] {
    guard let g = GlanceCache.glance()?.glance else { return [] }
    let picked = g.routines.filter { !$0.name.isEmpty }.map { WatchRoutineEntity(id: $0.id, botId: $0.botId, name: $0.name, bot: $0.bot) }
    if !picked.isEmpty { return picked }
    return g.next.map { WatchRoutineEntity(id: $0.id, botId: $0.botId, name: $0.name, bot: $0.bot) }
  }

  func entities(for identifiers: [String]) async throws -> [WatchRoutineEntity] {
    routines.filter { identifiers.contains($0.id) }
  }
  func entities(matching string: String) async throws -> [WatchRoutineEntity] {
    let s = string.lowercased()
    return routines.filter { $0.name.lowercased().contains(s) }
  }
  func suggestedEntities() async throws -> [WatchRoutineEntity] { routines }
}

/// The Ask and Bot complications: which bot. Left empty, the one Ask uses.
struct ChooseWatchBotIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Bot"
  static var description = IntentDescription("Where a bot stands and what it is doing")

  @Parameter(title: "Bot")
  var bot: WatchBotEntity?

  init() {}
  init(bot: WatchBotEntity?) { self.bot = bot }
}

/// Talk control: which bot.
struct TalkControlConfigIntent: ControlConfigurationIntent {
  static var title: LocalizedStringResource = "Talk to a bot"

  @Parameter(title: "Bot")
  var bot: WatchBotEntity?

  init() {}
}

/// Run a routine control: which routine.
struct RunRoutineControlConfigIntent: ControlConfigurationIntent {
  static var title: LocalizedStringResource = "Run a routine"

  @Parameter(title: "Routine")
  var routine: WatchRoutineEntity?

  init() {}
}

// MARK: Opening the app at a place

/// Hands a watch link from an intent to the running app (WatchOpen.handler, set at launch), or
/// keeps it for the app to pick up when it comes forward.
enum WatchOpen {
  @MainActor static var handler: ((WatchLink) -> Void)?
  private static let pendingKey = "pending_link"

  @MainActor
  static func open(_ link: WatchLink) {
    if let handler {
      handler(link)
    } else {
      WatchGroup.defaults.set(link.route, forKey: pendingKey)
    }
  }

  /// The link an intent left before the app was ready.
  static func takePending() -> WatchLink? {
    guard let route = WatchGroup.defaults.string(forKey: pendingKey) else { return nil }
    WatchGroup.defaults.removeObject(forKey: pendingKey)
    return WatchLink.parse(route: route)
  }
}

/// Opens the watch app at a screen (Ask listening, Talk, Needs you).
struct OpenWatchIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Casama"
  static var isDiscoverable: Bool = false
  static var openAppWhenRun: Bool = true

  /// A watch route ("/watch/ask?bot=…").
  @Parameter(title: "Where")
  var route: String

  init() {}
  init(_ link: WatchLink) { route = link.route }

  @MainActor
  func perform() async throws -> some IntentResult {
    WatchOpen.open(WatchLink.parse(route: route))
    return .result()
  }
}

// MARK: Acting without opening the app

/// Allow in place, on the Needs you complication and Smart Stack card. Only when the server says
/// this watch may allow it with a tap, and only on the wrist and unlocked: anything else waits
/// for the app, where a hold or the phone decides (§6.1 B).
struct AllowRequestIntent: AppIntent {
  static var title: LocalizedStringResource = "Allow"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Request")
  var approvalId: String

  init() {}
  init(approvalId: String) { self.approvalId = approvalId }

  func perform() async throws -> some IntentResult {
    guard let api = WatchAPI.current() else { return .result() }
    do {
      let approval = try await api.approval(approvalId)
      guard approval.isPending, approval.canAllow == .tap else {
        await WatchSync.refreshGlance(api: api)
        WatchSync.reloadWidgets()
        return .result()
      }
      guard await WristCheck.check() == .ok else { return .result() }
      try await api.decide(approvalId, allow: true, surface: WatchSurface.complication)
    } catch WatchAPIError.signedOut {
      WatchSync.signedOut()
      return .result()
    } catch {
      // Answered elsewhere, or no connection: the refresh below shows how it stands.
    }
    await WatchSync.refreshGlance(api: api)
    WatchSync.reloadWidgets()
    return .result()
  }
}

/// Run a routine now: the control, the Up next card and Siri ("Run my morning brief in Casama").
struct RunRoutineNowIntent: AppIntent {
  static var title: LocalizedStringResource = "Run a routine"
  static var description = IntentDescription("The next routine and when it runs")

  @Parameter(title: "Routine")
  var routine: WatchRoutineEntity

  init() {}
  init(routine: WatchRoutineEntity) { self.routine = routine }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let api = WatchAPI.current() else { return .result(dialog: "\(WatchL10n.openToSignIn)") }
    do {
      _ = try await api.runRoutine(routine.id, surface: WatchSurface.siri)
      await WatchSync.refreshGlance(api: api)
      WatchSync.reloadWidgets()
      return .result(dialog: "\(WatchL10n.started)")
    } catch WatchAPIError.signedOut {
      WatchSync.signedOut()
      return .result(dialog: "\(WatchL10n.openToSignIn)")
    } catch WatchAPIError.offline {
      return .result(dialog: "\(WatchL10n.couldntReach)")
    } catch {
      return .result(dialog: "\(WatchL10n.couldntReach)")
    }
  }
}

/// The Run a routine control's button: runs the picked routine, or opens Up next to pick one.
struct RunControlIntent: AppIntent {
  static var title: LocalizedStringResource = "Run a routine"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Routine")
  var routine: WatchRoutineEntity?

  init() {}
  init(routine: WatchRoutineEntity?) { self.routine = routine }

  func perform() async throws -> some IntentResult & OpensIntent {
    guard let routine else { return .result(opensIntent: OpenWatchIntent(.upNext)) }
    guard let api = WatchAPI.current() else { return .result(opensIntent: OpenWatchIntent(.now)) }
    _ = try? await api.runRoutine(routine.id, surface: WatchSurface.control)
    await WatchSync.refreshGlance(api: api)
    WatchSync.reloadWidgets()
    return .result()
  }
}
