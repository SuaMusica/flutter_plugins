import Foundation
import AFNetworking

@objc public protocol ReachabilityCenter {
    func start()
    func stop()
    func isConnected() -> Bool
}

@objc public protocol ReachabilityCenterFactory {
    func create(_ player: Player) -> ReachabilityCenter
}

@objc public enum ReachabilityStatus: Int {
    case unknown
    case connected
    case disconnected
}

// ReachabilityCenterFactory extension method which provides default implementation
extension ReachabilityCenterFactory {
    // This is the default factory method
    // Nevertheless, it can be overriden by any other factory implementation
    func create(_ player: Player) -> ReachabilityCenter {
        return AFNetworkBasedReachabilityCenter(player: player)
    }
}

// AFNetworkBasedReachabilityCenter defines uses the AFNetworkReachabilityManager component to implement the
// ReachabilityCenter protocol and invoke the reachbility callback when the reachability status changes
@objc public class AFNetworkBasedReachabilityCenter: NSObject, ReachabilityCenter {
    var player: Player
    
    var connected = true
    
    init(player: Player) {
        self.player = player
    }
    
    public func isConnected() -> Bool {
        return self.connected
    }
    
    public func start() {
        AFNetworkReachabilityManager.shared().setReachabilityStatusChange { status in
            var networkStatus: String = "UNKNOWN"
            
            switch (status) {
            case .unknown, .notReachable:
                self.connected = false;
                networkStatus = "DISCONNECTED";
                print("AFNetworkBasedReachabilityCenter \(networkStatus)")
                break
            case .reachableViaWWAN, .reachableViaWiFi:
                self.connected = true;
                networkStatus = "CONNECTED";
                print("AFNetworkBasedReachabilityCenter \(networkStatus)")
                if (self.player.failedToStartPlaying()) {
                    // we did not even manage to start playing
                    // or in this case download the .m3u8 file
                    // so let's try everything again
                    self.player.playLast()
                } else if (self.player.stopTryingToReconnect()) {
                    // we manage to start playing
                    // the AVPlayer retried several times
                    // but it stoped
                    self.player.playLast()
                }
                break
            @unknown default:
                print("unknown status")
            }
            
            if (self.player.shallSendEvents()) {
                self.player.invokeMethod("network.onChange", arguments: ["status": networkStatus])
            }
        }
        AFNetworkReachabilityManager.shared().startMonitoring()
    }
    
    public func stop() {
        AFNetworkReachabilityManager.shared().stopMonitoring()
    }
}

// AFNetworkBasedReachabilityCenterFactory defines a simple factory for creating a AFNetworkBasedReachbilityCenter
@objc public class AFNetworkBasedReachabilityCenterFactory: NSObject, ReachabilityCenterFactory {
    @objc public static let shared = AFNetworkBasedReachabilityCenterFactory()
    
    private override init() {
    }
    
    public func create(_ player: Player) -> ReachabilityCenter {
        return AFNetworkBasedReachabilityCenter(player: player)
    }
}
