import MediaPlayer

@objc public class NowPlayingCenter : NSObject {
    
    @objc static public func set(item: PlaylistItem?, index: Int, count: Int) {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = [String: Any]()
        
        if let currentItem = item {
            nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
            
            if #available(iOS 10.0, *) {
                nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
                nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
            }
            
            nowPlayingInfo[MPMediaItemPropertyTitle] = currentItem.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = currentItem.artist
            
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = index
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = count
            
//            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = nil
//            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = nil
//            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = nil
//            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = nil
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    @objc static public func update(art: MPMediaItemArtwork) {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
                        
        nowPlayingInfo[MPMediaItemPropertyArtwork] = art
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    @objc static public func update(rate: Float, position: Double, duration: Double) {
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
                        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Float(duration)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Float(position)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
    
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}

