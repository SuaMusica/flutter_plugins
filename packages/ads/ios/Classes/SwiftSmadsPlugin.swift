import Flutter
import UIKit
import GoogleInteractiveMediaAds

public class SwiftSmadsPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel?
    private var screen: Screen
    static let NoConnectivity = -1;
    static let ScreenIsLocked = -2;
    static let UnlockedScreen = 1;
    static let LockedScreen = 0;
    static var adsViewController: AdsViewController? = nil
    static var registrarAds: FlutterPluginRegistrar? = nil

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
                SwiftSmadsPlugin.channel = FlutterMethodChannel(name: "suamusica/pre_roll", binaryMessenger: registrar.messenger())
                let instance = SwiftSmadsPlugin(channel: SwiftSmadsPlugin.channel!)
                registrar.addMethodCallDelegate(instance, channel: SwiftSmadsPlugin.channel!)
            }

            if (registrarAds == nil) {
                registrarAds = registrar
                adsViewController = AdsViewController.instantiateFromNib()

                if (SwiftSmadsPlugin.registrarAds != nil) {
                    let viewFactory = FLNativeViewFactory(
                        messenger: SwiftSmadsPlugin.registrarAds!.messenger(),
                        controller: adsViewController!
                    )

                    SwiftSmadsPlugin.registrarAds!.register(viewFactory, withId: "suamusica/pre_roll_view")
                }
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
        print("Method call: \(call.method), arguments: \(call.arguments ?? "N/A"), result: \(String(describing: result))")
        switch call.method {
        case "load":
            DispatchQueue.main.async {
                do {
                    try ObjC.catchException { [self] in
                        let args = call.arguments as! [String: Any]
                        let adUrl = args["__URL__"] as! String
                        let contentUrl = args["__CONTENT__"] as! String
                        let ppID = args["ppid"] as? String;
                        if !Network.reachability.isReachable {
                            // if for any reason we are not reachable
                            // we shall try to update the network manager
                            SwiftSmadsPlugin.verifyNetworkAccess()
                        }
                        
                        if (Network.reachability.isReachable) {
                            print("AD: Screen is unlocked and ready to show ads | ppID: \(ppID ?? "N/A") | all args: \(args)")
                            SwiftSmadsPlugin.adsViewController!.ppID = ppID

                            SwiftSmadsPlugin.adsViewController!.setup(
                                channel: SwiftSmadsPlugin.channel,
                                adUrl: adUrl,
                                contentUrl: contentUrl,
                                screen: self.screen,
                                args: args)

                            result(1)
                        } else {
                            self.onError(code: SwiftSmadsPlugin.NoConnectivity)
                            result(SwiftSmadsPlugin.NoConnectivity)
                        }

                    }
                } catch {
                    result(0)
                    print("An error ocurred: \(error)")
                }
            }
        case "screen_status":
            result(self.screen.status == .unlocked ? SwiftSmadsPlugin.UnlockedScreen : SwiftSmadsPlugin.LockedScreen)
        case "play":
            SwiftSmadsPlugin.adsViewController!.play()
            result(1)
        case "pause":
            SwiftSmadsPlugin.adsViewController!.pause()
            result(1)
        case "dispose":
            SwiftSmadsPlugin.adsViewController!.dispose()
            result(1)
        case "skip":
            SwiftSmadsPlugin.adsViewController!.skip()
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
