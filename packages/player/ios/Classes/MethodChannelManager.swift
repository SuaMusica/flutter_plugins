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
//    let methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

    
    func notifyPositionChange(
        position: Double,
        duration: Double) {
        let args = MethodChannelManagerArgsBuilder()
            .playerId(id:"TAG_ONEPLAYER")
            .position(position:Int(position)*1000)
            .duration(duration:Int(duration)*1000)
//            .currentMediaIndex(currentMediaIndex:currentMediaIndex)
            .build()
            print("notifyPositionChange no tempo: \(position) segundos | duration: \(duration)")
            channel?.invokeMethod("audio.onCurrentPosition", arguments: args)
    }
    
    
    func notifyPlayerStateChange(state: PlayerState) {
        let args = MethodChannelManagerArgsBuilder()
            .playerId(id:"TAG_ONEPLAYER")
            .state(state:state)
            .build()
        channel?.invokeMethod("state.change", arguments: args)
    }
    
    func currentMediaIndex(index: Int) {
        let args = MethodChannelManagerArgsBuilder()
            .playerId(id:"TAG_ONEPLAYER")
            .currentIndex(index:index)
            .build()
        channel?.invokeMethod(SET_CURRENT_MEDIA_INDEX, arguments: args)
    }
//
//    func repeatModeChanged(repeatMode: Int) {
//        let args = MethodChannelManagerArgsBuilder()
//            .event(event: REPEAT_MODE_CHANGED)
//            .repeatMode(repeatMode: repeatMode)
//            .build()
//        eventSink?(args)
//    }
//    
//    func shuffleChanged(shuffleIsActive: Bool) {
//        let args = MethodChannelManagerArgsBuilder()
//            .event(event: SHUFFLE_CHANGED)
//            .shuffleIsActive(shuffleIsActive: shuffleIsActive)
//            .build()
//        eventSink?(args)
//    }
}

