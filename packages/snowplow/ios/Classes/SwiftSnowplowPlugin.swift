import Flutter
import UIKit
import Foundation
import SnowplowTracker

public class SwiftSnowplowPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel?
    static var tracker: TrackerController?
    var userId: String = "0"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftSnowplowPlugin.synced(self) {
            if SwiftSnowplowPlugin.channel == nil {
                SwiftSnowplowPlugin.channel = FlutterMethodChannel(name: "com.suamusica.br/snowplow", binaryMessenger: registrar.messenger())
                SwiftSnowplowPlugin.tracker = SnowplowTrackerBuilder().getTracker("snowplow.suamusica.com.br")
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
            let value = args["value"] as! Int;
            let property = args["property"] as! String;
            let pagename = args["pageName"] as! String;
            trackEvent(result: result, category, action, label, property, value, pagename);
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
        SnowplowUtils.trackScreenViewWithTracker(with: SwiftSnowplowPlugin.tracker!, andUserId: self.userId, andScreenName: screenName)
        result(true)
    }
    
    public func setUserId(result: @escaping FlutterResult, _ userId: String) {
        self.userId = userId
        result(true)
    }
    
    public func trackCustomEvent(result: @escaping FlutterResult, _ customSchema: String, _ eventMap: [String: Any]) {
        SnowplowUtils.trackCustomEventWithTracker(with: SwiftSnowplowPlugin.tracker!, andUserId: self.userId, andSchema: customSchema, andData: eventMap as NSObject)
        result(true)
    }
    
    public func trackEvent(result: @escaping FlutterResult, _ category: String, _ action: String, _ label: String , _ property: String, _ value: Int, _ pagename: String) {
        SnowplowUtils.trackStructuredEventWithTracker(with: SwiftSnowplowPlugin.tracker!, andUserId: self.userId, andCategory: category, andAction: action, andLabel: label, andProperty: property, andValue: value, andPagename: pagename)
        result(true)
    }
}
