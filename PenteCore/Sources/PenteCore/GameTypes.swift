import Foundation

public enum Player: String, CaseIterable, Codable {
    case black = "Black"
    case white = "White"

    public var opponent: Player {
        self == .black ? .white : .black
    }

    /// Localization key for displaying this player's side label.
    /// NOTE: rawValue is the wire format for URL-encoded game state and must
    /// never change. Display strings resolve through this key instead.
    public var displayNameKey: String {
        self == .black ? "player.black" : "player.white"
    }
}

public enum GameState: Codable, Equatable {
    case playing
    case won(by: Player, method: WinMethod)
}

public enum WinMethod: String, Codable {
    case fiveInARow
    case fiveCaptures

    /// Localization key for the win-reason banner.
    public var bannerKey: String {
        self == .fiveInARow ? "win.method.fiveInARow" : "win.method.fiveCaptures"
    }
}

public protocol GameMoveDelegate: AnyObject {
    func gameDidMakeMove()
}
