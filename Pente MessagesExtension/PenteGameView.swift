import SwiftUI
import PenteCore

struct PenteGameView: View {
    @ObservedObject var gameModel: PenteGameModel
    @Environment(\.colorScheme) var colorScheme
    /// ADR-0032: tap-outside-the-pill dismisses the win overlay so the final
    /// board can be inspected. Reset whenever the game-end state flips.
    @State private var winOverlayDismissed = false
    /// ADR-0043: first-launch rules overlay. Pente's capture rule is unknown to
    /// players arriving from Gomoku — shown once, dismissed only via "Got it!".
    @AppStorage("hasSeenRules") private var hasSeenRules = false

    // Dynamic colors based on theme
    var boardColor: Color {
        colorScheme == .dark ? Color(hex: "3E2723") : Color(hex: "D4A574")
    }
    
    var blackStoneColor: Color {
        colorScheme == .dark ? Color(hex: "0A0A0A") : Color(hex: "1C1C1C")
    }
    
    var whiteStoneColor: Color {
        colorScheme == .dark ? Color(hex: "E8E8E8") : Color(hex: "FAFAFA")
    }
    
    var gridLineColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.3)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Title
            Text("Pente")
                .font(.title)
                .padding(.top, 10)
            
            // Capture counts
            HStack(spacing: 20) {
                VStack {
                    Text(LocalizedStringKey(Player.black.displayNameKey))
                        .font(.caption)
                    Text("\(gameModel.capturedCount[.black, default: 0])")
                        .font(.title2)
                }

                Text("Captures")
                    .font(.caption)

                VStack {
                    Text(LocalizedStringKey(Player.white.displayNameKey))
                        .font(.caption)
                    Text("\(gameModel.capturedCount[.white, default: 0])")
                        .font(.title2)
                }
            }
            .padding(.vertical, 5)
            
            // Game board
            PenteBoardView(gameModel: gameModel,
                         boardColor: boardColor,
                         blackStoneColor: blackStoneColor,
                         whiteStoneColor: whiteStoneColor,
                         gridLineColor: gridLineColor)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 10)
            
            // Bottom status: single slot, fixed height (ADR-0031, supersedes
            // ADR-0018's hidden sizing replica). Contents are mutually exclusive
            // and the frame is constant, so the board never resizes between
            // states. Undo control removed — tap outside the board cancels a
            // pending stone instead (ADR-0030).
            Group {
                switch gameModel.gameState {
                case .playing:
                    if gameModel.pendingMove != nil || gameModel.isNewGamePendingSend {
                        Button(action: {
                            if gameModel.isNewGamePendingSend {
                                gameModel.sendFirstMove()
                            } else {
                                gameModel.confirmMove()
                            }
                        }) {
                            Text("Send")
                                .frame(width: 80, height: 36)
                                // Gold Send whenever the pending move wins —
                                // row win or fifth capture pair (ADR-0044).
                                .background(gameModel.pendingMoveWins
                                            ? Color(red: 1.0, green: 0.84, blue: 0.0)
                                            : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else if gameModel.waitingForOpponent {
                        VStack(spacing: 5) {
                            Text("Waiting for opponent")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)

                            HStack(spacing: 10) {
                                Circle()
                                    .fill(gameModel.currentPlayer == .black ? blackStoneColor : whiteStoneColor)
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))

                                Text(LocalizedStringKey(gameModel.currentPlayer == .black ? "turn.black" : "turn.white"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(gameModel.currentPlayer == .black ? blackStoneColor : whiteStoneColor)
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))

                            Text("Your turn")
                                .font(.system(size: 16))
                        }
                    }
                case .won:
                    // ADR-0031/0032: the overlay carries the win text; the slot
                    // holds the rematch trigger (visible once the overlay is
                    // dismissed to inspect the final board).
                    playAgainButton
                }
            }
            .frame(height: 60)
            .padding(.bottom, 10)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        // ADR-0030: tapping anywhere outside the board cancels the pending
        // stone. Inner gestures (board taps, Send button) win over this one,
        // so only "dead space" taps land here. undoMove() no-ops when there is
        // no pending stone, including the new-game pending-send state.
        .contentShape(Rectangle())
        .onTapGesture {
            gameModel.undoMove()
        }
        // ADR-0032: translucent game-end overlay — "YOU WON!/YOU LOST!" +
        // Play Again pill. Sits above the tap-outside gesture, so taps hit
        // the overlay (dismiss) rather than undoMove while it's visible.
        .overlay {
            if isWon && !winOverlayDismissed {
                ZStack {
                    Color.black.opacity(0.55)
                        .onTapGesture { winOverlayDismissed = true }
                    VStack(spacing: 24) {
                        Text(winHeadline)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        playAgainButton
                    }
                }
            }
        }
        .onChange(of: isWon) { _ in
            winOverlayDismissed = false
        }
        // ADR-0043: first-launch rules card. Rendered above everything —
        // capture (夹吃) is the rule nobody arriving from Gomoku expects.
        // Deliberately NOT tap-outside dismissable: one "Got it!" tap, once ever.
        .overlay {
            if !hasSeenRules {
                ZStack {
                    Color.black.opacity(0.55)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("tutorial.title")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity)
                        ruleRow("●●●●●", "tutorial.rule.five")
                        ruleRow("●○○●", "tutorial.rule.capture")
                        ruleRow("○○ ×5", "tutorial.rule.pairs")
                        Button(action: { hasSeenRules = true }) {
                            Text("tutorial.gotIt")
                                .font(.headline)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func ruleRow(_ glyph: String, _ key: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(glyph)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 64, alignment: .leading)
            Text(LocalizedStringKey(key))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var isWon: Bool {
        if case .won = gameModel.gameState { return true }
        return false
    }

    /// "YOU WON!" / "YOU LOST!" from the local player's perspective. Falls back
    /// to the winner-colored text when no role is assigned (e.g. spectating a
    /// finished game we never played in).
    private var winHeadline: LocalizedStringKey {
        guard case .won(let winner, _) = gameModel.gameState else { return "" }
        guard let mine = gameModel.assignedPlayerColor else {
            return LocalizedStringKey(winner == .black ? "win.black" : "win.white")
        }
        return mine == winner ? "YOU WON!" : "YOU LOST!"
    }

    private var playAgainButton: some View {
        Button(action: {
            // ADR-0039: rematch — start a fresh, fully-wired game (controller
            // sets blackPlayerID + new MSSession) and dispatch it immediately
            // through the one-tap send ladder. The tapper becomes black with
            // the center-seeded opening (ADR-0025); the opponent moves first.
            gameModel.newGameAction?()
            gameModel.sendFirstMove()
        }) {
            Text("Play Again")
                .font(.headline)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
    }
}

struct PenteBoardView: View {
    @ObservedObject var gameModel: PenteGameModel
    let boardColor: Color
    let blackStoneColor: Color
    let whiteStoneColor: Color
    let gridLineColor: Color

    // Pinch-to-zoom + pan (ADR-0041). `steady*` hold the committed values
    // between gestures; the live values update during a gesture. Transforms are
    // applied OUTSIDE the tap gesture, so hit-testing maps taps back into
    // logical board coordinates automatically — the tap math needs no changes.
    @State private var zoomScale: CGFloat = 1
    @State private var steadyZoom: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var steadyPan: CGSize = .zero

    /// Keep the board covering its viewport: pan is limited to the overhang
    /// created by the current zoom, so no edge ever pulls inside the frame.
    private func clampedPan(_ proposed: CGSize, scale: CGFloat, size: CGSize) -> CGSize {
        let limitX = (scale - 1) * size.width / 2
        let limitY = (scale - 1) * size.height / 2
        return CGSize(
            width: min(max(proposed.width, -limitX), limitX),
            height: min(max(proposed.height, -limitY), limitY)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with board color
                Rectangle()
                    .fill(boardColor)
                    .cornerRadius(8)
                
                // Game board canvas
                Canvas { context, size in
                    let boardSize = GameBoard.size
                    let cellSize = size.width / CGFloat(boardSize)
                    let halfCell = cellSize / 2
                    let stoneRadius = cellSize * 0.35
                    let stoneDiameter = cellSize * 0.7
                    let captureRadius = cellSize * 0.2
                    let captureDiameter = cellSize * 0.4
                    let board = gameModel.board
                    let winningSet = Set(gameModel.winningLine ?? [])
                    // ADR-0033: while a stone is scale-animating IN, the overlay
                    // Circle renders it — skip it here so it isn't double-drawn.
                    // (Scale-OUT stones are already off the board.)
                    let animatingPos = gameModel.animatingStone.flatMap { $0.appearing ? $0.pos : nil }

                    // Draw grid lines
                    for i in 0..<boardSize {
                        let position = CGFloat(i) * cellSize + halfCell

                        // Vertical lines
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: position, y: halfCell))
                                path.addLine(to: CGPoint(x: position, y: size.height - halfCell))
                            },
                            with: .color(gridLineColor),
                            lineWidth: 0.5
                        )

                        // Horizontal lines
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: halfCell, y: position))
                                path.addLine(to: CGPoint(x: size.width - halfCell, y: position))
                            },
                            with: .color(gridLineColor),
                            lineWidth: 0.5
                        )
                    }

                    // Pending captures render as red RINGS on the doomed stones
                    // in the stone loop below (ADR-0044). The old orange dots
                    // were drawn beneath the stones and thus invisible.

                    // Highlight last captures (after move is confirmed)
                    for capture in gameModel.lastCaptures {
                        if !gameModel.pendingCaptures.contains(where: { $0.row == capture.row && $0.col == capture.col }) {
                            let center = CGPoint(
                                x: CGFloat(capture.col) * cellSize + halfCell,
                                y: CGFloat(capture.row) * cellSize + halfCell
                            )

                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: center.x - captureRadius,
                                    y: center.y - captureRadius,
                                    width: captureDiameter,
                                    height: captureDiameter
                                )),
                                with: .color(.red.opacity(0.3))
                            )
                        }
                    }

                    // Draw stones
                    for row in 0..<boardSize {
                        for col in 0..<boardSize {
                            if let stone = board[row][col],
                               animatingPos != Position(row: row, col: col) {
                                let center = CGPoint(
                                    x: CGFloat(col) * cellSize + halfCell,
                                    y: CGFloat(row) * cellSize + halfCell
                                )

                                let isPending = gameModel.pendingMove?.row == row && gameModel.pendingMove?.col == col

                                // Shadow
                                context.fill(
                                    Path(ellipseIn: CGRect(
                                        x: center.x - stoneRadius + 2,
                                        y: center.y - stoneRadius + 2,
                                        width: stoneDiameter,
                                        height: stoneDiameter
                                    )),
                                    with: .color(.black.opacity(0.3))
                                )

                                // Stone with theme-aware colors
                                let stoneColor = stone == .black ? blackStoneColor : whiteStoneColor
                                context.fill(
                                    Path(ellipseIn: CGRect(
                                        x: center.x - stoneRadius,
                                        y: center.y - stoneRadius,
                                        width: stoneDiameter,
                                        height: stoneDiameter
                                    )),
                                    with: .color(stoneColor.opacity(isPending ? 0.7 : 1.0))
                                )

                                // Border for white stones
                                if stone == .white {
                                    context.stroke(
                                        Path(ellipseIn: CGRect(
                                            x: center.x - stoneRadius,
                                            y: center.y - stoneRadius,
                                            width: stoneDiameter,
                                            height: stoneDiameter
                                        )),
                                        with: .color(Color.gray.opacity(0.3)),
                                        lineWidth: 0.5
                                    )
                                }

                                // Red capture-preview ring (ADR-0044): while a
                                // move is pending, ring the stones it would
                                // capture — "send this and these two are gone."
                                // Takes priority over the green last-move ring
                                // (a just-placed opponent stone can be captured
                                // immediately; the warning matters more).
                                let isPendingCapture = gameModel.pendingCaptures
                                    .contains { $0.row == row && $0.col == col }

                                // Gold winning-line ring (ADR-0019). Suppresses
                                // green/blue on the same stones to avoid double-ringing.
                                let isWinning = winningSet.contains(Position(row: row, col: col))
                                if isPendingCapture {
                                    context.stroke(
                                        Path(ellipseIn: CGRect(
                                            x: center.x - stoneRadius,
                                            y: center.y - stoneRadius,
                                            width: stoneDiameter,
                                            height: stoneDiameter
                                        )),
                                        with: .color(.red),
                                        lineWidth: 2
                                    )
                                } else if isWinning {
                                    context.stroke(
                                        Path(ellipseIn: CGRect(
                                            x: center.x - stoneRadius,
                                            y: center.y - stoneRadius,
                                            width: stoneDiameter,
                                            height: stoneDiameter
                                        )),
                                        with: .color(Color(red: 1.0, green: 0.84, blue: 0.0)),
                                        lineWidth: 2.5
                                    )
                                } else if let last = gameModel.moveHistory.last,
                                          last.row == row, last.col == col {
                                    // Last move indicator (solid green ring — committed
                                    // counterpart of the dashed blue pending ring).
                                    context.stroke(
                                        Path(ellipseIn: CGRect(
                                            x: center.x - stoneRadius,
                                            y: center.y - stoneRadius,
                                            width: stoneDiameter,
                                            height: stoneDiameter
                                        )),
                                        with: .color(Color(.systemGreen)),
                                        lineWidth: 2
                                    )
                                }

                                // Highlight pending move (solid blue ring —
                                // matches GamePigeon Gomoku's convention).
                                if isPending && !isWinning {
                                    context.stroke(
                                        Path(ellipseIn: CGRect(
                                            x: center.x - stoneRadius,
                                            y: center.y - stoneRadius,
                                            width: stoneDiameter,
                                            height: stoneDiameter
                                        )),
                                        with: .color(.blue),
                                        lineWidth: 2
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(5)

                // ADR-0033: the single animating stone. Pixel-aligned with the
                // Canvas: same 5pt padding, same cellSize math. Identity is keyed
                // on (position, direction) so a new animation always gets a fresh
                // view instance (and a fresh onAppear).
                if let anim = gameModel.animatingStone {
                    let cellSize = (geometry.size.width - 10) / CGFloat(GameBoard.size)
                    AnimatingStoneView(
                        center: CGPoint(
                            x: 5 + CGFloat(anim.pos.col) * cellSize + cellSize / 2,
                            y: 5 + CGFloat(anim.pos.row) * cellSize + cellSize / 2
                        ),
                        diameter: cellSize * 0.7,
                        color: anim.player == .black ? blackStoneColor : whiteStoneColor,
                        // Canvas draws the pending stone at 0.7 opacity — match it
                        // so there's no opacity pop when the Canvas takes over.
                        opacity: (anim.appearing
                                  && gameModel.pendingMove?.row == anim.pos.row
                                  && gameModel.pendingMove?.col == anim.pos.col) ? 0.7 : 1.0,
                        appearing: anim.appearing,
                        onFinished: {
                            // ADR-0046: only clear the animation we own — a
                            // stale timer from a superseded animation must not
                            // clip a newer one mid-flight.
                            if let cur = gameModel.animatingStone,
                               cur.pos == anim.pos, cur.appearing == anim.appearing {
                                gameModel.animatingStone = nil
                            }
                        }
                    )
                    .id("\(anim.pos.row)-\(anim.pos.col)-\(anim.appearing)")
                }
            }
            .onTapGesture { location in
                let padding: CGFloat = 5
                let adjustedLocation = CGPoint(x: location.x - padding, y: location.y - padding)
                let cellSize = (geometry.size.width - padding * 2) / CGFloat(GameBoard.size)
                let col = Int(adjustedLocation.x / cellSize)
                let row = Int(adjustedLocation.y / cellSize)

                if col >= 0 && col < GameBoard.size && row >= 0 && row < GameBoard.size {
                    gameModel.makeMove(row: row, col: col)
                }
            }
            // ADR-0041: zoom/pan transforms sit outside the tap gesture, so the
            // tap location above is already in logical board coordinates.
            .scaleEffect(zoomScale)
            .offset(panOffset)
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = min(max(steadyZoom * value, 1), 3)
                        panOffset = clampedPan(panOffset, scale: zoomScale, size: geometry.size)
                    }
                    .onEnded { _ in
                        steadyZoom = zoomScale
                        steadyPan = panOffset
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        // Pan only exists while zoomed in.
                        guard zoomScale > 1 else { return }
                        panOffset = clampedPan(
                            CGSize(width: steadyPan.width + value.translation.width,
                                   height: steadyPan.height + value.translation.height),
                            scale: zoomScale, size: geometry.size)
                    }
                    .onEnded { _ in
                        steadyPan = panOffset
                    }
            )
            .clipped()
            .contentShape(Rectangle())
            // ADR-0046: zoom/pan are per-game, not per-process. The hosting
            // controller persists across activations, so without this a
            // different game would inherit the previous game's viewport
            // (contradicting ADR-0041's original reset assumption).
            .onChange(of: gameModel.gameID) { _ in
                zoomScale = 1
                steadyZoom = 1
                panOffset = .zero
                steadyPan = .zero
            }
        }
    }
}

/// ADR-0033: renders the one stone that is currently scale-animating.
/// Scale-in runs 0.3 → 1.0 (~150ms ease-out); scale-out is the mirror.
/// Calls `onFinished` slightly after the animation so the model can clear
/// `animatingStone` and hand rendering back to the Canvas without a seam.
private struct AnimatingStoneView: View {
    let center: CGPoint
    let diameter: CGFloat
    let color: Color
    let opacity: Double
    let appearing: Bool
    let onFinished: () -> Void

    @State private var scale: CGFloat

    init(center: CGPoint, diameter: CGFloat, color: Color, opacity: Double,
         appearing: Bool, onFinished: @escaping () -> Void) {
        self.center = center
        self.diameter = diameter
        self.color = color
        self.opacity = opacity
        self.appearing = appearing
        self.onFinished = onFinished
        _scale = State(initialValue: appearing ? 0.3 : 1.0)
    }

    var body: some View {
        Circle()
            .fill(color)
            .opacity(appearing ? opacity : opacity * Double(scale))
            .frame(width: diameter, height: diameter)
            .scaleEffect(scale)
            .position(center)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 0.15)) {
                    scale = appearing ? 1.0 : 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    onFinished()
                }
            }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    PenteGameView(gameModel: PenteGameModel())
}
