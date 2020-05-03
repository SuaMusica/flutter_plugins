import AVFoundation

@objc public class PlaylistItem : NSObject {
    @objc public let error: Error?
    
    @objc public let title: String
    
    @objc public let artist: String
    
    @objc public let url: String?
    
    @objc public let coverUrl: String?
    
    @objc public let duration: CMTime
    
    @objc public init(title: String, artist: String, url: String, coverUrl: String) {
        self.title = title
        self.artist = artist
        self.url = url
        self.coverUrl = coverUrl
        self.duration = .zero
        self.error = nil
    }
}
