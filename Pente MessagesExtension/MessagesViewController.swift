import UIKit
import Messages
import SwiftUI
import PenteCore

class MessagesViewController: MSMessagesAppViewController {

    private var hostingController: UIHostingController<PenteGameView>?
    let gameModel = PenteGameModel()
    private var currentSession: MSSession?
    /// Messages whose dispatch (send + insert) both failed, keyed by the
    /// `gameID` of the game each belongs to (ADR-0037). On willBecomeActive we
    /// re-dispatch the entry matching `gameModel.gameID` (after loading the
    /// active game) — UUID equality is stable across framework reads in a way
    /// `MSSession ===` is not, so this guards against both wrong-chat and
    /// wrong-game (same-chat multi-game) misrouting (ADR-0029). Keyed per game
    /// (ADR-0046) so a double-failure in one game can never evict another
    /// game's cached move.
    private var pendingFailedMessages: [UUID: MSMessage] = [:]

    /// Bundle that owns Localizable.xcstrings. In production this equals Bundle.main
    /// (the extension bundle), but in XCTest Bundle.main is the test runner, not the
    /// bundle containing the catalog. Looking up the bundle by this class forces the
    /// right one in both contexts.
    private static let localizationBundle = Bundle(for: MessagesViewController.self)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameView()

        // Set up the delegate to handle moves
        gameModel.moveDelegate = self

        // Wire the "New Game" button so it can rebuild a properly-configured game
        // with the local participant ID as blackPlayerID — required for both ends
        // to agree on player assignment in subsequent moves.
        gameModel.newGameAction = { [weak self] in
            guard let self = self, let conversation = self.activeConversation else { return }
            let localParticipantID = conversation.localParticipantIdentifier.uuidString
            self.gameModel.startNewGame(blackPlayerID: localParticipantID)
            self.gameModel.setPlayerAssignment(.black, blackPlayerID: localParticipantID)
            self.currentSession = MSSession()
        }
    }

    private func setupGameView() {
        // Create and host the SwiftUI view with our game model
        let gameView = PenteGameView(gameModel: gameModel)
        let hosting = UIHostingController(rootView: gameView)
        self.hostingController = hosting

        // Add as child view controller
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        // Set up constraints to fill the view with safe area
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        hosting.didMove(toParent: self)
    }

    // MARK: - Player Assignment

    private func assignPlayerRole(from conversation: MSConversation) {
        let localParticipantID = conversation.localParticipantIdentifier.uuidString
        if let blackPlayerID = gameModel.blackPlayerID {
            let color: Player = (blackPlayerID == localParticipantID) ? .black : .white
            gameModel.setPlayerAssignment(color, blackPlayerID: blackPlayerID)
        } else {
            #if DEBUG
            print("Warning: No black player ID found in game state")
            #endif
            gameModel.setPlayerAssignment(nil, blackPlayerID: nil)
        }
    }

    // MARK: - Conversation Handling

    override func willBecomeActive(with conversation: MSConversation) {
        #if DEBUG
        print("Extension becoming active")
        #endif

        // Apple documents that MSMessagesAppViewController callbacks "can be called
        // on any thread." Mutating @Published properties off-main leaves SwiftUI
        // without a main-thread notification and the view fails to refresh. Hop
        // to main when needed; stay synchronous when already on main so unit
        // tests can assert on state immediately after this call returns.
        let work: () -> Void = { [weak self] in
            guard let self = self else { return }
            // Load game state from selected message. Session adoption is gated
            // on decode success (ADR-0046) — same reasoning as didReceive: a
            // failed decode must not pair the prior game's state with this
            // bubble's session. On failure the model and session keep their
            // previous values.
            if let message = conversation.selectedMessage,
               let url = message.url {
                if self.gameModel.loadFromURL(url) {
                    self.assignPlayerRole(from: conversation)
                    // Reuse the existing session so all messages update together
                    self.currentSession = message.session
                    // ADR-0033: open-from-thumbnail replay — scale-in the
                    // opponent's just-arrived move so it's obvious which is new.
                    self.gameModel.animateLastMoveArrivalIfFromOpponent()
                }
            } else {
                // No existing game, start a new one - this player becomes black
                let localParticipantID = conversation.localParticipantIdentifier.uuidString
                self.gameModel.startNewGame(blackPlayerID: localParticipantID)
                self.gameModel.setPlayerAssignment(.black, blackPlayerID: localParticipantID)
                // Create a new session for this game
                self.currentSession = MSSession()
            }

            // Retry any message whose dispatch failed last time we were active.
            // Match on `gameID` (ADR-0037) — UUID equality is stable, unlike
            // MSSession `===`, and uniqueness per game means a match implies same
            // chat AND same game. Non-matching entries stay cached: if the user
            // opens a different Pente game in the interim, each failed move
            // waits in its own per-game slot until they return to that game.
            //
            // The matching entry is REMOVED before dispatch (single-flight,
            // ADR-0046): a second activation racing this one finds the slot
            // empty and cannot double-dispatch the same message. If the retry
            // double-fails again, the dispatch failure path re-caches it.
            if let currentID = self.gameModel.gameID,
               let cached = self.pendingFailedMessages.removeValue(forKey: currentID) {
                // Realign local state to what the cached message represents
                // *before* dispatching. The earlier loadFromURL in this call
                // rolled the model back to the opponent's last-seen position,
                // which is the state from *before* the user's failed move.
                // Reloading from the cached URL reapplies the failed move locally
                // so the UI matches what we're about to redeliver — otherwise
                // the user would look at a board missing their own move and
                // could re-tap, producing a duplicate.
                if let cachedURL = cached.url {
                    self.gameModel.loadFromURL(cachedURL)
                    self.assignPlayerRole(from: conversation)
                }
                self.dispatchMessage(cached, conversation: conversation)
            }
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    override func didResignActive(with conversation: MSConversation) {
        #if DEBUG
        print("Extension resigning active")
        #endif
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        #if DEBUG
        print("Received message")
        #endif

        // Apple documents that MSMessagesAppViewController callbacks "can be called
        // on any thread." If didReceive arrives on a background thread, mutating
        // @Published properties from there leaves SwiftUI without a main-thread
        // notification, so the board doesn't refresh until something else (like
        // willBecomeActive on a swipe-out/swipe-in) re-triggers a render. Hop to
        // main when needed; stay synchronous when we're already on main so unit
        // tests can assert on state immediately after this call returns.
        let work: () -> Void = { [weak self] in
            guard let self = self, let url = message.url else { return }
            let priorMoveCount = self.gameModel.moveHistory.count
            // ADR-0046: only on a successful load do we adopt the incoming
            // message's session. Adopting it after a failed decode would pair
            // the OLD game's state with the NEW message's session — a reply
            // would then update the wrong transcript bubble.
            guard self.gameModel.loadFromURL(url) else { return }
            self.assignPlayerRole(from: conversation)
            self.currentSession = message.session
            // ADR-0038: opponent-move-arrival haptic. Only fire when the loaded
            // state actually advanced — guards against redundant didReceive
            // callbacks for the same message.
            if self.gameModel.moveHistory.count > priorMoveCount {
                self.gameModel.opponentMoveArrived()
            }
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        #if DEBUG
        print("Started sending message")
        #endif
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        #if DEBUG
        print("Cancelled sending message")
        #endif
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        #if DEBUG
        print("Will transition to: \(presentationStyle == .compact ? "compact" : "expanded")")
        #endif
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        #if DEBUG
        print("Did transition to: \(presentationStyle == .compact ? "compact" : "expanded")")
        #endif
    }

    // MARK: - Message Creation

    private func createDynamicBoardImage(size: CGSize) -> UIImage? {
        // Generate both light and dark versions of the board image
        guard let lightImage = gameModel.generateBoardImage(size: size, colorScheme: .light),
              let darkImage = gameModel.generateBoardImage(size: size, colorScheme: .dark) else {
            return nil
        }

        // Create a dynamic image asset that adapts to viewer's theme
        let imageAsset = UIImageAsset()
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

        imageAsset.register(lightImage, with: lightTraits)
        imageAsset.register(darkImage, with: darkTraits)

        // Return the dynamic image that will adapt to the viewer's current theme
        return imageAsset.image(with: .current)
    }

    func createMessage() -> MSMessage {
        let session = currentSession ?? MSSession()
        currentSession = session
        let message = MSMessage(session: session)

        // Encode game state into URL
        var components = URLComponents()
        components.queryItems = gameModel.encodeToQueryItems()
        message.url = components.url

        // Create the message layout
        let layout = MSMessageTemplateLayout()

        // Generate dynamic board preview image that adapts to viewer's theme
        if let dynamicBoardImage = createDynamicBoardImage(size: CGSize(width: 300, height: 300)) {
            layout.image = dynamicBoardImage
        }

        layout.caption = String(localized: "layout.caption", bundle: Self.localizationBundle)

        // Create a summary based on game state.
        // NOTE: MSMessageTemplateLayout strings travel with the MSMessage itself
        // (the receiver does not regenerate them), so this renders in the sender's
        // locale for every recipient. The trailing subcaption uses locale-neutral
        // circle glyphs to avoid that asymmetry.
        switch gameModel.gameState {
        case .playing:
            let moveNumber = gameModel.moveHistory.count + 1
            let formatKey: String.LocalizationValue = gameModel.currentPlayer == .black
                ? "layout.subcaption.turn.black"
                : "layout.subcaption.turn.white"
            // Catalog value is a %lld format string. Resolve key, then substitute arg.
            let format = String(localized: formatKey, bundle: Self.localizationBundle)
            layout.subcaption = String(format: format, moveNumber)
        case .won(let winner, let method):
            let key: String.LocalizationValue
            switch (winner, method) {
            case (.black, .fiveInARow): key = "layout.subcaption.win.black.fiveInARow"
            case (.white, .fiveInARow): key = "layout.subcaption.win.white.fiveInARow"
            case (.black, .fiveCaptures): key = "layout.subcaption.win.black.fiveCaptures"
            case (.white, .fiveCaptures): key = "layout.subcaption.win.white.fiveCaptures"
            }
            layout.subcaption = String(localized: key, bundle: Self.localizationBundle)
        }

        // Locale-neutral trailing subcaption using circle glyphs (●=black, ○=white).
        // Not localized — identical in every language, safe to transmit in MSMessage.
        if gameModel.capturedCount[.black, default: 0] > 0 || gameModel.capturedCount[.white, default: 0] > 0 {
            layout.trailingSubcaption = "●\(gameModel.capturedCount[.black, default: 0]) ○\(gameModel.capturedCount[.white, default: 0])"
        }

        message.layout = layout

        return message
    }

    private func sendMessage() {
        guard let conversation = activeConversation else { return }
        // Lock the board until the opponent's reply lands (cleared by didReceive's
        // loadFromURL) or the extension reactivates (cleared by willBecomeActive's
        // loadFromURL). Set here, after the conversation guard, so unit tests that
        // drive the model through its delegate without a live MSConversation are
        // not gated by this flag. Skip on win — won-state UI handles the New Game
        // flow separately and shouldn't be locked.
        if case .playing = gameModel.gameState {
            gameModel.awaitingOpponentReply = true
        }
        dispatchMessage(createMessage(), conversation: conversation)
    }

    /// ADR-0029 dispatch ladder: try one-tap `send`, fall back to `insert` (compose
    /// bar) on failure, and finally cache the message for retry on next
    /// willBecomeActive if both fail. `confirmMove` has already mutated local state,
    /// so silently dropping the message would diverge our view from the opponent's.
    private func dispatchMessage(_ message: MSMessage, conversation: MSConversation) {
        // Snapshot the gameID under which the message was dispatched. Even if the
        // model's gameID later changes (extension reused for another game), the
        // cache still binds this message to its original game.
        let dispatchGameID = gameModel.gameID
        conversation.send(message) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async { self?.clearCacheIfHolds(message) }
                return
            }
            #if DEBUG
            print("send(_:) failed, falling back to insert: \(error!)")
            #endif
            conversation.insert(message) { [weak self] insertError in
                if insertError == nil {
                    // Insert succeeded — message is in the compose bar and the user
                    // can recover by tapping iMessage Send. No further retry needed.
                    DispatchQueue.main.async { self?.clearCacheIfHolds(message) }
                    return
                }
                #if DEBUG
                print("insert fallback also failed; cached for retry on next willBecomeActive: \(insertError!)")
                #endif
                guard let dispatchGameID = dispatchGameID else { return }
                DispatchQueue.main.async {
                    self?.pendingFailedMessages[dispatchGameID] = message
                }
            }
        }
    }

    /// Drop any cache entries holding the very same `MSMessage` instance that
    /// just dispatched successfully. Identity comparison (`===`) avoids clearing
    /// a different game's pending retry, and also defuses a stale failure
    /// closure from an earlier attempt re-caching a message that has since
    /// succeeded (ADR-0046).
    private func clearCacheIfHolds(_ message: MSMessage) {
        pendingFailedMessages = pendingFailedMessages.filter { $0.value !== message }
    }
}

// MARK: - Game Move Delegate

extension MessagesViewController: GameMoveDelegate {
    func gameDidMakeMove() {
        sendMessage()
    }
}
