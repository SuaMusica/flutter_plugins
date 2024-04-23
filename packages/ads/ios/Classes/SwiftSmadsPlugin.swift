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
    // nullable
    var adsViewController: AdsViewController? = nil
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
        print("Registering plugin at registrar: \(registrar), datetime: \(Date()), SwiftSmadsPlugin.channel: \(String(describing: SwiftSmadsPlugin.channel))")
        SwiftSmadsPlugin.synced(self) {
            if SwiftSmadsPlugin.channel == nil {
                SwiftSmadsPlugin.channel = FlutterMethodChannel(name: "suamusica/pre_roll", binaryMessenger: registrar.messenger())
                let instance = SwiftSmadsPlugin(channel: SwiftSmadsPlugin.channel!)
                registrar.addMethodCallDelegate(instance, channel: SwiftSmadsPlugin.channel!)
            }
//            let viewFactory = FLNativeViewFactory(
//                messenger: SwiftSmadsPlugin.registrarAds!.messenger(),
//                controller:adsViewController
//            )

//            SwiftSmadsPlugin.registrarAds!.register(viewFactory, withId: "suamusica/pre_roll_view")
            registrarAds = registrar
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
        print("Method call: \(call.method), arguments: \(call.arguments ?? "N/A"), result: \(result)")
        switch call.method {
        case "init":
            print("init is called");
            //            load factory e garante que não é nulo
            // adsViewController = AdsViewController.instantiateFromNib()
            // SwiftSmadsPlugin.adsViewController = SwiftSmadsPlugin.adsViewController.instantiateFromNib()
            adsViewController = AdsViewController.instantiateFromNib()
            
            if (adsViewController == nil) {
                print("Ads view controller is nil")
                result(FlutterError(code: "-1", message: "Ads view controller is nil", details: nil))
                return
            }

            let viewFactory = FLNativeViewFactory(
                messenger: SwiftSmadsPlugin.registrarAds!.messenger(),
                controller: adsViewController!
            )

             SwiftSmadsPlugin.registrarAds!.register(viewFactory, withId: "suamusica/pre_roll_view")
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
                        
                        if (self.screen.status == .unlocked) {
                            if (Network.reachability.isReachable) {
                                print("Screen is unlocked and ready to show ads | ppID: \(ppID ?? "N/A") | all args: \(args)")
                                adsViewController!.setup(
                                    channel: SwiftSmadsPlugin.channel,
                                    adUrl: adUrl,
                                    contentUrl: contentUrl,
                                    screen: self.screen,
                                    args: args)
                                adsViewController!.ppID = ppID

                                print("Registering would view factory - registrarAds: \(String(describing: SwiftSmadsPlugin.registrarAds)) at \(Date())")

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
        case "play":
            print("Playing ads")
            print("Ads view controller: \(AdsViewController.self)")
//            let savedArgsFromController = adsViewController.args
            print("Saved args from controller: \(String(describing: adsViewController?.args))")
            print("View factory registered")

            result(1)
        case "pause":
            adsViewController!.pause()
            result(1)
        case "dispose":
            adsViewController!.dispose()
            result(1)
        case "skip":
            adsViewController!.skip()
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

private let tag:String = "FLNativeViewFactory"
class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var controller: AdsViewController
    
    init(messenger: FlutterBinaryMessenger, controller:AdsViewController) {
        self.messenger = messenger
        self.controller = controller
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,
            controller: controller)
    }
}

class FLNativeView: NSObject, FlutterPlatformView {
    private var controller: AdsViewController

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?,
        controller:AdsViewController
    ) {
        self.controller = controller
        super.init()
    }

    func view() -> UIView {
        return controller.view
    }
}
