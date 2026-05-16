//
//  AchiEncoder.swift
//  AR-TicTacToe
//
//  Created by Siddharth Ganapathy on 3/22/26.
//  Copyright © 2026 Bjarne Møller Lundgren. All rights reserved.
//

struct AchiEncoder: PositionEncoder {
    
    var gameID = "achi"
    var variantID = "regular"
    
    func encode(board: [[String]], turn: Int) -> String {
        let flat = board
            .flatMap { $0 }
            .map { $0.isEmpty ? "-" : $0 }
            .joined()
        
        return "\(turn)_\(flat)"
    }
    
    func decode(move: String, board: [[String]]) -> GameAction {
        guard let index = Int(move), index >= 1 else {
            fatalError("AchiEncoder: unexpected move string '\(move)'")
        }
        let zero = index - 1
        return .put(at: (x: zero / 3, y: zero % 3))
    }
    
    
    
}
