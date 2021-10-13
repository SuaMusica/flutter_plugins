import Foundation
import MediaPlayer

class PreviousTrackRemoteControlCommand: RemoteControlCommand {
    var player: Player
    
    var commandId: Any? = nil
    
    init(player: Player) {
        self.player = player
    }
    
    func load() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        if (self.commandId != nil) {
            remoteCommandCenter.previousTrackCommand.removeTarget(self.commandId)
        }
        
        self.commandId = remoteCommandCenter.previousTrackCommand.addTarget(handler: { _ in
            print("Player: Remote Command Next Track: START")
            defer {
                print("Player: Remote Command Next Track: END")
            }
            
            if (self.player.isNotificationCommandEnabled()) {
                self.player.invokeMethod("commandCenter.onPrevious", arguments: [:])
            } else {
                print("Player: Remote Command Next Track: Disabled")
            }
                        
            return .success
        })
        remoteCommandCenter.previousTrackCommand.isEnabled = true;
    }
    
    func unload() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.previousTrackCommand.isEnabled = false
        remoteCommandCenter.previousTrackCommand.removeTarget(self.commandId)
        self.commandId = nil
    }
}
