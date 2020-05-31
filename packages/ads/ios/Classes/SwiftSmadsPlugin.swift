import Flutter
import UIKit

public class SwiftSmadsPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel?
    private var screen: Screen
    static let NoConnectivity = -1;
    static let ScreenIsLocked = -2;
    static let UnlockedScreen = 1;
    static let LockedScreen = 0;

    fileprivate static func verifyNetworkAccess() {
        do {
            try Network.reachability = Reachability(hostname: "www.google.com")
        } catch {
            switch error as? Network.Error {
            case let .failedToCreateWith(hostname)?:
                print("Network error:\nFailed to create reachability object With host named:", hostname)
            case let .failedToInitializeWith(address)?:
                print("Network error:\nFailed to initialize reachability object With address:", address)
            case .failedToSetCallout?:
                print("Network error:\nFailed to set callout")
            case .failedToSetDispatchQueue?:
                print("Network error:\nFailed to set DispatchQueue")
            case .none:
                print(error)
            }
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftSmadsPlugin.synced(self) {
            if SwiftSmadsPlugin.channel == nil {
                SwiftSmadsPlugin.channel = FlutterMethodChannel(name: "smads", binaryMessenger: registrar.messenger())
                let instance = SwiftSmadsPlugin(channel: SwiftSmadsPlugin.channel!)
                registrar.addMethodCallDelegate(instance, channel: SwiftSmadsPlugin.channel!)
            }

            verifyNetworkAccess()
        }
    }

    init(channel: FlutterMethodChannel) {
        SwiftSmadsPlugin.channel = channel
        self.screen = Screen()
        self.screen.addNotificationObservers()
    }

    fileprivate func onComplete() {
        SwiftSmadsPlugin.channel?.invokeMethod("onComplete", arguments: [String: String]())
    }
    
    fileprivate func onError(code: Int) {
        let arguments = ["error": code]
        SwiftSmadsPlugin.channel?.invokeMethod("onError", arguments: arguments)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "load":
            DispatchQueue.main.async {
                do {
                    try ObjC.catchException {
                        let args = call.arguments as! [String: Any]
                        let adUrl = args["__URL__"] as! String
                        let contentUrl = args["__CONTENT__"] as! String

                        if !Network.reachability.isReachable {
                            // if for any reason we are not reachable
                            // we shall try to update the network manager
                            SwiftSmadsPlugin.verifyNetworkAccess()
                        }
                        
                        if (self.screen.status == .unlocked) {
                            if (Network.reachability.isReachable) {                                
                                let adsViewController:AdsViewController = AdsViewController.instantiateFromNib()
                                adsViewController.setup(
                                    channel: SwiftSmadsPlugin.channel,
                                    adUrl: adUrl,
                                    contentUrl: contentUrl,
                                    screen: self.screen,
                                    args: args)
                                adsViewController.modalPresentationStyle = .fullScreen
                                let rootViewController = UIApplication.shared.keyWindow?.rootViewController
                                rootViewController?.present(adsViewController, animated: false, completion: nil)
                                result(1)
                            } else {
                                self.onError(code: SwiftSmadsPlugin.NoConnectivity)
                                result(SwiftSmadsPlugin.NoConnectivity)
                            }
                        } else {
                            self.onError(code: SwiftSmadsPlugin.ScreenIsLocked)
                            result(SwiftSmadsPlugin.ScreenIsLocked)
                        }
                        
                    }
                } catch {
                    result(0)
                    print("An error ocurred: \(error)")
                }
            }
        case "screen_status":
            result(self.screen.status == .unlocked ? SwiftSmadsPlugin.UnlockedScreen : SwiftSmadsPlugin.LockedScreen)
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
