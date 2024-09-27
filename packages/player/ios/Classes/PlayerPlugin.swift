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


var currentIndex:Int = 0

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
    
    func convertToMedia(mediaArray: [[String: Any]]) -> [PlaylistItem]? {
        var mediaList: [PlaylistItem] = []
        
        for mediaDict in mediaArray {
    
          var id = mediaDict["id"] // Certificar que 'id' é um número
          let title = mediaDict["name"]
          let albumId = mediaDict["albumId"]
          let albumName = mediaDict["albumTitle"]
          let artist = mediaDict["author"]
          let url = mediaDict["url"]
          let isLocal = mediaDict["isLocal"]
          let coverUrl = mediaDict["cover_url"]
          let bigCoverUrl = mediaDict["bigCoverUrl"]
          let isVerifiedString = mediaDict["isVerified"]
          let isVerified = isVerifiedString
        
    

            // Atribuição opcional
            let localPath = mediaDict["localPath"]
            let playlistId = mediaDict["playlistId"]
            let fallbackUrl = mediaDict["fallbackUrl"]
            
            // Criar o objeto Media e adicionar à lista
            let media = PlaylistItem(
                albumId:String(albumId as! Int),
                albumName: albumName as! String,
                title:title as! String,
                artist: artist as! String,
                url: url as! String,
                coverUrl: coverUrl as? String ?? "",
                fallbackUrl: fallbackUrl as? String ?? "",
                mediaId: id as! Int,
                bigCoverUrl: bigCoverUrl as? String ?? ""
            )
            mediaList.append(media)
        }
        
        return mediaList
    }
    
    deinit {
        smPlayer?.clearNowPlayingInfo()
    }

}
