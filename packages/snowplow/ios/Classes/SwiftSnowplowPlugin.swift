import Flutter
import UIKit
import Foundation
import SnowplowTracker

public class SwiftSnowplowPlugin: NSObject, FlutterPlugin {
  static var channel: FlutterMethodChannel?
  static var tracker: SPTracker?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    SwiftSnowplowPlugin.synced(self) {
            if SwiftSnowplowPlugin.channel == nil {
                SwiftSnowplowPlugin.channel = FlutterMethodChannel(name: "com.suamusica.br/snowplow", binaryMessenger: registrar.messenger())
                let methodType : SPRequestOptions = SPRequestGet
                let protocolType : SPProtocol = SPHttps
                SwiftSnowplowPlugin.tracker = SnowplowTrackerBuilder().getTracker("snowplow.suamusica.com.br", method: methodType, protocol: protocolType)
                let instance = SwiftSnowplowPlugin(channel: SwiftSnowplowPlugin.channel!)
                registrar.addMethodCallDelegate(instance, channel: SwiftSnowplowPlugin.channel!)
            }
        }    
  }

  init(channel: FlutterMethodChannel) {
    SwiftSnowplowPlugin.channel = channel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as! [String: Any]
    switch call.method {
        case "trackPageview":
          let screenName = args["screenName"] as! String;
          trackPageview(result: result, screenName);
        case "setUserId":
          let userId = args["userId"] as! String;
          setUserId(result: result, userId);
        default:
            result(FlutterError(code: "-1", message: "Operation not supported", details: nil))
        }
  }

  static func synced(_ lock: Any, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
  }

  public func trackPageview(result: @escaping FlutterResult, _ screenName: String) {
    SnowplowUtils.trackScreenViewWithTracker(SwiftSnowplowPlugin.tracker!, screenName)
    result(true)
  }

  public func setUserId(result: @escaping FlutterResult, _ userId: String) {
    SwiftSnowplowPlugin.tracker!.subject.setUserId(userId)
    result(true)
  }
}
