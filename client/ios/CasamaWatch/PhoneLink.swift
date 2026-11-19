import Foundation
import WatchConnectivity

// MARK: - The phone link (docs/WATCH-PROTOCOL.md §2)
//
// Carries three things only: the watch asking to be signed in, the phone's answer, and "open this
// on the phone". Data never comes this way: the watch talks to the server itself (§8.1). Messages
// go live when the iPhone is reachable, else queued with transferUserInfo, which the system
// delivers when it can (the phone's WatchBridge holds requests until Flutter runs).

final class PhoneLink: NSObject, WCSessionDelegate {
  static let shared = PhoneLink()

  /// Every message from the phone, on the main queue.
  var onMessage: (([String: Any]) -> Void)?

  private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

  func activate() {
    guard let session, session.delegate == nil else { return }
    session.delegate = self
    session.activate()
  }

  /// Whether a message would reach the iPhone app right now.
  var reachable: Bool {
    guard let session, session.activationState == .activated else { return false }
    return session.isReachable
  }

  /// Whether there is a companion iPhone app to ask at all.
  var hasCompanion: Bool {
    guard let session, session.activationState == .activated else { return false }
    return session.isCompanionAppInstalled
  }

  /// Sends [message] now when the phone is reachable, else queues it for delivery.
  func send(_ message: [String: Any]) {
    guard let session, session.activationState == .activated else {
      pending.append(message)
      return
    }
    if session.isReachable {
      session.sendMessage(message, replyHandler: nil) { [weak self] _ in
        // Reachability can drop between the check and the send: queue it instead.
        self?.session?.transferUserInfo(message)
      }
    } else {
      session.transferUserInfo(message)
    }
  }

  /// Messages asked for before activation finished.
  private var pending: [[String: Any]] = []

  // MARK: WCSessionDelegate

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    guard activationState == .activated else { return }
    DispatchQueue.main.async {
      let queued = self.pending
      self.pending = []
      queued.forEach(self.send)
      // The phone may have left its last answer as the application context while the watch app
      // wasn't running.
      let context = session.receivedApplicationContext
      if !context.isEmpty { self.deliver(context) }
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    deliver(message)
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    replyHandler([:])
    deliver(message)
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    deliver(userInfo)
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    deliver(applicationContext)
  }

  private func deliver(_ message: [String: Any]) {
    guard message["type"] is String else { return }
    DispatchQueue.main.async { self.onMessage?(message) }
  }
}
