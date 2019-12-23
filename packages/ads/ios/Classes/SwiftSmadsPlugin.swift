import Flutter
import UIKit

public class SwiftSmadsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "smads", binaryMessenger: registrar.messenger())
    let instance = SwiftSmadsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == "load") {
      DispatchQueue.main.async {
//        let flutterViewController = FlutterViewController()
//        let uiNavigationController = UINavigationController(rootViewController: flutterViewController)
//        uiNavigationController.setNavigationBarHidden(true, animated: false)
//        let window = UIWindow.init(frame: UIScreen.main.bounds)
//        window.rootViewController = uiNavigationController
//        window.makeKeyAndVisible()
//        uiNavigationController.present(UIViewController.init(), animated: false, completion: nil)
        
        
        //        let storyBoard: UIStoryboard = UIStoryboard.init(name: "Main", bundle: nil)
        //        print(storyBoard.description)
        //        let adsViewController = storyBoard.instantiateViewController(withIdentifier: "adsViewController") as! UIViewController
        //rootViewController.present(adsViewController, animated: true, completion: nil)
        do {
            try ObjC.catchException {
                print("HERE 1")
                let storyBoard: UIStoryboard = UIStoryboard.init(name: "iPhone", bundle: nil)
                print("HERE 2")
                let adsViewController = storyBoard.instantiateViewController(withIdentifier: "adsViewController") as! UIViewController
                print("HERE 3")
                let rootViewController = UIApplication.shared.keyWindow?.rootViewController
                print("HERE 4")
                rootViewController?.present(adsViewController, animated: false, completion: nil)
                print("HERE 5")
            }
        }
        catch {
            print("An error ocurred: \(error)")
        }
      }
    }
    else if (call.method == "play") {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Alert", message: "Playing...", preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil);
        }
    }
  }
}
