import UIKit
import UniformTypeIdentifiers

/// Share to bot: saves shared text and links to the App Group and opens Kasama's quick ask.
/// (Kept native and dependency-free so the extension stays small.)
final class ShareViewController: UIViewController {
  private let groupId = "group.com.kasama.app"

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { await collectAndOpen() }
  }

  private func collectAndOpen() async {
    var parts: [String] = []
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    for item in items {
      if let text = item.attributedContentText?.string, !text.isEmpty { parts.append(text) }
      for provider in item.attachments ?? [] {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
          parts.append(url.isFileURL ? url.lastPathComponent : url.absoluteString)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                  let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
          parts.append(text)
        }
      }
    }
    let text = parts.joined(separator: "\n")
    UserDefaults(suiteName: groupId)?.set(text, forKey: "shared_text")
    var components = URLComponents(string: "kasama://app/quick-ask")!
    components.queryItems = [URLQueryItem(name: "shared", value: "1")]
    if let url = components.url { open(url) }
    extensionContext?.completeRequest(returningItems: nil)
  }

  /// Extensions cannot call UIApplication.open directly; walk the responder chain to the app.
  private func open(_ url: URL) {
    var responder: UIResponder? = self
    while let r = responder {
      if let app = r as? UIApplication {
        app.open(url, options: [:], completionHandler: nil)
        return
      }
      responder = r.next
    }
  }
}
