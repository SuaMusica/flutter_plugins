import AVFoundation

// Gerenciador de repetição
public final class RepeatManager: NSObject {
    weak var player: AVQueuePlayer?
    
    var mode: AVQueuePlayer.RepeatMode = .REPEAT_MODE_OFF
    
    init(player: AVQueuePlayer) {
        self.player = player
        super.init()
        
        startObservingCurrentItem(of: player)
        if let playerItem = player.currentItem {
            startObservingNotifications(of: playerItem)
        }
    }
    
    deinit {
        guard let player = player else {
            return
        }
        
        stopObservingCurrentItem(of: player)
        if let playerItem = player.currentItem {
            stopObservingNotifications(of: playerItem)
        }
    }
    
    func startObservingCurrentItem(of player: AVPlayer) {
        player.addObserver(self, forKeyPath: "currentItem", options: [.old, .new], context: nil)
    }
    
    func stopObservingCurrentItem(of player: AVPlayer) {
        player.removeObserver(self, forKeyPath: "currentItem")
    }
    
    func startObservingNotifications(of playerItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleItemDidPlayToEnd(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    func stopObservingNotifications(of playerItem: AVPlayerItem) {
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    @objc func handleItemDidPlayToEnd(notification: Notification) {
        guard let player = player, let currentItem = player.currentItem, currentItem == notification.object as? AVPlayerItem else {
            return
        }
        
        switch mode {
        case .REPEAT_MODE_ALL:
            player.advanceToNextItem()
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            player.insert(currentItem, after: nil)
        case .REPEAT_MODE_ONE:
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        default:
            break
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem", let player = object as? AVPlayer {
            if let oldItem = change?[.oldKey] as? AVPlayerItem {
                stopObservingNotifications(of: oldItem)
            }
            if let newItem = change?[.newKey] as? AVPlayerItem {
                startObservingNotifications(of: newItem)
            }
        }
    }
}


