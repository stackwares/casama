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
    title = content.title
    body = content.body
  }

  /// No words: private notifications, or Hide reply text (§6.2). The watch loads what it may.
  var isPrivate: Bool { title.isEmpty && body.isEmpty }

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
    guard model.phase == .signedIn else { return }
    let info = PushInfo(response.notification.request.content)
    switch response.actionIdentifier {
    case WatchNotifications.Action.allow, "approve":
      guard let id = info.approvalId else { return model.open(info.destination) }
      await allow(id, model: model)
    case WatchNotifications.Action.deny, "deny":
      guard let id = info.approvalId else { return model.open(info.destination) }
      flash(await model.deny(id), success: .denied, model: model)
    case WatchNotifications.Action.doIt, "accept":
      guard let id = info.suggestionId else { return model.open(info.destination) }
      flash(await model.doIt(id), success: .done, model: model)
    case WatchNotifications.Action.notNow, "later":
      break
    case WatchNotifications.Action.reply:
      guard let text = (response as? UNTextInputNotificationResponse)?.userText.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty, let bot = info.botId else { return model.open(info.destination) }
      await sendReply(text, bot: bot, conversation: info.conversationId, model: model)
    case UNNotificationDefaultActionIdentifier:
      model.open(info.destination)
    default:
      break
    }
  }

  /// Allow from a notification: done here only when the server says a tap is enough; a hold or
  /// the phone opens the request instead (§6.2).
  private static func allow(_ id: String, model: AppModel) async {
    guard let api = WatchAPI.current() else { return }
    do {
      let approval = try await api.approval(id)
      guard approval.isPending else { return model.showFlash(.alreadyAnswered, pop: false) }
      guard approval.canAllow == .tap else { return model.open(.approval(id)) }
      let result = await model.allow(approval)
      if result == .noPasscode || result == .failed { return model.open(.approval(id)) }
      flash(result, success: .allowed, model: model)
    } catch WatchAPIError.notFound {
      model.showFlash(.alreadyAnswered, pop: false)
    } catch {
      model.open(.approval(id))
    }
  }

  static func sendReply(_ text: String, bot: String, conversation: String?, model: AppModel) async {
    guard let api = WatchAPI.current() else { return }
    let key = UUID().uuidString
    let body = WatchAskBody(botId: bot, conversationId: conversation, text: text, surface: "notification")
    do {
      _ = try await api.ask(body, idempotencyKey: key)
      model.showFlash(.sent, pop: false)
    } catch WatchAPIError.offline {
      model.keep(QueuedAsk(id: UUID().uuidString, botId: bot, botName: "", conversationId: conversation, text: text, askedAt: Date(), idempotencyKey: key))
    } catch {}
  }

  private static func flash(_ result: ActionResult, success: Flash.Kind, model: AppModel) {
    switch result {
    case .done: model.showFlash(success, pop: false)
    case .alreadyAnswered: model.showFlash(.alreadyAnswered, pop: false)
    default: break
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
    state.info = info
    state.title = info.title
    state.detail = info.body
    state.risk = WatchRisk(raw: info.risk)
    // High risk is never allowed from the wrist: only Deny here, a tap opens Review on iPhone.
    if state.risk == .high {
      notificationActions = notificationActions.filter { $0.identifier != WatchNotifications.Action.allow }
    }
    guard let id = info.approvalId, let api = WatchAPI.current() else { return }
    Task { @MainActor in
      guard let approval = try? await api.approval(id) else { return }
      if info.isPrivate || state.title.isEmpty {
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
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

final class SuggestionNotificationController: WKUserNotificationHostingController<SuggestionNotificationView> {
  private let state = NotificationState()
  override var body: SuggestionNotificationView { SuggestionNotificationView(state: state) }

  override func didReceive(_ notification: UNNotification) {
    let info = PushInfo(notification.request.content)
    state.info = info
    state.title = info.title
    state.detail = info.body
    guard info.isPrivate, let id = info.suggestionId else { return }
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
      if state.sent {
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
    // Hide reply text (D-325) hides the words on the watch as on the phone.
    state.detail = (me?.hideReplyText ?? false) ? "" : info.body
    state.quickReplies = Array((me?.quickReplies ?? [WatchL10n.quickYes, WatchL10n.quickNo, WatchL10n.quickTellMore, WatchL10n.quickNotNow]).prefix(4))
  }

  private func sendQuick(_ text: String) {
    guard let info = state.info, let bot = info.botId, let api = WatchAPI.current() else { return }
    let key = UUID().uuidString
    Task { @MainActor in
      let body = WatchAskBody(botId: bot, conversationId: info.conversationId, text: text, surface: "notification")
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
