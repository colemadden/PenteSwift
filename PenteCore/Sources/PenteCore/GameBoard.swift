import Foundation

public struct GameBoard {
    public static let size = 19
    private var board: [[Player?]]

    public init() {
        board = Array(repeating: Array(repeating: nil, count: Self.size), count: Self.size)
    }

    public subscript(row: Int, col: Int) -> Player? {
        get {
            guard isValidPosition(row, col) else { return nil }
            return board[row][col]
        }
        set {
            guard isValidPosition(row, col) else { return }
            board[row][col] = newValue
        }
    }

    public var asArray: [[Player?]] {
        return board
    }

    public func isValidPosition(_ row: Int, _ col: Int) -> Bool {
        return row >= 0 && row < Self.size && col >= 0 && col < Self.size
    }

    public func isEmpty(at row: Int, col: Int) -> Bool {
        guard isValidPosition(row, col) else { return false }
        return self[row, col] == nil
    }

    public mutating func reset() {
        board = Array(repeating: Array(repeating: nil, count: Self.size), count: Self.size)
    }

    public mutating func removeStone(at row: Int, col: Int) {
        self[row, col] = nil
    }

    public mutating func placeStone(_ player: Player, at row: Int, col: Int) {
        self[row, col] = player
    }
}
