import Flutter
import UIKit

public class SwiftSmadsPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftSmadsPlugin.synced(self) {
            if (SwiftSmadsPlugin.channel == nil) {
                SwiftSmadsPlugin.channel = FlutterMethodChannel(name: "smads", binaryMessenger: registrar.messenger())
                let instance = SwiftSmadsPlugin(channel: SwiftSmadsPlugin.channel!)
                registrar.addMethodCallDelegate(instance, channel: SwiftSmadsPlugin.channel!)
            }
        }
    }

    init(channel: FlutterMethodChannel) {
        SwiftSmadsPlugin.channel = channel
    }
        
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "load":
            DispatchQueue.main.async {
                do {
                    try ObjC.catchException {
                        let adsViewController = AdsViewController(channel: SwiftSmadsPlugin.channel)
                        adsViewController.modalPresentationStyle = .fullScreen
                        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
                        rootViewController?.present(adsViewController, animated: false, completion: nil)
                        result(1);
                    }
                }
                catch {
                    print("An error ocurred: \(error)")
                }
            }
            
        default:
            result(FlutterError(code: "-1", message: "Operation not supported", details: nil))
        }
    }

    static func synced(_ lock: Any, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
}
