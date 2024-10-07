import Foundation
import AVFoundation
import MediaPlayer

private var playlistItemKey: UInt8 = 0

public class SMPlayer : NSObject  {
    var methodChannelManager: MethodChannelManager?
    //Queue handle
    private var smPlayer: AVQueuePlayer
    private var playerItem: AVPlayerItem?
    private var historyQueue: [AVPlayerItem] = []
    private var futureQueue: [AVPlayerItem] = []
    //Shuffle handle
    private var originalQueue: [AVPlayerItem] = []
    private var shuffledIndices: [Int] = []
    private var isShuffleModeEnabled: Bool = false
    var shuffledQueue: [AVPlayerItem] = []
    
    var fullQueue: [AVPlayerItem] {
        return historyQueue + smPlayer.items() + futureQueue
    }
    
    var currentIndex : Int? {
        guard let currentItem = smPlayer.currentItem else {
            return nil
        }
        return fullQueue.firstIndex(of: currentItem)
    }
    
    init(methodChannelManager: MethodChannelManager?) {
        smPlayer = AVQueuePlayer()
        super.init()
        self.methodChannelManager = methodChannelManager
        let listeners = SMPlayerListeners(playerItem: playerItem,smPlayer:smPlayer,methodChannelManager:methodChannelManager)
        listeners.addObservers()
        listeners.onMediaChanged = {
            methodChannelManager?.currentMediaIndex(index: self.historyQueue.count)
        }
        setupNowPlayingInfoCenter()
        _ = AudioSessionManager.activeSession()
        _ = RepeatManager(player:smPlayer)
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: smPlayer.currentItem)
        
    }
    
    func pause() {
        smPlayer.pause()
    }
    
    
    func disableRepeatMode() {
        smPlayer.repeatMode = .REPEAT_MODE_OFF
        methodChannelManager?.repeatModeChanged(repeatMode: smPlayer.repeatMode.hashValue)
    }
    
    func seek(position:Int){
        let positionInSec = CMTime(seconds: Double(position/1000), preferredTimescale: 60000)
        smPlayer.seek(to: positionInSec, toleranceBefore: .zero, toleranceAfter: .zero)
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
        methodChannelManager?.repeatModeChanged(repeatMode: smPlayer.repeatMode.hashValue)
    }
    
    
    func stop() {
        smPlayer.pause()
        smPlayer.replaceCurrentItem(with: nil)
        clearNowPlayingInfo()
    }
    
    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func enqueue(medias: [PlaylistItem], autoPlay: Bool, cookie: String) {
        guard let message = MessageBuffer.shared.receive() else { return }
        let isFirstBatch = self.smPlayer.items().count == 0
        for media in message {
            guard let url = URL(string: media.url!) else { continue }
            let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": ["Cookie": cookie]]
            let playerItem = AVPlayerItem(asset: AVURLAsset(url: url, options: assetOptions))
            playerItem.playlistItem = media
            futureQueue.append(playerItem)
        }
        insertIntoPlayerIfNeeded()
        if autoPlay && isFirstBatch {
            self.smPlayer.play()
            self.setNowPlaying()
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
    
    func nextTrack() {
        if let currentItem = smPlayer.currentItem {
            historyQueue.append(currentItem)
        }
        smPlayer.advanceToNextItem()
        seekToPosition(position: 0)
        setNowPlaying()
        insertIntoPlayerIfNeeded()
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
        setNowPlaying()
        insertIntoPlayerIfNeeded()
        smPlayer.play()
        printStatus(from:"previousTrack")
    }
    
    func setNowPlaying(){
        NowPlayingCenter.set(item: getCurrentPlaylistItem())
    }
    
    private func insertIntoPlayerIfNeeded() {
        let maxTotalItems = 5
        let currentItemCount = smPlayer.items().count
        let itemsToAdd = min(maxTotalItems - currentItemCount, futureQueue.count)
        
        for _ in 0..<itemsToAdd {
            if let item = futureQueue.first {
                smPlayer.insert(item, after: nil)
                futureQueue.removeFirst()
            }
        }
        printStatus(from:"insertIntoPlayerIfNeeded")
    }
    
    
    func removeAll(){
        smPlayer.pause()
        smPlayer.seek(to: CMTime.zero)
        smPlayer.removeAllItems()
        historyQueue.removeAll()
        futureQueue.removeAll()
        originalQueue.removeAll()
    }
    
    func play(){
        smPlayer.play()
    }
    
    func seekToPosition(position:Int){
        let positionInSec = CMTime(seconds: Double(position/1000), preferredTimescale: 60000)
        smPlayer.seek(to: positionInSec, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func getCurrentPlaylistItem() -> PlaylistItem? {
        guard let currentItem = smPlayer.currentItem else {
            return nil
        }
        return currentItem.playlistItem
    }
    
    private func distributeItemsInRightQueue(currentQueue: [AVPlayerItem], keepFirst: Bool = true, positionArg: Int = -1) {
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
    }
    
    func playFromQueue(position: Int, timePosition: Int, loadOnly: Bool) {
        distributeItemsInRightQueue(currentQueue:fullQueue, keepFirst: false, positionArg: position)
        if(loadOnly){
            seekToPosition(position: timePosition)
            smPlayer.pause()
        }
    }
    
    func setupNowPlayingInfoCenter(){
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true;
        commandCenter.previousTrackCommand.isEnabled = true;
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        
        commandCenter.pauseCommand.addTarget { [self]event in
            smPlayer.pause()
            return .success
        }
        
        commandCenter.playCommand.addTarget { [self]event in
            smPlayer.play()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget {[self]event in
            nextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget {[self]event in
            previousTrack()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget{[self]event in
            let e = event as? MPChangePlaybackPositionCommandEvent
            seekToPosition(position: Int((e?.positionTime ?? 0) * 1000))
            return .success
        }
    }
    
    func printStatus(from:String) {
        print("#printStatus #################################################")
        print("#printStatus  \(from) ")
        print("#printStatus Current Index: \(String(describing: currentIndex))")
        print("#printStatus ------------------------------------------")
        print("#printStatus History: \(historyQueue.count) items")
        for item in historyQueue {
            print("#printStatus History: \(String(describing: item.playlistItem?.title))")
        }
        print("#printStatus ------------------------------------------")
        print("#printStatus futureQueue Items: \(futureQueue.count) items")
        for item in futureQueue {
            print("#printStatus Upcoming: \(String(describing: item.playlistItem?.title))")
        }
        print("#printStatus ------------------------------------------")
        print("#printStatus AVQueuePlayer items: \(smPlayer.items().count)")
        for item in smPlayer.items() {
            print("#printStatus AVQueuePlayer: \(String(describing: item.playlistItem?.title))")
        }
        print("#printStatus #################################################")
    }
    
    //override automatic next
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        smPlayer.pause()
        nextTrack()
        smPlayer.play()
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
    private struct CustomProperties {
        static var repeatManager: UInt8 = 0
    }
    
    private var repeatManager: RepeatManager? {
        get {
            return objc_getAssociatedObject(self, &CustomProperties.repeatManager) as? RepeatManager
        }
        set(value) {
            objc_setAssociatedObject(self, &CustomProperties.repeatManager, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    enum RepeatMode {
        case REPEAT_MODE_OFF
        case REPEAT_MODE_ONE
        case REPEAT_MODE_ALL
    }
    
    var repeatMode: RepeatMode {
        get {
            return repeatManager?.mode ?? .REPEAT_MODE_OFF
        }
        set(mode) {
            if repeatManager == nil {
                repeatManager = RepeatManager(player: self )
            }
            repeatManager?.mode = mode
            
            switch mode {
            case .REPEAT_MODE_OFF:
                actionAtItemEnd = .none
            case .REPEAT_MODE_ALL:
                actionAtItemEnd = .advance
            default:
                actionAtItemEnd = .pause
            }
        }
    }
    
}
