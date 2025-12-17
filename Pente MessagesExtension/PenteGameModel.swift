import SwiftUI

class PenteGameModel: ObservableObject {
    @Published private var gameBoard = GameBoard()
    @Published var currentPlayer: Player = .black
    @Published var moveHistory: [(row: Int, col: Int, player: Player)] = []
    @Published var capturedCount: [Player: Int] = [.black: 0, .white: 0]
    @Published var gameState: GameState = .playing
    @Published var lastCaptures: [(row: Int, col: Int)] = []
    @Published var pendingMove: (row: Int, col: Int)? = nil
    @Published var pendingCaptures: [(row: Int, col: Int)] = []
    @Published var isNewGamePendingSend: Bool = false
    @Published var canMakeMove: Bool = true
    @Published var waitingForOpponent: Bool = false
    
    var blackPlayerID: String? = nil
    var assignedPlayerColor: Player? = nil
    
    weak var moveDelegate: GameMoveDelegate?
    
    var board: [[Player?]] {
        return gameBoard.asArray
    }
    
    var isFirstMoveReadyToSend: Bool {
        return isNewGamePendingSend
    }
    
    func setPlayerAssignment(_ playerColor: Player?, blackPlayerID: String?) {
        self.assignedPlayerColor = playerColor
        self.blackPlayerID = blackPlayerID
        updateMovePermissions()
    }
    
    private func updateMovePermissions() {
        guard let assignedColor = assignedPlayerColor else {
            canMakeMove = true
            waitingForOpponent = false
            return
        }
        
        canMakeMove = (currentPlayer == assignedColor)
        waitingForOpponent = !canMakeMove
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
        
        // Check if this player can make moves
        guard canMakeMove else { return }
        
        // If there's already a pending move...
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
        guard gameBoard.isEmpty(at: row, col: col) else { return }
        
        // Place the stone temporarily
        gameBoard.placeStone(currentPlayer, at: row, col: col)
        pendingMove = (row: row, col: col)
        
        // Check for captures but don't remove them yet
        pendingCaptures = CaptureEngine.findCaptures(on: gameBoard, at: row, col: col, by: currentPlayer)
        
        // Highlight pending captures differently
        lastCaptures = pendingCaptures
    }
    
    func confirmMove() {
        guard let move = pendingMove else { return }
        
        // Add to move history
        moveHistory.append((row: move.row, col: move.col, player: currentPlayer))
        
        // Remove captured stones and update count
        for capture in pendingCaptures {
            gameBoard.removeStone(at: capture.row, col: capture.col)
        }
        capturedCount[currentPlayer, default: 0] += pendingCaptures.count / 2
        
        // Check win conditions
        if WinDetector.checkFiveInARow(on: gameBoard, at: move.row, col: move.col, for: currentPlayer) {
            gameState = .won(by: currentPlayer, method: .fiveInARow)
        } else if WinDetector.checkCaptureWin(capturedCount: capturedCount[currentPlayer, default: 0]) {
            gameState = .won(by: currentPlayer, method: .fiveCaptures)
        } else {
            // Switch players only if game continues
            currentPlayer = currentPlayer.opponent
        }
        
        // Update move permissions after turn change
        updateMovePermissions()
        
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
        gameBoard.removeStone(at: move.row, col: move.col)
        
        // Clear pending state
        pendingMove = nil
        pendingCaptures = []
        lastCaptures = []
    }
    
    // MARK: - URL Encoding/Decoding
    
    func encodeToQueryItems() -> [URLQueryItem] {
        return GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState,
            blackPlayerID: blackPlayerID
        )
    }
    
    func loadFromURL(_ url: URL) {
        GameStateDecoder.loadFromURL(
            url,
            board: &gameBoard,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
    }
    
    func resetGame() {
        gameBoard.reset()
        currentPlayer = .black
        moveHistory = []
        capturedCount = [.black: 0, .white: 0]
        gameState = .playing
        lastCaptures = []
        pendingMove = nil
        pendingCaptures = []
        isNewGamePendingSend = false
        blackPlayerID = nil
        assignedPlayerColor = nil
        canMakeMove = true
        waitingForOpponent = false
    }
    
    func startNewGame(blackPlayerID: String? = nil) {
        resetGame()
        self.blackPlayerID = blackPlayerID
        // Place the first black stone in the center as a completed move
        gameBoard.placeStone(.black, at: 9, col: 9)
        moveHistory.append((row: 9, col: 9, player: .black))
        currentPlayer = .white // Switch to white for the actual first move
        isNewGamePendingSend = true // Flag that this is a new game ready to send
    }
}

// MARK: - Board Image Generation

extension PenteGameModel {
    func generateBoardImage(size: CGSize = CGSize(width: 300, height: 300), colorScheme: UIUserInterfaceStyle) -> UIImage? {
        return BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: size,
            colorScheme: colorScheme
        )
    }
}