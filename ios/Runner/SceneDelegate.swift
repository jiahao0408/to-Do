import Flutter
import UIKit

/// Recibe archivos .ics abiertos desde otras apps y pasa la ruta a Flutter
/// por el canal `todo/ics` (igual que MainActivity en Android).
class SceneDelegate: FlutterSceneDelegate {
  private var channel: FlutterMethodChannel?
  private var pendingIcs: String?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let url = connectionOptions.urlContexts.first?.url {
      pendingIcs = copyIcs(url)
    }
    setupChannel()
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard let url = URLContexts.first?.url, let path = copyIcs(url) else { return }
    setupChannel()
    channel?.invokeMethod("icsFile", arguments: path)
  }

  private func setupChannel() {
    guard channel == nil,
      let controller = window?.rootViewController as? FlutterViewController
    else { return }
    let ch = FlutterMethodChannel(name: "todo/ics", binaryMessenger: controller.binaryMessenger)
    ch.setMethodCallHandler { [weak self] call, result in
      if call.method == "initialIcsFile" {
        result(self?.pendingIcs)
        self?.pendingIcs = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    channel = ch
  }

  /// Copia el .ics a la carpeta temporal (los enlaces todocal:// no son archivos).
  private func copyIcs(_ url: URL) -> String? {
    guard url.isFileURL, url.pathExtension.lowercased() == "ics" else { return nil }
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    let dest = FileManager.default.temporaryDirectory
      .appendingPathComponent("incoming-\(Int(Date().timeIntervalSince1970)).ics")
    do {
      try? FileManager.default.removeItem(at: dest)
      try FileManager.default.copyItem(at: url, to: dest)
      return dest.path
    } catch {
      return nil
    }
  }
}
