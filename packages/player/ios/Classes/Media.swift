class Media {
    let id: Int
    let name: String
    let albumId: Int
    let albumTitle: String
    let author: String
    var url: String
    var isLocal: Bool
    let localPath: String?
    let coverUrl: String
    let bigCoverUrl: String
    let isVerified: Bool
    let playlistId: Int?
    var fallbackUrl: String?
    
    // Inicializador para a classe
    init(id: Int, name: String, albumId: Int, albumTitle: String, author: String, url: String, isLocal: Bool, localPath: String?, coverUrl: String, bigCoverUrl: String, isVerified: Bool, playlistId: Int?, fallbackUrl: String?) {
        self.id = id
        self.name = name
        self.albumId = albumId
        self.albumTitle = albumTitle
        self.author = author
        self.url = url
        self.isLocal = isLocal
        self.localPath = localPath
        self.coverUrl = coverUrl
        self.bigCoverUrl = bigCoverUrl
        self.isVerified = isVerified
        self.playlistId = playlistId
        self.fallbackUrl = fallbackUrl
    }
}
