import AppIntents
import Foundation

// MARK: - Siri and Shortcuts on the watch (§6.4)
//
// "Ask Casama", "Run my <routine> in Casama", "What needs me in Casama". App Intents titles and
// phrases must be literals the system can index ahead of time, so they are written in English
// here and translated through the string catalog when one is added; what Siri says back comes
// from WatchL10n.

/// Opens the watch app listening, to the bot Ask goes to.
struct AskCasamaIntent: AppIntent {
  static var title: LocalizedStringResource = "Ask Casama"
  static var description = IntentDescription("Ask a bot something by voice")
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    WatchOpen.open(.ask(bot: nil))
    return .result()
  }
}

/// Says how many things wait and the first of them, without opening the app.
struct WhatNeedsMeIntent: AppIntent {
  static var title: LocalizedStringResource = "What needs me"
  static var description = IntentDescription("What is waiting for your OK")

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let api = WatchAPI.current() else { return .result(dialog: "\(WatchL10n.openToSignIn)") }
    let outcome = await WatchSync.refreshGlance(api: api)
    if outcome == .signedOut { return .result(dialog: "\(WatchL10n.openToSignIn)") }
    guard let glance = GlanceCache.glance()?.glance else { return .result(dialog: "\(WatchL10n.couldntReach)") }
    guard glance.needsCount > 0 else { return .result(dialog: "\(WatchL10n.allClear). \(WatchL10n.nothingWaiting)") }
    // Private workspaces and hidden details: the count only, never the words.
    let words = glance.flags.isPrivate || glance.flags.hideReplyText ? "" : (glance.needs.first.map { "\($0.bot): \($0.text)" } ?? "")
    return .result(dialog: "\(WatchL10n.siriNeeds("\(glance.needsCount)", text: words))")
  }
}

struct CasamaWatchShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AskCasamaIntent(),
      phrases: ["Ask \(.applicationName)", "Ask \(.applicationName) something"],
      shortTitle: "Ask",
      systemImageName: "mic.fill")
    AppShortcut(
      intent: RunRoutineNowIntent(),
      phrases: ["Run my \(\.$routine) in \(.applicationName)", "Run \(\.$routine) in \(.applicationName)"],
      shortTitle: "Run a routine",
      systemImageName: "clock.arrow.circlepath")
    AppShortcut(
      intent: WhatNeedsMeIntent(),
      phrases: ["What needs me in \(.applicationName)", "What's waiting in \(.applicationName)"],
      shortTitle: "Needs you",
      systemImageName: "exclamationmark.bubble.fill")
  }
}
