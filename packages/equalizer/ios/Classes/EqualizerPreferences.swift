//
//  EqualizerPreference.swift
//  equalizer
//
//  Created by Jeferson Krauss on 29/12/20.
//

import Foundation


public class EqualizerPreferences {
    
    let preferences = UserDefaults.standard
    static let PREFERENCE_NAME = "EqualizerPreferences."
    static let CUSTOM_PRESET_KEY = PREFERENCE_NAME + "CustomPreset"
    static let CURRENT_PRESET_POSITION_KEY = PREFERENCE_NAME + "CurrentPreset"
    static let IS_ENABLED_KEY = PREFERENCE_NAME + "isEnabled"
    static let CUSTOM_PRESET_DEFAULT: [Float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    
    func getCustomPreset() -> [Float] {
        return preferences.array(forKey: EqualizerPreferences.CUSTOM_PRESET_KEY) as? [Float] ??
            EqualizerPreferences.CUSTOM_PRESET_DEFAULT
    }
    
    func setCustomPreset(preset: [Float]) {
        preferences.set(preset, forKey: EqualizerPreferences.CUSTOM_PRESET_KEY)
        preferences.synchronize()
    }
    
    func getCurrentPresetPosition() -> Int {
        return preferences.integer(forKey: EqualizerPreferences.CURRENT_PRESET_POSITION_KEY)
    }
    
    func setCurrentPresetPosition(pos: Int) {
        preferences.setValue(pos, forKey: EqualizerPreferences.CURRENT_PRESET_POSITION_KEY)
        preferences.synchronize()
    }
    
    func isEnabled() -> Bool {
        return preferences.bool(forKey: EqualizerPreferences.IS_ENABLED_KEY)
    }
    
    func setEnabled(enable: Bool) {
        preferences.setValue(enable, forKey: EqualizerPreferences.IS_ENABLED_KEY)
        preferences.synchronize()
    }
}
