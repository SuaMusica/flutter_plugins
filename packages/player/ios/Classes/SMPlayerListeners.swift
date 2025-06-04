import Foundation
import AVFoundation

private enum ObserverKey: String {
    case status, isPlaybackBufferEmpty, isPlaybackLikelyToKeepUp, currentItem, reasonForWaitingToPlay, timeControlStatus
}

public class SMPlayerListeners: NSObject {
    let smPlayer: AVQueuePlayer
    weak var methodChannelManager: MethodChannelManager?
    
    var onMediaChanged: ((Bool) -> Void)?
    private var itemObservations = [NSKeyValueObservation]()
    private var playerObservations = [NSKeyValueObservation]()
    private var periodicTimeObserver: Any?
    private var lastState = PlayerState.idle
    
    init(smPlayer: AVQueuePlayer, methodChannelManager: MethodChannelManager?) {
        self.smPlayer = smPlayer
        self.methodChannelManager = methodChannelManager
        super.init()
        addPlayerObservers()
    }
    
    func addItemsObservers() {
        removeItemObservers()
        guard let currentItem = smPlayer.currentItem else { return }
        
        let statusObs = currentItem.observe(\AVPlayerItem.status, options: [.new, .old]) { [weak self] playerItem, _ in
            guard let self = self else { return }
            switch playerItem.status {
            case .failed:
                if let error = playerItem.error {
                    Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] ERROR: \(error.localizedDescription)")
                    self.methodChannelManager?.notifyError(error: error.localizedDescription)
                } else {
                    self.methodChannelManager?.notifyError(error: "Unknown error")
                }
            case .readyToPlay:
                self.notifyPlayerStateChange(state: PlayerState.stateReady)
            case .unknown:
                break
            @unknown default:
                break
            }
        }
        itemObservations.append(statusObs)
        
        let loadingObs = currentItem.observe(\AVPlayerItem.isPlaybackBufferEmpty, options: [.new, .old]) { [weak self] _, _ in
            guard let self = self else { return }
            Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Buffering (isPlaybackBufferEmpty)")
            self.notifyPlayerStateChange(state: PlayerState.buffering)
        }
        itemObservations.append(loadingObs)
        
        let loadedObs = currentItem.observe(\AVPlayerItem.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] _, _ in
            guard self != nil else { return }
            Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Loaded (isPlaybackLikelyToKeepUp)")
        }
        itemObservations.append(loadedObs)
        
        addErrorObserver(for: currentItem)
    }
    
    private func addErrorObserver(for item: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerItemError(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )
    }
    
    @objc private func handlePlayerItemError(_ notification: Notification) {
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Player Item Error: \(error.localizedDescription)")
            methodChannelManager?.notifyError(error: error.localizedDescription)
        }
    }
    
    func notifyPlayerStateChange(state: PlayerState) {
        if lastState != state {
            methodChannelManager?.notifyPlayerStateChange(state: state)
            lastState = state
        }
    }
    
    func addMediaChangeObserver() {
        removeMediaChangeObserver()
        let mediaChangeObs = smPlayer.observe(\AVQueuePlayer.currentItem, options: [.new, .old]) { [weak self] _, change in
            guard let self = self else { return }
            let oldItemExists = change.oldValue != nil
            Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Media changed. Old item exists: \(oldItemExists)")
            if let newItem = change.newValue, newItem != change.oldValue {
                self.onMediaChanged?(true)
                self.addItemsObservers()
            }
        }
        playerObservations.append(mediaChangeObs)
    }
    
    func addPlayerObservers() {
        addMediaChangeObserver()
        addPeriodicTimeObserver()
        
        let notPlayingReasonObs = smPlayer.observe(\AVQueuePlayer.reasonForWaitingToPlay, options: [.new]) { [weak self] player, _ in
            guard self != nil else { return }
            switch player.reasonForWaitingToPlay {
            case .evaluatingBufferingRate:
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Reason: evaluatingBufferingRate")
            case .toMinimizeStalls:
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Reason: toMinimizeStalls")
            case .noItemToPlay:
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Reason: noItemToPlay")
            default:
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Reason: default")
            }
        }
        playerObservations.append(notPlayingReasonObs)
        
        let playbackObs = smPlayer.observe(\AVQueuePlayer.timeControlStatus, options: [.new, .old]) { [weak self] player, _ in
            guard let self = self else { return }
            switch player.timeControlStatus {
            case .playing:
                self.notifyPlayerStateChange(state: PlayerState.playing)
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Playing")
            case .paused:
                self.notifyPlayerStateChange(state: PlayerState.paused)
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Paused")
            case .waitingToPlayAtSpecifiedRate:
                self.notifyPlayerStateChange(state: PlayerState.buffering)
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Buffering")
            @unknown default:
                break
            }
        }
        playerObservations.append(playbackObs)
    }
    
    private func addPeriodicTimeObserver() {
        removePeriodicTimeObserver()
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        periodicTimeObserver = smPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            let position: Float64 = CMTimeGetSeconds(self.smPlayer.currentTime())
            if let currentItem = self.smPlayer.currentItem {
                let duration: Float64 = CMTimeGetSeconds(currentItem.duration)
                if position < duration {
                    self.methodChannelManager?.notifyPositionChange(position: position, duration: duration)
                    if let playlistItem = currentItem.playlistItem {
                        NowPlayingCenter.update(item: playlistItem, rate: 1.0, position: position, duration: duration)
                    }
                }
            }
        }
    }
    
    private func removePeriodicTimeObserver() {
        if let observer = periodicTimeObserver {
            smPlayer.removeTimeObserver(observer)
            periodicTimeObserver = nil
        }
    }
    
    func removeItemObservers() {
        itemObservations.forEach { $0.invalidate() }
        itemObservations.removeAll()
        removeErrorObserver()
    }
    
    func removeMediaChangeObserver() {
        if !playerObservations.isEmpty {
            let mediaChangeObserver = playerObservations.removeFirst()
            mediaChangeObserver.invalidate()
        }
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
    
    /// Removes all player observers.
    func removePlayerObservers() {
        playerObservations.forEach { $0.invalidate() }
        playerObservations.removeAll()
        removePeriodicTimeObserver()
        removeItemObservers()
    }
    
    deinit {
        removePlayerObservers()
    }
}

