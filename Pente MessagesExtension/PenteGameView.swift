import SwiftUI

struct PenteGameView: View {
    @ObservedObject var gameModel: PenteGameModel
    @Environment(\.colorScheme) var colorScheme
    
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
                    Text("Black")
                        .font(.caption)
                    Text("\(gameModel.capturedCount[.black, default: 0])")
                        .font(.title2)
                }
                
                Text("Captures")
                    .font(.caption)
                
                VStack {
                    Text("White")
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
            
            // Game status and controls
            Group {
                switch gameModel.gameState {
                case .playing:
                    if gameModel.pendingMove != nil {
                        // Show Send/Undo buttons when there's a pending move
                        HStack(spacing: 20) {
                            Button(action: {
                                gameModel.undoMove()
                            }) {
                                Text("Undo")
                                    .frame(width: 80, height: 36)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                gameModel.confirmMove()
                            }) {
                                Text("Send")
                                    .frame(width: 80, height: 36)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    } else if gameModel.isFirstMoveReadyToSend {
                        // Show Send button for first move
                        Button(action: {
                            gameModel.sendFirstMove()
                        }) {
                            Text("Send")
                                .frame(width: 80, height: 36)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else {
                        // Show whose turn it is or waiting message
                        if gameModel.waitingForOpponent {
                            VStack(spacing: 5) {
                                Text("Waiting for opponent")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(gameModel.currentPlayer == .black ? blackStoneColor : whiteStoneColor)
                                        .frame(width: 20, height: 20)
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                    
                                    Text(gameModel.currentPlayer.rawValue + "'s turn")
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
                    }
                case .won(let winner, let method):
                    VStack(spacing: 5) {
                        Text("\(winner.rawValue) wins!")
                            .font(.title2)
                            .bold()
                        Text(method == .fiveInARow ? "Five in a row!" : "Five captures!")
                            .font(.caption)
                        
                        Button("New Game") {
                            // Note: In a real scenario, we'd need access to the conversation
                            // For now, we'll reset without setting a specific black player ID
                            // The MessagesViewController will handle player assignment
                            gameModel.startNewGame()
                        }
                        .padding(.top, 5)
                    }
                }
            }
            .padding(.bottom, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

struct PenteBoardView: View {
    @ObservedObject var gameModel: PenteGameModel
    let boardColor: Color
    let blackStoneColor: Color
    let whiteStoneColor: Color
    let gridLineColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with board color
                Rectangle()
                    .fill(boardColor)
                    .cornerRadius(8)
                
                // Game board canvas
                Canvas { context, size in
                    let cellSize = size.width / 19
                    
                    // Draw grid lines
                    for i in 0..<19 {
                        let position = CGFloat(i) * cellSize + cellSize / 2
                        
                        // Vertical lines
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: position, y: cellSize / 2))
                                path.addLine(to: CGPoint(x: position, y: size.height - cellSize / 2))
                            },
                            with: .color(gridLineColor),
                            lineWidth: 0.5
                        )
                        
                        // Horizontal lines
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: cellSize / 2, y: position))
                                path.addLine(to: CGPoint(x: size.width - cellSize / 2, y: position))
                            },
                            with: .color(gridLineColor),
                            lineWidth: 0.5
                        )
                    }
                    
                    // Highlight pending captures with different color
                    for capture in gameModel.pendingCaptures {
                        let center = CGPoint(
                            x: CGFloat(capture.col) * cellSize + cellSize / 2,
                            y: CGFloat(capture.row) * cellSize + cellSize / 2
                        )
                        
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: center.x - cellSize * 0.2,
                                y: center.y - cellSize * 0.2,
                                width: cellSize * 0.4,
                                height: cellSize * 0.4
                            )),
                            with: .color(.orange.opacity(0.3))
                        )
                    }
                    
                    // Highlight last captures (after move is confirmed)
                    for capture in gameModel.lastCaptures {
                        if !gameModel.pendingCaptures.contains(where: { $0.row == capture.row && $0.col == capture.col }) {
                            let center = CGPoint(
                                x: CGFloat(capture.col) * cellSize + cellSize / 2,
                                y: CGFloat(capture.row) * cellSize + cellSize / 2
                            )
                            
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: center.x - cellSize * 0.2,
                                    y: center.y - cellSize * 0.2,
                                    width: cellSize * 0.4,
                                    height: cellSize * 0.4
                                )),
                                with: .color(.red.opacity(0.3))
                            )
                        }
                    }
                    
                    // Draw stones
                    for row in 0..<19 {
                        for col in 0..<19 {
                            if let stone = gameModel.board[row][col] {
                                let center = CGPoint(
                                    x: CGFloat(col) * cellSize + cellSize / 2,
                                    y: CGFloat(row) * cellSize + cellSize / 2
                                )
                                
                                let isPending = gameModel.pendingMove?.row == row && gameModel.pendingMove?.col == col
                                
                                // Shadow for stones - more pronounced
                                context.fill(
                                    Path(ellipseIn: CGRect(
                                        x: center.x - cellSize * 0.35 + 2,
                                        y: center.y - cellSize * 0.35 + 2,
                                        width: cellSize * 0.7,
                                        height: cellSize * 0.7
                                    )),
                                    with: .color(.black.opacity(0.3))
                                )
                                
                                // Stone with theme-aware colors
                                let stoneColor = stone == .black ? blackStoneColor : whiteStoneColor
                                context.fill(
                                    Path(ellipseIn: CGRect(
                                        x: center.x - cellSize * 0.35,
                                        y: center.y - cellSize * 0.35,
                                        width: cellSize * 0.7,
                                        height: cellSize * 0.7
                                    )),
                                    with: .color(stoneColor.opacity(isPending ? 0.7 : 1.0))
                                )
                                
                                // Border for white stones - subtle in both themes
                                if stone == .white {
                                    context.stroke(
                                        Path(ellipseIn: CGRect(
                                            x: center.x - cellSize * 0.35,
                                            y: center.y - cellSize * 0.35,
                                            width: cellSize * 0.7,
                                            height: cellSize * 0.7
                                        )),
                                        with: .color(Color.gray.opacity(0.3)),
                                        lineWidth: 0.5
                                    )
                                }
                                
                                // Highlight pending move
                                if isPending {
                                    context.stroke(
                                        Path(ellipseIn: CGRect(
                                            x: center.x - cellSize * 0.35,
                                            y: center.y - cellSize * 0.35,
                                            width: cellSize * 0.7,
                                            height: cellSize * 0.7
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
            }
            .onTapGesture { location in
                let padding: CGFloat = 5
                let adjustedLocation = CGPoint(x: location.x - padding, y: location.y - padding)
                let cellSize = (geometry.size.width - padding * 2) / 19
                let col = Int(adjustedLocation.x / cellSize)
                let row = Int(adjustedLocation.y / cellSize)
                
                if col >= 0 && col < 19 && row >= 0 && row < 19 {
                    gameModel.makeMove(row: row, col: col)
                }
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
