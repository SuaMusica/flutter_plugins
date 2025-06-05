import Foundation
import AVFoundation

public class SMPlayerListeners: NSObject {
    let smPlayer: AVQueuePlayer
    weak var methodChannelManager: MethodChannelManager?
    
    var onMediaChanged: ((Bool) -> Void)?
    private var itemObservations = Set<NSKeyValueObservation>()
    private var playerObservations = Set<NSKeyValueObservation>()
    private var periodicTimeObserver: Any?
    private var notificationObservers = [NSObjectProtocol]()
    
    private var lastState = PlayerState.idle
    private var lastNotificationTime = Date()
    private let notificationThrottleInterval: TimeInterval = 0.1
    
    private let positionUpdateInterval: TimeInterval = 0.8
    
    init(smPlayer: AVQueuePlayer, methodChannelManager: MethodChannelManager?) {
        self.smPlayer = smPlayer
        self.methodChannelManager = methodChannelManager
        super.init()
        addPlayerObservers()
        addItemsObservers()
    }
    
    func addItemsObservers() {
        cleanupItemObservers()
        guard let currentItem = smPlayer.currentItem else { return }
        
        let statusObservation = currentItem.observe(
            \AVPlayerItem.status,
            options: [.new, .initial]
        ) { [weak self] playerItem, _ in
            switch playerItem.status {
            case .failed:
                let errorMessage = playerItem.error?.localizedDescription ?? "Unknown playback error"
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] ERROR: \(errorMessage)")
                self?.methodChannelManager?.notifyError(error: errorMessage)
            case .readyToPlay:
                self?.notifyPlayerStateChange(state: .stateReady)
            case .unknown:
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Player status unknown")
            @unknown default:
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Player status unknown default")
            }
        }
        itemObservations.insert(statusObservation)
        
        let bufferEmptyObservation = currentItem.observe(
            \AVPlayerItem.isPlaybackBufferEmpty,
            options: [.new]
        ) { [weak self] _, change in
            if change.newValue == true {
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Buffering (buffer empty)")
                self?.notifyPlayerStateChange(state: .buffering)
            }
        }
        itemObservations.insert(bufferEmptyObservation)
        
        let bufferKeepUpObservation = currentItem.observe(
            \AVPlayerItem.isPlaybackLikelyToKeepUp,
            options: [.new]
        ) { _, change in
            if change.newValue == true {
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Buffer ready (likely to keep up)")
            }
        }
        itemObservations.insert(bufferKeepUpObservation)
        
        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: currentItem,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Player Item Error: \(error.localizedDescription)")
                self?.methodChannelManager?.notifyError(error: error.localizedDescription)
            }
        }
        notificationObservers.append(observer)
    }
    
    func notifyPlayerStateChange(state: PlayerState) {
        let now = Date()
        guard lastState != state && (now.timeIntervalSince(lastNotificationTime) >= notificationThrottleInterval || lastState != state) else { 
            return 
        }
        
        lastNotificationTime = now
        methodChannelManager?.notifyPlayerStateChange(state: state)
        lastState = state
    }
    
    func addMediaChangeObserver() {
        let mediaChangeObservation = smPlayer.observe(
            \AVQueuePlayer.currentItem,
            options: [.new, .old]
        ) { [weak self] _, change in
            if let newItem = change.newValue, newItem != change.oldValue {
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Media changed")
                self?.onMediaChanged?(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.addItemsObservers()
                }
            }
        }
        playerObservations.insert(mediaChangeObservation)
    }
    
    func addPlayerObservers() {
        addMediaChangeObserver()
        addPeriodicTimeObserver()
        
        let reasonObservation = smPlayer.observe(
            \AVQueuePlayer.reasonForWaitingToPlay,
            options: [.new]
        ) { player, _ in
            if let reason = player.reasonForWaitingToPlay {
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Waiting reason: \(String(describing: reason))")
            }
        }
        playerObservations.insert(reasonObservation)
        
        let playbackObservation = smPlayer.observe(
            \AVQueuePlayer.timeControlStatus,
            options: [.new, .old]
        ) { [weak self] player, _ in
            switch player.timeControlStatus {
            case .playing:
                self?.notifyPlayerStateChange(state: .playing)
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Playing")
            case .paused:
                self?.notifyPlayerStateChange(state: .paused)
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Paused")
            case .waitingToPlayAtSpecifiedRate:
                self?.notifyPlayerStateChange(state: .buffering)
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Buffering")
            @unknown default:
                Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Unknown time control status")
            }
        }
        playerObservations.insert(playbackObservation)
    }
    
    private func addPeriodicTimeObserver() {
        removePeriodicTimeObserver()
        
        let interval = CMTime(seconds: positionUpdateInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        periodicTimeObserver = smPlayer.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] _ in
            self?.handlePeriodicTimeUpdate()
        }
    }
    
    private func handlePeriodicTimeUpdate() {
        let position = CMTimeGetSeconds(smPlayer.currentTime())
        
        guard let currentItem = smPlayer.currentItem else { return }
        let duration = CMTimeGetSeconds(currentItem.duration)
        
        guard duration.isFinite && duration > 0 && position.isFinite && position >= 0 && position <= duration else {
            return
        }
        
        methodChannelManager?.notifyPositionChange(position: position, duration: duration)
        
        if let playlistItem = currentItem.playlistItem {
            NowPlayingCenter.update(item: playlistItem, rate: 1.0, position: position, duration: duration)
        }
    }
    
    private func removePeriodicTimeObserver() {
        if let observer = periodicTimeObserver {
            smPlayer.removeTimeObserver(observer)
            periodicTimeObserver = nil
        }
    }
    
    private func cleanupItemObservers() {
        itemObservations.forEach { $0.invalidate() }
        itemObservations.removeAll()
        cleanupNotificationObservers()
    }
    
    private func cleanupNotificationObservers() {
        notificationObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
    
    func removePlayerObservers() {
        playerObservations.forEach { $0.invalidate() }
        playerObservations.removeAll()
        removePeriodicTimeObserver()
        cleanupItemObservers()
    }
    
    deinit {
        removePlayerObservers()
        Logger.debugLog("#NATIVE LOGS ==> [SMPlayerListeners] Deinitializing")
    }
}

