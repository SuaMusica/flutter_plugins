//
//  PlayerState.swift
//  smplayer
//
//  Created by Lucas Tonussi on 26/09/24.
//

import Foundation

enum PlayerState: Int {
    case idle = 0
    case buffering
    case playing
    case paused
    case stopped
    case completed
    case error
    case seekEnd
    case bufferEmpty
    case itemTransition
    case stateReady
    case stateEnded
}
