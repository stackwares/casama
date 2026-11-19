import Foundation
import Security

// MARK: - The watch key (docs/WATCH-PROTOCOL.md §1, D-410 §8.2)
//
// The watch makes its own key and keeps it in a keychain group only the watch app and its
// complications share: this device only (it never syncs to iCloud or another watch), readable
// after the first unlock so a complication can refresh while the watch is locked. Only its
// fingerprint ever leaves the watch, except in the Authorization header to the person's server.

enum WatchKeyStore {
  /// The team's App ID prefix, which `$(AppIdentifierPrefix)` expands to in the entitlements.
  /// Keep in step with DEVELOPMENT_TEAM.
  static let teamPrefix = "V8V5US964Z"
  static let accessGroup = "\(teamPrefix).ai.casama.app.watch"
  static let service = "ai.casama.watch"
  static let account = "key"

  private static func query(group: Bool) -> [String: Any] {
    var q: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    if group { q[kSecAttrAccessGroup as String] = accessGroup }
    return q
  }

  /// The key, or nil when none has been made yet.
  static func read() -> String? {
    for group in [true, false] {
      var q = query(group: group)
      q[kSecReturnData as String] = true
      q[kSecMatchLimit as String] = kSecMatchLimitOne
      var out: CFTypeRef?
      if SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data,
         let key = String(data: data, encoding: .utf8), WatchKeyMaker.isWellFormed(key) {
        return key
      }
    }
    return nil
  }

  /// Whether the keychain can't be read right now: the watch hasn't been unlocked since it
  /// restarted (the key is readable after the first unlock). As against holding no key at all,
  /// which `read()` also answers nil for.
  static var isLocked: Bool {
    for group in [true, false] {
      var q = query(group: group)
      q[kSecReturnData as String] = true
      q[kSecMatchLimit as String] = kSecMatchLimitOne
      var out: CFTypeRef?
      if SecItemCopyMatching(q as CFDictionary, &out) == errSecInteractionNotAllowed { return true }
    }
    return false
  }

  /// The key, made now when there is none. Nil only if the keychain refuses to keep one.
  static func readOrCreate() -> String? {
    if let key = read() { return key }
    let key = WatchKeyMaker.make()
    return write(key) ? key : nil
  }

  @discardableResult
  static func write(_ key: String) -> Bool {
    guard let data = key.data(using: .utf8) else { return false }
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecAttrSynchronizable as String: false,
    ]
    // The shared group first; a build signed without the group (a simulator run from the command
    // line) keeps it in the app's own keychain, which the app alone can then read.
    for group in [true, false] {
      let q = query(group: group)
      var status = SecItemUpdate(q as CFDictionary, attributes as CFDictionary)
      if status == errSecItemNotFound {
        status = SecItemAdd(q.merging(attributes) { $1 } as CFDictionary, nil)
      }
      if status == errSecSuccess { return true }
      if status != errSecMissingEntitlement { return false }
    }
    return false
  }

  /// Deletes the key: signing out of this watch. The next sign-in makes a new one.
  static func delete() {
    SecItemDelete(query(group: true) as CFDictionary)
    SecItemDelete(query(group: false) as CFDictionary)
  }
}
