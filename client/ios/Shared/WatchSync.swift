import Foundation
import LocalAuthentication
import WidgetKit

// MARK: - Keeping the saved glance fresh, and signing out (D-410)
//
// Used by the app (on open, on a push, in background refresh) and by the complications (on their
// own timeline refresh and after a button), so both write the same cache the same way.

enum WatchSync {
  /// Widget kinds, so the app can reload exactly what changed.
  enum Kind {
    static let inline = "WatchInline"
    static let needsCircular = "WatchNeedsCircular"
    static let needsCorner = "WatchNeedsCorner"
    static let needsRect = "WatchNeedsRect"
    static let ask = "WatchAsk"
    static let credits = "WatchCredits"
    static let bot = "WatchBot"
    static let upNext = "WatchUpNext"
    static let working = "WatchWorking"
    static let brief = "WatchBrief"
    static let relevant = [needsRect, working, upNext, brief]
  }

  enum Outcome: Equatable {
    case fresh
    case unchanged
    case offline
    case signedOut
    case failed
  }

  /// Asks the server for the glance (or "not changed") and saves it. Never throws. [quick] gives
  /// up after a few seconds, for a background refresh.
  @discardableResult
  static func refreshGlance(api: WatchAPI? = WatchAPI.current(), quick: Bool = false) async -> Outcome {
    guard let api else { return .signedOut }
    let saved = GlanceCache.glance()
    do {
      switch try await api.glance(etag: saved?.etag, quick: quick) {
      case .notModified:
        GlanceCache.touchGlance()
        return .unchanged
      case .fresh(let g, let data, let etag):
        if !g.orgId.isEmpty, g.orgId != WatchAccount.orgId {
          // The key answers for its own workspace, and it isn't the one saved here: the phone
          // moved this watch while it was away. Take the server's word and drop the old one's
          // glance and chats (the app picks up the new name from /v1/watch/me).
          GlanceCache.wipe(keepMe: true)
          WatchAccount.orgId = g.orgId
        } else if let s = saved?.glance.madeAt, let m = g.madeAt, s > m {
          // Keep the newest: another process may have saved a newer one while this was in flight.
          GlanceCache.touchGlance()
          return .unchanged
        }
        GlanceCache.saveGlance(data, etag: etag)
        return .fresh
      }
    } catch WatchAPIError.signedOut {
      signedOut()
      return .signedOut
    } catch WatchAPIError.offline {
      return .offline
    } catch {
      return .failed
    }
  }

  /// Redraws every complication and Smart Stack card, and lets the Smart Stack re-rank them.
  static func reloadWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
    for kind in Kind.relevant { WidgetCenter.shared.invalidateRelevance(ofKind: kind) }
  }

  /// The key is gone (a 401 from anywhere): wipe the key, the cache, kept asks and every
  /// complication, and say "signed out" (docs/WATCH-PROTOCOL.md §1).
  static func signedOut() {
    wipe(removed: true)
  }

  static func wipe(removed: Bool) {
    WatchKeyStore.delete()
    GlanceCache.wipe()
    AskQueueStore.wipe()
    WatchAccount.wipe(removed: removed)
    reloadWidgets()
  }
}

// MARK: - The wrist check before allowing (§8.7, §10)

enum WristCheck {
  enum Result: Equatable {
    case ok
    /// The watch has no passcode: it can read and deny, never allow.
    case noPasscode
    case failed
  }

  /// Whether the watch is on the wrist and unlocked. With wrist detection this needs no prompt
  /// while it is worn; off the wrist the system asks for the passcode.
  static func check(reason: String = WatchL10n.allow) async -> Result {
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithWristDetection, error: &error) else {
      if let code = error?.code, code == LAError.passcodeNotSet.rawValue { return .noPasscode }
      return error == nil ? .failed : .noPasscode
    }
    do {
      return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithWristDetection, localizedReason: reason) ? .ok : .failed
    } catch {
      return .failed
    }
  }
}
