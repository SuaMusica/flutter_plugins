import AVFoundation

@objc public class PlaylistItem : NSObject {
    @objc public var error: Error?
    
    @objc public var albumId: String
    
    @objc public var albumName: String
    
    @objc public var title: String
    
    @objc public var artist: String
    
    @objc public var url: String?
    
    @objc public var coverUrl: String?
    
    @objc public var duration: CMTime
    
    @objc public var fallbackUrl: String?
    
    @objc public var mediaId: Int
    
    @objc public var bigCoverUrl: String?
    
    @objc public var cookie: String?
//    @objc public var index: Int
    
    @objc public init(albumId: String, albumName: String, title: String, artist: String, url: String, coverUrl: String,fallbackUrl: String, mediaId:Int, bigCoverUrl: String, cookie: String) {
        self.albumId = albumId
        self.albumName = albumName
        self.title = title
        self.artist = artist
        self.url = url
        self.coverUrl = coverUrl
        self.duration = .zero
        self.error = nil
        self.fallbackUrl = fallbackUrl
        self.mediaId = mediaId
        self.bigCoverUrl = bigCoverUrl
        self.cookie = cookie
    }
}
