import AppIntents
import Foundation

// MARK: - Choosing what a widget shows (D-405 §6.1 B–D, §8.6)
//
// The bot and routine pickers read the glance in the app group: the Shortcuts list
// (ShortcutStore) sits in the app's own preferences, which an extension can't read. Named apart
// from the app's BotEntity and RoutineEntity (AppDelegate.swift), since this file is compiled into
// the iPhone app too (its controls' intents must be) and into the Mac widget extension.

@available(iOS 17.0, macOS 14.0, *)
struct WidgetBotEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Bot"
  static var defaultQuery = WidgetBotQuery()
  let id: String
  let name: String
  /// Its mark as the glance holds it (`mascot:<name>`), so a picked bot draws while the glance
  /// no longer lists it.
  let avatar: String
  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

  init(id: String, name: String, avatar: String) {
    self.id = id
    self.name = name
    self.avatar = avatar
  }

  init(_ bot: Glance.Bot) { self.init(id: bot.id, name: bot.name, avatar: bot.avatar) }
}

@available(iOS 17.0, macOS 14.0, *)
struct WidgetBotQuery: EntityQuery {
  private var bots: [WidgetBotEntity] { (GlanceStore.glance()?.bots ?? []).map(WidgetBotEntity.init) }

  func entities(for identifiers: [String]) async throws -> [WidgetBotEntity] {
    bots.filter { identifiers.contains($0.id) }
  }
  func suggestedEntities() async throws -> [WidgetBotEntity] { bots }
  /// A new widget shows the first bot until the person picks one.
  func defaultResult() async -> WidgetBotEntity? { bots.first }
}

@available(iOS 17.0, macOS 14.0, *)
struct WidgetRoutineEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Routine"
  static var defaultQuery = WidgetRoutineQuery()
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

  init(_ routine: Glance.RoutineRef) { self.init(id: routine.id, botId: routine.botId, name: routine.name, bot: routine.bot) }
}

/// The routine picker (Routines widget, Run a routine control): every routine when the glance
/// lists them, else what's coming up.
@available(iOS 17.0, macOS 14.0, *)
struct WidgetRoutineQuery: EntityQuery {
  private var routines: [WidgetRoutineEntity] { (GlanceStore.glance()?.pickableRoutines ?? []).map(WidgetRoutineEntity.init) }

  func entities(for identifiers: [String]) async throws -> [WidgetRoutineEntity] {
    routines.filter { identifiers.contains($0.id) }
  }
  func suggestedEntities() async throws -> [WidgetRoutineEntity] { routines }
}

/// Bot and Ask: which bot. Left empty, the first one.
@available(iOS 17.0, macOS 14.0, *)
struct ChooseBotIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Choose a bot"
  static var description = IntentDescription("Pick the bot this widget shows.")

  @Parameter(title: "Bot")
  var bot: WidgetBotEntity?

  init() {}
  init(bot: WidgetBotEntity?) { self.bot = bot }
}

/// Routines: up to four the person starts by hand. Left empty, the next runs across bots.
@available(iOS 17.0, macOS 14.0, *)
struct ChooseRoutinesIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Choose routines"
  static var description = IntentDescription("Show the next runs, or up to four routines you pick.")

  @Parameter(title: "Routines", size: 4)
  var routines: [WidgetRoutineEntity]?

  init() {}
}
