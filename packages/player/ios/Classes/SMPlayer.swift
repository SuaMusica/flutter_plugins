import Foundation
import AVFoundation
import MediaPlayer

public class SMPlayer : NSObject  {
    var methodChannelManager: MethodChannelManager?
    private var smPlayer: AVQueuePlayer
    private var playerItem: AVPlayerItem?
    private var queue : [AVPlayerItem] = []
    
    
    init(methodChannelManager: MethodChannelManager?) {
        smPlayer = AVQueuePlayer()
        super.init()
        self.methodChannelManager = methodChannelManager
        let listeners = SMPlayerListeners(playerItem: playerItem,smPlayer:smPlayer,methodChannelManager:methodChannelManager)
         listeners.addObservers()
    }
    
    private func setupNowPlaying() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.smPlayer.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }
    }

    func play(url: String) {
        guard let videoURL = URL(string: url) else { return }
        playerItem = AVPlayerItem(url: videoURL)
        smPlayer.replaceCurrentItem(with: playerItem)
        updateNowPlayingInfo()
        smPlayer.play()
    }

    func pause() {
        smPlayer.pause()
    }

    func stop() {
        smPlayer.pause()
        smPlayer.replaceCurrentItem(with: nil)
    }
    
    func enqueue(medias: [Media], autoPlay: Bool, cookie: String) {
        for media in medias {
            guard let url = URL(string: media.url) else { continue }
            queue.append(AVPlayerItem(url: url))
            let assetOptions = ["AVURLAssetHTTPHeaderFieldsKey": [ "Cookie": cookie]]
               let playerItem = AVPlayerItem(asset: AVURLAsset(url: url, options: assetOptions))
            smPlayer.insert(playerItem, after: nil)
        }
        
        if(autoPlay){
            smPlayer.play()
        }
    }
    
    func next(){
        smPlayer.advanceToNextItem()
    }
    
    func removeAll(){
        smPlayer.removeAllItems()
        queue.removeAll()
        smPlayer.pause()
        smPlayer.seek(to: .zero)
    }
    
    func play(){
        smPlayer.play()
    }
    
    private func updateNowPlayingInfo() {
//        guard let playerItem = playerItem else { return }
//        let artwork = MPMediaItemArtwork(image: UIImage(named: "queue.first.co)"))
//        let nowPlayingInfo: [String: Any] = [
//            MPMediaItemPropertyTitle: "Title",
//            MPMediaItemPropertyArtist: "Artist",
//            MPMediaItemPropertyArtwork: artwork,
//            MPMediaItemPropertyPlaybackDuration: playerItem.asset.duration.seconds,
//            MPNowPlayingInfoPropertyElapsedPlaybackTime: smPlayer.currentTime().seconds,
//            MPNowPlayingInfoPropertyPlaybackRate: smPlayer.rate
//        ]
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
