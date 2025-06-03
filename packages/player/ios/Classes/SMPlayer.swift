import Foundation
import AVFoundation

private var playlistItemKey: UInt8 = 0
var currentRepeatmode: AVQueuePlayer.RepeatMode = .REPEAT_MODE_OFF
public class SMPlayer : NSObject  {
    var methodChannelManager: MethodChannelManager?
    private var cookie: String = ""
    //Queue handle
    private var smPlayer: AVQueuePlayer
    var queueManager: QueueManager
    private var listeners: SMPlayerListeners? = nil
    // Transition Control
    var areNotificationCommandsEnabled: Bool = true
    
    private var notificationManager: NotificationManager!
    private var nowPlayingInfoManager: NowPlayingInfoManager!
    
    private enum Constants {
        static let maxTotalItems = 5
        static let defaultTimescale: CMTimeScale = 60000
    }
    
    var fullQueue: [PlaylistItem] {
        return queueManager.fullQueue
    }
    
    var currentIndex : Int {
        return queueManager.currentIndex
    }
    
    init(methodChannelManager: MethodChannelManager?) {
        smPlayer = AVQueuePlayer()
        queueManager = QueueManager(smPlayer: smPlayer, maxTotalItems: Constants.maxTotalItems)
        
        super.init()
        nowPlayingInfoManager = NowPlayingInfoManager()
        notificationManager = NotificationManager(target: self)
        self.methodChannelManager = methodChannelManager
        listeners = SMPlayerListeners(smPlayer:smPlayer,methodChannelManager:methodChannelManager)
        notificationManager.addAudioInterruptionObserver(selector: #selector(handleInterruption(_:)))
        listeners?.onMediaChanged = { [weak self] shouldNotify in
            guard let self = self else { return }
            guard self.smPlayer.items().count > 0 else { return }

            let isNotFirstItem = self.smPlayer.currentItem != self.fullQueue.first
            let hasHistory = self.queueManager.historyQueue.count > 0

            if isNotFirstItem && hasHistory && shouldNotify {
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.itemTransition)
            }

            self.updateEndPlaybackObserver()
            self.listeners?.addItemsObservers()
            self.methodChannelManager?.currentMediaIndex(index: self.currentIndex)
        }
        nowPlayingInfoManager.setupNowPlayingInfoCenter(
            areNotificationCommandsEnabled: { [weak self] in self?.areNotificationCommandsEnabled ?? true },
            play: { [weak self] in self?.play() },
            pause: { [weak self] in self?.pause() },
            nextTrack: { [weak self] in self?.queueManager.nextTrack(from: "commandCenter.nextTrackCommand") },
            previousTrack: { [weak self] in self?.queueManager.previousTrack() },
            seekToPosition: { [weak self] pos in self?.seekToPosition(position: pos) }
        )
        _ = AudioSessionManager.activeSession()
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        @unknown default:
            break
        }
    }
    
    func pause() {
        smPlayer.pause()
    }
    
    func addEndPlaybackObserver() {
        guard let currentItem = smPlayer.currentItem else { return }
        notificationManager.addEndPlaybackObserver(selector: #selector(itemDidFinishPlaying(_:)), for: currentItem)
    }
    
    func removeEndPlaybackObserver() {
        if let currentItem = smPlayer.currentItem {
            notificationManager.removeEndPlaybackObserver(for: currentItem)
        }
    }
    
    func updateEndPlaybackObserver() {
        removeEndPlaybackObserver()
        addEndPlaybackObserver()
    }
    
    func disableRepeatMode() {
        smPlayer.repeatMode = .REPEAT_MODE_OFF
        methodChannelManager?.repeatModeChanged(repeatMode: smPlayer.repeatModeIndex)
    }
    
    
    func toggleRepeatMode() {
        switch smPlayer.repeatMode {
        case .REPEAT_MODE_OFF:
            smPlayer.repeatMode = .REPEAT_MODE_ALL
        case .REPEAT_MODE_ALL:
            smPlayer.repeatMode = .REPEAT_MODE_ONE
        case .REPEAT_MODE_ONE:
            smPlayer.repeatMode = .REPEAT_MODE_OFF
        }
        methodChannelManager?.repeatModeChanged(repeatMode: smPlayer.repeatModeIndex)
    }
    
    
    func stop() {
        smPlayer.pause()
        smPlayer.replaceCurrentItem(with: nil)
        clearNowPlayingInfo()
        methodChannelManager?.notifyPlayerStateChange(state: PlayerState.idle)
    }
    
    func clearNowPlayingInfo() {
        nowPlayingInfoManager.clearNowPlayingInfo()
    }
    
    func enqueue(medias: [PlaylistItem], autoPlay: Bool, cookie: String) {
        guard let message = MessageBuffer.shared.receive() else { return }
        if(!cookie.isEmpty){
            self.cookie = cookie
        }
        let isFirstBatch = self.smPlayer.items().count == 0
        for media in message {
            media.cookie = cookie
                queueManager.enqueue(item: media)
        }
        queueManager.insertIntoPlayerIfNeeded()
        if autoPlay && isFirstBatch {
            self.smPlayer.play()
            self.setNowPlaying()
        }
        self.enableCommands()
        listeners?.addPlayerObservers()
    }
    
    func toggleShuffle(positionsList: [[String: Int]]) {
        queueManager.toggleShuffle(positionsList: positionsList)
        methodChannelManager?.shuffleChanged(shuffleIsActive: queueManager.isShuffleModeEnabled)
    }
    
    func setNowPlaying(){
        NowPlayingCenter.set(item: queueManager.getCurrentPlaylistItem())
    }
    
    
    func removeAll(){
        queueManager.removeAll()
        methodChannelManager?.notifyPlayerStateChange(state:PlayerState.idle)
    }
    
    func removeNotification(){
        nowPlayingInfoManager.removeNotification()
    }
    
    func play(){
        smPlayer.play()
    }
    
    func seekToPosition(position:Int){
        let positionInSec = CMTime(seconds: Double(position/1000), preferredTimescale: Constants.defaultTimescale)
        smPlayer.currentItem?.seek(to: positionInSec, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { completed in
            if completed {
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.seekEnd)
            }
        } )
    }
    
    func enableCommands(){
        nowPlayingInfoManager.enableCommands()
    }
    
    //override automatic next
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        pause()
        switch smPlayer.repeatMode {
        case .REPEAT_MODE_ALL:
            if(smPlayer.currentItem == fullQueue.last){
                queueManager.playFromQueue(position: 0)
                break
            }
            queueManager.nextTrack(from:"REPEAT_MODE_ALL")
        case .REPEAT_MODE_ONE:
            seekToPosition(position: 0)
        case .REPEAT_MODE_OFF:
            queueManager.nextTrack(from: "REPEAT_MODE_OFF")
        }
        play()
    }
    
    private func removeAllObservers() {
        notificationManager.removeAllObservers()
        // Remover outros observadores
    }
    
    private func notifyMediaChangedIfNeeded() {
        let isNotFirstItem = smPlayer.currentItem != fullQueue.first
        let hasHistory = queueManager.historyQueue.count > 0

        if isNotFirstItem && hasHistory {
            methodChannelManager?.notifyPlayerStateChange(state: PlayerState.itemTransition)
        }
    }
}

extension AVPlayerItem {
    var playlistItem: PlaylistItem? {
        get {
            return objc_getAssociatedObject(self, &playlistItemKey) as? PlaylistItem
        }
        set {
            objc_setAssociatedObject(self, &playlistItemKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public extension AVQueuePlayer {
    enum RepeatMode: Int,CaseIterable {
        case REPEAT_MODE_OFF
        case REPEAT_MODE_ONE
        case REPEAT_MODE_ALL
    }
    
    var repeatMode: RepeatMode {
        get {
            return currentRepeatmode
        }
        set(mode) {
            
            currentRepeatmode = mode
            
            switch mode {
            case .REPEAT_MODE_OFF:
                actionAtItemEnd = .none
            case .REPEAT_MODE_ALL:
                actionAtItemEnd = .pause
            default:
                actionAtItemEnd = .pause
            }
        }
        
    }
    
    var repeatModeIndex: Int {
        return RepeatMode.allCases.firstIndex(of: repeatMode) ?? -1
    }
    
}
