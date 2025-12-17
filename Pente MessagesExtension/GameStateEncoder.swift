import Foundation

struct GameStateEncoder {
    static func encodeToQueryItems(
        moveHistory: [(row: Int, col: Int, player: Player)],
        currentPlayer: Player,
        capturedCount: [Player: Int],
        gameState: GameState,
        blackPlayerID: String?
    ) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        // Encode board state as a string of positions
        var boardString = ""
        for move in moveHistory {
            let playerChar = move.player == .black ? "B" : "W"
            boardString += "\(playerChar)\(move.row),\(move.col);"
        }
        if !boardString.isEmpty {
            items.append(URLQueryItem(name: "moves", value: boardString))
        }
        
        // Current player
        items.append(URLQueryItem(name: "current", value: currentPlayer.rawValue))
        
        // Captured counts
        items.append(URLQueryItem(name: "capB", value: "\(capturedCount[.black, default: 0])"))
        items.append(URLQueryItem(name: "capW", value: "\(capturedCount[.white, default: 0])"))
        
        // Game state
        switch gameState {
        case .playing:
            items.append(URLQueryItem(name: "state", value: "playing"))
        case .won(let player, let method):
            items.append(URLQueryItem(name: "state", value: "won"))
            items.append(URLQueryItem(name: "winner", value: player.rawValue))
            items.append(URLQueryItem(name: "method", value: method.rawValue))
        }
        
        // Black player identifier
        if let blackPlayerID = blackPlayerID {
            items.append(URLQueryItem(name: "blackID", value: blackPlayerID))
        }
        
        return items
    }
}

struct GameStateDecoder {
    static func loadFromURL(
        _ url: URL,
        board: inout GameBoard,
        currentPlayer: inout Player,
        capturedCount: inout [Player: Int],
        gameState: inout GameState,
        moveHistory: inout [(row: Int, col: Int, player: Player)],
        blackPlayerID: inout String?
    ) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return }
        
        // Reset state
        board.reset()
        currentPlayer = .black
        capturedCount = [.black: 0, .white: 0]
        gameState = .playing
        moveHistory = []
        blackPlayerID = nil
        
        // Parse moves and replay them
        if let movesString = queryItems.first(where: { $0.name == "moves" })?.value {
            let moveComponents = movesString.split(separator: ";")
            for moveComponent in moveComponents {
                let moveStr = String(moveComponent)
                guard moveStr.count >= 4 else { continue }
                
                let playerChar = moveStr.first!
                let coords = moveStr.dropFirst()
                let parts = coords.split(separator: ",")
                
                if parts.count == 2,
                   let row = Int(parts[0]),
                   let col = Int(parts[1]) {
                    
                    let player: Player = playerChar == "B" ? .black : .white
                    
                    // Place the stone
                    board.placeStone(player, at: row, col: col)
                    
                    // Replay any captures from that move
                    let savedPlayer = currentPlayer
                    currentPlayer = player
                    let captures = CaptureEngine.findCaptures(on: board, at: row, col: col, by: player)
                    for capture in captures {
                        board.removeStone(at: capture.row, col: capture.col)
                    }
                    currentPlayer = savedPlayer
                    
                    // Record the move in history
                    moveHistory.append((row: row, col: col, player: player))
                }
            }
        }
        
        // Set current player
        if let currentString = queryItems.first(where: { $0.name == "current" })?.value {
            currentPlayer = currentString == "Black" ? .black : .white
        }
        
        // Set captured counts
        if let capBString = queryItems.first(where: { $0.name == "capB" })?.value,
           let capB = Int(capBString) {
            capturedCount[.black] = capB
        }
        if let capWString = queryItems.first(where: { $0.name == "capW" })?.value,
           let capW = Int(capWString) {
            capturedCount[.white] = capW
        }
        
        // Set game state
        if let stateString = queryItems.first(where: { $0.name == "state" })?.value {
            if stateString == "won",
               let winnerString = queryItems.first(where: { $0.name == "winner" })?.value,
               let methodString = queryItems.first(where: { $0.name == "method" })?.value {
                let winner: Player = winnerString == "Black" ? .black : .white
                let method: WinMethod = methodString == "fiveInARow" ? .fiveInARow : .fiveCaptures
                gameState = .won(by: winner, method: method)
            }
        }
        
        // Set black player identifier
        if let blackIDString = queryItems.first(where: { $0.name == "blackID" })?.value {
            blackPlayerID = blackIDString
        }
    }
}