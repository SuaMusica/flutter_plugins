//
//  MethodChannelManagerArgsBuilder.swift
//  oneplayer_ios
//
//  Created by Lucas Tonussi on 04/10/22.
//

import Foundation
class MethodChannelManagerArgsBuilder{
    var tag = "MethodChannelManagerArgsBuilder"
    var args : Dictionary<String, Any> = [:]
    
    open func build() -> Dictionary<String, Any>{
        return args
    }
    
    open func position(position: Int) -> MethodChannelManagerArgsBuilder{
        args[POSITION_ARGS] = position
        return self
    }
    
    func shuffleIsActive(shuffleIsActive: Bool) -> MethodChannelManagerArgsBuilder {
        args[SHUFFLE_ARGS] = shuffleIsActive
        return self
    }
    
    open func duration(duration: Int) -> MethodChannelManagerArgsBuilder {
        args[DURATION_ARGS] = duration
        return self
    }
    
    open func playerId(id: String) -> MethodChannelManagerArgsBuilder {
        args[PLAYER_ID_ARGS] = id
        return self
    }
    
    open func currentMediaIndex(currentMediaIndex: Int) -> MethodChannelManagerArgsBuilder {
        args[CURRENT_MEDIA_INDEX_ARGS] = currentMediaIndex
        return self
    }
    
    open func state(state: PlayerState) -> MethodChannelManagerArgsBuilder {
        args[STATE_ARGS] = state.rawValue
        return self
    }
    
    open func currentIndex(index: Int) -> MethodChannelManagerArgsBuilder {
        args[CURRENT_MEDIA_INDEX_ARGS] = index
        return self
    }
    
//    open func queue(queue: Array<Media>) -> MethodChannelManagerArgsBuilder {
//        let queueJson = JsonUtil.toJson(queue) as? String
//        //TODO: Melhorar o tratamento do null
//        args[QUEUE_ARGS] = queueJson!.replacingOccurrences(of: "{}", with: "null")
//        return self
//    }
    
    open func error(error: String?) -> MethodChannelManagerArgsBuilder {
        if(error != nil){
            args[ERROR_ARGS] = error
        }
        return self
    }
    
    
    open func repeatMode(repeatMode: Int) -> MethodChannelManagerArgsBuilder {
        args[REPEAT_MODE_ARGS] = repeatMode
        return self
    }
    
}
