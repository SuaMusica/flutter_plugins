import Flutter
import UIKit
import AVFoundation
import Foundation
//import Alamofire

let TAG = "SMPlayerIos"
let CHANNEL = "suamusica.com.br/player"
let CHANNEL_NOTIFICATION = "One_Player_Notification"
let NOTIFICATION_ID = 0xb339
//let MIME_TYPE_HLS = MimeTypes.APPLICATION_M3U8
//let AUDIO_MPEG = MimeTypes.BASE_TYPE_AUDIO
var registrarAds: FlutterPluginRegistrar? = nil
private let tag = TAG

private var smPlayer: SMPlayer? = nil




public class PlayerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: registrar.messenger())
        let instance = PlayerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        registrarAds = registrar
        smPlayer = SMPlayer(methodChannelManager: MethodChannelManager(channel: channel))
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("call.method: \(call.method)")
        switch call.method {
        case "enqueue":
            if let batch = call.arguments as? [String: Any],
               let listMedia = batch["batch"] as? [[String: Any]]{
                let autoPlay = batch["autoPlay"] as? Bool ?? false
                let cookie = batch["cookie"] as? String ?? ""
                if convertToMedia(mediaArray: listMedia) != nil {
                    smPlayer?.enqueue(medias: convertToMedia(mediaArray: listMedia)!, autoPlay: autoPlay,cookie: cookie)
                 }
            }
            result(NSNumber(value: true))
        case "next":
            smPlayer?.next()
            result(NSNumber(value: 1))
        case "play":
            smPlayer?.play()
            result(NSNumber(value: 1))
        case "pause":
            smPlayer?.pause()
            result(NSNumber(value: 1))
        case "remove_all":
            result(NSNumber(value: true))
        default:
            result(NSNumber(value: false))
        }
    }
    
    func convertToMedia(mediaArray: [[String: Any]]) -> [Media]? {
        var mediaList: [Media] = []
        
        for mediaDict in mediaArray {
            
          var id = mediaDict["id"] // Certificar que 'id' é um número
          let name = mediaDict["name"]
          let albumId = mediaDict["albumId"]
          let albumTitle = mediaDict["albumTitle"]
          let author = mediaDict["author"]
          let url = mediaDict["url"]
          let isLocal = mediaDict["isLocal"]
          let coverUrl = mediaDict["coverUrl"]
          let bigCoverUrl = mediaDict["bigCoverUrl"]
          let isVerifiedString = mediaDict["isVerified"]
          let isVerified = isVerifiedString
        
    

            // Atribuição opcional
            let localPath = mediaDict["localPath"]
            let playlistId = mediaDict["playlistId"]
            let fallbackUrl = mediaDict["fallbackUrl"]

            // Criar o objeto Media e adicionar à lista
            let media = Media(
                id: id as! Int,
                name: name as! String,
                albumId: albumId as! Int,
                albumTitle: albumTitle as! String,
                author: author as! String,
                url: url as! String,
                isLocal: isLocal as? Bool ?? false,
                localPath: localPath as? String ?? "",
                coverUrl: coverUrl as? String ?? "",
                bigCoverUrl: bigCoverUrl as? String ?? "",
                isVerified: isVerified as? Bool ?? false,
                playlistId: playlistId as? Int ?? 0,
                fallbackUrl: fallbackUrl as? String ?? ""
            )
            mediaList.append(media)
        }
        
        return mediaList
    }

}
