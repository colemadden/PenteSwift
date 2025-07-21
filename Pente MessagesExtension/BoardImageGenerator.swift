import SwiftUI
import UIKit

struct BoardImageGenerator {
    static func generateBoardImage(
        board: [[Player?]],
        moveHistory: [(row: Int, col: Int, player: Player)],
        size: CGSize = CGSize(width: 300, height: 300),
        colorScheme: UIUserInterfaceStyle
    ) -> UIImage? {
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