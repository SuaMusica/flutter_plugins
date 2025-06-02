import MediaPlayer
import UIKit

class NowPlayingInfoManager {
    func setupNowPlayingInfoCenter(areNotificationCommandsEnabled: @escaping () -> Bool, play: @escaping () -> Void, pause: @escaping () -> Void, nextTrack: @escaping () -> Void, previousTrack: @escaping () -> Void, seekToPosition: @escaping (Int) -> Void) {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        
        commandCenter.pauseCommand.addTarget { _ in
            if areNotificationCommandsEnabled() {
                pause()
            }
            return .success
        }
        commandCenter.playCommand.addTarget { _ in
            if areNotificationCommandsEnabled() {
                play()
            }
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { _ in
            if areNotificationCommandsEnabled() {
                nextTrack()
            }
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { _ in
            if areNotificationCommandsEnabled() {
                previousTrack()
            }
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            if areNotificationCommandsEnabled() {
                if let e = event as? MPChangePlaybackPositionCommandEvent {
                    seekToPosition(Int(e.positionTime * 1000))
                }
            }
            return .success
        }
    }
    
    func enableCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }
    
    func removeNotification() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        removeNotification()
    }
} 