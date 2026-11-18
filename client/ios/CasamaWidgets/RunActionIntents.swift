import ActivityKit
import AppIntents
import Foundation

// MARK: - Acting from a Live Activity without opening Casama (D-324, Phase 6; decision 5)
//
// Built into both the app and the widget extension: the activity's buttons name these intents,
// and iOS runs them in the app's process (starting it in the background if need be), where the app
// hands them to Dart (IslandActivities.perform), which acts as the signed-in person.
//
// - Stop is never gated (§10): it runs from the Lock Screen as is.
// - Allow and Deny ask for Face ID or the passcode first (`requiresAuthentication`), and Dart
//   answers only a request it shows as waiting that isn't high risk; those show Review instead.
// - If the app can't do it in place (still starting after 10 seconds, or Dart says no), the app
//   opens where the person can: the stop screen, or the request.

@available(iOS 17.0, *)
enum RunActions {
  /// Set by the app; nil in the widget extension, which never runs these. Throws to have iOS bring
  /// the app forward when it couldn't act in place (only the app can ask that: the
  /// foreground-continuable conformances live in IslandActivities.swift).
  @MainActor static var perform: ((_ args: [String: Any], _ fallback: String, _ intent: any AppIntent) async throws -> Void)?
}

@available(iOS 17.0, *)
struct StopRunIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Stop the bot"
  static var isDiscoverable: Bool = false
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

  @Parameter(title: "Run")
  var runId: String

  init() {}
  init(runId: String) { self.runId = runId }

  @MainActor
  func perform() async throws -> some IntentResult {
    try await RunActions.perform?(["kind": "stop", "run_id": runId], "/runs/\(runId)/stop", self)
    return .result()
  }
}

@available(iOS 17.0, *)
struct AnswerRequestIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Answer a bot's request"
  static var isDiscoverable: Bool = false
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

  @Parameter(title: "Request")
  var approvalId: String

  @Parameter(title: "Allow")
  var allow: Bool

  /// A Home Screen widget's Allow/Deny (D-405): Dart then answers low-risk requests only (§10).
  @Parameter(title: "From a widget", default: false)
  var fromWidget: Bool

  init() {}
  init(approvalId: String, allow: Bool, fromWidget: Bool = false) {
    self.approvalId = approvalId
    self.allow = allow
    self.fromWidget = fromWidget
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    var args: [String: Any] = ["kind": allow ? "allow" : "deny", "approval_id": approvalId, "unlocked": true]
    if fromWidget { args["from"] = "widget" }
    try await RunActions.perform?(args, "/approvals/\(approvalId)", self)
    return .result()
  }
}

// MARK: - Acting from a widget or control (D-405 §8.4, §17)
//
// Run now and Do it on the Home Screen widgets, and the Run a routine control, go the same way as
// Stop: a LiveActivityIntent, so iOS runs it in the app's process, which hands it to Dart. Both
// ask for the phone to be unlocked first (a widget's buttons are dead on a locked phone anyway;
// the control asks, decision 6). Dart refuses what it can't do here and the app opens the link.

@available(iOS 17.0, *)
struct RunRoutineWidgetIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Run a routine now"
  static var isDiscoverable: Bool = false
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

  @Parameter(title: "Routine")
  var routineId: String

  @Parameter(title: "Bot")
  var botId: String

  init() {}
  init(routineId: String, botId: String) {
    self.routineId = routineId
    self.botId = botId
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    // A control with no routine picked yet: Dart finds nothing to run and the app opens the bots.
    let fallback = routineId.isEmpty ? "/bots" : "/run-routine/\(routineId):\(botId)"
    try await RunActions.perform?(["kind": "run_routine", "routine_id": routineId, "bot_id": botId], fallback, self)
    // It started: the widget, reloaded after a button, says Started (GlanceSnapshot.started).
    GlanceStore.markStarted(routineId)
    return .result()
  }
}

@available(iOS 17.0, *)
struct AcceptSuggestionIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Do what a bot suggests"
  static var isDiscoverable: Bool = false
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

  @Parameter(title: "Suggestion")
  var suggestionId: String

  @Parameter(title: "Bot")
  var botId: String

  init() {}
  init(suggestionId: String, botId: String) {
    self.suggestionId = suggestionId
    self.botId = botId
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    let args: [String: Any] = ["kind": "accept", "suggestion_id": suggestionId, "bot_id": botId]
    try await RunActions.perform?(args, "/suggestions/\(suggestionId)/accept?bot=\(botId)", self)
    return .result()
  }
}
