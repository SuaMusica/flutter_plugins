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
        let lockCompleteString = "com.apple.springboard.lockcomplete"
        let lockString = "com.apple.springboard.lockstate"

        // Listen to CFNotification, post Notification accordingly.
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        nil,
                                        { (_, _, _, _, _) in
                                            NotificationCenter.default.post(name: NotificationName.lockComplete, object: nil)
                                        },
                                        lockCompleteString as CFString,
                                        nil,
                                        CFNotificationSuspensionBehavior.deliverImmediately)

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        nil,
                                        { (_, _, _, _, _) in
                                            NotificationCenter.default.post(name: NotificationName.lockState, object: nil)
                                        },
                                        lockString as CFString,
                                        nil,
                                        CFNotificationSuspensionBehavior.deliverImmediately)

        // Listen to Notification and handle.
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(onLockComplete),
                                                name: NotificationName.lockComplete,
                                                object: nil)

        NotificationCenter.default.addObserver(self,
                                                selector: #selector(onLockState),
                                                name: NotificationName.lockState,
                                                object: nil)
    }
    
    // nil means don't know; ture or false means we did or did not received such notification.
    var receiveLockStateNotification: Bool? = nil
    // when we received lockState notification, use timer to wait 0.3s for the lockComplete notification.
    var waitForLockCompleteNotificationTimer: Timer? = nil
    var receiveLockCompleteNotification: Bool? = nil
    var status: Status = .unlocked

    // When we received lockComplete notification, invalidate timer and refresh lock status.
    @objc
    func onLockComplete() {
        if let timer = waitForLockCompleteNotificationTimer {
            timer.invalidate()
            waitForLockCompleteNotificationTimer = nil
        }

        receiveLockCompleteNotification = true
        changeIsLockedIfNeeded()
    }

    // When we received lockState notification, refresh lock status.
    @objc
    func onLockState() {
        receiveLockStateNotification = true
        changeIsLockedIfNeeded()
    }

    func changeIsLockedIfNeeded() {
        guard let state = receiveLockStateNotification, state else {
            // If we don't receive lockState notification, return.
            return
        }

        guard let complete = receiveLockCompleteNotification else {
            // If we don't receive lockComplete notification, wait 0.3s.
            // If nothing happens in 0.3s, then make sure we don't receive lockComplete, and refresh lock status.
            
            if #available(iOS 10.0, *) {
                waitForLockCompleteNotificationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in
                    self.receiveLockCompleteNotification = false
                    self.changeIsLockedIfNeeded()
                })
            } else {
                // Fallback on earlier versions
            }
            return
        }
        
        let oldStat = self.status
        self.status = complete ? Status.locked : Status.unlocked
        
        print("Screen status changed from \(oldStat) to \(self.status)" )
        
        // When we determined lockState and lockComplete notification is received or not.
        // We can update the device lock status by 'complete' value.
        NotificationCenter.default.post(
            name: complete ? NotificationName.locked : NotificationName.unlocked,
            object: nil
        )

        // Reset status.
        receiveLockStateNotification = nil
        receiveLockCompleteNotification = nil
    }
}
