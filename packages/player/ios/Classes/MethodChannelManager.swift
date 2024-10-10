//
//  MethodChannelManager.swift
//  smplayer
//
//  Created by Lucas Tonussi on 26/09/24.
//



import Foundation
import Flutter.FlutterPlugin



public class MethodChannelManager:NSObject{
    let channel: FlutterMethodChannel?
    init(channel: FlutterMethodChannel?) {
        self.channel = channel
    }
    var tag = "MethodChannelManager"
    
    func notifyPositionChange(
        position: Double,
        duration: Double) {
        let args = MethodChannelManagerArgsBuilder()
            .playerId(id:"smplayer")
            .position(position:Int(position)*1000)
            .duration(duration:Int(duration)*1000)
            .build()
            channel?.invokeMethod("audio.onCurrentPosition", arguments: args)
    }
    
    func notifyNetworkStatus(
    status:Bool) {
        let args = MethodChannelManagerArgsBuilder()
            .playerId(id:"smplayer")
            .build()
        channel?.invokeMethod("network.onChange", arguments: status ? "CONNECTED" : "DISCONNECTED")
    }
    
    
    func notifyPlayerStateChange(state: PlayerState) {
        print("#CheckListeners - notifyPlayerStateChange \(state)")
        let args = MethodChannelManagerArgsBuilder()
            .playerId(id:"smplayer")
            .state(state:state)
            .build()
        channel?.invokeMethod("state.change", arguments: args)
    }
    
    func notifyError(error: String? = nil) {
         let args = MethodChannelManagerArgsBuilder()
            .playerId(id: "smplayer")
            .state(state:PlayerState.error)
            .error(error:error)
            .build()
        channel?.invokeMethod("state.change", arguments: args)
     }
    
    func currentMediaIndex(index: Int) {
        let args = MethodChannelManagerArgsBuilder()
            .playerId(id:"smplayer")
            .currentIndex(index:index)
            .build()
        channel?.invokeMethod(SET_CURRENT_MEDIA_INDEX, arguments: args)
    }

    func repeatModeChanged(repeatMode: Int) {
        let args = MethodChannelManagerArgsBuilder()
            .repeatMode(repeatMode: repeatMode)
            .build()
        channel?.invokeMethod(REPEAT_MODE_CHANGED, arguments: args)
    }
    
    func shuffleChanged(shuffleIsActive: Bool) {
        let args = MethodChannelManagerArgsBuilder()
            .shuffleIsActive(shuffleIsActive: shuffleIsActive)
            .build()
        channel?.invokeMethod(SHUFFLE_CHANGED, arguments: args)
    }
}

