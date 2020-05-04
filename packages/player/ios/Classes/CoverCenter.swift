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
        return getCover(url: item?.coverUrl ?? defaultCover)
    }
    
    static private func getCover(url: String) -> MPMediaItemArtwork? {
        var data = getCoverFromCache(url: url)
        if (data == nil) {
            data = getCoverFromWeb(url: url)
            if data == nil {
                return nil
            } else {
                saveToLocalCache(url: url, data: data!)
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
    
    static private func getCoverFromCache(url: String) -> NSData? {
        let coverPath = getCoverPath(url)
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
    
    static private func saveToLocalCache(url: String, data: NSData) {
        DispatchQueue.global().async {
            do {
                try data.write(toFile: getCoverPath(url), options: NSData.WritingOptions.atomic)
            } catch let error as NSError {
                print("Player: Cover: Failed to save to local cache: \(error.localizedDescription)")
            }
        }
    }
    
    static private func getCoverPath(_ url: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectory = paths[0]
        if !FileManager.default.fileExists(atPath: documentDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: documentDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Player: Cover: Failed to create directory \(error.localizedDescription)");
            }
        }
        let coverPath = "\(documentDirectory)/\(url.md5())"
        return coverPath
    }
}
