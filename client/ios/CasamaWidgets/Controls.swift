import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Controls: Control Center, the Lock Screen's corners and the Action button (D-405 §6.3)
//
// Ask and Talk open Casama at the place (OpenCasamaIntent runs in the app, ControlIntents.swift);
// Run a routine runs it without opening Casama, after the phone is unlocked
// (RunRoutineWidgetIntent asks for that, decision 6).

struct AskCasamaControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "AskCasamaControl") {
      ControlWidgetButton(action: OpenCasamaIntent(path: "/quick-ask")) {
        Label("Ask Casama", systemImage: "bubble.left.fill")
      }
    }
    .displayName("Ask Casama")
    .description("Open quick ask with the keyboard up.")
  }
}

struct TalkToBotControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(kind: "TalkToBotControl", intent: TalkToBotControlIntent.self) { config in
      ControlWidgetButton(action: OpenCasamaIntent(path: config.bot.map { "/bots/\($0.id)/call" } ?? "/quick-ask")) {
        Label(config.bot.map { "Talk to \($0.name)" } ?? "Talk to a bot", systemImage: "mic.fill")
      }
    }
    .displayName("Talk to a bot")
    .description("Start a voice call with the bot you pick.")
    .promptsForUserConfiguration()
  }
}

struct RunRoutineControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(kind: "RunRoutineControl", intent: RunRoutineControlIntent.self) { config in
      ControlWidgetButton(action: RunRoutineWidgetIntent(routineId: config.routine?.id ?? "", botId: config.routine?.botId ?? "")) {
        Label(config.routine?.name ?? "Run a routine", systemImage: "play.fill")
      }
    }
    .displayName("Run a routine")
    .description("Run the routine you pick, without opening Casama.")
    .promptsForUserConfiguration()
  }
}
