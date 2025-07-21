import Foundation

struct WinDetector {
    private static let directions = [
        (0, 1),   // horizontal
        (1, 0),   // vertical
        (1, 1),   // diagonal \
        (1, -1)   // diagonal /
    ]
    
    static func checkFiveInARow(on board: GameBoard, at row: Int, col: Int, for player: Player) -> Bool {
        for (dRow, dCol) in directions {
            var count = 1 // Count the stone just placed
            
            // Count in positive direction
            var r = row + dRow
            var c = col + dCol
            while board.isValidPosition(r, c) && board[r, c] == player {
                count += 1
                r += dRow
                c += dCol
            }
            
            // Count in negative direction
            r = row - dRow
            c = col - dCol
            while board.isValidPosition(r, c) && board[r, c] == player {
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
    
    static func checkCaptureWin(capturedCount: Int) -> Bool {
        return capturedCount >= 5
    }
}