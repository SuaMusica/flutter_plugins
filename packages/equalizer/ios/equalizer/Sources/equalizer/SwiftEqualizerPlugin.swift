import Flutter
import UIKit
import AVFoundation

public class SwiftEqualizerPlugin: NSObject, FlutterPlugin {
    
    let preferences = EqualizerPreferences()
    
    let OK = 0;
    let NOT_OK = -1;
    
    let bandLevelRange: [Int] = [-10, 10]
    let frequencies: [Int] = [63000, 125000, 250000, 500000, 1000000, 2000000, 4000000, 8000000, 16000000]
    
    let NORMAL_PRESET_KEY = "Normal"
    let CUSTOM_PRESET_KEY = "Custom"
    
    let presetNames = [
        "Normal",
        "Pop",
        "Classic",
        "Jazz",
        "Rock"
    ]
    
    let presetsLevels: [[Float]] = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 2, 2, 3, -2, -4],
        [0, 0, -1, -6, 0, 1, 1, 0, 6],
        [0, 0, 2, 5, -6, -2, -1, 2, -1],
        [0, 0, 1, 3, -10, -2, -1, 3, 3]
    ]
    
    var audioSession: AVAudioSession!
    
    var audioPlayer: AVAudioNode!
    
    var audioEngine: AVAudioEngine!
    
    var audioUnitEq: AVAudioUnitEQ!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "equalizer", binaryMessenger: registrar.messenger())
        let instance = SwiftEqualizerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
//        if (self.audioUintEq == nil) {
//            result(FlutterError(code: "-1", message: "Plugin was not initialized", details: ""))
//            return
//        }

        if (call.method == "init") {
            
            do {
                self.audioSession = AVAudioSession.sharedInstance()
//                try self.audioSession.setCategory(AVAudioSession.Category.playback)
//                try self.audioSession.setActive(true, options: [])
                
//                self.audioPlayer = AVAudioNode.init()
                
                // Creating nodes
                self.audioUnitEq = AVAudioUnitEQ(numberOfBands: frequencies.count)
                
                // Creating engine
                self.audioEngine = AVAudioEngine.init()
                
//                self.audioEngine.attach(self.audioPlayer)
                self.audioEngine.attach(self.audioUnitEq)
                
//                self.audioEngine.connect(self.audioPlayer, to: self.audioUnitEq, format: nil)
                self.audioEngine.connect(self.audioUnitEq, to: self.audioEngine.mainMixerNode, format: self.audioUnitEq.inputFormat(forBus: 0))
                
                self.audioEngine.prepare()
                
                try self.audioEngine.start()
                
                initialize()
                
                result(OK)
                
            } catch {
                result(FlutterError(code: "-1", message: "An error occurred on init", details: error))
            }
            
        } else if (call.method == "open") {
            result(OK)
        } else if (call.method == "deviceHasEqualizer") {
            result(false)
        } else if (call.method == "setAudioSessionId") {
            
            // do nothing
            result(OK)
            
        } else if (call.method == "removeAudioSessionId") {
            
            // do nothing
            result(OK)
            
        } else if (call.method == "enable") {
            
            let isToEnable = call.arguments as! Bool
            //                try AVAudioSession.sharedInstance().setActive(isToEnable, options: [])
            preferences.setEnabled(enable: isToEnable)
            initialize()
            result(OK)
            
        } else if (call.method == "isEnabled") {
            
            result(preferences.isEnabled())
            
        } else if (call.method == "release") {
            
            let presetPosition = presetNames.firstIndex(of: NORMAL_PRESET_KEY)!
            let preset = presetsLevels[presetPosition]
            setPresetIntoEqualizer(preset: preset)
            preferences.setCurrentPresetPosition(pos: presetPosition)
            result(OK)
            
        } else if (call.method == "getBandLevelRange") {
            
            result(bandLevelRange)
            
        } else if (call.method == "getCenterBandFreqs") {
            
            result(frequencies)
            
        } else if (call.method == "getPresetNames") {
            
            var presets = presetNames
            presets += [CUSTOM_PRESET_KEY]
            result(presets)
            
        } else if (call.method == "getCurrentPreset") {
            
            result(preferences.getCurrentPresetPosition())
            
        } else if (call.method == "getBandLevel") {
            
            let bandId = call.arguments as! Int;
            let preset = getCurrentPreset()
            
            if (bandId >= preset.count) {
                let details = "bandId \(bandId) not found, there is \(preset.count) bands"
                result(FlutterError(code: "-1", message: "Invalid argument for getBandLevel method", details: details))
                return
            }
            
            result(Int(preset[bandId]))
            
        } else if (call.method == "setBandLevel") {
            
            if (!preferences.isEnabled()) {
                return
            }
            
            var preset = getCurrentPreset()
            
            // Changing current preset to custom
            let customPresetPosition = presetsLevels.count
            preferences.setCurrentPresetPosition(pos: customPresetPosition)
            
            let args = call.arguments as! [String: Any]
            let bandId = args["bandId"] as! Int
            let level = args["level"] as! Float
            
            preset[bandId] = level
            
            setPresetIntoEqualizer(preset: preset)
            
            preferences.setCustomPreset(preset: preset)
            
            result(OK)
            
        } else if (call.method == "setPreset") {
            
            if (!preferences.isEnabled()) {
                result(NOT_OK)
                return
            }
            
            let presetName = call.arguments as! String
            
            if (CUSTOM_PRESET_KEY == presetName) {
                
                let customPreset = preferences.getCustomPreset()
                setPresetIntoEqualizer(preset: customPreset)
                let customPresetPosition = presetsLevels.count
                preferences.setCurrentPresetPosition(pos: customPresetPosition)
                
            } else {
                
                if (!presetNames.contains(presetName)) {
                    let details = "there is no \(presetName) preset"
                    result(FlutterError(code: "-1", message: "Invalid preset name", details: details))
                    return
                }
                
                let presetPosition = presetNames.firstIndex(of: presetName)!
                let preset = presetsLevels[presetPosition]
                setPresetIntoEqualizer(preset: preset)
                preferences.setCurrentPresetPosition(pos: presetPosition)
            }
            
            result(OK)
            
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    fileprivate func initialize() {
        if (preferences.isEnabled()) {
            setPresetIntoEqualizer(preset: getCurrentPreset())
        } else {
            let presetPosition = presetNames.firstIndex(of: NORMAL_PRESET_KEY)!
            let preset = presetsLevels[presetPosition]
            setPresetIntoEqualizer(preset: preset)
        }
    }
    
    private func getCurrentPreset() -> [Float] {
        
        var preset: [Float]
        
        // Getting current preset
        let currentPresetPosition = preferences.getCurrentPresetPosition()
        
        if (currentPresetPosition == presetsLevels.count) {
            // is custom
            preset = preferences.getCustomPreset()
        } else {
            // is not custom
            preset = presetsLevels[currentPresetPosition]
        }
        
        return preset
    }
    
    private func setPresetIntoEqualizer(preset: [Float]) {
        for i in 0..<preset.count {
            let band = audioUnitEq.bands[i]
            band.filterType = .parametric
            band.gain = preset[i]
            band.frequency = Float(frequencies[i] / 1000)
            band.bypass = false
        }
    }
}
