import Foundation
import MediaPlayer

class TogglePlayPauseRemoteControlCommand: RemoteControlCommand {
    var player: Player
    
    var commandId: Any? = nil
    
    init(player: Player) {
        self.player = player
    }
    
    func load() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        if (self.commandId != nil) {
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(self.commandId)
        }

        self.commandId = remoteCommandCenter.togglePlayPauseCommand.addTarget(handler: { _ in
            print("Player: Remote Command Toggle Play Pause: START")
            defer {
                print("Player: Remote Command Toggle Play Pause: END")
            }

            if (self.player.isNotificationCommandEnabled()) {
                if (self.player.rate() == 0.0) {
                    _ = self.player.resume()
                } else {
                    _ = self.player.pause()
                }
            } else {
                print("Player: Remote Command Toggle Play Pause: Disabled")
            }

            return .success
        })
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true;
    }
    
    func unload() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = false
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(self.commandId)
        self.commandId = nil
    }
}
