import UIKit
import Flutter
//import AdsViewController

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
//    let registrar = self.registrar(forPlugin: "SmadsPlugin")
//    let viewFactory = FLNativeViewFactory(messenger: registrar?.messenger(), controller: self)
//    registrar.register(viewFactory, withId: "suamusica/pre_roll_view")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
//
//class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
//    private var messenger: FlutterBinaryMessenger
//    private var controller: AdsViewController
//    
//    init(messenger: FlutterBinaryMessenger, controller:AdsViewController) {
//        self.messenger = messenger
//        self.controller = controller
//        super.init()
//    }
//    
//    func create(
//        withFrame frame: CGRect,
//        viewIdentifier viewId: Int64,
//        arguments args: Any?
//    ) -> FlutterPlatformView {
//        return FLNativeView(
//            frame: frame,
//            viewIdentifier: viewId,
//            arguments: args,
//            binaryMessenger: messenger,
//            controller: controller)
//    }
//}
//
//class FLNativeView: NSObject, FlutterPlatformView {
//    private var controller: AdsViewController
//
//    init(
//        frame: CGRect,
//        viewIdentifier viewId: Int64,
//        arguments args: Any?,
//        binaryMessenger messenger: FlutterBinaryMessenger?,
//        controller:AdsViewController
//    ) {
//        self.controller = controller
//        super.init()
//    }
//
//    func view() -> UIView {
//        return controller.view
//    }
//}
