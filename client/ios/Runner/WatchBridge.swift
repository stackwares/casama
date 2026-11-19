import Flutter
import Foundation
import WatchConnectivity

// MARK: - The Apple Watch's link to this phone (D-410, docs/WATCH-PROTOCOL.md §2–3)
//
// The watch asks to be signed in (`sign_in` with its key's fingerprint); Flutter registers the
// key with the server and answers; this passes the answer back. It also carries "open this on
// the phone" from the watch, and workspace switches and sign-outs to it. No data comes this way:
// the watch talks to the server itself.
//
// Sign-in requests can arrive while Flutter isn't running (the system wakes the app for
// WatchConnectivity in the background), so they are held in UserDefaults until Dart answers or
// takes them (`takeRequests`). Dart ignores a request it has already seen.

final class WatchBridge: NSObject, WCSessionDelegate {
  static let shared = WatchBridge()

  private static let heldKey = "casama.watch.requests"
  private var channel: FlutterMethodChannel?
  private var queued: [[String: Any]] = []

  private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

  /// Called at launch, before Flutter: the session must be active to receive anything.
  func activate() {
    guard let session, session.delegate == nil else { return }
    session.delegate = self
    session.activate()
  }

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/watch", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel
  }

  // MARK: Dart → native

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "takeRequests":
      let held = Self.held()
      Self.saveHeld([])
      result(held)
    case "answer":
      guard let id = args["request_id"] as? String, !id.isEmpty else {
        return result(FlutterError(code: "bad_args", message: "request_id is needed", details: nil))
      }
      Self.saveHeld(Self.held().filter { ($0["request_id"] as? String) != id })
      var message: [String: Any] = ["request_id": id]
      if (args["ok"] as? Bool) == true {
        message["type"] = "signed_in"
        for key in ["server", "org_id", "org_name", "person_name"] {
          message[key] = (args[key] as? String) ?? ""
        }
      } else {
        message["type"] = "sign_in_failed"
        message["reason"] = (args["reason"] as? String) ?? "error"
      }
      send(message)
      result(nil)
    case "setContext":
      var message: [String: Any] = ["type": "context"]
      for key in ["server", "org_id", "org_name", "person_name"] {
        message[key] = (args[key] as? String) ?? ""
      }
      send(message)
      result(nil)
    case "signOut":
      Self.saveHeld([])
      send(["type": "sign_out"])
      result(nil)
    case "status":
      guard let session else {
        return result(["supported": false, "paired": false, "installed": false])
      }
      let active = session.activationState == .activated
      result([
        "supported": true,
        "paired": active && session.isPaired,
        "installed": active && session.isWatchAppInstalled,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: Native → watch

  /// Live when the watch app is reachable, else queued for the system to deliver.
  private func send(_ message: [String: Any]) {
    guard let session, session.activationState == .activated else {
      queued.append(message)
      return
    }
    guard session.isPaired, session.isWatchAppInstalled else { return }
    if session.isReachable {
      session.sendMessage(message, replyHandler: nil) { _ in
        session.transferUserInfo(message)
      }
    } else {
      session.transferUserInfo(message)
    }
  }

  // MARK: Watch → native

  private func receive(_ message: [String: Any]) {
    guard let type = message["type"] as? String else { return }
    switch type {
    case "sign_in":
      guard let id = message["request_id"] as? String, !id.isEmpty,
            let fingerprint = message["fingerprint"] as? String, !fingerprint.isEmpty else { return }
      var request: [String: Any] = [
        "request_id": id,
        "platform": (message["platform"] as? String) ?? "watchos",
        "fingerprint": fingerprint,
        "name": (message["name"] as? String) ?? "Apple Watch",
      ]
      for key in ["model", "app_version", "os_version"] {
        if let v = message[key] as? String, !v.isEmpty { request[key] = v }
      }
      var held = Self.held().filter { ($0["request_id"] as? String) != id }
      held.append(request)
      Self.saveHeld(Array(held.suffix(5)))
      channel?.invokeMethod("request", arguments: request)
    case "open":
      guard let link = message["link"] as? String, link.hasPrefix("/"), !link.hasPrefix("//") else { return }
      if let channel {
        channel.invokeMethod("open", arguments: ["link": link])
      } else {
        // Flutter isn't up yet: the same queue Siri and the widgets use (ShortcutBridge).
        ShortcutBridge.shared.open(link)
      }
    default:
      break
    }
  }

  private static func held() -> [[String: Any]] {
    (UserDefaults.standard.array(forKey: heldKey) as? [[String: Any]]) ?? []
  }

  private static func saveHeld(_ list: [[String: Any]]) {
    UserDefaults.standard.set(list, forKey: heldKey)
  }

  // MARK: WCSessionDelegate

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    guard activationState == .activated else { return }
    DispatchQueue.main.async {
      let waiting = self.queued
      self.queued = []
      waiting.forEach(self.send)
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  /// The person switched to another watch: activate again for the new one.
  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    DispatchQueue.main.async { self.receive(message) }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    replyHandler([:])
    DispatchQueue.main.async { self.receive(message) }
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    DispatchQueue.main.async { self.receive(userInfo) }
  }
}
