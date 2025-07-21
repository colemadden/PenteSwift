import Foundation

struct CaptureEngine {
    private static let directions = [
        (-1, -1), (-1, 0), (-1, 1),
        (0, -1),           (0, 1),
        (1, -1),  (1, 0),  (1, 1)
    ]
    
    static func findCaptures(on board: GameBoard, at row: Int, col: Int, by player: Player) -> [(row: Int, col: Int)] {
        var captures: [(row: Int, col: Int)] = []
        
        for (dRow, dCol) in directions {
            let capturedStones = checkCaptureInDirection(
                on: board,
                startRow: row,
                startCol: col,
                deltaRow: dRow,
                deltaCol: dCol,
                player: player
            )
            captures.append(contentsOf: capturedStones)
        }
        
        return captures
    }
    
    private static func checkCaptureInDirection(
        on board: GameBoard,
        startRow: Int,
        startCol: Int,
        deltaRow: Int,
        deltaCol: Int,
        player: Player
    ) -> [(row: Int, col: Int)] {
        let pos1 = (startRow + deltaRow, startCol + deltaCol)
        let pos2 = (startRow + 2*deltaRow, startCol + 2*deltaCol)
        let pos3 = (startRow + 3*deltaRow, startCol + 3*deltaCol)
        
        guard board.isValidPosition(pos1.0, pos1.1),
              board.isValidPosition(pos2.0, pos2.1),
              board.isValidPosition(pos3.0, pos3.1) else {
            return []
        }
        
        if board[pos1.0, pos1.1] == player.opponent &&
           board[pos2.0, pos2.1] == player.opponent &&
           board[pos3.0, pos3.1] == player {
            return [(row: pos1.0, col: pos1.1), (row: pos2.0, col: pos2.1)]
        }
        
        return []
    }
}