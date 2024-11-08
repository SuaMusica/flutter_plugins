import Flutter
import UIKit
import AVFoundation
import Foundation
//import Alamofire

let TAG = "SMPlayerIos"
let CHANNEL = "suamusica.com.br/player"
let CHANNEL_NOTIFICATION = "One_Player_Notification"
let NOTIFICATION_ID = 0xb339
private let tag = TAG

private var smPlayer: SMPlayer? = nil

public class PlayerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: registrar.messenger())
        let instance = PlayerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        smPlayer = SMPlayer(methodChannelManager: MethodChannelManager(channel: channel))
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("call.method: \(call.method)")
        switch call.method {
        case "enqueue":
            if let batch = call.arguments as? [String: Any],
               let listMedia = batch["batch"] as? [[String: Any]] {
                let autoPlay = batch["autoPlay"] as? Bool ?? false
                let cookie = batch["cookie"] as? String ?? ""
                if let mediaList = convertToMedia(mediaArray: listMedia) {
                    MessageBuffer.shared.send(mediaList)
                    smPlayer?.enqueue(medias: mediaList, autoPlay: autoPlay, cookie: cookie)
                }
            }
            result(NSNumber(value: true))
        case "next":
            smPlayer?.nextTrack(from:"next call")
            result(NSNumber(value: 1))
        case "previous":
            smPlayer?.previousTrack()
            result(NSNumber(value: 1))
        case "play":
            smPlayer?.play()
            result(NSNumber(value: 1))
        case "pause":
            smPlayer?.pause()
            result(NSNumber(value: 1))
        case "toggle_shuffle":
            if let args = call.arguments as? [String: Any]{
                smPlayer?.toggleShuffle(positionsList: args["positionsList"] as! [[String: Int]])
            }
            result(NSNumber(value: 1))
        case "disable_repeat_mode":
            smPlayer?.disableRepeatMode()
            result(NSNumber(value: 1))
        case "playFromQueue":
            if let args = call.arguments as? [String: Any] {
                smPlayer?.playFromQueue(position: args["position"] as? Int ?? 0, timePosition: args["timePosition"] as? Int ?? 0, loadOnly: args["loadOnly"] as? Bool ?? false)
            }
            result(NSNumber(value: 1))
        case "remove_all":
            smPlayer?.removeAll()
            result(NSNumber(value: true))
        case "repeat_mode":
            smPlayer?.toggleRepeatMode()
            result(NSNumber(value: 1))
        case "remove_in":
            let args = call.arguments as? [String: Any]
            smPlayer?.removeByPosition(indexes:args?["indexesToDelete"] as? [Int] ?? [])
            result(NSNumber(value: 1))
        case "reorder":
            if let args = call.arguments as? [String: Any],
               let oldIndex = args["oldIndex"] as? Int,
               let newIndex = args["newIndex"] as? Int,
               let positionsList = args["positionsList"] as? [[String : Int]] {
                smPlayer?.reorder(fromIndex: oldIndex, toIndex: newIndex,positionsList: positionsList)
            }
            result(NSNumber(value: true))
        case "update_media_uri":
            if let args = call.arguments as? [String: Any],
               let id = args["id"] as? Int,
               let uri = args["uri"] as? String {
                smPlayer?.updateMediaUri(id: id, uri: uri)
            }
            result(NSNumber(value: true))
        case "seek":
            if let args = call.arguments as? [String: Any] {
                let position = args["position"] as? Int ?? 0
                smPlayer?.seekToPosition(position: position)
            }
            result(NSNumber(value: 1))
        default:
            result(NSNumber(value: 0))
        }
    }
    
    func convertToMedia(mediaArray: [[String: Any]]) -> [PlaylistItem]? {
        let enqueueStartTime = Date()
        var mediaList: [PlaylistItem] = []
        
        for mediaDict in mediaArray {
            
            let id = mediaDict["id"]
            let title = mediaDict["name"]
            let albumId = mediaDict["albumId"]
            let albumName = mediaDict["albumTitle"]
            let artist = mediaDict["author"]
            let url = mediaDict["url"]
            let isLocal = mediaDict["isLocal"]
            let coverUrl = mediaDict["cover_url"]
            let bigCoverUrl = mediaDict["bigCoverUrl"]
            let isVerifiedString = mediaDict["isVerified"]
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
                bigCoverUrl: bigCoverUrl as? String ?? "",
                cookie: ""
            )
            mediaList.append(media)
        }
        let enqueueEndTime = Date()
        let enqueueTime = enqueueEndTime.timeIntervalSince(enqueueStartTime)
        print("PlayerPlugin: convertToMedia concluído em \(enqueueTime) segundos mediaArray: \(mediaArray.count)")
        return mediaList
    }
    
    deinit {
        print("PlayerPlugin: deinit")
        smPlayer?.clearNowPlayingInfo()
        smPlayer?.removeAll()
    }
    
}
