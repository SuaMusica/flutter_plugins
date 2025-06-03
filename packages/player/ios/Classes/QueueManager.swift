import AVFoundation

class QueueManager {
    var historyQueue: [PlaylistItem] = []
    var futureQueue: [PlaylistItem] = []
    var originalQueue: [PlaylistItem] = []
    var shuffledQueue: [PlaylistItem] = []
    
    var shuffledIndices: [Int] = []
    var isShuffleModeEnabled: Bool = false
    private let smPlayer: AVQueuePlayer
    private let maxTotalItems: Int
    
    init(smPlayer: AVQueuePlayer, maxTotalItems: Int = 5) {
        self.smPlayer = smPlayer
        self.maxTotalItems = maxTotalItems
    }
    
    
    var mirrorPlayerQueue: [PlaylistItem] {
        return smPlayer.items().compactMap { $0.playlistItem}
    }
    
    var fullQueue: [PlaylistItem] {
        return historyQueue + mirrorPlayerQueue + futureQueue
    }
    
    var currentIndex: Int {
        guard let currentItem = smPlayer.currentItem?.playlistItem else {
            return 0
        }
        return fullQueue.firstIndex(of: currentItem) ?? 0
    }
    
    func fillShuffledQueue() {
        shuffledQueue.removeAll()
        for index in shuffledIndices {
            if index < fullQueue.count {
                shuffledQueue.append(fullQueue[index])
            }
        }
    }
    
    func reorder(fromIndex: Int, toIndex: Int) {
        var queue = isShuffleModeEnabled ? shuffledQueue : fullQueue
        queue.insert(queue.remove(at: fromIndex), at: toIndex)
        distributeItemsInRightQueue(currentQueue: queue)
    }
    
    func removeByPosition(indexes: [Int]) {
        if indexes.count > 0 {
            let sortedIndexes = indexes.sorted(by: >)
            var queueAfterRemovedItems = isShuffleModeEnabled ? shuffledQueue : fullQueue
            for index in sortedIndexes {
                if index < queueAfterRemovedItems.count {
                    queueAfterRemovedItems.remove(at: index)
                }
            }
            distributeItemsInRightQueue(currentQueue: queueAfterRemovedItems, keepFirst: true)
        }
        printStatus(from: "removeByPosition")
    }
    
    func toggleShuffle(positionsList: [[String: Int]]) {
        isShuffleModeEnabled.toggle()
        if isShuffleModeEnabled {
            shuffledIndices = positionsList.compactMap { $0["originalPosition"] }
            originalQueue = fullQueue
            fillShuffledQueue()
            distributeItemsInRightQueue(currentQueue: shuffledQueue)
        } else {
            if !originalQueue.isEmpty {
                distributeItemsInRightQueue(currentQueue: originalQueue)
            }
        }
    }
    
    func distributeItemsInRightQueue(currentQueue: [PlaylistItem], keepFirst: Bool = true, positionArg: Int = -1, completionHandler completion: (() -> Void)? = nil) {
        guard currentQueue.count > 0 else { return }
        var position = positionArg
        historyQueue.removeAll()
        futureQueue.removeAll()
        
        if keepFirst {
            position = (smPlayer.currentItem?.playlistItem != nil ? currentQueue.firstIndex(of: smPlayer.currentItem!.playlistItem!) : -1)!
            let itemsToRemove = smPlayer.items().dropFirst()
            for item in itemsToRemove {
                smPlayer.remove(item)
            }
        } else {
            smPlayer.removeAllItems()
            if position >= 0 && position < currentQueue.count {
                futureQueue.append(currentQueue[position])
            }
        }
        
        for (index, item) in currentQueue.enumerated() {
            if index != position {
                if index < position {
                    historyQueue.append(item)
                } else {
                    futureQueue.append(item)
                }
            }
        }
        insertIntoPlayerIfNeeded()
        completion?()
    }
    
    func insertIntoPlayerIfNeeded() {
        let itemsToAdd = min(maxTotalItems - smPlayer.items().count, futureQueue.count)
        for _ in 0..<itemsToAdd {
            if let item = futureQueue.first {
                let aVPlayerItem = createPlayerItemFromUri(item.url, fallbackUrl:item.fallbackUrl,cookie:item.cookie)
                aVPlayerItem?.playlistItem = item
                smPlayer.insert(aVPlayerItem!, after: nil)
                futureQueue.removeFirst()
            }
        }
        Logger.debugLog("#NATIVE LOGS insertIntoPlayerIfNeeded ==> \(String(describing: smPlayer.currentItem?.playlistItem?.title))")
         printStatus(from:"insertIntoPlayerIfNeeded")
    }
    
    func removeAll() {
        smPlayer.pause()
        smPlayer.seek(to: CMTime.zero)
        smPlayer.removeAllItems()
        historyQueue.removeAll()
        futureQueue.removeAll()
        originalQueue.removeAll()
        shuffledQueue.removeAll()
        shuffledIndices.removeAll()
    }
    
    func updateMediaUri(id: Int, uri: String?) {
        guard let newUri = uri else { return }
        guard let index = fullQueue.firstIndex(where: { $0.mediaId == id }) else { return } 
        let oldItem = fullQueue[index]
        if oldItem.url == newUri { return }
        let updatedItem = createUpdatedPlaylistItem(from: oldItem, newUri: newUri)
        fullQueue[index] = updatedItem
        distributeItemsInRightQueue(currentQueue: updatedQueue)
    }
    
    private func createUpdatedPlaylistItem(from oldItem: PlaylistItem, newUri: String) -> PlaylistItem {
        return PlaylistItem(
            albumId: oldItem.albumId,
            albumName: oldItem.albumName,
            title: oldItem.title,
            artist: oldItem.artist,
            url: newUri,
            coverUrl: oldItem.coverUrl ?? "",
            fallbackUrl: oldItem.fallbackUrl ?? "",
            mediaId: oldItem.mediaId,
            bigCoverUrl: oldItem.bigCoverUrl ?? "",
            cookie: oldItem.cookie ?? ""
        )
    }
    
    func playFromQueue(position: Int, timePosition: Int = 0, loadOnly: Bool = false, seekToPosition: ((Int) -> Void)? = nil, pause: (() -> Void)? = nil, play: (() -> Void)? = nil, notifyCurrentMediaIndex: ((Int) -> Void)? = nil, addMediaChangeObserver: (() -> Void)? = nil) {
        distributeItemsInRightQueue(currentQueue: fullQueue, keepFirst: false, positionArg: position, completionHandler: {
            notifyCurrentMediaIndex?(self.currentIndex)
            if timePosition > 0 {
                seekToPosition?(timePosition)
            }
        })
        if loadOnly {
            pause?()
//            shouldNotifyTransition = false
        } else {
            play?()
        }
//        addMediaChangeObserver?()
    }
    
    func nextTrack(from: String, playFromQueue: ((Int) -> Void)? = nil) {
        smPlayer.pause()
        if let currentItem = smPlayer.currentItem?.playlistItem{
            historyQueue.append(currentItem)
        }
        if smPlayer.currentItem?.playlistItem == fullQueue.last && smPlayer.repeatMode == .REPEAT_MODE_ALL {
            playFromQueue?(0)
        }
        smPlayer.advanceToNextItem()
        smPlayer.seek(to: CMTime.zero)
        insertIntoPlayerIfNeeded()
        smPlayer.play()
    }
    
    func previousTrack(seekToPosition: ((Int) -> Void)? = nil) {
        smPlayer.pause()
        guard let lastHistoryItem = historyQueue.popLast() else {
            seekToPosition?(0)
            return
        }
        guard let currentItem = smPlayer.currentItem else { return }
        guard let lastItemInPlayer = smPlayer.items().last else { return }
        if currentItem != lastItemInPlayer {
            smPlayer.remove(lastItemInPlayer)
            futureQueue.insert(lastItemInPlayer.playlistItem!, at: 0)
        }
        let historyAVPlayerItem = createPlayerItemFromUri(lastHistoryItem.url, fallbackUrl:lastHistoryItem.fallbackUrl,cookie:lastHistoryItem.cookie)
        smPlayer.insert(historyAVPlayerItem!, after: currentItem)
        smPlayer.advanceToNextItem()
        smPlayer.insert(currentItem, after: smPlayer.currentItem)
        smPlayer.seek(to: CMTime.zero)
        insertIntoPlayerIfNeeded()
        smPlayer.play()
    }
    
    func getCurrentPlaylistItem() -> PlaylistItem? {
        guard let currentItem = smPlayer.currentItem else {
            return nil
        }
        return currentItem.playlistItem
    }
    
    func printStatus(from: String) {
        Logger.debugLog("QueueActivity #################################################")
        Logger.debugLog("QueueActivity  \(from) ")
        Logger.debugLog("QueueActivity Current Index: \(String(describing: currentIndex))")
        Logger.debugLog("QueueActivity ------------------------------------------")
        Logger.debugLog("QueueActivity printStatus History: \(historyQueue.count) items")
        
        for item in historyQueue {
            Logger.debugLog("QueueActivity printStatus History: \(String(describing: item.title))")
        }
        Logger.debugLog("QueueActivity printStatus ------------------------------------------")
        Logger.debugLog("QueueActivity printStatus futureQueue Items: \(futureQueue.count) items")
        
        for item in futureQueue {
            Logger.debugLog("QueueActivity printStatus Upcoming: \(String(describing: item.title))")
        }
        Logger.debugLog("QueueActivity printStatus ------------------------------------------")
        Logger.debugLog("QueueActivity printStatus AVQueuePlayer items: \(smPlayer.items().count)")
        
        for item in smPlayer.items() {
            Logger.debugLog("QueueActivity printStatus AVQueuePlayer: \(String(describing: item.playlistItem?.title))")
        }
        Logger.debugLog("QueueActivity printStatus #################################################")
    }
    
    func enqueue(item: PlaylistItem) {
        futureQueue.append(item)
    }
    
    private func createPlayerItem(with url: URL, cookie: String?) -> AVPlayerItem {
        let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": ["Cookie": cookie ?? ""]]
        return AVPlayerItem(asset: AVURLAsset(url: url, options: assetOptions))
    }
    
    private func createLocalPlayerItem(with path: String) -> AVPlayerItem {
        return AVPlayerItem(asset: AVAsset(url: NSURL(fileURLWithPath: path) as URL))
    }
    
    func createPlayerItemFromUri(_ uri: String?, fallbackUrl: String?, cookie: String?) -> AVPlayerItem? {
        if uri?.contains("https") ?? true {
            guard let url = URL(string: (uri ?? fallbackUrl!) ?? "") else { return nil }
            return createPlayerItem(with: url, cookie: cookie)
        } else {
            return createLocalPlayerItem(with: uri!)
        }
    }
}
