import Flutter
import Foundation
import UIKit
import WatchConnectivity

// MARK: - The Apple Watch's link to this phone (D-410, docs/WATCH-PROTOCOL.md §2–3)
//
// The watch asks to be signed in (`sign_in` with its key's fingerprint); Flutter registers the
// key with the server and answers; this passes the answer back. It also carries "open this on
// the phone" from the watch, and workspace switches and sign-outs to it. No data comes this way:
// the watch talks to the server itself.
//
// Sign-in requests can arrive while Flutter isn't running (the system wakes the app for
// WatchConnectivity in the background), so they are held in UserDefaults until Dart answers them.
// One request is held per watch key (its fingerprint): a watch that asks again replaces its
// earlier request, so one watch is one question. Each is stamped with when it came (`at`, epoch
// milliseconds) and dropped after fifteen minutes; a watch still waiting asks again. `takeRequests`
// reads the list without clearing it (Dart ignores a request it has already seen), so a request
// isn't lost when the app is closed before the person answers; `answer` is what removes it.

final class WatchBridge: NSObject, WCSessionDelegate {
  static let shared = WatchBridge()

  private static let heldKey = "casama.watch.requests"
  /// A held request older than this is dropped: the watch asks again while it still wants in.
  private static let heldFor: TimeInterval = 15 * 60
  private static let maxHeld = 5
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
      // A read: the requests stay held until each is answered.
      result(Self.held())
    case "answer":
      guard let id = args["request_id"] as? String, !id.isEmpty else {
        return result(FlutterError(code: "bad_args", message: "request_id is needed", details: nil))
      }
      // Answered: it goes, and so does any other request from the same watch key. Dart says which
      // key it answered for (`fingerprint`): the held request may by now be a newer one from the
      // same watch, with another id. Without it (an older Dart side), the held request's own.
      let held = Self.held()
      let named = (args["fingerprint"] as? String).flatMap { $0.isEmpty ? nil : $0 }
      let fingerprint = named ?? (held.first { ($0["request_id"] as? String) == id }?["fingerprint"] as? String)
      Self.saveHeld(held.filter {
        ($0["request_id"] as? String) != id && (fingerprint == nil || ($0["fingerprint"] as? String) != fingerprint)
      })
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
      request["at"] = Self.nowMs()
      // One request per watch key: this one replaces what the same watch asked before.
      var held = Self.held().filter {
        ($0["request_id"] as? String) != id && ($0["fingerprint"] as? String) != fingerprint
      }
      held.append(request)
      Self.saveHeld(Array(held.suffix(Self.maxHeld)))
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

  private static func nowMs() -> Int64 { Int64((Date().timeIntervalSince1970 * 1000).rounded()) }

  /// The held requests that are still fresh. One held by an older build has no `at`: it is
  /// stamped now, so it gets its fifteen minutes from here.
  private static func held() -> [[String: Any]] {
    let saved = (UserDefaults.standard.array(forKey: heldKey) as? [[String: Any]]) ?? []
    guard !saved.isEmpty else { return [] }
    let now = nowMs()
    let oldest = now - Int64(heldFor * 1000)
    var changed = false
    var fresh: [[String: Any]] = []
    for var request in saved {
      guard let at = (request["at"] as? NSNumber)?.int64Value else {
        request["at"] = now
        fresh.append(request)
        changed = true
        continue
      }
      if at >= oldest { fresh.append(request) } else { changed = true }
    }
    if changed { saveHeld(fresh) }
    return fresh
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
    DispatchQueue.main.async {
      // "Open on iPhone" is told whether the app is in front of the person right now. When it
      // isn't (the system woke it in the background for this message), the watch asks the server
      // to leave a notification, so there is something to tap. Every message gets one reply.
      if (message["type"] as? String) == "open" {
        replyHandler(["front": UIApplication.shared.applicationState == .active])
      } else {
        replyHandler([:])
      }
      self.receive(message)
    }
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    DispatchQueue.main.async { self.receive(userInfo) }
  }
}
