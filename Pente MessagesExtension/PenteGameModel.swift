import SwiftUI
import PenteCore

class PenteGameModel: ObservableObject {
    // Haptics (ADR-0034). Lazy-prepared generators stay warm for low-latency feedback.
    private let placeHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let captureHaptic = UINotificationFeedbackGenerator()
    private let winHaptic = UINotificationFeedbackGenerator()

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
    @Published var winningLine: [Position]? = nil
    /// Hard gate: after the user confirms a move on this device, no further moves
    /// are allowed until either the opponent's response arrives (didReceive) or
    /// the extension reloads authoritative state (willBecomeActive). Independent
    /// of canMakeMove so it survives any drift in the player-assignment derivation.
    @Published var awaitingOpponentReply: Bool = false
    /// ADR-0033: the single stone currently scale-animating. While `appearing`,
    /// the Canvas skips this position and an overlay Circle renders it instead;
    /// the view clears this back to nil when the ~150ms animation completes and
    /// the Canvas takes over seamlessly. `appearing == false` is the undo
    /// scale-out — the stone is already off the board and only the overlay
    /// shows it shrinking away.
    @Published var animatingStone: (pos: Position, player: Player, appearing: Bool)? = nil

    var blackPlayerID: String? = nil
    var assignedPlayerColor: Player? = nil
    /// Stable identifier for this game, persisted in URL state (ADR-0037). Set on
    /// `startNewGame`, propagated unchanged through every subsequent message, and
    /// restored from URL on `loadFromURL`. Used by the failed-send retry guard.
    /// @Published (ADR-0046) so the view can reset per-game state (zoom/pan)
    /// when a different game loads into the same hosting controller.
    @Published var gameID: UUID? = nil
    
    weak var moveDelegate: GameMoveDelegate?
    /// Set by `MessagesViewController` so the View's "New Game" button can start
    /// a properly-configured game with the local participant ID as `blackPlayerID`.
    /// Without this hook, calling `startNewGame()` directly from the View leaves
    /// `blackPlayerID` nil and pollutes the URL chain (both sides fall into
    /// ADR-0026's permissive fallback and conclude "I am black").
    var newGameAction: (() -> Void)?
    
    var board: [[Player?]] {
        return gameBoard.asArray
    }

    /// ADR-0044: true when confirming the pending move would win the game —
    /// by five-in-a-row (winningLine is set on tentative placement) OR by
    /// completing the fifth capture pair. Drives the gold Send button so
    /// "gold = this move wins" holds for both win conditions.
    var pendingMoveWins: Bool {
        guard pendingMove != nil else { return false }
        if winningLine != nil { return true }
        return WinDetector.checkCaptureWin(
            capturedCount: capturedCount[currentPlayer, default: 0] + pendingCaptures.count / 2)
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
        guard isNewGamePendingSend else { return }
        isNewGamePendingSend = false
        moveDelegate?.gameDidMakeMove()
    }

    /// ADR-0038: fire the placement haptic when an opponent's move lands. Reuses
    /// the same generator as local placement so a stone appearing always feels
    /// the same regardless of who placed it. Also replays the scale-in animation
    /// on the arrived stone (ADR-0033).
    func opponentMoveArrived() {
        placeHaptic.impactOccurred()
        placeHaptic.prepare()
        animateLastMoveArrival()
    }

    /// ADR-0033: scale-in the last committed move. Used for live opponent
    /// arrivals (didReceive) and the open-from-thumbnail replay — no haptic
    /// here; ADR-0038 scopes the arrival haptic to didReceive only.
    func animateLastMoveArrival() {
        guard let last = moveHistory.last else { return }
        animatingStone = (Position(row: last.row, col: last.col), last.player, true)
    }

    /// Open-from-thumbnail replay (ADR-0033): animate the last move on load,
    /// but only when it was the opponent's — replaying the user's own last
    /// move would be noise.
    func animateLastMoveArrivalIfFromOpponent() {
        guard let mine = assignedPlayerColor,
              let last = moveHistory.last,
              last.player != mine else { return }
        animateLastMoveArrival()
    }
    
    func makeMove(row: Int, col: Int) {
        // Check if game is over
        guard case .playing = gameState else { return }

        // Prevent moves during first move ready-to-send state
        guard !isNewGamePendingSend else { return }

        // Hard gate: after we just confirmed a move on this device, lock the
        // board until the opponent's reply lands or the extension reloads.
        guard !awaitingOpponentReply else { return }

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

        // Show the gold winning-line ring on tentative placement so the player
        // sees their about-to-win move highlighted before they tap Send.
        winningLine = WinDetector.checkFiveInARow(on: gameBoard, at: row, col: col, for: currentPlayer)

        // ADR-0033: scale-in the tentative stone.
        animatingStone = (Position(row: row, col: col), currentPlayer, true)

        // ADR-0034: place haptic on successful tentative placement.
        placeHaptic.impactOccurred()
        placeHaptic.prepare()
    }
    
    func confirmMove() {
        guard let move = pendingMove else { return }

        // Snapshot captures before clearing (we still need them to remove stones below).
        let capturesToApply = pendingCaptures

        // Clear pending state FIRST so any intermediate SwiftUI render observes a
        // consistent world: no dashed blue pending ring while the new solid green
        // last-move ring is being placed. Belt-and-suspenders — SwiftUI normally
        // coalesces @Published emissions within a synchronous method, but reordering
        // eliminates any theoretical race where moveHistory.append publishes before
        // pendingMove is cleared.
        pendingMove = nil
        pendingCaptures = []
        lastCaptures = []

        // Add to move history
        moveHistory.append((row: move.row, col: move.col, player: currentPlayer))

        // Remove captured stones and update count
        for capture in capturesToApply {
            gameBoard.removeStone(at: capture.row, col: capture.col)
        }
        capturedCount[currentPlayer, default: 0] += capturesToApply.count / 2

        // ADR-0042: keep the red "just captured" circles visible after the move
        // commits — previously cleared above and never repopulated, so the
        // capture sites vanished the instant the move was confirmed.
        lastCaptures = capturesToApply

        // ADR-0034: capture haptic when captures actually land (warning notification).
        if !capturesToApply.isEmpty {
            captureHaptic.notificationOccurred(.warning)
        }

        // Check win conditions
        if let line = WinDetector.checkFiveInARow(on: gameBoard, at: move.row, col: move.col, for: currentPlayer) {
            winningLine = line
            gameState = .won(by: currentPlayer, method: .fiveInARow)
            winHaptic.notificationOccurred(.success)
        } else if WinDetector.checkCaptureWin(capturedCount: capturedCount[currentPlayer, default: 0]) {
            gameState = .won(by: currentPlayer, method: .fiveCaptures)
            winHaptic.notificationOccurred(.success)
        } else {
            // Switch players only if game continues
            currentPlayer = currentPlayer.opponent
        }

        // Update move permissions after turn change
        updateMovePermissions()

        // Notify delegate that a move was made
        moveDelegate?.gameDidMakeMove()
    }
    
    func undoMove() {
        guard let move = pendingMove else { return }

        // ADR-0033: scale-out the cancelled stone. Set before removal so the
        // overlay knows the stone's color; the board itself loses the stone
        // immediately and only the overlay shows it shrinking away.
        animatingStone = (Position(row: move.row, col: move.col), currentPlayer, false)

        // Remove the pending stone
        gameBoard.removeStone(at: move.row, col: move.col)

        // Clear pending state, including any tentative gold winning-line ring
        // shown by the placement we're undoing.
        pendingMove = nil
        pendingCaptures = []
        lastCaptures = []
        winningLine = nil
    }
    
    // MARK: - URL Encoding/Decoding
    
    func encodeToQueryItems() -> [URLQueryItem] {
        return GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState,
            blackPlayerID: blackPlayerID,
            gameID: gameID
        )
    }
    
    /// Returns false when the URL doesn't decode — the model is left untouched,
    /// and callers must NOT act as if the new state loaded (e.g. adopting the
    /// message's session would pair old game state with a new session, ADR-0046).
    @discardableResult
    func loadFromURL(_ url: URL) -> Bool {
        guard let decoded = GameStateDecoder.decodeFromURL(url) else { return false }

        // ADR-0046: discard any tentative state belonging to the PRE-load
        // board. A pending stone surviving a reload could be confirmed into
        // the new game as a phantom move with stale captures; a surviving
        // isNewGamePendingSend flag would block all moves on the loaded game.
        // (The old board is replaced wholesale below, so the tentative stone
        // itself vanishes with it — only the bookkeeping needs clearing.)
        pendingMove = nil
        pendingCaptures = []
        isNewGamePendingSend = false

        // Assign board and moveHistory as close together as possible so any
        // intermediate SwiftUI render during decode sees a consistent
        // (board, moveHistory) pair — otherwise the last-move ring could
        // briefly point at an old intersection on the new board.
        gameBoard = decoded.board
        moveHistory = decoded.moveHistory
        currentPlayer = decoded.currentPlayer
        capturedCount = decoded.capturedCount
        gameState = decoded.gameState

        // ADR-0042: show which stones the last move captured — replay-derived,
        // so it works for any client version's URL. Fixes the "my stones
        // silently vanished" confusion on game resume.
        lastCaptures = decoded.lastCaptures

        // Snapshot the prior gameID so we can decide whether the URL we're loading
        // belongs to the same game we were previously holding state for. Used for
        // the blackPlayerID defensive merge below.
        let priorGameID = gameID
        let sameGame = decoded.gameID != nil && decoded.gameID == priorGameID

        // gameID is always authoritative from the URL — never preserve a prior
        // value. A stale gameID in the model could let a cached failed message's
        // retry guard match against a different conversation and misroute the
        // dispatch (ADR-0029 / ADR-0037).
        gameID = decoded.gameID

        // blackPlayerID is an immutable per-game property. Only defensively merge
        // (preserve local when URL lacks it) within the SAME game — protects
        // against an in-game poisoned URL without leaking a prior game's role
        // assignment into a different game opened in the same chat.
        if let decodedBlackID = decoded.blackPlayerID {
            blackPlayerID = decodedBlackID
        } else if !sameGame {
            blackPlayerID = nil
        }
        // (else: same game, URL lacks blackID — keep local value as repair.)

        // Recompute winningLine on resume — encoder doesn't persist it (ADR-0019).
        // The last move is the one that triggered the win.
        if case .won(_, .fiveInARow) = gameState, let last = moveHistory.last {
            winningLine = WinDetector.checkFiveInARow(on: gameBoard, at: last.row, col: last.col, for: last.player)
        } else {
            winningLine = nil
        }

        // Authoritative state reloaded — clear the awaiting-opponent gate so the
        // canMakeMove logic (driven by currentPlayer vs assignedPlayerColor) can
        // determine whose turn it is from the loaded position.
        awaitingOpponentReply = false

        // Drop any in-flight stone animation — its position belongs to the
        // pre-load board. Arrival triggers (opponentMoveArrived /
        // animateLastMoveArrivalIfFromOpponent) run after this and re-set it.
        animatingStone = nil

        return true
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
        winningLine = nil
        gameID = nil
        awaitingOpponentReply = false
        animatingStone = nil
    }

    func startNewGame(blackPlayerID: String? = nil) {
        resetGame()
        self.blackPlayerID = blackPlayerID
        self.gameID = UUID()
        // Place the first black stone in the center as a completed move
        let center = GameBoard.size / 2
        gameBoard.placeStone(.black, at: center, col: center)
        moveHistory.append((row: center, col: center, player: .black))
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
            winningLine: winningLine,
            size: size,
            colorScheme: colorScheme
        )
    }
}
