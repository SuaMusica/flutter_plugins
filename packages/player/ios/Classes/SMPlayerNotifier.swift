//
//  SMPlayerNotifier.swift
//  smplayer
//
//  Created by Lucas Tonussi on 26/09/24.
//
private let tag = "SMPlayerNotifier"

import Foundation
public class SMPlayerNotifier : NSObject{
   
   let methodChannelManager: MethodChannelManager?
    init(methodChannelManager: MethodChannelManager?) {
        self.methodChannelManager = methodChannelManager
    }
    
    func notifyPositionChange(position: Double, duration: Double, currentMediaIndex: Int) {
        if (duration >= 0 && position >= 0) {
            methodChannelManager?.notifyPositionChange(position:position, duration:duration)
        }
    }
    
//    func notifyPlayerStateChange(  state: OnePlayerState,
//                                   error: String? = nil,
//                                   currentMediaIndex: Int,
//                                   itsAdTime: Bool?){
//        methodChannelManager.notifyPlayerStateChange(state: state, currentMediaIndex: currentMediaIndex, itsAdTime: itsAdTime)
//    }
    
//    func repeatModeChanged(repeatMode:Int){
//        methodChannelManager?.repeatModeChanged(repeatMode: repeatMode)
//    }
//    
//    func onAds(status: String,code: String?, message: String?, isAudioAd: Bool = false){
//        methodChannelManager>.onAds(status: status, code: code, message: message, isAudioAd: isAudioAd)
//    }
//    
//    func shuffleChanged(shuffleIsActive: Bool){
//        methodChannelManager?.shuffleChanged(shuffleIsActive: shuffleIsActive)
//    }
    
}
