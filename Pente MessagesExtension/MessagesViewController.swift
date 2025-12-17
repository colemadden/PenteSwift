import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {
    
    private var hostingController: UIHostingController<PenteGameView>?
    private let gameModel = PenteGameModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameView()
        
        // Set up the delegate to handle moves
        gameModel.moveDelegate = self
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
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        print("Extension becoming active")
        
        // Load game state from selected message
        if let message = conversation.selectedMessage,
           let url = message.url {
            gameModel.loadFromURL(url)
            
            // Determine this player's role based on who started the game
            let localParticipantID = conversation.localParticipantIdentifier.uuidString
            
            if let blackPlayerID = gameModel.blackPlayerID {
                // Game already has a black player assigned
                if blackPlayerID == localParticipantID {
                    // This device is the black player
                    gameModel.setPlayerAssignment(.black, blackPlayerID: blackPlayerID)
                } else {
                    // This device is the white player
                    gameModel.setPlayerAssignment(.white, blackPlayerID: blackPlayerID)
                }
            } else {
                // No black player assigned yet (shouldn't happen with proper encoding)
                print("Warning: No black player ID found in game state")
                gameModel.setPlayerAssignment(nil, blackPlayerID: nil)
            }
        } else {
            // No existing game, start a new one - this player becomes black
            let localParticipantID = conversation.localParticipantIdentifier.uuidString
            gameModel.startNewGame(blackPlayerID: localParticipantID)
            gameModel.setPlayerAssignment(.black, blackPlayerID: localParticipantID)
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        print("Extension resigning active")
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        print("Received message")
        
        // Update game state from received message
        if let url = message.url {
            gameModel.loadFromURL(url)
            
            // Determine this player's role based on who started the game
            let localParticipantID = conversation.localParticipantIdentifier.uuidString
            
            if let blackPlayerID = gameModel.blackPlayerID {
                // Game has a black player assigned
                if blackPlayerID == localParticipantID {
                    // This device is the black player
                    gameModel.setPlayerAssignment(.black, blackPlayerID: blackPlayerID)
                } else {
                    // This device is the white player
                    gameModel.setPlayerAssignment(.white, blackPlayerID: blackPlayerID)
                }
            } else {
                // No black player assigned yet (shouldn't happen)
                print("Warning: No black player ID found in received message")
                gameModel.setPlayerAssignment(nil, blackPlayerID: nil)
            }
        }
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        print("Started sending message")
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        print("Cancelled sending message")
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        print("Will transition to: \(presentationStyle == .compact ? "compact" : "expanded")")
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        print("Did transition to: \(presentationStyle == .compact ? "compact" : "expanded")")
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
    
    private func createMessage() -> MSMessage {
        let message = MSMessage()
        
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
        
        layout.caption = "Pente"
        
        // Create a summary based on game state
        switch gameModel.gameState {
        case .playing:
            let moveCount = gameModel.moveHistory.count
            layout.subcaption = "\(gameModel.currentPlayer.rawValue)'s turn (Move \(moveCount + 1))"
        case .won(let winner, let method):
            layout.subcaption = "\(winner.rawValue) wins by \(method == .fiveInARow ? "five in a row" : "captures")!"
        }
        
        // Add capture info if any
        if gameModel.capturedCount[.black, default: 0] > 0 || gameModel.capturedCount[.white, default: 0] > 0 {
            layout.trailingSubcaption = "B:\(gameModel.capturedCount[.black, default: 0]) W:\(gameModel.capturedCount[.white, default: 0])"
        }
        
        message.layout = layout
        
        return message
    }
    
    private func sendMessage() {
        guard let conversation = activeConversation else { return }
        
        let message = createMessage()
        
        // Insert the message into the conversation
        conversation.insert(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
        
        // Dismiss the extension after sending
        dismiss()
    }
}

// MARK: - Game Move Delegate

extension MessagesViewController: GameMoveDelegate {
    func gameDidMakeMove() {
        // Send the updated game state
        sendMessage()
    }
}
