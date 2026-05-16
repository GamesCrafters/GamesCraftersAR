//
//  UWAPIClient.swift
//  AR-TicTacToe
//
//  Created by Siddharth Ganapathy on 3/16/26.
//  Copyright © 2026 Bjarne Møller Lundgren. All rights reserved.
//

import Foundation


struct UWAPIResponse: Codable {
    let moves: [Move]
    let position: String
    let positionValue: String
    let remoteness: Int
}

struct Move: Codable {
    let move: String
    let autoguiMove: String
//    let moveName: String
    let moveValue: String
    let position: String
    let positionValue: String
    let remoteness: Int
    let deltaRemoteness: Int
}

enum UWAPIError: Error {
    case badURL(String)
    case invalidPosition(String)
    case noMoves(String)
    case httpError(Int)
}

@available(iOS 13.0.0, *)
struct UWAPIClient {
//    static let base = "http://10.1.35.149:8082" // apt IP address
    static let base = "http://10.1.32.112:8082/"
//    static let base = "http://10.44.141.76:8082" // school IP address
//    static let base = "http://10.44.68.118:8082"
//    static let base = "http://192.168.86.37:8082" // home IP address
    
    
    static func fetchMoves(
        board: [[String]],
        turn: Int,
        game: GameDefinition
    ) async throws -> (best: Move, all: [Move]) {

        let position = game.encoder.encode(board: board, turn: turn)
        let urlString = "\(base)/\(game.encoder.gameID)/\(game.encoder.variantID)/positions/?p=\(position)"
        guard let url = URL(string: urlString) else { throw UWAPIError.badURL(urlString) }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw UWAPIError.httpError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(UWAPIResponse.self, from: data)
        guard let best = decoded.moves.first else { throw UWAPIError.noMoves(position) }
        print(best)

        return (best: best, all: decoded.moves)
    }

    // Keep bestAction too but have it call fetchMoves internally:
    static func bestAction(
        board: [[String]],
        turn: Int,
        game: GameDefinition
    ) async throws -> (action: GameAction, moveValue: String, remoteness: Int, moveType: String) {

        let result = try await fetchMoves(board: board, turn: turn, game: game)
        let best = result.best
        let action = game.encoder.decode(move: best.move, board: board)
        let moveType = String(best.autoguiMove.prefix(1))
        return (action: action, moveValue: best.moveValue, remoteness: best.remoteness, moveType: moveType)
    }
    
    
}
