import Foundation
import MediaPlayer

@objc public protocol RemoteControlCenter {
    func start()
    func stop()
}

protocol RemoteControlCommand {
    func load()
    func unload()
}

@objc public class RemoteControlCenterFactory: NSObject {
    @objc public static let shared = RemoteControlCenterFactory()
    
    private override init() {
    }
    
    @objc public func create(player: Player) -> RemoteControlCenter {
        return RemoteControlCenterImpl(commands: [
                PlayRemoteControlCommand(player: player),
                PauseRemoteControlCommand(player: player),
                TogglePlayPauseRemoteControlCommand(player: player),
                NextTrackRemoteControlCommand(player: player),
                PreviousTrackRemoteControlCommand(player: player)
        ])
    }
}


@objc public class RemoteControlCenterImpl: NSObject, RemoteControlCenter {
    let commands: Array<RemoteControlCommand>
    
    init(commands: Array<RemoteControlCommand>) {
        self.commands = commands
    }
    
    public func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                UIApplication.shared.beginReceivingRemoteControlEvents()
            }
        }
    
        for command in self.commands {
            command.load()
        }
    }
    
    public func stop() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                UIApplication.shared.endReceivingRemoteControlEvents()
            }
        }
        for command in self.commands {
            command.unload()
        }
    }
}
