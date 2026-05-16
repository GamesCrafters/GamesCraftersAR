//
//  MoveRecommendation.swift
//  AR-TicTacToe
//
//  Created by Siddharth Ganapathy on 3/16/26.
//  Copyright © 2026 Bjarne Møller Lundgren. All rights reserved.
//

import Foundation
import UIKit

struct MoveRecommendation {
    let action: GameAction
    let moveValue: String  // win, lose, tie
    let remoteness: Int // # moves left until game ends
    
    var displayText: String {
        let verb: String
        switch moveValue {
            case "win": verb = "Winning"
            case "lose": verb = "Losing"
            case "tie": verb = "Tieing"
            default: verb = moveValue.capitalized
        }
        
        if (remoteness <= 0) {
            return "\(verb) imminently"
        }
        return "\(verb) in \(remoteness)"
    }
    
    var displayUIColor: UIColor {
        switch moveValue {
            case "win": return UIColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 1)
            case "lose": return UIColor(red: 0.95, green: 0.3, blue: 0.25, alpha: 1)
            default: return UIColor(red: 1.0, green: 0.85, blue: 1.0, alpha: 1)
        }
    }
    
}
