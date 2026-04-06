import Foundation

public struct GameStateEncoder {
    public static func encodeToQueryItems(
        moveHistory: [(row: Int, col: Int, player: Player)],
        currentPlayer: Player,
        capturedCount: [Player: Int],
        gameState: GameState,
        blackPlayerID: String? = nil
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

public struct DecodedGameState {
    public var board: GameBoard
    public var currentPlayer: Player
    public var capturedCount: [Player: Int]
    public var gameState: GameState
    public var moveHistory: [(row: Int, col: Int, player: Player)]
    public var blackPlayerID: String?

    public init(
        board: GameBoard,
        currentPlayer: Player,
        capturedCount: [Player: Int],
        gameState: GameState,
        moveHistory: [(row: Int, col: Int, player: Player)],
        blackPlayerID: String?
    ) {
        self.board = board
        self.currentPlayer = currentPlayer
        self.capturedCount = capturedCount
        self.gameState = gameState
        self.moveHistory = moveHistory
        self.blackPlayerID = blackPlayerID
    }
}

public struct GameStateDecoder {
    public static func decodeFromURL(_ url: URL) -> DecodedGameState? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }

        var state = DecodedGameState(
            board: GameBoard(),
            currentPlayer: .black,
            capturedCount: [.black: 0, .white: 0],
            gameState: .playing,
            moveHistory: [],
            blackPlayerID: nil
        )

        // Parse moves and replay them, computing captures from the replay
        if let movesString = queryItems.first(where: { $0.name == "moves" })?.value {
            let moveComponents = movesString.split(separator: ";")
            for moveComponent in moveComponents {
                let moveStr = String(moveComponent)
                guard let playerChar = moveStr.first,
                      playerChar == "B" || playerChar == "W" else { continue }

                let coords = moveStr.dropFirst()
                let parts = coords.split(separator: ",")

                guard parts.count == 2,
                      let row = Int(parts[0]),
                      let col = Int(parts[1]),
                      row >= 0, row < GameBoard.size,
                      col >= 0, col < GameBoard.size else { continue }

                let player: Player = playerChar == "B" ? .black : .white

                state.board.placeStone(player, at: row, col: col)

                let captures = CaptureEngine.findCaptures(on: state.board, at: row, col: col, by: player)
                for capture in captures {
                    state.board.removeStone(at: capture.row, col: capture.col)
                }
                state.capturedCount[player, default: 0] += captures.count / 2

                state.moveHistory.append((row: row, col: col, player: player))
            }
        }

        // Set current player
        if let currentString = queryItems.first(where: { $0.name == "current" })?.value,
           let player = Player(rawValue: currentString) {
            state.currentPlayer = player
        }

        // Set game state
        if let stateString = queryItems.first(where: { $0.name == "state" })?.value,
           stateString == "won",
           let winnerString = queryItems.first(where: { $0.name == "winner" })?.value,
           let winner = Player(rawValue: winnerString),
           let methodString = queryItems.first(where: { $0.name == "method" })?.value,
           let method = WinMethod(rawValue: methodString) {
            state.gameState = .won(by: winner, method: method)
        }

        // Set black player identifier
        state.blackPlayerID = queryItems.first(where: { $0.name == "blackID" })?.value

        return state
    }
}
