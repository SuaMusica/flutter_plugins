import Foundation
import AVFoundation

public class SMPlayerListeners : NSObject {
    let smPlayer: AVQueuePlayer
    let methodChannelManager: MethodChannelManager?
    
    var onMediaChanged: (() -> Void)?
    
    init(smPlayer: AVQueuePlayer, methodChannelManager: MethodChannelManager?) {
        self.smPlayer = smPlayer
        self.methodChannelManager = methodChannelManager
        super.init()
        addPlayerObservers()
    }
    
    var mediaChange: NSKeyValueObservation?
    private var statusChange: NSKeyValueObservation?
    private var loading: NSKeyValueObservation?
    private var loaded: NSKeyValueObservation?
    private var error: NSKeyValueObservation?
    private var notPlayingReason: NSKeyValueObservation?
    private var playback: NSKeyValueObservation?
    
    
    func addItemsObservers() {
        removeItemObservers()
        guard let currentItem = smPlayer.currentItem else { return }
        statusChange = currentItem.observe(\.status, options: [.new, .old]) { (playerItem, change) in
            if playerItem.status == .failed {
               if let error = playerItem.error {
                    print("#NATIVE LOGS ==> ERROR: \(String(describing: playerItem.error))")
                    self.methodChannelManager?.notifyError(error: "UNKNOW ERROR")
                }
            }
        }

        loading = currentItem.observe(\.isPlaybackBufferEmpty, options: [.new, .old]) { [weak self] (new, old) in
            guard let self = self else { return }
            print("#NATIVE LOGS ==> Listeners - observer - loading")
            self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.buffering)
        }
        
        loaded = currentItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { (player, _) in
            print("#NATIVE LOGS ==> Listeners - observer - loaded")
        }
    }
    

    func addMediaChangeObserver(){
        mediaChange = smPlayer.observe(\.currentItem, options: [.new, .old]) { [weak self] (player, change) in
            guard let self = self else { return }
            let oldItemExists = change.oldValue != nil
            print("#NATIVE LOGS ==> onMediaChanged: \(oldItemExists)")
            
            if let newItem = change.newValue, newItem != change.oldValue {
                self.onMediaChanged?()
                self.addItemsObservers()
            }
        }
    }
    func addPlayerObservers() {
        addMediaChangeObserver()
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        smPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let position: Float64 = CMTimeGetSeconds(self.smPlayer.currentTime())
            if let currentItem = self.smPlayer.currentItem {
                let duration: Float64 = CMTimeGetSeconds(currentItem.duration)
                if position < duration {
                    self.methodChannelManager?.notifyPositionChange(position: position, duration: duration)
                    NowPlayingCenter.update(item: currentItem.playlistItem, rate: 1.0, position: position, duration: duration)
                }
            }
        }
        
        notPlayingReason = smPlayer.observe(\.reasonForWaitingToPlay, options: [.new]) { (playerItem, change) in
            switch self.smPlayer.reasonForWaitingToPlay {
            case .evaluatingBufferingRate:
                print("#NATIVE LOGS ==> Listeners reasonForWaitingToPlay - evaluatingBufferingRate")
            case .toMinimizeStalls:
                print("#NATIVE LOGS ==> Listeners reasonForWaitingToPlay - toMinimizeStalls")
            case .noItemToPlay:
                print("#NATIVE LOGS ==> Listeners reasonForWaitingToPlay - noItemToPlay")
            default:
                print("#NATIVE LOGS ==> Listeners reasonForWaitingToPlay - default")
            }
        }
        
        playback = smPlayer.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] (player, change) in
            guard let self = self else { return }
            switch player.timeControlStatus {
            case .playing:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.playing)
                print("#NATIVE LOGS ==> Listeners - Playing")
            case .paused:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.paused)
                print("#NATIVE LOGS ==> Listeners - Paused")
            case .waitingToPlayAtSpecifiedRate:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.buffering)
                print("#NATIVE LOGS ==> Listeners - Buffering")
            @unknown default:
                break
            }
        }
    }
    
    func removeItemObservers() {
        statusChange?.invalidate()
        loading?.invalidate()
        loaded?.invalidate()
        
        statusChange = nil
        loading = nil
        loaded = nil
        
        removeErrorObserver()
    }
    
    func removeErrorObserver() {
        if let currentItem = smPlayer.currentItem {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemFailedToPlayToEndTime,
                object: currentItem
            )
        }
    }
    

    func removePlayerObservers() {
        notPlayingReason?.invalidate()
        playback?.invalidate()
        mediaChange?.invalidate()
        mediaChange = nil
        notPlayingReason = nil
        playback = nil
    }
    
    deinit {
        removePlayerObservers()
        removeItemObservers()
    }
}
