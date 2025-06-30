import SwiftUI

enum Player: String, CaseIterable, Codable {
    case black = "Black"
    case white = "White"
    
    var opponent: Player {
        self == .black ? .white : .black
    }
}

enum GameState: Codable {
    case playing
    case won(by: Player, method: WinMethod)
}

enum WinMethod: String, Codable {
    case fiveInARow
    case fiveCaptures
}

protocol GameMoveDelegate: AnyObject {
    func gameDidMakeMove()
}

class PenteGameModel: ObservableObject {
    @Published var board: [[Player?]] = Array(repeating: Array(repeating: nil, count: 19), count: 19)
    @Published var currentPlayer: Player = .black
    @Published var moveHistory: [(row: Int, col: Int, player: Player)] = []
    @Published var capturedCount: [Player: Int] = [.black: 0, .white: 0]
    @Published var gameState: GameState = .playing
    @Published var lastCaptures: [(row: Int, col: Int)] = []
    @Published var pendingMove: (row: Int, col: Int)? = nil
    @Published var pendingCaptures: [(row: Int, col: Int)] = []
    @Published var isNewGamePendingSend: Bool = false
    
    weak var moveDelegate: GameMoveDelegate?
    
    var isFirstMoveReadyToSend: Bool {
        return isNewGamePendingSend
    }
    
    func sendFirstMove() {
        guard isFirstMoveReadyToSend else { return }
        isNewGamePendingSend = false
        moveDelegate?.gameDidMakeMove()
    }
    
    func makeMove(row: Int, col: Int) {
        // Check if game is over
        guard case .playing = gameState else { return }
        
        // Prevent moves during first move ready-to-send state
        guard !isFirstMoveReadyToSend else { return }
        
        //If there's already a pending move...
        if let pending = pendingMove {
            if pending.row == row && pending.col == col {
                // .. and it's the same cell, undo and bail out
                undoMove()
                return
            } else {
                // .. otherwise just clear the old pending move
                undoMove()
            }
        }
        
        // Check if position is occupied (after checking for pending move)
        guard board[row][col] == nil else { return }
        
        // Place the stone temporarily
        board[row][col] = currentPlayer
        pendingMove = (row: row, col: col)
        
        // Check for captures but don't remove them yet
        pendingCaptures = checkCaptures(row: row, col: col)
        
        // Highlight pending captures differently
        lastCaptures = pendingCaptures
    }
    
    func confirmMove() {
        guard let move = pendingMove else { return }
        
        // Add to move history
        moveHistory.append((row: move.row, col: move.col, player: currentPlayer))
        
        // Remove captured stones and update count
        for capture in pendingCaptures {
            board[capture.row][capture.col] = nil
        }
        capturedCount[currentPlayer, default: 0] += pendingCaptures.count / 2
        
        // Check win conditions
        if checkFiveInARow(row: move.row, col: move.col) {
            gameState = .won(by: currentPlayer, method: .fiveInARow)
        } else if capturedCount[currentPlayer, default: 0] >= 5 { // 5 captures (pairs)
            gameState = .won(by: currentPlayer, method: .fiveCaptures)
        } else {
            // Switch players only if game continues
            currentPlayer = currentPlayer.opponent
        }
        
        // Clear pending state
        pendingMove = nil
        pendingCaptures = []
        lastCaptures = []
        
        // Notify delegate that a move was made
        moveDelegate?.gameDidMakeMove()
    }
    
    func undoMove() {
        guard let move = pendingMove else { return }
        
        // Remove the pending stone
        board[move.row][move.col] = nil
        
        // Clear pending state
        pendingMove = nil
        pendingCaptures = []
        lastCaptures = []
    }
    
    // MARK: - URL Encoding/Decoding
    
    func encodeToQueryItems() -> [URLQueryItem] {
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
        
        return items
    }
    
    func loadFromURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return }
        
        // Reset the game first
        resetGame()
        
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
                    // 1) Place the stone
                    board[row][col] = player

                    // 2) Replay any captures from that move
                    let savedPlayer = currentPlayer
                    currentPlayer = player
                    let caps = checkCaptures(row: row, col: col)
                    for cap in caps {
                        board[cap.row][cap.col] = nil
                    }
                    currentPlayer = savedPlayer

                    // 3) Record the move in history
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
    }
    
    // Check for captures in all 8 directions
    private func checkCaptures(row: Int, col: Int) -> [(row: Int, col: Int)] {
        var captures: [(row: Int, col: Int)] = []
        let directions = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]
        
        for (dRow, dCol) in directions {
            // Check pattern: current-opponent-opponent-current
            let pos1 = (row + dRow, col + dCol)
            let pos2 = (row + 2*dRow, col + 2*dCol)
            let pos3 = (row + 3*dRow, col + 3*dCol)
            
            if isValidPosition(pos1.0, pos1.1) &&
               isValidPosition(pos2.0, pos2.1) &&
               isValidPosition(pos3.0, pos3.1) {
                
                if board[pos1.0][pos1.1] == currentPlayer.opponent &&
                   board[pos2.0][pos2.1] == currentPlayer.opponent &&
                   board[pos3.0][pos3.1] == currentPlayer {
                    
                    captures.append((row: pos1.0, col: pos1.1))
                    captures.append((row: pos2.0, col: pos2.1))
                }
            }
        }
        
        return captures
    }
    
    // Check for five in a row
    private func checkFiveInARow(row: Int, col: Int) -> Bool {
        let directions = [
            (0, 1),   // horizontal
            (1, 0),   // vertical
            (1, 1),   // diagonal \
            (1, -1)   // diagonal /
        ]
        
        for (dRow, dCol) in directions {
            var count = 1 // Count the stone just placed
            
            // Count in positive direction
            var r = row + dRow
            var c = col + dCol
            while isValidPosition(r, c) && board[r][c] == currentPlayer {
                count += 1
                r += dRow
                c += dCol
            }
            
            // Count in negative direction
            r = row - dRow
            c = col - dCol
            while isValidPosition(r, c) && board[r][c] == currentPlayer {
                count += 1
                r -= dRow
                c -= dCol
            }
            
            if count >= 5 {
                return true
            }
        }
        
        return false
    }
    
    private func isValidPosition(_ row: Int, _ col: Int) -> Bool {
        return row >= 0 && row < 19 && col >= 0 && col < 19
    }
    
    func resetGame() {
        board = Array(repeating: Array(repeating: nil, count: 19), count: 19)
        currentPlayer = .black
        moveHistory = []
        capturedCount = [.black: 0, .white: 0]
        gameState = .playing
        lastCaptures = []
        pendingMove = nil
        pendingCaptures = []
        isNewGamePendingSend = false
    }
    
    func startNewGame() {
        resetGame()
        // Place the first black stone in the center as a completed move
        board[9][9] = .black
        moveHistory.append((row: 9, col: 9, player: .black))
        currentPlayer = .white // Switch to white for the actual first move
        isNewGamePendingSend = true // Flag that this is a new game ready to send
    }
}

// MARK: - Board Image Generation

extension PenteGameModel {
    func generateBoardImage(size: CGSize = CGSize(width: 300, height: 300), colorScheme: UIUserInterfaceStyle) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Dynamic colors based on theme
            let boardColor: UIColor
            let gridLineColor: UIColor
            let blackStoneColor: UIColor
            let whiteStoneColor: UIColor
            
            if colorScheme == .dark {
                boardColor = UIColor(red: 0.243, green: 0.153, blue: 0.137, alpha: 1.0) // #3E2723
                gridLineColor = UIColor.white.withAlphaComponent(0.2)
                blackStoneColor = UIColor(white: 0.04, alpha: 1.0) // #0A0A0A
                whiteStoneColor = UIColor(white: 0.91, alpha: 1.0) // #E8E8E8
            } else {
                boardColor = UIColor(red: 0.831, green: 0.647, blue: 0.455, alpha: 1.0) // #D4A574
                gridLineColor = UIColor.black.withAlphaComponent(0.3)
                blackStoneColor = UIColor(white: 0.11, alpha: 1.0) // #1C1C1C
                whiteStoneColor = UIColor(white: 0.98, alpha: 1.0) // #FAFAFA
            }
            
            // Board background
            ctx.setFillColor(boardColor.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            let margin: CGFloat = size.width * 0.05  // 5% margin
            let boardSize = size.width - 2 * margin
            let cellSize = boardSize / 18  // 18 gaps between 19 lines
            let stoneRadius = cellSize * 0.35
            
            // Draw grid lines
            ctx.setStrokeColor(gridLineColor.cgColor)
            ctx.setLineWidth(0.5)
            
            for i in 0..<19 {
                let position = margin + CGFloat(i) * cellSize
                
                // Vertical lines
                ctx.move(to: CGPoint(x: position, y: margin))
                ctx.addLine(to: CGPoint(x: position, y: size.height - margin))
                ctx.strokePath()
                
                // Horizontal lines
                ctx.move(to: CGPoint(x: margin, y: position))
                ctx.addLine(to: CGPoint(x: size.width - margin, y: position))
                ctx.strokePath()
            }
            
            // Draw stones on intersections
            for row in 0..<19 {
                for col in 0..<19 {
                    if let stone = board[row][col] {
                        // Place stones on intersections
                        let center = CGPoint(
                            x: margin + CGFloat(col) * cellSize,
                            y: margin + CGFloat(row) * cellSize
                        )
                        
                        // Shadow
                        ctx.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
                        ctx.fillEllipse(in: CGRect(
                            x: center.x - stoneRadius + 1,
                            y: center.y - stoneRadius + 1,
                            width: stoneRadius * 2,
                            height: stoneRadius * 2
                        ))
                        
                        // Stone
                        ctx.setFillColor(stone == .black ? blackStoneColor.cgColor : whiteStoneColor.cgColor)
                        ctx.fillEllipse(in: CGRect(
                            x: center.x - stoneRadius,
                            y: center.y - stoneRadius,
                            width: stoneRadius * 2,
                            height: stoneRadius * 2
                        ))
                        
                        // Border for white stones
                        if stone == .white {
                            ctx.setStrokeColor(UIColor.gray.withAlphaComponent(0.5).cgColor)
                            ctx.setLineWidth(0.5)
                            ctx.strokeEllipse(in: CGRect(
                                x: center.x - stoneRadius,
                                y: center.y - stoneRadius,
                                width: stoneRadius * 2,
                                height: stoneRadius * 2
                            ))
                        }
                    }
                }
            }
            
            // Highlight the last move with a blue ring
            if let lastMove = moveHistory.last {
                let center = CGPoint(
                    x: margin + CGFloat(lastMove.col) * cellSize,
                    y: margin + CGFloat(lastMove.row) * cellSize
                )
                
                // Draw a blue ring around the stone outline
                ctx.setStrokeColor(UIColor.systemBlue.cgColor)
                ctx.setLineWidth(1.0)
                ctx.strokeEllipse(in: CGRect(
                    x: center.x - stoneRadius,
                    y: center.y - stoneRadius,
                    width: stoneRadius * 2,
                    height: stoneRadius * 2
                ))
            }
        }
    }
}