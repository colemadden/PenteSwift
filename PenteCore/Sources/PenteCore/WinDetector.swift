import Foundation

public struct WinDetector {
    private static let directions = [
        (0, 1),   // horizontal
        (1, 0),   // vertical
        (1, 1),   // diagonal \
        (1, -1)   // diagonal /
    ]

    /// Returns the 5 winning coordinates if `player` has 5-in-a-row through (row, col),
    /// or `nil` otherwise. Capture-wins are detected separately by `checkCaptureWin`.
    public static func checkFiveInARow(on board: GameBoard, at row: Int, col: Int, for player: Player) -> [Position]? {
        for (dRow, dCol) in directions {
            var line: [Position] = [Position(row: row, col: col)]

            var r = row + dRow
            var c = col + dCol
            while board.isValidPosition(r, c) && board[r, c] == player {
                line.append(Position(row: r, col: c))
                r += dRow
                c += dCol
            }

            r = row - dRow
            c = col - dCol
            while board.isValidPosition(r, c) && board[r, c] == player {
                line.append(Position(row: r, col: c))
                r -= dRow
                c -= dCol
            }

            if line.count >= 5 {
                // Trim to the 5 contiguous stones surrounding (row, col): pick the
                // window of 5 with (row, col) inside it. Sorting keeps the array
                // stable for tests and renderer hit-tests.
                let sorted = line.sorted { ($0.row, $0.col) < ($1.row, $1.col) }
                let pivotIdx = sorted.firstIndex(of: Position(row: row, col: col)) ?? 0
                let start = max(0, min(pivotIdx - 2, sorted.count - 5))
                return Array(sorted[start..<(start + 5)])
            }
        }

        return nil
    }

    public static func checkCaptureWin(capturedCount: Int) -> Bool {
        return capturedCount >= 5
    }
}
