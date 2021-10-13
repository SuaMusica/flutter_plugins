import Foundation

@objc public protocol Player {
    var STATE_IDLE: Int { get }
    var STATE_BUFFERING: Int { get }
    var STATE_PLAYING: Int { get }
    var STATE_PAUSED: Int { get }
    var STATE_STOPPED: Int { get }
    var STATE_COMPLETED: Int { get }
    var STATE_ERROR: Int { get }
    var STATE_SEEK_END: Int { get }
    var STATE_BUFFER_EMPTY: Int { get }
    
    func pause() -> Int
    func resume() -> Int
    func rate() -> Float
    func notifyStateChange(_: Int, overrideBlock: Bool)
    func invokeMethod(_: String, arguments: NSDictionary)
    func isNotificationCommandEnabled() -> Bool
    func failedToStartPlaying() -> Bool
    func stopTryingToReconnect() -> Bool
    func shallSendEvents() -> Bool
    func playLast()
}

extension Player {
    var STATE_IDLE: Int { return 0 }
    var STATE_BUFFERING: Int { return 1 }
    var STATE_PLAYING: Int { return 2 }
    var STATE_PAUSED: Int { return 3 }
    var STATE_STOPPED: Int { return 4 }
    var STATE_COMPLETED: Int { return 5 }
    var STATE_ERROR: Int { return 6 }
    var STATE_SEEK_END: Int { return 7 }
    var STATE_BUFFER_EMPTY: Int { return 8 }
}
