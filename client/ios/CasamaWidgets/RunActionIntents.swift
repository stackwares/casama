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

  init() {}
  init(approvalId: String, allow: Bool) {
    self.approvalId = approvalId
    self.allow = allow
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    let args: [String: Any] = ["kind": allow ? "allow" : "deny", "approval_id": approvalId, "unlocked": true]
    try await RunActions.perform?(args, "/approvals/\(approvalId)", self)
    return .result()
  }
}
