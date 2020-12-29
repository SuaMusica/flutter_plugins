//
//  EqualizerPreference.swift
//  equalizer
//
//  Created by Jeferson Krauss on 29/12/20.
//

import Foundation


public class EqualizerPreference {
    
    func getCustomPreset() -> [Float] {
        return [0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
    
    func setCustomPreset(preset: [Float]) {
        // persist into storage
    }
    
    func getCurrentPresetPosition() -> Int {
        return 0
    }
    
    func setCurrentPresetPosition(pos: Int) {
        // persist position into storage
    }
}
