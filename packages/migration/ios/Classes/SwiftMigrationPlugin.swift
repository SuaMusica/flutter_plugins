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
    result("iOS " + UIDevice.current.systemVersion)
    
    switch call.method {
    case "getLegacyDownloadedContent":
        DispatchQueue.main.async {
            let tracks = Track.getAll() as! [Track]
          //TODO: split documents in localFile, check if exists
          //TODO: idTrack
          // DownloadedTrack(idTrack: Int, localPath: String)
        }

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
