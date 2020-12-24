import Flutter
import UIKit
import AVFoundation

public class SwiftEqualizerPlugin: NSObject, FlutterPlugin {
    
    let OK = 0;
    let NOT_OK = -1;
    
    let frequencies: [Int] = [32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    var preSets: [[Float]] = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // My setting
        [4, 6, 5, 0, 1, 3, 5, 4.5, 3.5, 0], // Dance
        [4, 3, 2, 2.5, -1.5, -1.5, 0, 1, 2, 3], // Jazz
        [5, 4, 3.5, 3, 1, 0, 0, 0, 0, 0] // Base Main
    ]
    
    var eq = AVAudioUnitEQ(numberOfBands: 5)
    var audioManager = AVAudioUnitComponentManager.shared()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "equalizer", binaryMessenger: registrar.messenger())
        let instance = SwiftEqualizerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            
            
            if (call.method == "open") {
                result(OK)
            } else if (call.method == "setAudioSessionId") {
                
                // do nothing
                
            } else if (call.method == "removeAudioSessionId") {
                
                // do nothing
                
            } else if (call.method == "init") {
                
                // do nothing
                
            } else if (call.method == "enable") {
                
                let isToEnable = call.arguments as! Bool
                try AVAudioSession.sharedInstance().setActive(isToEnable, options: [])
                
            } else if (call.method == "release") {
                
                // do nothing
                
            } else if (call.method == "getBandLevelRange") {
                
                result([-15, 15])
                
            } else if (call.method == "getCenterBandFreqs") {
                
                result([16000, 20000, 40000, 60000, 120000])
                
            } else if (call.method == "getPresetNames") {
                
                result(["Dance", "Jazz"])
                
            } else if (call.method == "getCurrentPreset") {
                
                // Position of current preset in array
                result(0)
                
            } else if (call.method == "getBandLevel") {
                
                //let bandId = call.arguments as! Int;
                // TODO
                result(240)
                
            } else if (call.method == "setBandLevel") {
                
                let args = call.arguments as! [String: Any]
                let bandId = args["bandId"] as! Int
                let level = args["level"] as! Float
                eq.bands[bandId].gain = level
                
            } else if (call.method == "setPreset") {
                
                //let presetName = call.arguments as! String
                // TODO
                
            } else {
                result(FlutterMethodNotImplemented)
            }
            
        } catch {
            result(FlutterError(code: "-1", message: "An error occurred", details: ""))
        }
    }
}
