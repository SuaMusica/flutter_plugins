import Foundation
import CoreMedia

public class PeriodicTimeObserver: Observer {
    var player: Player
    var observerId: Any?
    
    init(player: Player) {
        self.player = player
    }
    
    func start() {
        let interval = CMTimeMakeWithSeconds(0.9, preferredTimescale: Int32(NSEC_PER_SEC))
        self.observerId = self.player.getPlayer().addPeriodicTimeObserver(forInterval: interval, queue: nil) { time in
            self.player.onTimeInterval(time)
        }
    }
    
    func stop() {
        if (self.observerId != nil) {
            self.player.getPlayer().removeTimeObserver(self.observerId!)
        }
    }
}
