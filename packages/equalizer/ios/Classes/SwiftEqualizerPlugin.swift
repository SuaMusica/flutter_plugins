import Flutter
import UIKit
import AVFoundation

public class SwiftEqualizerPlugin: NSObject, FlutterPlugin {
    
    let preference = EqualizerPreference()
    
    let OK = 0;
    let NOT_OK = -1;
    
    let bandLevelRange: [Int] = [-10, 10]
    let frequencies: [Int] = [63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    
    let NORMAL_PRESET_KEY = "Normal"
    let CUSTOM_PRESET_KEY = "Custom"
    
    var preSetsMap: [String : [Float]] = [
        "Normal": [0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Pop": [0, 0, 0, 0, 2, 2, 3, -2, -4],
        "Classic": [0, 0, -1, -6, 0, 1, 1, 0, 6],
        "Jazz": [0, 0, 2, 5, -6, -2, -1, 2, -1],
        "Rock": [0, 0, 1, 3, -10, -2, -1, 3, 3]
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
                
                let presetsValues = Array(preSetsMap.values)
                let presetPosition = preference.getCurrentPresetPosition()
                let preset = presetsValues[presetPosition]
                setPresetIntoEqualizer(preset: preset)
                
            } else if (call.method == "enable") {
                
                let isToEnable = call.arguments as! Bool
                try AVAudioSession.sharedInstance().setActive(isToEnable, options: [])
                
            } else if (call.method == "isEnabled") {
                
                // TODO Not Implemented yet
                result(false)
                
            } else if (call.method == "release") {
                
                let presetKeys = Array(preSetsMap.keys)
                let preset = preSetsMap[NORMAL_PRESET_KEY]!
                setPresetIntoEqualizer(preset: preset)
                let presetPosition: Int = presetKeys.firstIndex(of: NORMAL_PRESET_KEY)!
                preference.setCurrentPresetPosition(pos: presetPosition)
                
            } else if (call.method == "getBandLevelRange") {
                
                result(bandLevelRange)
                
            } else if (call.method == "getCenterBandFreqs") {
                
                result(frequencies)
                
            } else if (call.method == "getPresetNames") {
                
                var presetNames = Array(preSetsMap.keys)
                presetNames += [CUSTOM_PRESET_KEY]
                result(presetNames)
                
            } else if (call.method == "getCurrentPreset") {
                
                result(preference.getCustomPreset())
                
            } else if (call.method == "getBandLevel") {
                
                let bandId = call.arguments as! Int;
                let preset = getCurrentPreset()
                
                if (bandId >= preset.count) {
                    let details = "bandId \(bandId) not found, there is \(preset.count) bands"
                    result(FlutterError(code: "-1", message: "Invalid argument for getBandLevel method", details: details))
                    return
                }
                
                result(preset[bandId])
                                
            } else if (call.method == "setBandLevel") {
                
                var preset = getCurrentPreset()
                
                // Changing current preset to custom
                let customPresetPosition = preSetsMap.values.count
                preference.setCurrentPresetPosition(pos: customPresetPosition)
                
                let args = call.arguments as! [String: Any]
                let bandId = args["bandId"] as! Int
                let level = args["level"] as! Float
                
                preset[bandId] = level
                
                setPresetIntoEqualizer(preset: preset)
                                
                preference.setCustomPreset(preset: preset)
                
            } else if (call.method == "setPreset") {
                
                let presetName = call.arguments as! String
                
                if (CUSTOM_PRESET_KEY == presetName) {
                    
                    let customPreset = preference.getCustomPreset()
                    setPresetIntoEqualizer(preset: customPreset)
                    let customPresetPosition = preSetsMap.values.count
                    preference.setCurrentPresetPosition(pos: customPresetPosition)
                    
                } else {
                    
                    let presetKeys = Array(preSetsMap.keys)
                    
                    if (!presetKeys.contains(presetName)) {
                        let details = "there is no \(presetName) preset"
                        result(FlutterError(code: "-1", message: "Invalid preset name", details: details))
                        return
                    }
                    
                    let preset = preSetsMap[presetName]!
                    setPresetIntoEqualizer(preset: preset)
                    let presetPosition: Int = presetKeys.firstIndex(of: presetName)!
                    preference.setCurrentPresetPosition(pos: presetPosition)
                }
                
            } else {
                result(FlutterMethodNotImplemented)
            }
            
        } catch {
            result(FlutterError(code: "-1", message: "An error occurred", details: ""))
        }
    }
    
    private func getCurrentPreset() -> [Float] {
        
        let presetValues = Array(preSetsMap.values)
        var preset: [Float]
        
        // Getting current preset
        let currentPresetPosition = preference.getCurrentPresetPosition()
        
        if (currentPresetPosition == presetValues.count) {
            // is custom
            preset = preference.getCustomPreset()
        } else {
            // is not custom
            preset = presetValues[currentPresetPosition]
        }
        
        return preset
    }
    
    private func setPresetIntoEqualizer(preset: [Float]) {
        for i in 0..<preset.count {
            eq.bands[i].gain = preset[i]
        }
    }
}
