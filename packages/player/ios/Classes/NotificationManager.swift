import Foundation
import AVFoundation

class NotificationManager {
    private weak var target: AnyObject?
    
    init(target: AnyObject) {
        self.target = target
    }
    
    func addAudioInterruptionObserver(selector: Selector) {
        NotificationCenter.default.addObserver(
            target as Any,
            selector: selector,
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    func addEndPlaybackObserver(selector: Selector, for item: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            target as Any,
            selector: selector,
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }
    
    func removeEndPlaybackObserver(for item: AVPlayerItem) {
        NotificationCenter.default.removeObserver(
            target as Any,
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }
    
    func removeAllObservers() {
        NotificationCenter.default.removeObserver(target as Any)
    }
} 