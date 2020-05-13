import Foundation
import MediaPlayer
import CommonCrypto

extension String {
    func md5() -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.base64EncodedString().replacingOccurrences(of: "/", with: "A")
    }
}

@objc public class CoverCenter : NSObject {
    private static let defaultCover = "https://images.suamusica.com.br/gaMy5pP78bm6VZhPZCs4vw0TdEw=/500x500/imgs/cd_cover.png"
    
    @objc static public func get(item: PlaylistItem?) -> MPMediaItemArtwork? {
        return getCover(item: item, url: item?.coverUrl ?? defaultCover)
    }
    
    @objc static public func saveDefaultCover(path: String) {
        let fileName = getCoverPath(albumId: "0", url: path)
        if !FileManager.default.fileExists(atPath: fileName) {
            do {
                try FileManager.default.copyItem(atPath: path, toPath: fileName)
                print("Player: Cover: Default Cover was succesfully set from asset (\(path)) to path (\(fileName))")
            } catch let error as NSError {
                print("Player: Cover: Failed to set default cover from (\(path) to (\(fileName): \(error.localizedDescription)")
            }
        }
    }
    
    static private func getCover(item: PlaylistItem?, url: String) -> MPMediaItemArtwork? {
        var data = getCoverFromCache(albumId: item?.albumId ?? "0", url: url)
        if (data == nil) {
            data = getCoverFromWeb(url: url)
            if data == nil {
                data = getCoverFromCache(albumId: "0", url: defaultCover)
            } else {
                saveToLocalCache(item: item, url: url, data: data!)
            }
        }
        
        let image = UIImage.init(data: Data.init(referencing: data!))
        var art: MPMediaItemArtwork? = nil
        if #available(iOS 10.0, *) {
            art = MPMediaItemArtwork.init(boundsSize: image!.size, requestHandler: { (size) -> UIImage in
                return image!
            })
        } else {
            art = MPMediaItemArtwork.init(image: image!)
        }
        return art
    }
    
    static private func getCoverFromCache(albumId: String, url: String) -> NSData? {
        let coverPath = getCoverPath(albumId: albumId, url: url)
        do {
            let data = try NSData.init(contentsOfFile: coverPath, options: NSData.ReadingOptions.mappedRead)
            print("Player: Cover: Got cover from cache!")
            return data
        } catch let error as NSError {
            print("Player: Cover: Failed to set retrieve cover from cache (\(coverPath)): \(error.localizedDescription)")
            return nil
        }
    }
    
    static private func getCoverFromWeb(url: String) -> NSData? {
        do {
            let data = try NSData.init(contentsOf: URL.init(string: url)!, options: Data.ReadingOptions.mappedIfSafe)
            return data
        } catch let error as NSError {
            print("Player: Cover: Failed to set retrieve cover from web: \(error.localizedDescription)")
            return nil
        }
    }
    
    static private func saveToLocalCache(item: PlaylistItem?, url: String, data: NSData) {
        DispatchQueue.global().async {
            do {
                try data.write(toFile: getCoverPath(albumId: item?.albumId ?? "0", url: url), options: NSData.WritingOptions.atomic)
            } catch let error as NSError {
                print("Player: Cover: Failed to save to local cache: \(error.localizedDescription)")
            }
        }
    }
    
    static private func getCoverPath(albumId: String, url: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationSupportDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectory = "\(paths[0])/covers"
        if !FileManager.default.fileExists(atPath: documentDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: documentDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Player: Cover: Failed to create directory \(error.localizedDescription)");
            }
        }
        let index = url.lastIndex(of: ".")
        let fileExt = url.suffix(from: index!)
        let coverPath = "\(documentDirectory)/\(albumId)\(fileExt)"
        return coverPath
    }
}
