import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Controls (§6.3): Ask, Talk, Run a routine

struct AskControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "WatchAskControl") {
      ControlWidgetButton(action: OpenWatchIntent(.ask(bot: nil))) {
        Label(WatchL10n.controlAsk, systemImage: "mic.fill")
      }
    }
    .displayName(LocalizedStringResource(stringLiteral: WatchL10n.controlAsk))
  }
}

struct TalkControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(kind: "WatchTalkControl", intent: TalkControlConfigIntent.self) { config in
      ControlWidgetButton(action: OpenWatchIntent(.talk(bot: config.bot?.id))) {
        Label(config.bot?.name ?? WatchL10n.controlTalk, systemImage: "phone.fill")
      }
    }
    .displayName(LocalizedStringResource(stringLiteral: WatchL10n.controlTalk))
  }
}

struct RunRoutineControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(kind: "WatchRunControl", intent: RunRoutineControlConfigIntent.self) { config in
      // Not picked yet, it opens Up next to choose there.
      ControlWidgetButton(action: RunControlIntent(routine: config.routine)) {
        Label(config.routine?.name ?? WatchL10n.controlRun, systemImage: "play.fill")
      }
    }
    .displayName(LocalizedStringResource(stringLiteral: WatchL10n.controlRun))
  }
}

@main
struct CasamaWatchWidgets: WidgetBundle {
  var body: some Widget {
    WatchInlineWidget()
    WatchNeedsCircularWidget()
    WatchNeedsCornerWidget()
    WatchNeedsRectWidget()
    WatchAskWidget()
    WatchCreditsWidget()
    WatchBotWidget()
    WatchUpNextWidget()
    WatchWorkingWidget()
    WatchBriefWidget()
    AskControl()
    TalkControl()
    RunRoutineControl()
  }
}
