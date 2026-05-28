import Foundation
import SystemConfiguration
import MediaPlayer

struct NotificationName {
    // Listen to CFNotification, and convert to Notification
    public static let lockComplete = Notification.Name("NotificationName.lockComplete")
    public static let lockState = Notification.Name("NotificationName.lockState")

    // Handle lockComplete and lockState Notification to post locked or unlocked notification.
    public static let locked = Notification.Name("NotificationName.locked")
    public static let unlocked = Notification.Name("NotificationName.unlocked")
}

enum Status: String {
    case unlocked, locked
}

@objc public class ScreenCenter : NSObject {
    @objc public static func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(notification:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil);
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(notification:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil);
    }

    @objc static func applicationDidBecomeActive(notification: NSNotification) {
        print("Player: ScreenCenter: setting status as unlocked")
        status = .unlocked
    }

    @objc static func applicationDidEnterBackground(notification: NSNotification) {
        print("Player: ScreenCenter: setting status as locked")
        status = .locked
    }
    
    @objc public static func isUnlocked() -> Bool {
        print("Player: ScreenCenter: check status \(status)")
        return status == .unlocked
    }

    static var status: Status = .unlocked
}
