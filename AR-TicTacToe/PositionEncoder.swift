//
//  PositionEncoder.swift
//  AR-TicTacToe
//
//  Created by Siddharth Ganapathy on 3/16/26.
//  Copyright © 2026 Bjarne Møller Lundgren. All rights reserved.
//

// Converts between game board and UWAPI format

import Foundation

protocol PositionEncoder {
    
    var gameID: String {
        get
    }
    var variantID: String {
        get
    }
//    var remoteness: Int {
//        get
//    }
    
    // Board -> UWAPI position str
    func encode(board: [[String]], turn: Int) -> String
    
    // UWAPI -> Board
    func decode(move: String, board: [[String]]) -> GameAction
}
