import Foundation
import MediaPlayer

class PauseRemoteControlCommand: RemoteControlCommand {
    let statePaused = 3
    var player: Player
    
    var commandId: Any? = nil
    
    init(player: Player) {
        self.player = player
    }
    
    func load() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        if (self.commandId != nil) {
            remoteCommandCenter.pauseCommand.removeTarget(self.commandId)
        }
        
        self.commandId = remoteCommandCenter.pauseCommand.addTarget(handler: { _ in
            print("Player: Remote Command Pause: START")
            defer {
                print("Player: Remote Command Pause: END")
            }
            
            if (self.player.isNotificationCommandEnabled()) {
                _ = self.player.pause()
                self.player.notifyStateChange(self.statePaused, overrideBlock: true)
                self.player.invokeMethod("commandCenter.onPause", arguments: [:])
            } else {
                print("Player: Remote Command Pause: Disabled")
            }
                        
            return .success
        })
        remoteCommandCenter.pauseCommand.isEnabled = true;
    }
    
    func unload() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.pauseCommand.isEnabled = false
        remoteCommandCenter.pauseCommand.removeTarget(self.commandId)
        self.commandId = nil
    }
}
