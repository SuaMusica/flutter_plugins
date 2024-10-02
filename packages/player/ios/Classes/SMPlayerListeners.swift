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
    
    var onMediaChanged: (() -> Void)?
    
    init(playerItem: AVPlayerItem?, smPlayer: AVQueuePlayer,methodChannelManager: MethodChannelManager?) {
        self.playerItem = playerItem
        self.smPlayer = smPlayer
        self.methodChannelManager = methodChannelManager
        super.init()
        
        
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
                    NowPlayingCenter.update(item: smPlayer.currentItem?.playlistItem, rate: 1.0, position: position, duration: duration)
                }
            }
        }
        
        mediaChange = smPlayer.observe(\.currentItem, options: [.new, .old]) { [weak self] (player, change) in
            guard let self = self else { return }
            
            if let newItem = change.newValue, newItem != change.oldValue {
                onMediaChanged?()
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.itemTransition)
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
        
        playback = smPlayer.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] (player, change) in
            guard let self = self else { return }
            
            switch player.timeControlStatus {
            case .playing:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.playing)
            case .paused:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.paused)
            case .waitingToPlayAtSpecifiedRate:
                self.methodChannelManager?.notifyPlayerStateChange(state: PlayerState.buffering)
            @unknown default:
                break
            }
        }
        
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
