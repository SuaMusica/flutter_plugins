import Foundation
import AVFoundation
import MediaPlayer

private var playlistItemKey: UInt8 = 0
var currentRepeatmode: AVQueuePlayer.RepeatMode = .REPEAT_MODE_OFF
public class SMPlayer : NSObject  {
    var methodChannelManager: MethodChannelManager?
    private var cookie: String = ""
    //Queue handle
    private var smPlayer: AVQueuePlayer
    private var historyQueue: [AVPlayerItem] = []
    private var futureQueue: [AVPlayerItem] = []
    //Shuffle handle
    private var originalQueue: [AVPlayerItem] = []
    private var shuffledIndices: [Int] = []
    private var isShuffleModeEnabled: Bool = false
    var shuffledQueue: [AVPlayerItem] = []
    private var listeners: SMPlayerListeners? = nil
    private var seekToLoadOnly: Bool = false
    // Transition Control
    private var shouldNotifyTransition: Bool = false
    var areNotificationCommandsEnabled: Bool = true
    
    var fullQueue: [AVPlayerItem] {
        return historyQueue + smPlayer.items() + futureQueue
    }
    
    var currentIndex : Int {
        guard let currentItem = smPlayer.currentItem else {
            return 0
        }
        return fullQueue.firstIndex(of: currentItem) ?? 0
    }
    
    init(methodChannelManager: MethodChannelManager?) {
        smPlayer = AVQueuePlayer()
        super.init()
        self.methodChannelManager = methodChannelManager
        listeners = SMPlayerListeners(smPlayer:smPlayer,methodChannelManager:methodChannelManager)
        listeners?.addPlayerObservers()
    
        listeners?.onMediaChanged = { [self] in
            if(self.smPlayer.items().count > 0){
                if(self.smPlayer.currentItem != self.fullQueue.first && self.historyQueue.count > 0 && shouldNotifyTransition){
                    methodChannelManager?.notifyPlayerStateChange(state: PlayerState.itemTransition)
                }
                shouldNotifyTransition = true
                self.updateEndPlaybackObserver()
                seekToLoadOnly = !seekToLoadOnly
                self.listeners?.addItemsObservers()
                if(seekToLoadOnly){
                    seekToLoadOnly = false
                    methodChannelManager?.currentMediaIndex(index: self.currentIndex)
                }             
            }
        }
        setupNowPlayingInfoCenter()
        _ = AudioSessionManager.activeSession()
    }
    
    func pause() {
        smPlayer.pause()
    }
    
    func addEndPlaybackObserver() {
        guard let currentItem = smPlayer.currentItem else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFinishPlaying(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: currentItem
        )
    }
    
    func removeEndPlaybackObserver() {
        if let currentItem = smPlayer.currentItem {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: currentItem
            )
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
    }
    
    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        removeNotification()
    }
    
    func enqueue(medias: [PlaylistItem], autoPlay: Bool, cookie: String, shouldNotifyTransition: Bool) {
        var playerItem: AVPlayerItem?
        guard let message = MessageBuffer.shared.receive() else { return }
        self.shouldNotifyTransition = shouldNotifyTransition
        if(!cookie.isEmpty){
            self.cookie = cookie
        }
        let isFirstBatch = self.smPlayer.items().count == 0
        for media in message {
            if(media.url!.contains("https")){
                guard let url = URL(string: media.url!) else { continue }
                let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": ["Cookie": self.cookie]]
                playerItem = AVPlayerItem(asset: AVURLAsset(url: url, options: assetOptions))
            }else{
                playerItem = AVPlayerItem(asset:AVAsset(url: NSURL(fileURLWithPath: media.url!) as URL))
                media.cookie = cookie
            }
            playerItem!.playlistItem = media
            futureQueue.append(playerItem!)
        }
        insertIntoPlayerIfNeeded()
        if autoPlay && isFirstBatch {
            self.smPlayer.play()
            self.setNowPlaying()
            self.enableCommands()
        }
        print("#ENQUEUE: shouldNotifyTransition: \(shouldNotifyTransition)")
        if(shouldNotifyTransition){
            methodChannelManager?.notifyPlayerStateChange(state: PlayerState.itemTransition)
        }
        self.enableCommands()
    }
    
    func removeByPosition(indexes: [Int]) {
        if(indexes.count > 0){
            let sortedIndexes = indexes.sorted(by: >)
            var queueAfterRemovedItems = isShuffleModeEnabled ? shuffledQueue : fullQueue
            for index in sortedIndexes {
                if index < queueAfterRemovedItems.count {
                    queueAfterRemovedItems.remove(at: index)
                }
            }
            distributeItemsInRightQueue(currentQueue: queueAfterRemovedItems, keepFirst: true)
            printStatus(from: "removeByPosition")
        }
    }
    
    func toggleShuffle(positionsList: [[String: Int]]) {
        isShuffleModeEnabled.toggle()
        if isShuffleModeEnabled {
            shuffledIndices = positionsList.compactMap { $0["originalPosition"] }
            originalQueue = fullQueue
            fillShuffledQueue()
            distributeItemsInRightQueue(currentQueue: shuffledQueue)
        } else {
            if(!originalQueue.isEmpty){
                distributeItemsInRightQueue(currentQueue: originalQueue)
            }
        }
        methodChannelManager?.shuffleChanged(shuffleIsActive: isShuffleModeEnabled)
    }
    
    func fillShuffledQueue()  {
        shuffledQueue.removeAll()
        for index in shuffledIndices {
            if index < fullQueue.count {
                shuffledQueue.append(fullQueue[index])
            }
        }
    }
    
    
    func reorder(fromIndex: Int, toIndex: Int, positionsList: [[String: Int]]) {
        var queue = isShuffleModeEnabled ?  shuffledQueue : fullQueue
        queue.insert(queue.remove(at: fromIndex), at: toIndex)
        distributeItemsInRightQueue(currentQueue: queue)
    }
    
    func nextTrack(from:String) {
        smPlayer.pause()
        print("#print nextTrack \(from)")
        if let currentItem = smPlayer.currentItem {
            historyQueue.append(currentItem)
        }
        
        if(smPlayer.currentItem == fullQueue.last && smPlayer.repeatMode == .REPEAT_MODE_ALL){
            playFromQueue(position: 0)
        }
        smPlayer.advanceToNextItem()
        seekToPosition(position: 0)
        insertIntoPlayerIfNeeded()
        smPlayer.play()
        printStatus(from:"NEXT")
    }
    
    func previousTrack() {
        smPlayer.pause()

        guard let lastHistoryItem = historyQueue.popLast() else {
            seekToPosition(position: 0)
            return
        }
        guard let currentItem = smPlayer.currentItem else { return}
        guard let lastItemInPlayer = smPlayer.items().last else { return }
        
        if(currentItem != lastItemInPlayer) {
            smPlayer.remove(lastItemInPlayer)
            futureQueue.insert(lastItemInPlayer, at: 0)
        }
        
        smPlayer.insert(lastHistoryItem, after: currentItem)
        smPlayer.advanceToNextItem()
        smPlayer.insert(currentItem, after: smPlayer.currentItem)
        
        seekToPosition(position: 0)
        insertIntoPlayerIfNeeded()
        smPlayer.play()
        printStatus(from:"previousTrack")
    }
    
    func setNowPlaying(){
        NowPlayingCenter.set(item: getCurrentPlaylistItem())
    }
    
    private func insertIntoPlayerIfNeeded() {
        let maxTotalItems = 5
        let itemsToAdd = min(maxTotalItems - smPlayer.items().count, futureQueue.count)
        
        for _ in 0..<itemsToAdd {
            if let item = futureQueue.first {
                smPlayer.insert(item, after: nil)
                futureQueue.removeFirst()
            }
        }
        print("#NATIVE LOGS insertIntoPlayerIfNeeded ==> \(String(describing: smPlayer.currentItem?.playlistItem?.title))")
        printStatus(from:"insertIntoPlayerIfNeeded")
    }
    
    
    func removeAll(){
        smPlayer.pause()
        smPlayer.seek(to: CMTime.zero)
        smPlayer.removeAllItems()
        historyQueue.removeAll()
        futureQueue.removeAll()
        originalQueue.removeAll()
        shuffledQueue.removeAll()
        shuffledIndices.removeAll()
    }
    
    func removeNotification(){
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = false;
        commandCenter.previousTrackCommand.isEnabled = false;
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.playCommand.removeTarget(self)
        commandCenter.pauseCommand.removeTarget(self)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    func play(){
        smPlayer.play()
    }
    
    func seekToPosition(position:Int){
        let positionInSec = CMTime(seconds: Double(position/1000), preferredTimescale: 60000)
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
        guard currentQueue.count > 0 else { return }
        var position = positionArg
        historyQueue.removeAll()
        futureQueue.removeAll()
        
        if(keepFirst){
            position =  smPlayer.currentItem != nil ? currentQueue.firstIndex(of:smPlayer.currentItem!)  ?? -1 : -1
            let itemsToRemove = smPlayer.items().dropFirst()
            for item in itemsToRemove {
                smPlayer.remove(item)
            }
        }else{
            smPlayer.removeAllItems()
            futureQueue.append(currentQueue[position])
        }
        
        for (index, item) in currentQueue.enumerated() {
            if(index != position){
                if index < position  {
                    historyQueue.append(item)
                } else  {
                    futureQueue.append(item)
                }
            }
        }
        insertIntoPlayerIfNeeded()
        completion?()
    }
    
    func updateMediaUri(id: Int, uri: String?){
        var fullQueueUpdated = fullQueue
        if let index = fullQueue.firstIndex(where: { $0.playlistItem?.mediaId == id }){
            let oldItem = fullQueueUpdated[index]
            var playerItem: AVPlayerItem?
            if(uri?.contains("https") ?? true){
                guard let url = URL(string: (uri ?? oldItem.playlistItem!.fallbackUrl!)) else { return }
                let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": ["Cookie": oldItem.playlistItem?.cookie]]
                playerItem = AVPlayerItem(asset: AVURLAsset(url: url, options: assetOptions))
            }else{
                playerItem = AVPlayerItem(asset:AVAsset(url: NSURL(fileURLWithPath: uri!) as URL))
            }
            playerItem?.playlistItem = oldItem.playlistItem
            fullQueueUpdated[index] = playerItem!
            print("updateMediaUri: \(String(describing: uri))")
            for item in fullQueueUpdated {
                print("#updateMediaUri QUEUE: \(String(describing: item.playlistItem?.title)) | \(item.asset) | \(currentIndex)")
            }
            distributeItemsInRightQueue(currentQueue: fullQueueUpdated)
        }
        
    }

    func playFromQueue(position: Int, timePosition: Int = 0, loadOnly: Bool = false) {
        if (loadOnly) {
            seekToLoadOnly = true
            listeners?.mediaChange?.invalidate()
        }
        listeners?.removeItemObservers()
        distributeItemsInRightQueue(currentQueue: fullQueue, keepFirst: false, positionArg: position, completionHandler: {
            print("#NATIVE LOGS ==> completionHandler")
            self.methodChannelManager?.currentMediaIndex(index: self.currentIndex)
            if(timePosition > 0){
                self.seekToPosition(position: timePosition)
            }
        })
        if(loadOnly){
            pause()
        }else{
            play()
        }
        listeners?.addMediaChangeObserver()
    }
    
    func enableCommands(){
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true;
        commandCenter.previousTrackCommand.isEnabled = true;
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }
    
    func setupNowPlayingInfoCenter(){
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true;
        commandCenter.previousTrackCommand.isEnabled = true;
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        
        commandCenter.pauseCommand.addTarget { [self]event in
            if(areNotificationCommandsEnabled){
                smPlayer.pause()
            }
            return .success
        }
        
        commandCenter.playCommand.addTarget { [self]event in
            if(areNotificationCommandsEnabled){
                smPlayer.play()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget {[self]event in
            if(areNotificationCommandsEnabled){
                nextTrack(from: "commandCenter.nextTrackCommand")
            }
            return .success
        }
        commandCenter.previousTrackCommand.addTarget {[self]event in
            if(areNotificationCommandsEnabled){
                previousTrack()
            }
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget{[self]event in
            if(areNotificationCommandsEnabled){
                let e = event as? MPChangePlaybackPositionCommandEvent
                seekToPosition(position: Int((e?.positionTime ?? 0) * 1000))
            }
            return .success
        }
    }
    
    func printStatus(from:String) {
        if(isDebugMode()){
            print("QueueActivity #################################################")
            print("QueueActivity  \(from) ")
            print("QueueActivity Current Index: \(String(describing: currentIndex))")
            print("QueueActivity ------------------------------------------")
            print("QueueActivity printStatus History: \(historyQueue.count) items")
            
            for item in historyQueue {
                print("QueueActivity printStatus History: \(String(describing: item.playlistItem?.title))")
            }
            print("QueueActivity printStatus ------------------------------------------")
            print("QueueActivity printStatus futureQueue Items: \(futureQueue.count) items")
            
            for item in futureQueue {
                print("QueueActivity printStatus Upcoming: \(String(describing: item.playlistItem?.title))")
            }
            print("QueueActivity printStatus ------------------------------------------")
            print("QueueActivity printStatus AVQueuePlayer items: \(smPlayer.items().count)")
            
            for item in smPlayer.items() {
                print("QueueActivity printStatus AVQueuePlayer: \(String(describing: item.playlistItem?.title))")
            }
            print("QueueActivity printStatus #################################################")
        }
    }
    
    func isDebugMode() -> Bool {
           #if DEBUG
           return true
           #else
           return false
           #endif
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
