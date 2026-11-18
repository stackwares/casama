import SwiftUI
import WidgetKit

// MARK: - Refresh pushes (D-405 §8.3 step 4; iOS 26 and macOS 26 only)
//
// The server can ask Apple to reload these widgets: a push with no content to
// `<bundle id>.push-type.widgets`. WidgetKit hands the extension a token for it, which goes to
// the server with the widget key (GlanceFetch.sendPushToken). The push is a hint: the widgets
// still refresh on their own schedule. Shared by the iPhone and Mac widget extensions.

@available(iOS 26.0, macOS 26.0, *)
struct GlancePushHandler: WidgetPushHandler {
  init() {}

  func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
    GlanceFetch.store(pushToken: pushInfo.token)
    Task { await GlanceFetch.sendPushToken() }
  }
}

/// A widget with the push handler added, for systems that have it.
@available(iOS 26.0, macOS 26.0, *)
struct PushRefreshed<W: Widget>: Widget {
  private let inner = W()
  init() {}
  var body: some WidgetConfiguration { inner.body.pushHandler(GlancePushHandler.self) }
}

enum GlanceBundle {
  /// [W], refreshed by server pushes where the system supports them. A widget configuration has
  /// no `if #available` of its own, so the choice is made where a widget bundle allows one, under
  /// the same kind either way: placed widgets carry over across system updates.
  static func refreshable<W: Widget>(_: W.Type) -> some Widget {
    WidgetBundleBuilder.buildOptional(pick(W.self))
  }

  private static func pick<W: Widget>(_: W.Type) -> any Widget & _LimitedAvailabilityWidgetMarker {
    if #available(iOS 26.0, macOS 26.0, *) {
      return WidgetBundleBuilder.buildLimitedAvailability(PushRefreshed<W>())
    }
    return WidgetBundleBuilder.buildLimitedAvailability(W())
  }
}
