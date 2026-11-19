import SwiftUI

// MARK: - A request (§6.1 B, mockups "Needs you · tap", "Hold to allow", "Phone only")
//
// Drawn first from what the glance said, then from the server's own word on what this watch may
// do: allow in one tap, after a hold, or only on the phone. Deny is always there.

struct ApprovalView: View {
  let id: String
  let seed: NeedSeed?
  @EnvironmentObject private var model: AppModel
  @Environment(\.hideWords) private var hideWords
  @State private var approval: WatchApproval?
  @State private var gone = false
  @State private var busy = false
  @State private var note: String?

  private var bot: String { approval?.bot ?? seed?.bot ?? "" }
  private var avatar: String { approval?.botAvatar ?? seed?.avatar ?? "" }
  private var title: String { approval?.title ?? seed?.text ?? "" }
  private var risk: WatchRisk? { approval?.risk ?? WatchRisk(raw: seed?.risk) }
  private var link: String { approval?.link ?? seed?.link ?? "/approvals/\(id)" }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          BotMarkView(name: bot, avatar: avatar, size: 26, muted: hideWords)
          Eyebrow(text: WatchL10n.needsOkFrom(bot), color: WatchTheme.needs(model.online))
        }
        .accessibilityElement(children: .combine)
        PrivateText(title, font: .watchTitle, lines: nil)
        if let details = approval?.details, !details.isEmpty, !hideWords {
          VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(details.prefix(4).enumerated()), id: \.offset) { _, line in
              Text(line).font(.watchCaption).foregroundStyle(WatchTheme.secondary).lineLimit(3)
            }
          }
        }
        if let risk { RiskChip(risk: risk) }
        if let note {
          Text(note).font(.watchCaption).foregroundStyle(WatchTheme.amber).fixedSize(horizontal: false, vertical: true)
        }
        actions
      }
      .padding(.horizontal, 2)
    }
    .navigationTitle(WatchL10n.needsYou)
    .disabled(busy)
    .task { await load() }
  }

  @ViewBuilder
  private var actions: some View {
    if gone || (approval.map { !$0.isPending } ?? false) {
      Text(WatchL10n.alreadyAnswered).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
    } else if let approval {
      switch approval.canAllow {
      case .tap:
        Button(WatchL10n.allow) { act { await model.allow(approval) } success: { .allowed } }
          .buttonStyle(PillStyle(tone: .allow))
      case .hold:
        HoldToAllowButton(confirmTitle: approval.title) {
          act { await model.allow(approval) } success: { .allowed }
        }
      case .phone:
        if let why = approval.whyPhoneText {
          Text(why).font(.watchCaption).foregroundStyle(WatchTheme.secondary).fixedSize(horizontal: false, vertical: true)
        }
        Button(WatchL10n.reviewOnIphone) {
          Task { await model.openOnPhone(link: link, title: title) }
        }
        .buttonStyle(PillStyle(tone: .main))
      }
      denyButton
    } else {
      // Not heard from the server yet: Deny works already, Allow waits for its word.
      Button(WatchL10n.allow) {}
        .buttonStyle(PillStyle(tone: .allow))
        .disabled(true)
        .opacity(0.5)
      denyButton
    }
  }

  private var denyButton: some View {
    Button(WatchL10n.deny) { act { await model.deny(id) } success: { .denied } }
      .buttonStyle(PillStyle(tone: .plain))
  }

  private func load() async {
    guard let api = WatchAPI.current() else { return }
    do {
      approval = try await api.approval(id)
    } catch WatchAPIError.notFound {
      gone = true
    } catch {
      // Offline: the seed stays on screen and Deny still tries.
    }
  }

  private func act(_ call: @escaping () async -> ActionResult, success: @escaping () -> Flash.Kind) {
    busy = true
    note = nil
    Task {
      let result = await call()
      busy = false
      switch result {
      case .done:
        model.showFlash(success(), pop: true)
      case .alreadyAnswered:
        model.showFlash(.alreadyAnswered, pop: true)
      case .noPasscode:
        Haptic.problem()
        note = WatchL10n.lockToAllow
      case .forbidden(let why):
        Haptic.problem()
        note = why ?? approval?.whyPhoneText ?? WatchL10n.reviewOnIphone
        await load()
      case .offline:
        Haptic.problem()
        note = WatchL10n.offline
      case .failed:
        Haptic.problem()
        note = WatchL10n.couldntReach
      }
    }
  }
}

// MARK: - A suggestion (mockup "Suggestion")

struct SuggestionView: View {
  let seed: NeedSeed
  @EnvironmentObject private var model: AppModel
  @Environment(\.hideWords) private var hideWords
  @State private var busy = false
  @State private var note: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          BotMarkView(name: seed.bot, avatar: seed.avatar, size: 26, muted: hideWords)
          Eyebrow(text: WatchL10n.suggests(seed.bot), color: WatchTheme.orchid)
        }
        .accessibilityElement(children: .combine)
        PrivateText(seed.text, font: .watchTitle, lines: nil)
        if let note {
          Text(note).font(.watchCaption).foregroundStyle(WatchTheme.amber)
        }
        Button(WatchL10n.doIt) { act(accept: true) }
          .buttonStyle(PillStyle(tone: .main))
        Button(WatchL10n.notNow) { act(accept: false) }
          .buttonStyle(PillStyle(tone: .plain))
      }
      .padding(.horizontal, 2)
    }
    .navigationTitle(WatchL10n.needsYou)
    .disabled(busy)
  }

  private func act(accept: Bool) {
    busy = true
    note = nil
    Task {
      let result = accept ? await model.doIt(seed.id) : await model.notNow(seed.id)
      busy = false
      switch result {
      case .done: model.showFlash(accept ? .started : .done, pop: true)
      case .alreadyAnswered: model.showFlash(.alreadyAnswered, pop: true)
      case .offline:
        Haptic.problem()
        note = WatchL10n.offline
      default:
        Haptic.problem()
        note = WatchL10n.couldntReach
      }
    }
  }
}

// MARK: - Something only the phone answers (mockup "Phone only")

struct PhoneOnlyView: View {
  let seed: NeedSeed
  @EnvironmentObject private var model: AppModel
  @Environment(\.hideWords) private var hideWords

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          BotMarkView(name: seed.bot, avatar: seed.avatar, size: 26, muted: hideWords)
          Eyebrow(text: seed.kind == "takeover" ? WatchL10n.takeOver : WatchL10n.needsYou, color: WatchTheme.needs(model.online))
        }
        .accessibilityElement(children: .combine)
        PrivateText(seed.text, font: .watchTitle, lines: nil)
        Text(WatchL10n.continuesOnIphone).font(.watchCaption).foregroundStyle(WatchTheme.secondary)
        Button {
          Task { await model.openOnPhone(link: seed.link, title: seed.text) }
        } label: {
          Label(WatchL10n.openOnIphone, systemImage: "iphone")
        }
        .buttonStyle(PillStyle(tone: .main))
      }
      .padding(.horizontal, 2)
    }
    .navigationTitle(WatchL10n.needsYou)
  }
}
