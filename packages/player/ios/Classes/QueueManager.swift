import AVFoundation

class QueueManager {
    var historyQueue: [AVPlayerItem] = []
    var futureQueue: [AVPlayerItem] = []
    var originalQueue: [AVPlayerItem] = []
    var shuffledQueue: [AVPlayerItem] = []
    var shuffledIndices: [Int] = []
    var isShuffleModeEnabled: Bool = false
    private let smPlayer: AVQueuePlayer
    private let maxTotalItems: Int
    
    init(smPlayer: AVQueuePlayer, maxTotalItems: Int = 5) {
        self.smPlayer = smPlayer
        self.maxTotalItems = maxTotalItems
    }
    
    var fullQueue: [AVPlayerItem] {
        return historyQueue + smPlayer.items() + futureQueue
    }
    
    var currentIndex: Int {
        guard let currentItem = smPlayer.currentItem else {
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
    
    func distributeItemsInRightQueue(currentQueue: [AVPlayerItem], keepFirst: Bool = true, positionArg: Int = -1, completionHandler completion: (() -> Void)? = nil) {
        guard currentQueue.count > 0 else { return }
        var position = positionArg
        historyQueue.removeAll()
        futureQueue.removeAll()
        
        if keepFirst {
            position = smPlayer.currentItem != nil ? currentQueue.firstIndex(of: smPlayer.currentItem!) ?? -1 : -1
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
                smPlayer.insert(item, after: nil)
                futureQueue.removeFirst()
            }
        }
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
    
    func updateMediaUri(id: Int, uri: String?, createPlayerItemFromUri: (String?, String?, String?) -> AVPlayerItem?, cookie: String?) {
        var fullQueueUpdated = fullQueue
        if let index = fullQueue.firstIndex(where: { $0.playlistItem?.mediaId == id }) {
            let oldItem = fullQueueUpdated[index]
            if let playerItem = createPlayerItemFromUri(uri, oldItem.playlistItem?.fallbackUrl, cookie) {
                playerItem.playlistItem = oldItem.playlistItem
                fullQueueUpdated[index] = playerItem
                distributeItemsInRightQueue(currentQueue: fullQueueUpdated)
            }
        }
    }
    
    func playFromQueue(position: Int, timePosition: Int = 0, loadOnly: Bool = false, seekToPosition: ((Int) -> Void)? = nil, pause: (() -> Void)? = nil, play: (() -> Void)? = nil, notifyCurrentMediaIndex: ((Int) -> Void)? = nil, addMediaChangeObserver: (() -> Void)? = nil, shouldNotifyTransition: inout Bool) {
        distributeItemsInRightQueue(currentQueue: fullQueue, keepFirst: false, positionArg: position, completionHandler: {
            notifyCurrentMediaIndex?(self.currentIndex)
            if timePosition > 0 {
                seekToPosition?(timePosition)
            }
        })
        if loadOnly {
            pause?()
            shouldNotifyTransition = false
        } else {
            play?()
        }
        addMediaChangeObserver?()
    }
    
    func nextTrack(from: String, playFromQueue: ((Int) -> Void)? = nil, play: (() -> Void)? = nil) {
        smPlayer.pause()
        if let currentItem = smPlayer.currentItem {
            historyQueue.append(currentItem)
        }
        if smPlayer.currentItem == fullQueue.last && smPlayer.repeatMode == .REPEAT_MODE_ALL {
            playFromQueue?(0)
        }
        smPlayer.advanceToNextItem()
        smPlayer.seek(to: CMTime.zero)
        insertIntoPlayerIfNeeded()
        play?()
    }
    
    func previousTrack(seekToPosition: ((Int) -> Void)? = nil, play: (() -> Void)? = nil) {
        smPlayer.pause()
        guard let lastHistoryItem = historyQueue.popLast() else {
            seekToPosition?(0)
            return
        }
        guard let currentItem = smPlayer.currentItem else { return }
        guard let lastItemInPlayer = smPlayer.items().last else { return }
        if currentItem != lastItemInPlayer {
            smPlayer.remove(lastItemInPlayer)
            futureQueue.insert(lastItemInPlayer, at: 0)
        }
        smPlayer.insert(lastHistoryItem, after: currentItem)
        smPlayer.advanceToNextItem()
        smPlayer.insert(currentItem, after: smPlayer.currentItem)
        smPlayer.seek(to: CMTime.zero)
        insertIntoPlayerIfNeeded()
        play?()
    }
    
    func getCurrentPlaylistItem() -> PlaylistItem? {
        guard let currentItem = smPlayer.currentItem else {
            return nil
        }
        return currentItem.playlistItem
    }
    
    func printStatus(from: String) {
        // Implementação opcional para debug
    }
    
    func enqueue(item: AVPlayerItem) {
        futureQueue.append(item)
    }
} 