import Flutter
import UIKit

public class SwiftSmadsPlugin: NSObject, FlutterPlugin {
    let channel: FlutterMethodChannel
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "smads", binaryMessenger: registrar.messenger())
        let instance = SwiftSmadsPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "load":
            DispatchQueue.main.async {
                do {
                    try ObjC.catchException {
                        let adsViewController = AdsViewController(channel: self.channel)
                        adsViewController.modalPresentationStyle = .fullScreen
                        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
                        rootViewController?.present(adsViewController, animated: false, completion: nil)
                    }
                }
                catch {
                    print("An error ocurred: \(error)")
                }
            }
            
        case "play":
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Alert", message: "Playing...", preferredStyle: .alert);
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil);
            }
        default:
            result(FlutterError(code: "-1", message: "Operation not supported", details: nil))
        }
    }
}
