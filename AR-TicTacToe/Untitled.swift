import Foundation
import GameAI

struct UWAPIClient {
    static let base = "http://127.0.0.1:8082"
    
    static func bestAction(for state: GameState) async throws -> GameAction {
        let position = encodePosition(from: state)
        let urlString = "\(base)/tictactoe/regular/positions/?p=\(position)"
        
        guard let url = URL(string: urlString) else {
            throw UWAPIError.badURL(urlString)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(UWAPIResponse.self, from: data)
        
        guard let best = response.moves.first else {
            throw UWAPIError.noMoves(position)
        }
        
        return decodeMove(best.move, state: state)
    }
}

enum UWAPIError: Error {
    case badURL(String)
    case noMoves(String)
}
