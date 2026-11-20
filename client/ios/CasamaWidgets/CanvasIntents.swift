import AppIntents
import Foundation

// MARK: - Which canvas a Canvas widget shows (docs/BOT-WIDGET-PLAN.md §10.1, §11.3)
//
// Automatic (the canvas set most recently) or one named canvas, from the list stored in the app
// group (Canvas.swift). Shared by the iPhone and Mac widget extensions.

@available(iOS 17.0, macOS 14.0, *)
struct WidgetCanvasEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Canvas"
  static var defaultQuery = WidgetCanvasQuery()
  /// The id that stands for Automatic.
  static let automaticId = "automatic"

  let id: String
  let name: String
  let bot: String

  var isAutomatic: Bool { id == Self.automaticId }

  var displayRepresentation: DisplayRepresentation {
    if isAutomatic {
      return DisplayRepresentation(title: "Automatic", subtitle: "What a bot set most recently")
    }
    return DisplayRepresentation(title: "\(bot.isEmpty ? name : "\(name) · \(bot)")")
  }

  init(id: String, name: String, bot: String) {
    self.id = id
    self.name = name
    self.bot = bot
  }

  init(_ canvas: BotCanvas) { self.init(id: canvas.id, name: canvas.name, bot: canvas.bot) }

  static let automatic = WidgetCanvasEntity(id: automaticId, name: "Automatic", bot: "")
}

@available(iOS 17.0, macOS 14.0, *)
struct WidgetCanvasQuery: EntityQuery {
  private var canvases: [WidgetCanvasEntity] {
    let shown = (CanvasStore.load()?.items ?? []).filter { $0.status == "shown" }
    return [WidgetCanvasEntity.automatic] + shown.map(WidgetCanvasEntity.init)
  }

  func entities(for identifiers: [String]) async throws -> [WidgetCanvasEntity] {
    let all = canvases
    // A picked canvas that's gone keeps its id: the widget falls back to Automatic.
    return identifiers.map { id in all.first { $0.id == id } ?? WidgetCanvasEntity(id: id, name: "Canvas", bot: "") }
  }
  func suggestedEntities() async throws -> [WidgetCanvasEntity] { canvases }
  /// A new widget shows Automatic.
  func defaultResult() async -> WidgetCanvasEntity? { .automatic }
}

/// The Canvas widget's setting.
@available(iOS 17.0, macOS 14.0, *)
struct ChooseCanvasIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Choose a canvas"
  static var description = IntentDescription("Show what a bot set most recently, or one canvas.")

  @Parameter(title: "Canvas")
  var canvas: WidgetCanvasEntity?

  init() {}
  init(canvas: WidgetCanvasEntity?) { self.canvas = canvas }

  /// The picked canvas's id, or nil for Automatic.
  var canvasId: String? {
    guard let c = canvas, !c.isAutomatic else { return nil }
    return c.id
  }
}
