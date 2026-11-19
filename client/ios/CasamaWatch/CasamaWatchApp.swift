import SwiftUI
import UserNotifications
import WatchKit
import WidgetKit

// MARK: - Casama on Apple Watch (D-410)
//
// A single-target watchOS app inside the iPhone app's project (client/ios/CasamaWatch). It works
// without the iPhone once signed in (WKRunsIndependentlyOfCompanionApp): its own key, its own
// calls to the person's server, its own push token. The iPhone only signs it in.

@main
struct CasamaWatchApp: App {
  @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate
  @StateObject private var model = AppModel.shared
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(model)
        .onAppear { model.start() }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { model.becameActive() }
    }

    WKNotificationScene(controller: ApprovalNotificationController.self, category: WatchNotifications.approval)
    WKNotificationScene(controller: SuggestionNotificationController.self, category: WatchNotifications.suggestion)
    WKNotificationScene(controller: ReplyNotificationController.self, category: WatchNotifications.reply)
  }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
  /// Background refresh: about every 20 minutes, within the system's budget of four an hour.
  static let refreshEvery: TimeInterval = 20 * 60

  func applicationDidFinishLaunching() {
    UNUserNotificationCenter.current().delegate = self
    WatchNotifications.registerCategories()
    scheduleRefresh()
  }

  func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
    Task { @MainActor in AppModel.shared.gotPushToken(deviceToken) }
  }

  func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
    // Pushes still reach the watch mirrored from the iPhone; nothing to tell the person.
  }

  /// A push that asks the app to refresh (Phase 5 sends these with content-available).
  func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {
    Task {
      let outcome = await WatchSync.refreshGlance()
      if outcome == .fresh { WatchSync.reloadWidgets() }
      switch outcome {
      case .fresh: completionHandler(.newData)
      case .unchanged: completionHandler(.noData)
      default: completionHandler(.failed)
      }
    }
  }

  func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
    for task in backgroundTasks {
      switch task {
      case let refresh as WKApplicationRefreshBackgroundTask:
        Task {
          // The glance is small and usually "not changed": well within the few seconds a refresh gets.
          let outcome = await WatchSync.refreshGlance()
          if outcome == .fresh || outcome == .signedOut { WatchSync.reloadWidgets() }
          self.scheduleRefresh()
          refresh.setTaskCompletedWithSnapshot(false)
        }
      case let snapshot as WKSnapshotRefreshBackgroundTask:
        snapshot.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: .distantFuture, userInfo: nil)
      default:
        task.setTaskCompletedWithSnapshot(false)
      }
    }
  }

  private func scheduleRefresh() {
    WKApplication.shared().scheduleBackgroundRefresh(
      withPreferredDate: Date().addingTimeInterval(Self.refreshEvery), userInfo: nil) { _ in }
  }

  // MARK: UNUserNotificationCenterDelegate

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    // Something changed: the glance behind Now and the complications should show it.
    Task { @MainActor in AppModel.shared.refresh() }
    return [.banner, .list, .sound]
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    await NotificationRouter.handle(response)
  }
}
