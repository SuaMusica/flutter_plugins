import Flutter
import UIKit

struct GlobalConstants {
    static let CHANNEL_NAME = "suamusica/pre_roll"
    static let VIEW_TYPE_ID = "suamusica/pre_roll_view"
    
    static let LOAD_METHOD = "load"
    static let PLAY_METHOD = "play"
    static let PAUSE_METHOD = "pause"
    static let DISPOSE_METHOD = "dispose"
    static let SKIP_METHOD = "skip"
    static let SCREEN_STATUS_METHOD = "screen_status"
    static let UnlockedScreen = 1
    static let LockedScreen = 0
}

public class SwiftSmadsPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel?
    private var screen: Screen
    private var controller: AdsViewController
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: GlobalConstants.CHANNEL_NAME, binaryMessenger: registrar.messenger())
        let callback = SmadsCallback(channel: channel)
        let controller = AdsViewController(callback: callback)
        let instance = SwiftSmadsPlugin(channel: channel,controller: controller)
        
        registrar.addMethodCallDelegate(instance, channel:channel)
        let viewFactory = FLNativeViewFactory(messenger: registrar.messenger(),controller:controller)
        registrar.register(viewFactory, withId: GlobalConstants.VIEW_TYPE_ID)
        
    }
    
    init(channel: FlutterMethodChannel, controller: AdsViewController) {
        SwiftSmadsPlugin.channel = channel
        self.screen = Screen()
        self.screen.addNotificationObservers()
        self.controller = controller
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("AD: Called method:: \(call.method)")
        
        switch call.method {
        case GlobalConstants.LOAD_METHOD:
            DispatchQueue.main.async {
                do {
                    try ObjC.catchException {
                        let args = call.arguments as! [String: Any]
                        print(args)
                        let adUrl = args["__URL__"] as! String
                        self.controller.load(adUrl: adUrl,
                                             args: args
                        )
                        
                        result(1)
                    }
                } catch {
                    result(0)
                    print("An error ocurred: \(error)")
                }
            }
        case GlobalConstants.SCREEN_STATUS_METHOD:
            result(self.screen.status == .unlocked ? GlobalConstants.UnlockedScreen : GlobalConstants.LockedScreen)
        case GlobalConstants.DISPOSE_METHOD:
            self.controller.dispose()
            break
        case GlobalConstants.PAUSE_METHOD:
            self.controller.pause()
            break
        case GlobalConstants.PLAY_METHOD:
            self.controller.play()
            break
            
        case GlobalConstants.SKIP_METHOD:
            self.controller.skipAd()
            break
        default:
            result(FlutterError(code: "-1", message: "Operation not supported", details: nil))
        }
    }
}
