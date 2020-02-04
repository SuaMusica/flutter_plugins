import Foundation
import CoreData


public enum DownloadTrackStatus: Int {
    case downloading = 1
    case paused = 2
    case downloaded = 3
    case none = 4
}


class Track: Model {
    
    init() {
        let entityDescription = NSEntityDescription.entity(forEntityName: "Track", in: AppHelper.shared.managedObjectContext)
        super.init(entity: entityDescription!, insertInto: AppHelper.shared.managedObjectContext)
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        let entityDescription = NSEntityDescription.entity(forEntityName: "Track", in: AppHelper.shared.managedObjectContext)
        super.init(entity: entityDescription!, insertInto: AppHelper.shared.managedObjectContext)
    }

    var downloadTrackStatus: DownloadTrackStatus {
        guard let downloadStatus = downloadStatus?.intValue, let status = DownloadTrackStatus(rawValue: downloadStatus) else {
            return DownloadTrackStatus.none
        }
        return status
    }
    
    @NSManaged var album: String?
    @NSManaged var name: String?
    @NSManaged var artist: String?
    @NSManaged var cover: String?
    @NSManaged var username: String?
    @NSManaged var url: String?
    @NSManaged var streamURL: String?
    @NSManaged var path: String?
    @NSManaged var downloadStatus: NSNumber?
    @NSManaged var idProfile: String?
    @NSManaged var idTrack: String?
    @NSManaged var idCd: String?
    @NSManaged var plid: String?
    
    func delete(isDownloaded: Bool) {
        if isDownloaded {
            if let fileUrl = localFile() {
                do {
                    try FileManager.default.removeItem(at: fileUrl)
                } catch {
                    print("Falha ao deletar arquivo local: \(name ?? "") - \(error)")
                }
            }
        }
        delete()
    }
}

extension Track {
    func localFile() -> URL? {
        var isDir: ObjCBool = false
        if let idTrack = idTrack {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let fullPath = documentsPath.appendingPathComponent(idTrack)
            if FileManager.default.fileExists(atPath: "\(fullPath).mp3", isDirectory: &isDir) {
                return URL(fileURLWithPath: "\(fullPath).mp3")
            } else {
                if let path = path, let url = URL(string: path) {
                    let lastPathComponent = url.lastPathComponent
                    let fullPath = documentsPath.appendingPathComponent(lastPathComponent)
                    if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) {
                        return URL(fileURLWithPath:fullPath)
                    }
                }
            }
        }
        return nil
    }
}