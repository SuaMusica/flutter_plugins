import Foundation
import MediaPlayer

@objc public class AudioSessionManager: NSObject {
   private static var _isActive : Bool = false
   
   @objc public static func isActive() -> Bool {
       return _isActive;
   }
   
    @objc public static func activeSession() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            let audioSessionCategory: AVAudioSession.CategoryOptions = [.allowAirPlay, .allowBluetoothA2DP]
            try audioSession.setCategory(.playback, mode: .default, options: audioSessionCategory)
       } catch let error as NSError {
           print("Player: Failed to set Audio Category \(error.localizedDescription)")
           return false
       }
       
       
       do {
           try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
           print("Player: Audio Session is Active - notifyOthersOnDeactivation")
       } catch let error as NSError {
           print("Player: Failed to activate Audio Session \(error.localizedDescription)")
           return false
       }
       _isActive = true;
       return true
   }
   
   @objc public static func inactivateSession() -> Bool {
       if !_isActive {
           return true;
       }
       
       do {
           try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
           print("Player: Audio Session is Inactive - notifyOthersOnDeactivation")
       } catch let error as NSError {
           print("Player: Failed to activate Audio Session \(error.localizedDescription)")
           return false
       }
       _isActive = false;
       return true
   }
}
