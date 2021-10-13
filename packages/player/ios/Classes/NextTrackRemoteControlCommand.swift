import Foundation
import MediaPlayer

class NextTrackRemoteControlCommand: RemoteControlCommand {
    var player: Player
    
    var commandId: Any? = nil
    
    init(player: Player) {
        self.player = player
    }
    
    func load() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        if (self.commandId != nil) {
            remoteCommandCenter.nextTrackCommand.removeTarget(self.commandId)
        }
        
        self.commandId = remoteCommandCenter.nextTrackCommand.addTarget(handler: { _ in
            print("Player: Remote Command Next Track: START")
            defer {
                print("Player: Remote Command Next Track: END")
            }
            
            if (self.player.isNotificationCommandEnabled()) {
                self.player.invokeMethod("commandCenter.onNext", arguments: [:])
            } else {
                print("Player: Remote Command Next Track: Disabled")
            }
                        
            return .success
        })
        remoteCommandCenter.nextTrackCommand.isEnabled = true;
    }
    
    func unload() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.nextTrackCommand.isEnabled = false
        remoteCommandCenter.nextTrackCommand.removeTarget(self.commandId)
        self.commandId = nil
    }
}
