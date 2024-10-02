//
//  MessageBuffer.swift
//  smplayer
//
//  Created by Lucas Tonussi on 01/10/24.
//
import Foundation
import AVFoundation

class MessageBuffer {
    static let shared = MessageBuffer()
    
    private let queue = DispatchQueue(label: "suamusica.messagebuffer", attributes: .concurrent)
    private var buffer: [PlaylistItem] = []
    private var bufferUnique: AVPlayerItem? = nil
    private let bufferSize = 10

    private init() {}
    
    func sendUnique(_ message: AVPlayerItem) {
        queue.async(flags: .barrier) {
            if self.buffer.count >= self.bufferSize {
                self.buffer.removeFirst()
                print("MessageBuffer: Removido o primeiro item do buffer.")
            }
            self.bufferUnique = message
            print("MessageBuffer: Adicionado  item unico Buffer atual: \(message.playlistItem?.title)")
        }
    }
    
    func receiveUnique() -> AVPlayerItem? {
        var result: AVPlayerItem?
        queue.sync {
            if (self.bufferUnique != nil) {
                result = self.bufferUnique
                print("MessageBuffer: Recebido \(String(describing: result?.playlistItem?.title))")
                self.bufferUnique = nil
                print("MessageBuffer: BufferUnique limpo após recebimento.")
            } else {
                print("MessageBuffer: BufferUnique vazio.")
            }
        }
        return result
    }

    func send(_ message: [PlaylistItem]) {
        queue.async(flags: .barrier) {
            if self.buffer.count >= self.bufferSize {
                self.buffer.removeFirst()
                print("MessageBuffer: Removido o primeiro item do buffer.")
            }
            self.buffer.append(contentsOf: message)
            print("MessageBuffer: Adicionado \(message.count) itens. Buffer atual: \(self.buffer.count)")
        }
    }

    func receive() -> [PlaylistItem]? {
        var result: [PlaylistItem]?
        queue.sync {
            if !self.buffer.isEmpty {
                result = self.buffer
                print("MessageBuffer: Recebido \(result?.count ?? 0) itens.")
                self.buffer.removeAll()
                print("MessageBuffer: Buffer limpo após recebimento.")
            } else {
                print("MessageBuffer: Buffer vazio.")
            }
        }
        return result
    }
}
