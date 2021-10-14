
import Foundation

protocol Observer {
    func start()
    func stop()
}

@objc public protocol ObserverCenter {
    func start()
    func stop()
}

@objc public class ObserverCenterImpl: NSObject, ObserverCenter {
    let observers: Array<Observer>
    
    init(observers: Array<Observer>) {
        self.observers = observers
    }
    
    public func start() {
        for observer in self.observers {
            observer.start()
        }
    }
    
    public func stop() {
        for observer in self.observers {
            observer.stop()
        }
    }
}


@objc public class ObserverCenterFactory: NSObject {
    @objc public static let shared = ObserverCenterFactory()
    
    private override init() {
    }
    
    @objc public func create(player: Player) -> ObserverCenter {
        return ObserverCenterImpl(observers: [
            PeriodicTimeObserver(player: player)
        ])
    }
}
