import Foundation
import MediaPlayer

class PlayRemoteControlCommand: RemoteControlCommand {
    let statePlaying = 2
    var player: Player
    
    var commandId: Any? = nil
    
    init(player: Player) {
        self.player = player
    }
    
    func load() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        if (self.commandId != nil) {
            remoteCommandCenter.playCommand.removeTarget(self.commandId)
        }
        
        self.commandId = remoteCommandCenter.playCommand.addTarget(handler: { _ in
            print("Player: Remote Command Play: START")
            defer {
                print("Player: Remote Command Play: END")
            }
            
            if (self.player.isNotificationCommandEnabled()) {
                _ = self.player.resume()
                self.player.notifyStateChange(self.statePlaying, overrideBlock: true)
                self.player.invokeMethod("commandCenter.onPlay", arguments: [:])
            } else {
                print("Player: Remote Command Play: Disabled")
            }
                        
            return .success
        })
        remoteCommandCenter.playCommand.isEnabled = true;
    }
    
    func unload() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.playCommand.isEnabled = false
        remoteCommandCenter.playCommand.removeTarget(self.commandId)
        self.commandId = nil
    }
}
