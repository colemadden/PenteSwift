import Foundation

struct GameBoard {
    static let size = 19
    private var board: [[Player?]]
    
    init() {
        board = Array(repeating: Array(repeating: nil, count: Self.size), count: Self.size)
    }
    
    subscript(row: Int, col: Int) -> Player? {
        get {
            guard isValidPosition(row, col) else { return nil }
            return board[row][col]
        }
        set {
            guard isValidPosition(row, col) else { return }
            board[row][col] = newValue
        }
    }
    
    var asArray: [[Player?]] {
        return board
    }
    
    func isValidPosition(_ row: Int, _ col: Int) -> Bool {
        return row >= 0 && row < Self.size && col >= 0 && col < Self.size
    }
    
    func isEmpty(at row: Int, col: Int) -> Bool {
        return self[row, col] == nil
    }
    
    mutating func reset() {
        board = Array(repeating: Array(repeating: nil, count: Self.size), count: Self.size)
    }
    
    mutating func removeStone(at row: Int, col: Int) {
        self[row, col] = nil
    }
    
    mutating func placeStone(_ player: Player, at row: Int, col: Int) {
        self[row, col] = player
    }
}