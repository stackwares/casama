import SwiftUI
import UserNotifications
import WatchKit

// MARK: - Notifications on the wrist (D-410 §6.2, docs/WATCH-PROTOCOL.md §4)
//
// The iPhone's pushes are mirrored here when the phone is locked; the watch's own pushes (Phase 5)
// carry the same data. The watch registers the same categories with its own buttons and gives
// each its own layout. Buttons that answer open the watch app (`.foreground`), so the answer is
// made here with this watch's key, not on the phone the push was sent to. Allow is always first,
// so Double Tap answers a low-risk request; a medium one opens with Hold to allow, a high one
// offers only Deny and Review on iPhone.

enum WatchNotifications {
  static let approval = "APPROVAL"
  static let suggestion = "SUGGESTION"
  static let reply = "REPLY"

  enum Action {
    static let allow = "ALLOW"
    static let deny = "DENY"
    static let doIt = "DO_IT"
    static let notNow = "NOT_NOW"
    static let reply = "REPLY"
  }

  static func registerCategories() {
    let allow = UNNotificationAction(identifier: Action.allow, title: WatchL10n.allow, options: [.foreground])
    let deny = UNNotificationAction(identifier: Action.deny, title: WatchL10n.deny, options: [.foreground, .destructive])
    let doIt = UNNotificationAction(identifier: Action.doIt, title: WatchL10n.doIt, options: [.foreground])
    // Not now only clears the notification, as on the phone: nothing to run, so nothing to open.
    let notNow = UNNotificationAction(identifier: Action.notNow, title: WatchL10n.notNow, options: [])
    let replyAction = UNTextInputNotificationAction(
      identifier: Action.reply, title: WatchL10n.reply, options: [.foreground],
      textInputButtonTitle: WatchL10n.send, textInputPlaceholder: WatchL10n.reply)
    UNUserNotificationCenter.current().setNotificationCategories([
      UNNotificationCategory(identifier: approval, actions: [allow, deny], intentIdentifiers: [], options: []),
      UNNotificationCategory(identifier: suggestion, actions: [doIt, notNow], intentIdentifiers: [], options: []),
      UNNotificationCategory(identifier: Self.reply, actions: [replyAction], intentIdentifiers: [], options: []),
    ])
  }
}

/// The data keys a push carries (WATCH-PROTOCOL §4), read defensively: every value is optional.
struct PushInfo {
  let kind: String
  let link: String
  let botId: String?
  let botName: String
  let botAvatar: String
  let approvalId: String?
  let risk: String?
  let suggestionId: String?
  let conversationId: String?
  let messageId: String?
  let runId: String?
  /// The workspace the push is about (newer servers send it).
  let orgId: String?
  /// What this watch may do with the request, when the server said: tap, hold or phone.
  let canAllow: String?
  let title: String
  let body: String

  init(_ content: UNNotificationContent) {
    let info = content.userInfo
    func s(_ key: String) -> String? {
      guard let v = info[key] as? String, !v.isEmpty else { return nil }
      return v
    }
    let category = content.categoryIdentifier
    // `watch_kind` holds the watch's kinds (WATCH-PROTOCOL §4); `kind` keeps the phone's own
    // values (`approval_request`, `routine_result`…), so it is only a fallback via the category.
    kind = s("watch_kind") ?? (category == WatchNotifications.approval ? "approval" : category == WatchNotifications.suggestion ? "suggestion" : category == WatchNotifications.reply ? "reply" : "other")
    link = s("link") ?? ""
    botId = s("bot_id")
    botName = s("bot_name") ?? ""
    botAvatar = s("bot_avatar") ?? ""
    approvalId = s("approval_id")
    risk = s("risk")
    suggestionId = s("suggestion_id")
    conversationId = s("conversation_id")
    messageId = s("message_id")
    runId = s("run_id")
    orgId = s("org_id")
    canAllow = s("can_allow")
    title = content.title
    body = content.body
  }

  /// No words: private notifications, or Hide reply text (§6.2). The watch loads what it may.
  var isPrivate: Bool { title.isEmpty && body.isEmpty }

  /// About another workspace than the one this watch is signed in to (a notification the iPhone
  /// mirrored): this watch's key can't answer it, the phone can.
  var isElsewhere: Bool { PushScope.isElsewhere(pushOrg: orgId, watchOrg: WatchAccount.orgId) }

  /// Whether the watch's own layouts must leave the words out: Show details is off for this
  /// person's watches, or the workspace's glance is private. The mirrored iPhone copy still
  /// carries them, so the layout decides.
  static var wordsHidden: Bool {
    if GlanceCache.me()?.prefs?.showDetails == false { return true }
    return GlanceCache.glance()?.glance.flags.isPrivate ?? false
  }

  /// The phone's route for it, for Open on iPhone.
  var phoneLink: String {
    if !link.isEmpty { return link }
    if let approvalId { return PhoneRoutes.approval(approvalId) }
    if let botId { return PhoneRoutes.chat(bot: botId, conversation: conversationId) }
    return PhoneRoutes.home
  }

  /// What a screen about it starts from when it can only be opened on the phone. [known]: the
  /// push itself says it is from another workspace; otherwise the server only said "not found
  /// in this watch's workspace", and the screen says so without guessing more.
  func elsewhereSeed(known: Bool) -> NeedSeed {
    // The words follow the same switches as everywhere else: Show details, and Hide reply text.
    let hide = PushInfo.wordsHidden || (kind == "reply" && (GlanceCache.me()?.hideReplyText ?? false))
    return NeedSeed(
      id: approvalId ?? suggestionId ?? messageId ?? "", kind: known ? NeedSeed.elsewhere : NeedSeed.notHere, botId: botId ?? "", bot: botName,
      avatar: botAvatar, text: hide ? "" : (body.isEmpty ? title : body), risk: risk, link: phoneLink)
  }

  /// Where a plain tap goes.
  var destination: WatchLink {
    switch kind {
    case "approval": return approvalId.map { .approval($0) } ?? WatchLink.parse(route: link)
    case "suggestion": return suggestionId.map { .suggestion($0) } ?? .needs
    case "reply", "failed", "routine":
      if let bot = botId { return .chat(bot: bot, conversation: conversationId) }
      return WatchLink.parse(route: link)
    case "brief": return .brief
    default: return WatchLink.parse(route: link)
    }
  }
}

// MARK: - Answering from a notification

@MainActor
enum NotificationRouter {
  static func handle(_ response: UNNotificationResponse) async {
    let model = AppModel.shared
    // A button can be the thing that launches the app: the model must know it is signed in before
    // the first screen has appeared (start() does nothing the second time).
    model.start()
    // Started before the watch was first unlocked, the key couldn't be read then; it can now.
    model.adoptKeyIfReadable()
    guard model.phase == .signedIn else { return }
    let info = PushInfo(response.notification.request.content)
    let action = response.actionIdentifier
    if action == WatchNotifications.Action.notNow || action == "later" { return }
    // From the person's other workspace: this watch's key would only get "not found" for it.
    if info.isElsewhere {
      if action != UNNotificationDismissActionIdentifier { model.showElsewhere(info.elsewhereSeed(known: true)) }
      return
    }
    switch action {
    case WatchNotifications.Action.allow, "approve":
      guard let id = info.approvalId else { return model.open(info.destination) }
      await allow(id, info: info, model: model)
    case WatchNotifications.Action.deny, "deny":
      guard let id = info.approvalId else { return model.open(info.destination) }
      settle(await model.deny(id, surface: WatchSurface.notification), success: .denied, id: id, info: info, model: model) {
        model.open(.approval(id))
      }
    case WatchNotifications.Action.doIt, "accept":
      guard let id = info.suggestionId else { return model.open(info.destination) }
      settle(await model.doIt(id, surface: WatchSurface.notification), success: .done, id: id, info: info, model: model) {
        model.open(.suggestion(id))
      }
    case WatchNotifications.Action.reply:
      guard let text = (response as? UNTextInputNotificationResponse)?.userText.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty, let bot = info.botId else { return model.open(info.destination) }
      await sendReply(text, bot: bot, conversation: info.conversationId, info: info, model: model)
    case UNNotificationDefaultActionIdentifier:
      model.open(info.destination)
    default:
      break
    }
  }

  /// Allow from a notification: done here only when the server says a tap is enough; a hold or
  /// the phone opens the request instead (§6.2).
  private static func allow(_ id: String, info: PushInfo, model: AppModel) async {
    guard let api = WatchAPI.current() else { return }
    do {
      let approval = try await api.approval(id)
      guard approval.isPending else { return model.showFlash(.alreadyAnswered, pop: false) }
      guard approval.canAllow == .tap else { return model.open(.approval(id)) }
      settle(await model.allow(approval, surface: WatchSurface.notification), success: .allowed, id: id, info: info, model: model) {
        model.open(.approval(id))
      }
    } catch WatchAPIError.notFound {
      // The server has no such request for this watch: it is in the person's other workspace (a
      // push without `org_id` can't say so), or it isn't theirs to see. Never "Already answered":
      // a request that was answered still comes back, with how it went.
      model.showElsewhere(info.elsewhereSeed(known: false))
    } catch WatchAPIError.signedOut {
      model.keyGone()
    } catch {
      model.open(.approval(id))
    }
  }

  static func sendReply(_ text: String, bot: String, conversation: String?, info: PushInfo, model: AppModel) async {
    guard let api = WatchAPI.current() else { return }
    let key = UUID().uuidString
    let body = WatchAskBody(botId: bot, conversationId: conversation, text: text, surface: WatchSurface.notification)
    do {
      _ = try await api.ask(body, idempotencyKey: key)
      model.online = true
      model.showFlash(.replied, pop: false)
    } catch WatchAPIError.offline {
      // Kept with the same key, and sent when the watch is back online.
      model.online = false
      model.keep(QueuedAsk(id: key, botId: bot, botName: info.botName, conversationId: conversation, text: text, askedAt: Date(), idempotencyKey: key))
      model.say(WatchL10n.keptOffline)
    } catch WatchAPIError.signedOut {
      model.keyGone()
    } catch WatchAPIError.notFound {
      // The bot or the chat isn't in this watch's workspace (or is gone).
      model.showElsewhere(info.elsewhereSeed(known: false))
    } catch {
      // Not sent, and not kept: open the chat so it can be said again, and say so.
      model.open(.chat(bot: bot, conversation: conversation))
      model.say(WatchL10n.replyNotSent)
    }
  }

  /// Shows how an answer from a notification went. Anything but a clear yes or "already answered"
  /// opens the request ([fallback]) with what went wrong, so a failed Deny is never silent.
  private static func settle(_ result: ActionResult, success: Flash.Kind, id: String, info: PushInfo, model: AppModel, fallback: () -> Void) {
    switch result {
    case .done: model.showFlash(success, pop: false)
    case .alreadyAnswered: model.showFlash(.alreadyAnswered, pop: false)
    case .elsewhere: model.showElsewhere(info.elsewhereSeed(known: false))
    default:
      // A key the server no longer knows already put the watch on the signed-out screen.
      guard model.phase == .signedIn else { return }
      model.leaveNote(result.note, for: id)
      fallback()
    }
  }
}

// MARK: - The layouts

/// What a notification layout draws; filled in after the fact for private pushes.
final class NotificationState: ObservableObject {
  @Published var info: PushInfo?
  @Published var title = ""
  @Published var detail = ""
  @Published var risk: WatchRisk?
  @Published var quickReplies: [String] = []
  @Published var sent = false
  /// About another workspace: the watch can't answer it, so the layout says so and has no buttons.
  @Published var elsewhere = false
}

/// "In another workspace. Answer it on your phone", under a mirrored notification this watch's key
/// can't answer.
private struct ElsewhereLine: View {
  var body: some View {
    Text(WatchL10n.otherWorkspace)
      .font(.watchCaption)
      .foregroundStyle(WatchTheme.secondary)
      .fixedSize(horizontal: false, vertical: true)
  }
}

private struct NotificationHeader: View {
  let info: PushInfo?
  var body: some View {
    HStack(spacing: 6) {
      BotMarkView(name: info?.botName ?? "", avatar: info?.botAvatar, size: 22)
      Text(info?.botName ?? "")
        .font(.watchTitle)
        .foregroundStyle(WatchTheme.orchid)
        .lineLimit(1)
    }
    .accessibilityElement(children: .combine)
  }
}

struct ApprovalNotificationView: View {
  @ObservedObject var state: NotificationState
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      NotificationHeader(info: state.info)
      Text(WatchL10n.needsOk.uppercased())
        .font(.watchEyebrow)
        .foregroundStyle(WatchTheme.amber)
      if !state.title.isEmpty {
        Text(state.title).font(.watchTitle).fixedSize(horizontal: false, vertical: true)
      }
      if !state.detail.isEmpty {
        Text(state.detail).font(.watchCaption).foregroundStyle(WatchTheme.secondary).lineLimit(3)
      }
      if let risk = state.risk { RiskChip(risk: risk) }
      if state.elsewhere { ElsewhereLine() }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

final class ApprovalNotificationController: WKUserNotificationHostingController<ApprovalNotificationView> {
  private let state = NotificationState()
  override var body: ApprovalNotificationView { ApprovalNotificationView(state: state) }
  override class var sashColor: Color? { WatchTheme.amber.opacity(0.35) }

  override func didReceive(_ notification: UNNotification) {
    let info = PushInfo(notification.request.content)
    let hidden = PushInfo.wordsHidden
    state.info = info
    state.title = hidden ? "" : info.title
    state.detail = hidden ? "" : info.body
    state.risk = WatchRisk(raw: info.risk)
    // From the person's other workspace: nothing here can answer it. A tap opens Open on iPhone.
    if info.isElsewhere {
      state.elsewhere = true
      notificationActions = []
      return
    }
    // High risk is never allowed from the wrist: only Deny here, a tap opens Review on iPhone.
    // The same when the server already said this one is for the phone.
    if state.risk == .high || info.canAllow == "phone" {
      notificationActions = notificationActions.filter { $0.identifier != WatchNotifications.Action.allow }
    }
    guard let id = info.approvalId, let api = WatchAPI.current() else { return }
    Task { @MainActor in
      guard let approval = try? await api.approval(id) else { return }
      if !hidden, info.isPrivate || state.title.isEmpty {
        state.title = approval.title
        state.detail = approval.details.first ?? ""
      }
      state.risk = approval.risk
      if approval.canAllow == .phone || !approval.isPending {
        notificationActions = notificationActions.filter { $0.identifier != WatchNotifications.Action.allow }
      }
    }
  }
}

struct SuggestionNotificationView: View {
  @ObservedObject var state: NotificationState
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(WatchL10n.suggests(state.info?.botName ?? "").uppercased())
        .font(.watchEyebrow)
        .foregroundStyle(WatchTheme.orchid)
      if !state.title.isEmpty { Text(state.title).font(.watchTitle).fixedSize(horizontal: false, vertical: true) }
      if !state.detail.isEmpty { Text(state.detail).font(.watchCaption).foregroundStyle(WatchTheme.secondary).lineLimit(2) }
      if state.elsewhere { ElsewhereLine() }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

final class SuggestionNotificationController: WKUserNotificationHostingController<SuggestionNotificationView> {
  private let state = NotificationState()
  override var body: SuggestionNotificationView { SuggestionNotificationView(state: state) }

  override func didReceive(_ notification: UNNotification) {
    let info = PushInfo(notification.request.content)
    let hidden = PushInfo.wordsHidden
    state.info = info
    state.title = hidden ? "" : info.title
    state.detail = hidden ? "" : info.body
    if info.isElsewhere {
      state.elsewhere = true
      notificationActions = []
      return
    }
    guard !hidden, info.isPrivate, let id = info.suggestionId else { return }
    if let need = GlanceCache.glance()?.glance.needs.first(where: { $0.id == id }) { state.title = need.text }
  }
}

/// A reply: the bot, the start of it, and the person's quick replies right in the layout.
struct ReplyNotificationView: View {
  @ObservedObject var state: NotificationState
  let send: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      NotificationHeader(info: state.info)
      Text(state.detail.isEmpty ? WatchL10n.replyReady : state.detail)
        .font(.watchBody)
        .lineLimit(4)
        .fixedSize(horizontal: false, vertical: true)
      if state.elsewhere {
        ElsewhereLine()
      } else if state.sent {
        Image(systemName: "checkmark")
          .font(.title3.weight(.bold))
          .foregroundStyle(WatchTheme.green)
          .frame(maxWidth: .infinity)
          .accessibilityLabel(WatchL10n.done)
      } else if state.info?.botId != nil {
        ForEach(state.quickReplies, id: \.self) { reply in
          Button(reply) { send(reply) }
            .buttonStyle(.bordered)
            .tint(.white)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

final class ReplyNotificationController: WKUserNotificationHostingController<ReplyNotificationView> {
  private let state = NotificationState()
  override class var isInteractive: Bool { true }

  override var body: ReplyNotificationView {
    ReplyNotificationView(state: state) { [weak self] text in self?.sendQuick(text) }
  }

  override func didReceive(_ notification: UNNotification) {
    let info = PushInfo(notification.request.content)
    state.info = info
    let me = GlanceCache.me()
    // Hide reply text (D-325) hides the words on the watch as on the phone; so does Show details off.
    state.detail = (me?.hideReplyText ?? false) || PushInfo.wordsHidden ? "" : info.body
    // A reply from the person's other workspace can't be answered with this watch's key.
    if info.isElsewhere {
      state.elsewhere = true
      notificationActions = []
      return
    }
    state.quickReplies = Array((me?.quickReplies ?? [WatchL10n.quickYes, WatchL10n.quickNo, WatchL10n.quickTellMore, WatchL10n.quickNotNow]).prefix(4))
  }

  private func sendQuick(_ text: String) {
    guard let info = state.info, let bot = info.botId, let api = WatchAPI.current() else { return }
    let key = UUID().uuidString
    Task { @MainActor in
      let body = WatchAskBody(botId: bot, conversationId: info.conversationId, text: text, surface: WatchSurface.notification)
      do {
        _ = try await api.ask(body, idempotencyKey: key)
        state.sent = true
        WKInterfaceDevice.current().play(.success)
        try? await Task.sleep(nanoseconds: 900_000_000)
        performDismissAction()
      } catch {
        WKInterfaceDevice.current().play(.failure)
      }
    }
  }
}
