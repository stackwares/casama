import UIKit
import UniformTypeIdentifiers

/// Share to bot: saves shared text and links to the App Group, copies shared pictures and files
/// into the App Group's container, and opens Casama's quick ask, which attaches them as files.
/// (Kept native and dependency-free so the extension stays small.)
final class ShareViewController: UIViewController {
  private let groupId = "group.ai.casama.app"

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { await collectAndOpen() }
  }

  private func collectAndOpen() async {
    var parts: [String] = []
    var files: [[String: String]] = []
    let folder = sharedFolder()
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    for item in items {
      if let text = item.attributedContentText?.string, !text.isEmpty { parts.append(text) }
      for provider in item.attachments ?? [] {
        let isFileURL = provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        if !isFileURL, provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
          parts.append(url.absoluteString)
        } else if let folder, let type = fileType(provider, isFileURL: isFileURL),
                  let file = await copy(provider, type: type, into: folder) {
          files.append(file)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                  let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
          parts.append(text)
        }
      }
    }
    let text = parts.joined(separator: "\n")
    let defaults = UserDefaults(suiteName: groupId)
    defaults?.set(text, forKey: "shared_text")
    // Read by takeSharedFiles() in lib/core/mobile_extras.dart.
    if let data = try? JSONSerialization.data(withJSONObject: files),
       let json = String(data: data, encoding: .utf8) {
      defaults?.set(files.isEmpty ? nil : json, forKey: "shared_files")
    }
    var components = URLComponents(string: "casama://app/quick-ask")!
    components.queryItems = [URLQueryItem(name: "shared", value: "1")]
    if let url = components.url { open(url) }
    extensionContext?.completeRequest(returningItems: nil)
  }

  /// The App Group folder shared files are copied into. What an earlier share left is removed
  /// first: quick ask has read it by now.
  private func sharedFolder() -> URL? {
    guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else { return nil }
    let folder = root.appendingPathComponent("shared", isDirectory: true)
    try? FileManager.default.removeItem(at: folder)
    do {
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      return folder
    } catch {
      return nil
    }
  }

  /// The type to copy a shared item as: a file from Files, or a picture, video, PDF or other
  /// document. Plain text and web links stay text.
  private func fileType(_ provider: NSItemProvider, isFileURL: Bool) -> String? {
    let content = provider.registeredTypeIdentifiers.first { id in
      guard let t = UTType(id) else { return false }
      return t.conforms(to: .data) && !t.conforms(to: .plainText) && !t.conforms(to: .url)
    }
    if let content { return content }
    return isFileURL ? UTType.data.identifier : nil
  }

  /// Copies a shared item into [folder]; returns its path, name and MIME type.
  private func copy(_ provider: NSItemProvider, type: String, into folder: URL) async -> [String: String]? {
    let suggested = provider.suggestedName
    return await withCheckedContinuation { done in
      _ = provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
        guard let url else { return done.resume(returning: nil) }
        let utType = UTType(type)
        var name = suggested ?? url.lastPathComponent
        if (name as NSString).pathExtension.isEmpty {
          let ext = url.pathExtension.isEmpty ? (utType?.preferredFilenameExtension ?? "") : url.pathExtension
          if !ext.isEmpty { name += "." + ext }
        }
        let dest = folder.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let file = dest.appendingPathComponent(name)
        do {
          try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
          try FileManager.default.copyItem(at: url, to: file)
        } catch {
          return done.resume(returning: nil)
        }
        let mime = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? utType?.preferredMIMEType
        var entry = ["path": file.path, "name": name]
        if let mime { entry["mime"] = mime }
        done.resume(returning: entry)
      }
    }
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
