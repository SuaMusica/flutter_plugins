import Foundation
import AVFoundation

private var playlistItemKey: UInt8 = 0
var currentRepeatmode: AVQueuePlayer.RepeatMode = .REPEAT_MODE_OFF
public class SMPlayer : NSObject  {
    var methodChannelManager: MethodChannelManager?
    private var cookie: String = ""
    //Queue handle
    private var smPlayer: AVQueuePlayer
    private var queueManager: QueueManager
    private var listeners: SMPlayerListeners? = nil
    // Transition Control
    private var shouldNotifyTransition: Bool = true
    var areNotificationCommandsEnabled: Bool = true
    
    private var notificationManager: NotificationManager!
    private var nowPlayingInfoManager: NowPlayingInfoManager!
    
    private enum Constants {
        static let maxTotalItems = 5
        static let defaultTimescale: CMTimeScale = 60000
    }
    
    var fullQueue: [AVPlayerItem] {
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
        listeners?.onMediaChanged = { [weak self] in
            guard let self = self else { return }
            if(self.smPlayer.items().count > 0){
                if(self.smPlayer.currentItem != self.fullQueue.first && self.queueManager.historyQueue.count > 0 && shouldNotifyTransition){
                    methodChannelManager?.notifyPlayerStateChange(state: PlayerState.itemTransition)
                }
                shouldNotifyTransition = true
                self.updateEndPlaybackObserver()
                self.listeners?.addItemsObservers()
                methodChannelManager?.currentMediaIndex(index: self.currentIndex)
            }
        }
        nowPlayingInfoManager.setupNowPlayingInfoCenter(
            areNotificationCommandsEnabled: { [weak self] in self?.areNotificationCommandsEnabled ?? true },
            play: { [weak self] in self?.play() },
            pause: { [weak self] in self?.pause() },
            nextTrack: { [weak self] in self?.nextTrack(from: "commandCenter.nextTrackCommand") },
            previousTrack: { [weak self] in self?.previousTrack() },
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
    
    private func createPlayerItem(with url: URL, cookie: String?) -> AVPlayerItem {
        let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": ["Cookie": cookie ?? ""]]
        return AVPlayerItem(asset: AVURLAsset(url: url, options: assetOptions))
    }
    
    private func createLocalPlayerItem(with path: String) -> AVPlayerItem {
        return AVPlayerItem(asset: AVAsset(url: NSURL(fileURLWithPath: path) as URL))
    }
    
    private func createPlayerItemFromUri(_ uri: String?, fallbackUrl: String?, cookie: String?) -> AVPlayerItem? {
        if uri?.contains("https") ?? true {
            guard let url = URL(string: (uri ?? fallbackUrl!) ?? "") else { return nil }
            return createPlayerItem(with: url, cookie: cookie)
        } else {
            return createLocalPlayerItem(with: uri!)
        }
    }
    
    func enqueue(medias: [PlaylistItem], autoPlay: Bool, cookie: String) {
        var playerItem: AVPlayerItem?
        guard let message = MessageBuffer.shared.receive() else { return }
        if(!cookie.isEmpty){
            self.cookie = cookie
        }
        let isFirstBatch = self.smPlayer.items().count == 0
        for media in message {
            playerItem = createPlayerItemFromUri(media.url, fallbackUrl: nil, cookie: self.cookie)
            media.cookie = cookie
            if playerItem != nil {
                playerItem!.playlistItem = media
                queueManager.enqueue(item: playerItem!)
            }
        }
        insertIntoPlayerIfNeeded()
        if autoPlay && isFirstBatch {
            self.smPlayer.play()
            self.setNowPlaying()
        }
        self.enableCommands()
        //TODO: precisa adicionar em todos os batches?
        listeners?.addPlayerObservers()
    }
    
    func removeByPosition(indexes: [Int]) {
        queueManager.removeByPosition(indexes: indexes)
        printStatus(from: "removeByPosition")
    }
    
    func toggleShuffle(positionsList: [[String: Int]]) {
        queueManager.toggleShuffle(positionsList: positionsList)
        methodChannelManager?.shuffleChanged(shuffleIsActive: queueManager.isShuffleModeEnabled)
    }
    
    func reorder(fromIndex: Int, toIndex: Int, positionsList: [[String: Int]]) {
        queueManager.reorder(fromIndex: fromIndex, toIndex: toIndex)
    }
    
    func nextTrack(from:String) {
        smPlayer.pause()
        Logger.debugLog("#print nextTrack \(from)")
        if let currentItem = smPlayer.currentItem {
            queueManager.historyQueue.append(currentItem)
        }
        
        if(smPlayer.currentItem == fullQueue.last && smPlayer.repeatMode == .REPEAT_MODE_ALL){
            playFromQueue(position: 0)
        }
        smPlayer.advanceToNextItem()
        smPlayer.seek(to: CMTime.zero)
        insertIntoPlayerIfNeeded()
        smPlayer.play()
        printStatus(from:"NEXT")
    }
    
    func previousTrack() {
        smPlayer.pause()

        guard let lastHistoryItem = queueManager.historyQueue.popLast() else {
            seekToPosition(position: 0)
            return
        }
        guard let currentItem = smPlayer.currentItem else { return}
        guard let lastItemInPlayer = smPlayer.items().last else { return }
        
        if(currentItem != lastItemInPlayer) {
            smPlayer.remove(lastItemInPlayer)
            queueManager.futureQueue.insert(lastItemInPlayer, at: 0)
        }
        
        smPlayer.insert(lastHistoryItem, after: currentItem)
        smPlayer.advanceToNextItem()
        smPlayer.insert(currentItem, after: smPlayer.currentItem)
        
        smPlayer.seek(to: CMTime.zero)
        insertIntoPlayerIfNeeded()
        smPlayer.play()
        printStatus(from:"previousTrack")
    }
    
    func setNowPlaying(){
        NowPlayingCenter.set(item: getCurrentPlaylistItem())
    }
    
    private func insertIntoPlayerIfNeeded() {
        let maxTotalItems = Constants.maxTotalItems
        let itemsToAdd = min(maxTotalItems - smPlayer.items().count, queueManager.futureQueue.count)
        
        for _ in 0..<itemsToAdd {
            if let item = queueManager.futureQueue.first {
//                print("#NATIVE LOGS insertIntoPlayerIfNeeded count ==> \(String(describing: smPlayer.items()))")
                smPlayer.insert(item, after: nil)
                queueManager.futureQueue.removeFirst()
            }
        }
        Logger.debugLog("#NATIVE LOGS insertIntoPlayerIfNeeded ==> \(String(describing: smPlayer.currentItem?.playlistItem?.title))")
         printStatus(from:"insertIntoPlayerIfNeeded")
    }
    
    
    func removeAll(){
        smPlayer.pause()
        smPlayer.seek(to: CMTime.zero)
        smPlayer.removeAllItems()
        queueManager.historyQueue.removeAll()
        queueManager.futureQueue.removeAll()
        queueManager.originalQueue.removeAll()
        queueManager.shuffledQueue.removeAll()
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
    
    func getCurrentPlaylistItem() -> PlaylistItem? {
        guard let currentItem = smPlayer.currentItem else {
            return nil
        }
        return currentItem.playlistItem
    }
    
    private func distributeItemsInRightQueue(currentQueue: [AVPlayerItem], keepFirst: Bool = true, positionArg: Int = -1, completionHandler completion: (() -> Void)? = nil) {
        let startTime = CFAbsoluteTimeGetCurrent()
        guard currentQueue.count > 0 else { return }
        var position = positionArg
        queueManager.historyQueue.removeAll()
        queueManager.futureQueue.removeAll()
        
        if(keepFirst){
            position =  smPlayer.currentItem != nil ? currentQueue.firstIndex(of:smPlayer.currentItem!)  ?? -1 : -1
            let itemsToRemove = smPlayer.items().dropFirst()
            for item in itemsToRemove {
                smPlayer.remove(item)
            }
        }else{
            smPlayer.removeAllItems()
            queueManager.futureQueue.append(currentQueue[position])
        }
        
        for (index, item) in currentQueue.enumerated() {
            if(index != position){
                if index < position  {
                    queueManager.historyQueue.append(item)
                } else  {
                    queueManager.futureQueue.append(item)
                }
            }
        }
        insertIntoPlayerIfNeeded()
        completion?()
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("TIME distributeItemsInRightQueue execution time: \(timeElapsed) seconds")
    }
    
    func updateMediaUri(id: Int, uri: String?){
        var fullQueueUpdated = fullQueue
        if let index = fullQueue.firstIndex(where: { $0.playlistItem?.mediaId == id }){
            let oldItem = fullQueueUpdated[index]
            if let playerItem = createPlayerItemFromUri(uri, fallbackUrl: oldItem.playlistItem?.fallbackUrl, cookie: oldItem.playlistItem?.cookie) {
                playerItem.playlistItem = oldItem.playlistItem
                fullQueueUpdated[index] = playerItem
                print("updateMediaUri: \(String(describing: uri))")
                for item in fullQueueUpdated {
                    print("#updateMediaUri QUEUE: \(String(describing: item.playlistItem?.title)) | \(item.asset) | \(currentIndex)")
                }
                distributeItemsInRightQueue(currentQueue: fullQueueUpdated)
            }
        }
    }

    func playFromQueue(position: Int, timePosition: Int = 0, loadOnly: Bool = false) {
        distributeItemsInRightQueue(currentQueue: fullQueue, keepFirst: false, positionArg: position, completionHandler: {
            print("#NATIVE LOGS ==> completionHandler")
            self.methodChannelManager?.currentMediaIndex(index: self.currentIndex)
            if(timePosition > 0){
                self.seekToPosition(position: timePosition)
            }
        })
        if(loadOnly){
            pause()
            shouldNotifyTransition = false
        }else{
            play()
        }
        listeners?.addMediaChangeObserver()
    }
    
    func enableCommands(){
        nowPlayingInfoManager.enableCommands()
    }
    
    
    func printStatus(from:String) {
            Logger.debugLog("QueueActivity #################################################")
            Logger.debugLog("QueueActivity  \(from) ")
            Logger.debugLog("QueueActivity Current Index: \(String(describing: currentIndex))")
            Logger.debugLog("QueueActivity ------------------------------------------")
            Logger.debugLog("QueueActivity printStatus History: \(queueManager.historyQueue.count) items")
            
            for item in queueManager.historyQueue {
                Logger.debugLog("QueueActivity printStatus History: \(String(describing: item.playlistItem?.title))")
            }
            Logger.debugLog("QueueActivity printStatus ------------------------------------------")
            Logger.debugLog("QueueActivity printStatus futureQueue Items: \(queueManager.futureQueue.count) items")
            
            for item in queueManager.futureQueue {
                Logger.debugLog("QueueActivity printStatus Upcoming: \(String(describing: item.playlistItem?.title))")
            }
            Logger.debugLog("QueueActivity printStatus ------------------------------------------")
            Logger.debugLog("QueueActivity printStatus AVQueuePlayer items: \(smPlayer.items().count)")
            
            for item in smPlayer.items() {
                Logger.debugLog("QueueActivity printStatus AVQueuePlayer: \(String(describing: item.playlistItem?.title))")
            }
            Logger.debugLog("QueueActivity printStatus #################################################")

    }
    
    //override automatic next
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        pause()
        switch smPlayer.repeatMode {
        case .REPEAT_MODE_ALL:
            if(smPlayer.currentItem == fullQueue.last){
                playFromQueue(position: 0)
                break
            }
            nextTrack(from:"REPEAT_MODE_ALL")
        case .REPEAT_MODE_ONE:
            seekToPosition(position: 0)
        case .REPEAT_MODE_OFF:
            nextTrack(from: "REPEAT_MODE_OFF")
        }
        play()
    }
    
    private func removeAllObservers() {
        notificationManager.removeAllObservers()
        // Remover outros observadores
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
