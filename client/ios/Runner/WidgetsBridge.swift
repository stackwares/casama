import Flutter
import Foundation
import WidgetKit

// MARK: - casama/widgets (D-405 §8.3, §17): the iPhone side of the widgets that isn't data
//
// The glance and its words reach the App Group through home_widget; this keeps the widget key in
// the keychain group the widget extension shares (WidgetKey.swift), redraws the widgets, and says
// which ones are placed (for Settings → Widgets and the `widgets_placed` count, §15).
//
//   setKey {key: String?}  → bool   stores the key, or deletes it when null (sign-out)
//   reload                 → null   redraws every widget
//   installed              → [{kind, family}]

final class WidgetsBridge {
  static let shared = WidgetsBridge()
  private var channel: FlutterMethodChannel?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "casama/widgets", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "setKey":
        let key = (call.arguments as? [String: Any])?["key"] as? String
        let ok = WidgetKey.write(key)
        WidgetCenter.shared.reloadAllTimelines()
        result(ok)
      case "reload":
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      case "installed":
        WidgetCenter.shared.getCurrentConfigurations { configs in
          let list = (try? configs.get())?.map { ["kind": $0.kind, "family": Self.name($0.family)] } ?? []
          DispatchQueue.main.async { result(list) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  /// WidgetKit's family names, as Dart reads them.
  static func name(_ family: WidgetFamily) -> String {
    switch family {
    case .systemSmall: return "systemSmall"
    case .systemMedium: return "systemMedium"
    case .systemLarge: return "systemLarge"
    case .systemExtraLarge: return "systemExtraLarge"
    case .accessoryCircular: return "accessoryCircular"
    case .accessoryRectangular: return "accessoryRectangular"
    case .accessoryInline: return "accessoryInline"
    default:
      if #available(iOS 27.0, *), family == .systemExtraLargePortrait { return "systemExtraLargePortrait" }
      return "\(family)"
    }
  }
}
