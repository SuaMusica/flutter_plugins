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
    
    @objc public init(albumId: String, albumName: String, title: String, artist: String, url: String, coverUrl: String) {
        self.albumId = albumId
        self.albumName = albumName
        self.title = title
        self.artist = artist
        self.url = url
        self.coverUrl = coverUrl
        self.duration = .zero
        self.error = nil
    }
}
