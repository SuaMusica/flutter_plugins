//
//  SMPlayerListeners.swift
//  smplayer
//
//  Created by Lucas Tonussi on 26/09/24.
//

import Foundation
import AVFoundation

public class SMPlayerListeners : NSObject {
    var playerItem:AVPlayerItem?
    let smPlayer:AVQueuePlayer
    let methodChannelManager: MethodChannelManager?
    
    init(playerItem: AVPlayerItem?, smPlayer: AVQueuePlayer,methodChannelManager: MethodChannelManager?) {
        self.playerItem = playerItem
        self.smPlayer = smPlayer
        self.methodChannelManager = methodChannelManager
    }

    private var mediaChange: NSKeyValueObservation?
    private var statusChange: NSKeyValueObservation?
    private var loading: NSKeyValueObservation?
    private var loaded: NSKeyValueObservation?
    private var error: NSKeyValueObservation?
    private var notPlayingReason: NSKeyValueObservation?
    private var playback: NSKeyValueObservation?
    
    func addObservers() {
        let interval = CMTime(seconds: 0.5,
                                      preferredTimescale: CMTimeScale(NSEC_PER_SEC))
               smPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [self] time in
                    let position : Float64 = CMTimeGetSeconds(smPlayer.currentTime());
                    if(smPlayer.currentItem != nil){
                        let duration : Float64 = CMTimeGetSeconds(smPlayer.currentItem!.duration);
                        if(position < duration){
                            methodChannelManager?.notifyPositionChange(position: position, duration: duration)
                        }
                    }
                }

                mediaChange = smPlayer.observe(\.currentItem, options: [.new,.old]) { [self]
                    (player, item) in
                    if(item.oldValue! != nil && (item.newValue != item.oldValue)){
//                        OnePlayerSingleton.i.currentInterval += 1
                    }
                    if(item.newValue != item.oldValue){
                       print("onMediaChanged")
                    }
                }

                statusChange = smPlayer.currentItem?.observe(\.status, options:  [.new, .old], changeHandler: {
                    (playerItem, change) in
                    if playerItem.status == .readyToPlay {
                        print("readyToPlay")
                    } else if playerItem.status == .failed {
                        print("failed")
                    }
                })

                loading = smPlayer.currentItem?.observe(\.isPlaybackBufferEmpty, options: [.new,.old]) { [self]
                    (new, old) in
                   print("observer - loading")
                    methodChannelManager?.notifyPlayerStateChange(state:  PlayerState.buffering)
                }

                loaded = smPlayer.currentItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) {
                    (player, _) in
//                    OnePlayerSingleton.i.log(tag: tag, message: "observer - loaded \(player)")
                    print("observer - loaded")
                }


                notPlayingReason = smPlayer.observe(\.reasonForWaitingToPlay, options: [.new], changeHandler: { [self]
                    (playerItem, change) in
                    switch (smPlayer.reasonForWaitingToPlay) {
                    case AVPlayer.WaitingReason.evaluatingBufferingRate:
                        print("evaluatingBufferingRate")
                    case AVPlayer.WaitingReason.toMinimizeStalls:
                        print("toMinimizeStalls")
                    case AVPlayer.WaitingReason.noItemToPlay:
                        print("noItemToPlay")
                    default:
                        print("default")
                    }
                })

                playback = smPlayer.observe(\.timeControlStatus, options: [.new, .old], changeHandler: { [self]
                    (playerItem, change) in
                    switch (playerItem.timeControlStatus) {
                    case AVPlayer.TimeControlStatus.paused:
                        print("observer - paused")
//                        onePlayerManager?.onStateChange(state: OnePlayerState.PAUSED)
                        methodChannelManager?.notifyPlayerStateChange(state:  PlayerState.paused)
                        break
                    case AVPlayer.TimeControlStatus.playing:
                        print("observer - playing")
                        methodChannelManager?.notifyPlayerStateChange(state:  PlayerState.playing)
                        break
                    case AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate:
                        print("observer - waitingToPlayAtSpecifiedRate")
                        break
                    default:
                        print("observer - default: \(AVPlayer.TimeControlStatus.self)")
                        break
                    }
                })

                smPlayer.addObserver(self, forKeyPath: "error", options: [.old, .new], context: nil)
    }
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "error", let change = change, let error = change[.newKey] as? Error {
            if (error as NSError).code == AVError.contentIsNotAuthorized.rawValue {
                print("Erro HTTP: contentIsNotAuthorized")
            }
        }
    }

}
