import Flutter
import UIKit

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
