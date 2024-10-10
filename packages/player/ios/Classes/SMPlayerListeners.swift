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
    
    private var mediaChange: NSKeyValueObservation?
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
            if playerItem.status == .readyToPlay {
                print("#Listeners - readyToPlay")
            } else if playerItem.status == .failed {
                if let error = playerItem.error {
                    print("#Listeners notifyError \(error.localizedDescription)")
                    if let fallbackUrl = playerItem.playlistItem?.fallbackUrl  {
                        let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": ["Cookie": playerItem.playlistItem?.cookie ?? ""]]
                        let fallbackItem = AVPlayerItem(asset: AVURLAsset(url: URL(string: fallbackUrl)! , options: assetOptions))
                        
                        self.smPlayer.replaceCurrentItem(with: fallbackItem)
                    } else {
                        self.methodChannelManager?.notifyError(error: "NO FALLBACK")
                    }
                } else {
                    self.methodChannelManager?.notifyError(error: "UNKNOW ERROR")
                }
            }
        }

        loading = currentItem.observe(\.isPlaybackBufferEmpty, options: [.new, .old]) { [weak self] (new, old) in
            guard let self = self else { return }
            print("#Listeners - observer - loading")
            self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.buffering)
        }
        
        loaded = currentItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { (player, _) in
            print("#Listeners - observer - loaded")
        }
    }
    

    
    func addPlayerObservers() {
        mediaChange = smPlayer.observe(\.currentItem, options: [.new, .old]) { [weak self] (player, change) in
            guard let self = self else { return }
            let oldItemExists = change.oldValue != nil
            print("onMediaChanged: \(oldItemExists)")
            
            if let newItem = change.newValue, newItem != change.oldValue {
                self.onMediaChanged?()
                self.addItemsObservers()
            }
        }
        
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
                print("#Listeners reasonForWaitingToPlay - evaluatingBufferingRate")
            case .toMinimizeStalls:
                print("#Listeners reasonForWaitingToPlay - toMinimizeStalls")
            case .noItemToPlay:
                print("#Listeners reasonForWaitingToPlay - noItemToPlay")
            default:
                print("#Listeners reasonForWaitingToPlay - default")
            }
        }
        
        playback = smPlayer.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] (player, change) in
            guard let self = self else { return }
            switch player.timeControlStatus {
            case .playing:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.playing)
                print("#Listeners - Playing")
            case .paused:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.paused)
                print("#Listeners - Paused")
            case .waitingToPlayAtSpecifiedRate:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.buffering)
                print("#Listeners - Buffering")
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
