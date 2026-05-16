//
//  GameDefinition.swift
//  AR-TicTacToe
//
//  Created by Siddharth Ganapathy on 3/16/26.
//  Copyright © 2026 Bjarne Møller Lundgren. All rights reserved.
//

import Foundation

struct GameDefinition {
    let displayName: String
//    let variantName: String
    
    let rows: Int
    let cols: Int
    
    let p1: String
    let p2: String
    let emptySymbol: String
    
    let encoder: any PositionEncoder
}
