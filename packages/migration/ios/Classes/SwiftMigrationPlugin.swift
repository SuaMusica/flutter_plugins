import Flutter
import UIKit
import CoreData

public class SwiftMigrationPlugin: NSObject, FlutterPlugin {
  static var channel: FlutterMethodChannel?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    SwiftMigrationPlugin.synced(self) {
        if SwiftMigrationPlugin.channel == nil {
            SwiftMigrationPlugin.channel = FlutterMethodChannel(name: "migration", binaryMessenger: registrar.messenger())
            let instance = SwiftMigrationPlugin(channel: SwiftMigrationPlugin.channel!)
            registrar.addMethodCallDelegate(instance, channel: SwiftMigrationPlugin.channel!)
        }
    }
  }

  init(channel: FlutterMethodChannel) {
      SwiftMigrationPlugin.channel = channel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestDownloadedContent":
        DispatchQueue.main.async {
            let tracks = Track.getAll() as! [Track]
          
          let downloadedContent = tracks.map { (track) -> [String: Any?] in
            guard let id = track.idTrack, let path = track.localFile()?.absoluteString else {
              return [:]
            }
            
            return [
              "id": id,
              "path": path.components(separatedBy: "Documents").last ?? ""
            ]
          }
          SwiftMigrationPlugin.channel?.invokeMethod("downloadedContent", arguments: downloadedContent)
        }
        result(1)

    default:
        result(FlutterError(code: "-1", message: "Operation not supported", details: nil))
    }
  }

  static func synced(_ lock: Any, closure: () -> Void) {
      objc_sync_enter(lock)
      closure()
      objc_sync_exit(lock)
  }
}
