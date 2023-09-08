import Foundation
import MediaPlayer
import CommonCrypto
import SDWebImage
import SDWebImageWebPCoder

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
    private let defaultCover = "https://images.suamusica.com.br/gaMy5pP78bm6VZhPZCs4vw0TdEw=/500x500/imgs/cd_cover.png"
    
    @objc public static let shared = CoverCenter()
    
    private override init() {
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
    }
    
    
    @objc public func get(item: PlaylistItem?) -> MPMediaItemArtwork? {
        return getCover(item: item, url: item?.coverUrl ?? defaultCover)
    }
    
    @objc public func saveDefaultCover(path: String) {
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
    
    private func getCover(item: PlaylistItem?, url: String) -> MPMediaItemArtwork? {
        /// TODO: Aqui
        var data = getCoverFromCache(albumId: item?.albumId ?? "0", url: url)
        if (data == nil) {
            data = getCoverFromWeb(url: url)
            if (data == nil) {
                data = getCoverFromCache(albumId: "0", url: defaultCover)
            } else {
                print("Player: Cover: Got cover from web");
                saveToLocalCache(item: item, url: url, data: data!)
            }
        }
        
        let image = self.toUIImage(data: Data.init(referencing: data!), url: url)
        var art: MPMediaItemArtwork? = nil
        if (image != nil) {
            if #available(iOS 10.0, *) {
                art = MPMediaItemArtwork.init(boundsSize: image!.size, requestHandler: { (size) -> UIImage in
                    return image!
                })
            } else {
                art = MPMediaItemArtwork.init(image: image!)
            }
        } else {
            art = getDefaultCover()
        }
        return art
    }
    
    private func toUIImage(data: Data, url: String) -> UIImage? {
        let fileExt = self.fileExt(url: url)
        if (fileExt.hasPrefix(".webp") || url.contains("filters:format(webp)")) {
            return SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
        } else {
            return UIImage.init(data: data)
        }
    }
    
    // url - defaultCover
    private func getDefaultCover() -> MPMediaItemArtwork? {
        let data = getCoverFromCache(albumId: "0", url: defaultCover)
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
    
    // atribuído
    private func getCoverFromCache(albumId: String, url: String) -> NSData? {
        /// TODO: Aqui
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
    
    private func getCoverFromWeb(url: String) -> NSData? {
        do {
            // Synchronous URL loading of should not occur on this application's main thread as it may lead to UI unresponsiveness.
            // Please switch to an asynchronous networking API such as URLSession.
            let data = try NSData.init(contentsOf: URL.init(string: url)!, options: Data.ReadingOptions.mappedIfSafe)
            return data
        } catch let error as NSError {
            print("Player: Cover: Failed to set retrieve cover from web: \(error.localizedDescription)")
            return nil
        }
    }
    
    // atribuido
    private func saveToLocalCache(item: PlaylistItem?, url: String, data: NSData) {
        DispatchQueue.global().async {
            do {
                try data.write(toFile: self.getCoverPath(albumId: item?.albumId ?? "0", url: url), options: NSData.WritingOptions.atomic)
            } catch let error as NSError {
                print("Player: Cover: Failed to save to local cache: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCoverPath(albumId: String, url: String) -> String {
        // var paths = NSSearchPathForDirectoriesInDomains(
        //     FileManager.SearchPathDirectory.applicationSupportDirectory,
        //     FileManager.SearchPathDomainMask.userDomainMask,
        //     true
        // )

        var paths = [""];

        // paths is empty or null, try to get the documents directory
        print("coverpath paths \(paths) - albumId \(albumId) - url \(url)")

        if (paths.isEmpty || paths[0].isEmpty) {
            return uiImageToAssetString()
        }

        let documentDirectory = "\(paths[0])/covers"
        print("coverpath dir \(documentDirectory)")
        if !FileManager.default.fileExists(atPath: documentDirectory) {
            do {
                print("coverpath is \(documentDirectory)")
                try FileManager.default.createDirectory(atPath: documentDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("coverpath error \(error.localizedDescription)");
                print("Player: Cover: Failed to create directory \(error.localizedDescription)");
                return uiImageToAssetString()
            }
        }
        var fileExt = self.fileExt(url: url)
        if (fileExt.hasPrefix(".webp") || url.contains("filters:format(webp)")) {
            fileExt = ".webp"
        }
        let coverPath = "\(documentDirectory)/\(albumId)\(fileExt)"
        return coverPath
    }
    
    private func fileExt(url: String) -> String {
        let index = url.lastIndex(of: ".")
        let fileExt = url.suffix(from: index!)
        return "\(fileExt)"
    }

    private func uiImageToAssetString() -> String {
        print("coverpath uiimage local")
        let image = UIImage(named: "cover")
        guard let data = image?.pngData() else {
            return ""
        }
        print("coverpath uiimage local 2")
        return data.base64EncodedString(options: .lineLength64Characters)
    }
}
