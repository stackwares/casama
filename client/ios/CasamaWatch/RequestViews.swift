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
  /// Not on this watch (another workspace, or not this person's to see): only the phone answers it.
  @State private var elsewhere = false
  @State private var busy = false
  @State private var note: String?

  private var bot: String { approval?.bot ?? seed?.bot ?? "" }
  private var avatar: String { approval?.botAvatar ?? seed?.avatar ?? "" }
  private var title: String { approval?.title ?? seed?.text ?? "" }
  private var risk: WatchRisk? { approval?.risk ?? WatchRisk(raw: seed?.risk) }
  private var link: String { PhoneRoutes.first(approval?.link, seed?.link, else: PhoneRoutes.approval(id)) }

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
    // What went wrong when it was answered from its notification: read when this screen opens for
    // it, and when it was open already.
    .onChange(of: model.pendingNotes[id], initial: true) { _, left in
      if left != nil, let text = model.takeNote(for: id) { note = text }
    }
  }

  @ViewBuilder
  private var actions: some View {
    if elsewhere {
      Text(WatchL10n.notOnWatch).font(.watchCaption).foregroundStyle(WatchTheme.secondary).fixedSize(horizontal: false, vertical: true)
      Button {
        Task { await model.openOnPhone(link: link, title: title) }
      } label: {
        Label(WatchL10n.openOnIphone, systemImage: "iphone")
      }
      .buttonStyle(PillStyle(tone: .main))
    } else if approval.map({ !$0.isPending }) ?? false {
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
      // The server has no such request for this watch. It may be waiting in the person's other
      // workspace (a push without `org_id` can't say so), so never "Already answered": a request
      // that was answered still comes back, with how it went.
      elsewhere = true
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
      case .elsewhere:
        Haptic.problem()
        elsewhere = true
      case .offline, .outOfCredits, .refused, .failed:
        Haptic.problem()
        note = result.note
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
  /// It couldn't start from here (out of credits, another workspace): offer the phone.
  @State private var offerPhone = false

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
          Text(note).font(.watchCaption).foregroundStyle(WatchTheme.amber).fixedSize(horizontal: false, vertical: true)
        }
        if offerPhone {
          Button {
            Task { await model.openOnPhone(link: PhoneRoutes.first(seed.link, else: PhoneRoutes.needsYou), title: seed.text) }
          } label: {
            Label(WatchL10n.openOnIphone, systemImage: "iphone")
          }
          .buttonStyle(PillStyle(tone: .main))
        } else {
          Button(WatchL10n.doIt) { act(accept: true) }
            .buttonStyle(PillStyle(tone: .main))
        }
        Button(WatchL10n.notNow) { act(accept: false) }
          .buttonStyle(PillStyle(tone: .plain))
      }
      .padding(.horizontal, 2)
    }
    .navigationTitle(WatchL10n.needsYou)
    .disabled(busy)
    // What went wrong when it was answered from its notification: read when this screen opens for
    // it, and when it was open already.
    .onChange(of: model.pendingNotes[seed.id], initial: true) { _, left in
      if left != nil, let text = model.takeNote(for: seed.id) { note = text }
    }
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
      case .elsewhere:
        Haptic.problem()
        note = WatchL10n.notOnWatch
        offerPhone = true
      case .outOfCredits:
        // Nothing started and the suggestion is kept: the phone is where credits are topped up.
        Haptic.problem()
        note = WatchL10n.outOfCredits
        offerPhone = true
      default:
        Haptic.problem()
        note = result.note ?? WatchL10n.couldntReach
      }
    }
  }
}

// MARK: - Something only the phone answers (mockup "Phone only")

struct PhoneOnlyView: View {
  let seed: NeedSeed
  @EnvironmentObject private var model: AppModel
  @Environment(\.hideWords) private var hideWords

  /// From a notification this watch's key can't answer (another workspace): it may be a reply as
  /// well as a request, so the screen names the bot and doesn't say "Needs you".
  private var notMine: Bool { seed.kind == NeedSeed.elsewhere || seed.kind == NeedSeed.notHere }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          BotMarkView(name: seed.bot, avatar: seed.avatar, size: 26, muted: hideWords)
          if notMine {
            Eyebrow(text: seed.bot.isEmpty ? WatchL10n.compCasama : seed.bot, color: WatchTheme.secondary)
          } else {
            Eyebrow(text: seed.kind == "takeover" ? WatchL10n.takeOver : WatchL10n.needsYou, color: WatchTheme.needs(model.online))
          }
        }
        .accessibilityElement(children: .combine)
        if !seed.text.isEmpty { PrivateText(seed.text, font: .watchTitle, lines: nil) }
        Text(seed.kind == NeedSeed.elsewhere ? WatchL10n.otherWorkspace : seed.kind == NeedSeed.notHere ? WatchL10n.notOnWatch : WatchL10n.continuesOnIphone)
          .font(.watchCaption)
          .foregroundStyle(WatchTheme.secondary)
          .fixedSize(horizontal: false, vertical: true)
        Button {
          Task { await model.openOnPhone(link: PhoneRoutes.first(seed.link, else: PhoneRoutes.needsYou), title: seed.text.isEmpty ? seed.bot : seed.text) }
        } label: {
          Label(WatchL10n.openOnIphone, systemImage: "iphone")
        }
        .buttonStyle(PillStyle(tone: .main))
      }
      .padding(.horizontal, 2)
    }
    .navigationTitle(notMine ? WatchL10n.compCasama : WatchL10n.needsYou)
  }
}
