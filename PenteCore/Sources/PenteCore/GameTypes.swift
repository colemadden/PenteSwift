import Foundation

public enum Player: String, CaseIterable, Codable {
    case black = "Black"
    case white = "White"

    public var opponent: Player {
        self == .black ? .white : .black
    }
}

public enum GameState: Codable, Equatable {
    case playing
    case won(by: Player, method: WinMethod)
}

public enum WinMethod: String, Codable {
    case fiveInARow
    case fiveCaptures
}

public protocol GameMoveDelegate: AnyObject {
    func gameDidMakeMove()
}
