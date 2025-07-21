import Foundation

enum Player: String, CaseIterable, Codable {
    case black = "Black"
    case white = "White"
    
    var opponent: Player {
        self == .black ? .white : .black
    }
}

enum GameState: Codable {
    case playing
    case won(by: Player, method: WinMethod)
}

enum WinMethod: String, Codable {
    case fiveInARow
    case fiveCaptures
}

protocol GameMoveDelegate: AnyObject {
    func gameDidMakeMove()
}