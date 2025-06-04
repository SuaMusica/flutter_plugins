import AVFoundation

class QueueManager {
    var historyQueue = [PlaylistItem]()
    var futureQueue = [PlaylistItem]()
    var originalQueue = [PlaylistItem]()
    var shuffledQueue = [PlaylistItem]()
    
    var shuffledIndices = [Int]()
    var isShuffleModeEnabled = false
    private let smPlayer: AVQueuePlayer
    private let listeners: SMPlayerListeners
    private let methodChannelManager: MethodChannelManager
    
    private enum Constants {
        static let maxTotalItems = 5
        static let defaultTimescale: CMTimeScale = 60000
    }
    
    init(smPlayer: AVQueuePlayer, listeners: SMPlayerListeners, methodChannelManager: MethodChannelManager) {
        self.smPlayer = smPlayer
        self.listeners = listeners
        self.methodChannelManager = methodChannelManager
    }
    
    var mirrorPlayerQueue: [PlaylistItem] {
        smPlayer.items().compactMap { $0.playlistItem }
    }
    
    var fullQueue: [PlaylistItem] {
        historyQueue + mirrorPlayerQueue + futureQueue
    }
    
    func seekToTimePosition(position: Int) {
        let positionInSec = CMTime(seconds: Double(position/1000), preferredTimescale: Constants.defaultTimescale)
        smPlayer.currentItem?.seek(to: positionInSec, toleranceBefore: .zero, toleranceAfter: .zero) { completed in
            if completed {
                self.methodChannelManager.notifyPlayerStateChange(state: PlayerState.seekEnd)
            }
        }
    }
    
    var currentIndex: Int {
        guard let currentItem = smPlayer.currentItem?.playlistItem else { return 0 }
        return fullQueue.firstIndex(of: currentItem) ?? 0
    }
    
    func fillShuffledQueue() {
        shuffledQueue = shuffledIndices.compactMap { index in
            index < fullQueue.count ? fullQueue[index] : nil
        }
    }
    
    func reorder(fromIndex: Int, toIndex: Int) {
        var queue = isShuffleModeEnabled ? shuffledQueue : fullQueue
        queue.insert(queue.remove(at: fromIndex), at: toIndex)
        distributeItemsInRightQueue(currentQueue: queue)
    }
    
    func removeByPosition(indexes: [Int]) {
        guard !indexes.isEmpty else { return }
        
        let sortedIndexes = indexes.sorted(by: >)
        var queueAfterRemovedItems = isShuffleModeEnabled ? shuffledQueue : fullQueue
        
        for index in sortedIndexes where index < queueAfterRemovedItems.count {
            queueAfterRemovedItems.remove(at: index)
        }
        
        distributeItemsInRightQueue(currentQueue: queueAfterRemovedItems, keepFirst: true)
        printStatus(from: "removeByPosition")
    }
    
    func toggleShuffle(positionsList: [[String: Int]]) {
        isShuffleModeEnabled.toggle()
        if isShuffleModeEnabled {
            shuffledIndices = positionsList.compactMap { $0["originalPosition"] }
            originalQueue = fullQueue
            fillShuffledQueue()
            distributeItemsInRightQueue(currentQueue: shuffledQueue)
        } else if !originalQueue.isEmpty {
            distributeItemsInRightQueue(currentQueue: originalQueue)
        }
    }
    
    func distributeItemsInRightQueue(currentQueue: [PlaylistItem], keepFirst: Bool = true, positionArg: Int = -1, completionHandler completion: (() -> Void)? = nil) {
        guard !currentQueue.isEmpty else { return }
        
        var position = positionArg
        historyQueue.removeAll()
        futureQueue.removeAll()
        
        if keepFirst {
            position = smPlayer.currentItem?.playlistItem.flatMap { currentQueue.firstIndex(of: $0) } ?? -1
            smPlayer.items().dropFirst().forEach { smPlayer.remove($0) }
        } else {
            smPlayer.removeAllItems()
            if position >= 0 && position < currentQueue.count {
                futureQueue.append(currentQueue[position])
            }
        }
        
        for (index, item) in currentQueue.enumerated() where index != position {
            if index < position {
                historyQueue.append(item)
            } else {
                futureQueue.append(item)
            }
        }
        
        insertIntoPlayerIfNeeded()
        completion?()
    }
    
    func insertIntoPlayerIfNeeded() {
        let itemsToAdd = min(Constants.maxTotalItems - smPlayer.items().count, futureQueue.count)
        guard itemsToAdd > 0 else { return }
        
        for _ in 0..<itemsToAdd {
            guard let item = futureQueue.first else { break }
            
            if let playerItem = createPlayerItemFromUri(item.url, fallbackUrl: item.fallbackUrl, cookie: item.cookie) {
                playerItem.playlistItem = item
                smPlayer.insert(playerItem, after: nil)
                futureQueue.removeFirst()
            }
        }
        
        Logger.debugLog("#NATIVE LOGS insertIntoPlayerIfNeeded ==> \(smPlayer.currentItem?.playlistItem?.title ?? "Unknown")")
        printStatus(from: "insertIntoPlayerIfNeeded")
    }
    
    func removeAll() {
        smPlayer.pause()
        seekToTimePosition(position: 0)
        smPlayer.removeAllItems()
        historyQueue.removeAll()
        futureQueue.removeAll()
        originalQueue.removeAll()
        shuffledQueue.removeAll()
        shuffledIndices.removeAll()
    }
    
    func updateMediaUri(id: Int, uri: String?) {
        guard let newUri = uri,
              let index = fullQueue.firstIndex(where: { $0.mediaId == id }) else { return }
        
        let oldItem = fullQueue[index]
        guard oldItem.url != newUri else { return }
        
        let updatedItem = createUpdatedPlaylistItem(from: oldItem, newUri: newUri)
        var updatedQueue = fullQueue
        updatedQueue[index] = updatedItem
        distributeItemsInRightQueue(currentQueue: updatedQueue)
    }
    
    private func createUpdatedPlaylistItem(from oldItem: PlaylistItem, newUri: String) -> PlaylistItem {
        PlaylistItem(
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
    
    func playFromQueue(position: Int, timePosition: Int = 0, loadOnly: Bool = false) {
        distributeItemsInRightQueue(currentQueue: fullQueue, keepFirst: false, positionArg: position) {
            self.methodChannelManager.currentMediaIndex(index: self.currentIndex)
            if timePosition > 0 {
                self.seekToTimePosition(position: timePosition)
            }
        }
        
        if loadOnly {
            smPlayer.pause()
        } else {
            smPlayer.play()
        }
    }
    
    func nextTrack() {
        smPlayer.pause()
        
        if let currentItem = smPlayer.currentItem?.playlistItem {
            historyQueue.append(currentItem)
        }
        
        if smPlayer.currentItem?.playlistItem == fullQueue.last && smPlayer.repeatMode == .REPEAT_MODE_ALL {
            playFromQueue(position: 0)
            return
        }
        
        smPlayer.advanceToNextItem()
        seekToTimePosition(position: 0)
        insertIntoPlayerIfNeeded()
        smPlayer.play()
    }
    
    func previousTrack() {
        smPlayer.pause()
        
        guard let lastHistoryItem = historyQueue.popLast() else {
            seekToTimePosition(position: 0)
            smPlayer.play()
            return
        }
        
        guard let currentItem = smPlayer.currentItem,
              let lastItemInPlayer = smPlayer.items().last else { return }
        
        if currentItem != lastItemInPlayer {
            smPlayer.remove(lastItemInPlayer)
            if let playlistItem = lastItemInPlayer.playlistItem {
                futureQueue.insert(playlistItem, at: 0)
            }
        }
        
        guard let historyAVPlayerItem = createPlayerItemFromUri(lastHistoryItem.url, fallbackUrl: lastHistoryItem.fallbackUrl, cookie: lastHistoryItem.cookie) else { return }
        
        historyAVPlayerItem.playlistItem = lastHistoryItem
        smPlayer.insert(historyAVPlayerItem, after: currentItem)
        smPlayer.advanceToNextItem()
        smPlayer.insert(currentItem, after: smPlayer.currentItem)
        
        seekToTimePosition(position: 0)
        insertIntoPlayerIfNeeded()
        listeners.addItemsObservers()
        smPlayer.play()
    }
    
    func getCurrentPlaylistItem() -> PlaylistItem? {
        smPlayer.currentItem?.playlistItem
    }
    
    func printStatus(from: String) {
        Logger.debugLog("QueueActivity #################################################")
        Logger.debugLog("QueueActivity  \(from) ")
        Logger.debugLog("QueueActivity Current Index: \(currentIndex)")
        Logger.debugLog("QueueActivity ------------------------------------------")
        Logger.debugLog("QueueActivity printStatus History: \(historyQueue.count) items")
        
        historyQueue.forEach { item in
            Logger.debugLog("QueueActivity printStatus History: \(item.title)")
        }
        
        Logger.debugLog("QueueActivity printStatus ------------------------------------------")
        Logger.debugLog("QueueActivity printStatus futureQueue Items: \(futureQueue.count) items")
        
        futureQueue.forEach { item in
            Logger.debugLog("QueueActivity printStatus Upcoming: \(item.title)")
        }
        
        Logger.debugLog("QueueActivity printStatus ------------------------------------------")
        Logger.debugLog("QueueActivity printStatus AVQueuePlayer items: \(smPlayer.items().count)")
        
        smPlayer.items().forEach { item in
            Logger.debugLog("QueueActivity printStatus AVQueuePlayer: \(item.playlistItem?.title ?? "Unknown")")
        }
        
        Logger.debugLog("QueueActivity printStatus #################################################")
    }
    
    func enqueue(item: PlaylistItem) {
        futureQueue.append(item)
    }
    
    func createPlayerItemFromUri(_ uri: String?, fallbackUrl: String?, cookie: String?) -> AVPlayerItem? {
        let urlString = uri ?? fallbackUrl ?? ""
        guard !urlString.isEmpty else { return nil }
        
        if urlString.contains("https") {
            guard let url = URL(string: urlString) else { return nil }
            let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": ["Cookie": cookie ?? ""]]
            return AVPlayerItem(asset: AVURLAsset(url: url, options: assetOptions))
        } else {
            return AVPlayerItem(asset: AVAsset(url: URL(fileURLWithPath: urlString)))
        }
    }
    
    deinit {
        removeAll()
    }
}
