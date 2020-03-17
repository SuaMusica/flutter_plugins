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

class Screen {
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AdsViewController.applicationDidBecomeActive(notification:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil);

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AdsViewController.applicationDidEnterBackground(notification:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil);
    }

    @objc func applicationDidBecomeActive(notification: NSNotification) {
        self.status = .unlocked
    }

    @objc func applicationDidEnterBackground(notification: NSNotification) {
        self.status = .locked
    }

    var status: Status = .unlocked
}
