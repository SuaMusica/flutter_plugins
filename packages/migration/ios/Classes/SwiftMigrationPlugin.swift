import Flutter
import UIKit
import CoreData
import os.log

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
        let tracks = Track.getAll() as! [Track]
        
        let downloadedContent = tracks.map { (track) -> [String: Any]? in
          guard let id = track.idTrack, let path = track.localFile()?.absoluteString.components(separatedBy: "Documents").last,
          let directory = FileManager.documentsDir(), FileManager().fileExists(atPath: directory.appending(path)) else {
            print("Migration incomplete downloadItem: \(track.idTrack ?? "unknown") not available;", terminator: "")
            return nil
          }
          
          return [
            "id": id,
            "path": path
          ]
        }
        
        let downloads = downloadedContent.compactMap { $0 }
        
        SwiftMigrationPlugin.channel?.invokeMethod("downloadedContent", arguments: downloads)
        if (downloads.isEmpty) {
          result(0)
        } else {
          result(1)
        }
      break
    case "deleteOldContent":
      let wasDeleted = AppHelper.shared.removeDatabase()
      print("Migration: Database was deleted: \(wasDeleted == 1)")
      result(wasDeleted)
      break
    case "requestLoggedUser":
      let users = LoggedUser.getAll() as! [LoggedUser]
      if (users.isEmpty) {
        result(nil)
      } else {
        let user = users[0]

        result([
          "userid": user.userId,
          "name": user.name,
          "cover": user.pictureUrl,
        ])
      }
      LoggedUser.truncate()
      break

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

extension FileManager {
    class func documentsDir() -> String? {
      let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [String]
      if (paths.isEmpty) {
        return nil
      } else {
        return paths[0]
      }
    }
}
