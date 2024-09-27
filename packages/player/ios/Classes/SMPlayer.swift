import Foundation
import AVFoundation
import MediaPlayer

private var playlistItemKey: UInt8 = 0

public class SMPlayer : NSObject  {
    var methodChannelManager: MethodChannelManager?
    private var smPlayer: AVQueuePlayer
    private var playerItem: AVPlayerItem?
//    private var queue : [PlaylistItem] = []
    
    
    init(methodChannelManager: MethodChannelManager?) {
        smPlayer = AVQueuePlayer()
        super.init()
        self.methodChannelManager = methodChannelManager
        let listeners = SMPlayerListeners(playerItem: playerItem,smPlayer:smPlayer,methodChannelManager:methodChannelManager)
         listeners.addObservers()
        setupNowPlayingInfoCenter()
        
        _ = AudioSessionManager.activeSession()
    }

    func play(url: String) {
        guard let videoURL = URL(string: url) else { return }
        playerItem = AVPlayerItem(url: videoURL)
        smPlayer.replaceCurrentItem(with: playerItem)
//        updateNowPlayingInfo()
        smPlayer.play()
    }

    func pause() {
        smPlayer.pause()
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
        for media in medias {
            guard let url = URL(string: media.url!) else { continue }
//            queue.append(media)
            let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": [ "Cookie": cookie]]
               let playerItem = AVPlayerItem(asset: AVURLAsset(url: url, options: assetOptions))
            playerItem.playlistItem = media
    
            smPlayer.insert(playerItem, after: smPlayer.items().isEmpty ? nil : smPlayer.items().last)
            
            
            print("enqueued: \(smPlayer.items().count)")
        }
        
        if(autoPlay){
            smPlayer.play()
        }
        NowPlayingCenter.set(item: getCurrentPlaylistItem())
//        methodChannelManager?.currentMediaIndex(index: getCurrentIndex() ?? 0)
    }
    
    func getCurrentIndex() -> Int? {
        guard let currentItem = smPlayer.currentItem else {
            return nil
        }

        return smPlayer.items().firstIndex(of: currentItem)
    }
    
    func next(){
        smPlayer.advanceToNextItem()
    }
    
    func removeAll(){
        smPlayer.removeAllItems()
//        queue.removeAll()
        smPlayer.pause()
        smPlayer.seek(to: .zero)
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
             smPlayer.advanceToNextItem()
             return .success
         }
         commandCenter.previousTrackCommand.addTarget {[self]event in
             smPlayer.advanceToNextItem()
             return .success
         }
         
         commandCenter.changePlaybackPositionCommand.addTarget{[self]event in
             let e = event as? MPChangePlaybackPositionCommandEvent
             seekToPosition(position: Int((e?.positionTime ?? 0) * 1000))
             return .success
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
