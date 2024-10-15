import MediaPlayer

public class NowPlayingCenter : NSObject {
    
    @objc static public func set(item: PlaylistItem?) {
        DispatchQueue.main.async {
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
                
                let art = CoverCenter.shared.get(item: item)
                if art != nil {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = art
                }
            }
            
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
    
    @objc static public func update(item: PlaylistItem?, rate: Float, position: Double, duration: Double) {
        DispatchQueue.main.async {
            let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
            var nowPlayingInfo = [String: Any]()
            
            if let currentItem = item {
                nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
                
                if #available(iOS 10.0, *) {
                    nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
                    nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
                }
                
                if(nowPlayingInfo[MPMediaItemPropertyTitle] == nil || (nowPlayingInfo[MPMediaItemPropertyTitle] != nil && nowPlayingInfo [MPMediaItemPropertyTitle] as! String != currentItem.title)){
                    nowPlayingInfo[MPMediaItemPropertyTitle] = currentItem.title
                    nowPlayingInfo[MPMediaItemPropertyArtist] = currentItem.artist
                    
                    let art = CoverCenter.shared.get(item: item)
                    if art != nil {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = art
                    }
                }
            }
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Float(duration)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Float(position)
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
    
}
