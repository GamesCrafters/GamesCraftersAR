//
//  TTTEncoder.swift
//  AR-TicTacToe
//
//  Created by Siddharth Ganapathy on 3/16/26.
//  Copyright © 2026 Bjarne Møller Lundgren. All rights reserved.
//

import Foundation

struct TTTEncoder: PositionEncoder {
    let gameID = "tictactoe"
    let variantID = "regular"
    
    func encode(board: [[String]], turn: Int) -> String {
        let flat = board
            .flatMap { $0 }
            .map { cell -> String in
                if cell == GamePlayer.p1.rawValue { return "x" }
                if cell == GamePlayer.p2.rawValue { return "o" }
                return "-"
            }
            .joined()
        
        return "\(turn)_\(flat)"
    }
    
    func decode(move: String, board: [[String]]) -> GameAction {
        let parts = move.split(separator: "_").compactMap { Int($0) }

        switch parts.count {
        case 1:
            // put phase
            let zero = parts[0] - 1               // 1-indexed → 0-indexed
            return .put(at: (x: zero / 3, y: zero % 3))

        case 2:
            // move phase
            let fromZero = parts[0] - 1
            let toZero   = parts[1] - 1
            return .move(from: (x: fromZero / 3, y: fromZero % 3),
                                 to:   (x: toZero   / 3, y: toZero   % 3))

        default:
            fatalError("TicTacToeEncoder: unexpected move string '\(move)'")
        }
    }
    
}
