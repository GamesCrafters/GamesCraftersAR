//
//  GameRegistry.swift
//  AR-TicTacToe
//
//  Created by Siddharth Ganapathy on 3/16/26.
//  Copyright © 2026 Bjarne Møller Lundgren. All rights reserved.
//

import Foundation

enum GameRegistry {
    static let all: [GameDefinition] = [
        tictactoe,
        notakto,
        // more games/puzzles to be added!
    ]
    
    static let tictactoe = GameDefinition(
        displayName: "Tic-Tac-Toe",
        rows: 3,
        cols: 3,
        p1: "x",
        p2: "o",
        emptySymbol: "",
        encoder: TTTEncoder()
    )
    
    static let notakto = GameDefinition(
        displayName: "Notakto",
        rows: 3,
        cols: 3,
        p1: "x",
        p2: "x",
        emptySymbol: "",
        encoder: NotaktoEncoder()
    )
    
    static let achi = GameDefinition(
        displayName: "achi",
        rows: 3,
        cols: 3,
        p1: "x",
        p2: "o",
        emptySymbol: "",
        encoder: AchiEncoder()
    )
    
}
