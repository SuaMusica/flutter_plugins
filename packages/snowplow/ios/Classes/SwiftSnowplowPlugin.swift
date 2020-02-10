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
        case "trackCustomEvent":
          let customScheme = args["customScheme"] as! String;
          let eventMap = args["eventMap"] as! [String: Any];
          trackCustomEvent(result: result, customScheme, eventMap);
        case "trackEvent":
          let category = args["category"] as! String;
          let action = args["action"] as! String;
          let label = args["label"] as! String;
          let property = args["property"] as! String;
          trackEvent(result: result, category, action, label, property);
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
    SnowplowUtils.trackScreenViewWithTracker(with: SwiftSnowplowPlugin.tracker!, andScreenName: screenName)
    result(true)
  }

  public func setUserId(result: @escaping FlutterResult, _ userId: String) {
    SwiftSnowplowPlugin.tracker!.subject.setUserId(userId)
    result(true)
  }

  public func trackCustomEvent(result: @escaping FlutterResult, _ customSchema: String, _ eventMap: [String: Any]) {
    SnowplowUtils.trackCustomEventWithTracker(with: SwiftSnowplowPlugin.tracker!, andSchema: customSchema, andData: eventMap as! NSObject)
    result(true)
  }

  public func trackEvent(result: @escaping FlutterResult, _ category: String, _ action: String, _ label: String, _ property: String) {
    SnowplowUtils.trackStructuredEventWithTracker(with: SwiftSnowplowPlugin.tracker!, andCategory: category, andAction: action, andLabel: label, andProperty: property)
    result(true)
  }
}
