import Flutter
import UIKit
import ComScore

public class SwiftComscorePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "comscore", binaryMessenger: registrar.messenger())
        let instance = SwiftComscorePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments ?? [String: Any]() 
        switch call.method {
        case "initialize":
            let myPublisherConfig = SCORPublisherConfiguration(builderBlock: { builder in
                builder?.publisherId = "1000001"
                builder?.secureTransmissionEnabled = false
            })
            result(true)
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterError(code: "-1", message: "Operation not supported", details: nil))
        }
    }
}
