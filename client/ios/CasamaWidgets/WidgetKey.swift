import Foundation
import Security

// MARK: - The widget key (D-405 §8.3, §8.6, §17)
//
// A key the app asks the server for, which reads the glance and creation covers and nothing else.
// It lives in a keychain group only the app and its widget extensions share, readable after the
// first unlock so a widget can refresh on a locked phone, and never leaves this device.
// Compiled into the iPhone app and its widget extension, and the Mac app and its widget extension.

enum WidgetKey {
  /// The team's App ID prefix, which `$(AppIdentifierPrefix)` expands to in the entitlements.
  /// Keep in step with DEVELOPMENT_TEAM (and the Mac app group, GlanceStore.groupId).
  static let teamPrefix = "V8V5US964Z"
  static let accessGroup = "\(teamPrefix).ai.casama.app.widgets"
  static let service = "ai.casama.widgets"
  static let account = "key"

  private static func query() -> [String: Any] {
    var q: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
    ]
    #if os(macOS)
    // Access groups only work in the data protection keychain on the Mac.
    q[kSecUseDataProtectionKeychain as String] = true
    #endif
    return q
  }

  /// The key, or nil when there is none (signed out, an older app, or a build whose signing
  /// doesn't grant the keychain group).
  static func read() -> String? {
    var q = query()
    q[kSecReturnData as String] = true
    q[kSecMatchLimit as String] = kSecMatchLimitOne
    var out: CFTypeRef?
    guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
    return String(data: data, encoding: .utf8).flatMap { $0.isEmpty ? nil : $0 }
  }

  /// Stores [key], or deletes it when nil or empty. Answers whether the keychain took it.
  @discardableResult
  static func write(_ key: String?) -> Bool {
    let q = query()
    guard let key, !key.isEmpty, let data = key.data(using: .utf8) else {
      let status = SecItemDelete(q as CFDictionary)
      return status == errSecSuccess || status == errSecItemNotFound
    }
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let status = SecItemUpdate(q as CFDictionary, attributes as CFDictionary)
    if status == errSecSuccess { return true }
    guard status == errSecItemNotFound else { return false }
    return SecItemAdd(q.merging(attributes) { $1 } as CFDictionary, nil) == errSecSuccess
  }
}
