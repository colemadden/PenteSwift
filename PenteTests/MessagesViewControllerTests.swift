import XCTest
import Messages
@testable import Pente_MessagesExtension

// Mock conversation for testing
class MockMSConversation: MSConversation {
    var mockSelectedMessage: MSMessage?
    
    override var selectedMessage: MSMessage? {
        return mockSelectedMessage
    }
    
    // Store inserted messages for verification
    var insertedMessages: [MSMessage] = []
    
    override func insert(_ message: MSMessage, completionHandler: ((Error?) -> Void)? = nil) {
        insertedMessages.append(message)
        completionHandler?(nil)
    }
}

// Mock message for testing
class MockMSMessage: MSMessage {
    var mockURL: URL?
    
    override var url: URL? {
        get { return mockURL }
        set { mockURL = newValue }
    }
}

final class MessagesViewControllerTests: XCTestCase {
    
    var viewController: MessagesViewController!
    var mockConversation: MockMSConversation!
    
    override func setUp() {
        super.setUp()
        viewController = MessagesViewController()
        mockConversation = MockMSConversation()
        
        // Load the view
        viewController.loadViewIfNeeded()
    }
    
    override func tearDown() {
        viewController = nil
        mockConversation = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testViewControllerInitialization() {
        XCTAssertNotNil(viewController.view)
        // Game model should be initialized
        // Hosting controller should be set up
    }
    
    func testGameModelSetup() {
        // Game model should have the view controller as delegate
        XCTAssertNotNil(viewController.value(forKey: "gameModel"))
        
        // Access gameModel through reflection or make it internal for testing
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        XCTAssertNotNil(gameModel)
        XCTAssertTrue(gameModel?.moveDelegate === viewController)
    }
    
    // MARK: - Conversation Handling Tests
    
    func testWillBecomeActiveWithoutSelectedMessage() {
        // Test becoming active without a selected message (new game scenario)
        viewController.willBecomeActive(with: mockConversation)
        
        // Should start a new game
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        XCTAssertNotNil(gameModel)
        XCTAssertTrue(gameModel?.isFirstMoveReadyToSend == true)
        XCTAssertEqual(gameModel?.board[9][9], .black) // Center stone should be placed
    }
    
    func testWillBecomeActiveWithSelectedMessage() {
        // Create a mock message with game state
        let mockMessage = MockMSMessage()
        mockMessage.mockURL = URL(string: "pente://game?moves=B9,9;W10,10;&current=Black&capB=0&capW=0&state=playing")
        mockConversation.mockSelectedMessage = mockMessage
        
        viewController.willBecomeActive(with: mockConversation)
        
        // Should load the game state from the message
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        XCTAssertNotNil(gameModel)
        XCTAssertEqual(gameModel?.moveHistory.count, 2)
        XCTAssertEqual(gameModel?.currentPlayer, .black)
    }
    
    func testDidReceiveMessage() {
        let mockMessage = MockMSMessage()
        mockMessage.mockURL = URL(string: "pente://game?moves=B9,9;&current=White&capB=0&capW=0&state=playing")
        
        viewController.didReceive(mockMessage, conversation: mockConversation)
        
        // Should update game state from received message
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        XCTAssertNotNil(gameModel)
        XCTAssertEqual(gameModel?.moveHistory.count, 1)
        XCTAssertEqual(gameModel?.currentPlayer, .white)
    }
    
    // MARK: - Message Creation Tests
    
    func testCreateMessageWithEmptyGame() {
        // Use reflection to access private method or make it internal for testing
        let selector = NSSelectorFromString("createMessage")
        
        if viewController.responds(to: selector) {
            let message = viewController.perform(selector)?.takeUnretainedValue() as? MSMessage
            
            XCTAssertNotNil(message)
            XCTAssertNotNil(message?.url)
            XCTAssertNotNil(message?.layout)
            
            if let layout = message?.layout as? MSMessageTemplateLayout {
                XCTAssertEqual(layout.caption, "Pente")
                XCTAssertNotNil(layout.subcaption)
            }
        }
    }
    
    func testCreateMessageWithGameInProgress() {
        // Set up game state first
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        // Make some moves
        gameModel?.makeMove(row: 9, col: 9)
        gameModel?.confirmMove()
        gameModel?.makeMove(row: 10, col: 10)
        gameModel?.confirmMove()
        
        let selector = NSSelectorFromString("createMessage")
        
        if viewController.responds(to: selector) {
            let message = viewController.perform(selector)?.takeUnretainedValue() as? MSMessage
            
            XCTAssertNotNil(message)
            XCTAssertNotNil(message?.url)
            
            // URL should contain move history
            if let urlString = message?.url?.absoluteString {
                XCTAssertTrue(urlString.contains("moves="))
            }
            
            if let layout = message?.layout as? MSMessageTemplateLayout {
                XCTAssertNotNil(layout.subcaption)
                XCTAssertTrue(layout.subcaption?.contains("turn") == true || layout.subcaption?.contains("Move") == true)
            }
        }
    }
    
    func testCreateMessageWithWonGame() {
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        // Force game to won state
        gameModel?.gameState = .won(by: .black, method: .fiveInARow)
        
        let selector = NSSelectorFromString("createMessage")
        
        if viewController.responds(to: selector) {
            let message = viewController.perform(selector)?.takeUnretainedValue() as? MSMessage
            
            if let layout = message?.layout as? MSMessageTemplateLayout {
                XCTAssertTrue(layout.subcaption?.contains("wins") == true)
            }
        }
    }
    
    func testCreateMessageWithCaptures() {
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        // Set some captures
        gameModel?.capturedCount[.black] = 2
        gameModel?.capturedCount[.white] = 1
        
        let selector = NSSelectorFromString("createMessage")
        
        if viewController.responds(to: selector) {
            let message = viewController.perform(selector)?.takeUnretainedValue() as? MSMessage
            
            if let layout = message?.layout as? MSMessageTemplateLayout {
                XCTAssertNotNil(layout.trailingSubcaption)
                XCTAssertTrue(layout.trailingSubcaption?.contains("B:2") == true)
                XCTAssertTrue(layout.trailingSubcaption?.contains("W:1") == true)
            }
        }
    }
    
    // MARK: - GameMoveDelegate Tests
    
    func testGameDidMakeMoveCallsSendMessage() {
        // Mock the active conversation
        let conversationProperty = class_getInstanceVariable(MessagesViewController.self, "activeConversation")
        if let conversationProperty = conversationProperty {
            object_setIvar(viewController, conversationProperty, mockConversation)
        }
        
        // Trigger gameDidMakeMove
        viewController.gameDidMakeMove()
        
        // Should create and insert a message
        XCTAssertEqual(mockConversation.insertedMessages.count, 1)
        
        let insertedMessage = mockConversation.insertedMessages.first
        XCTAssertNotNil(insertedMessage)
        XCTAssertNotNil(insertedMessage?.url)
        XCTAssertNotNil(insertedMessage?.layout)
    }
    
    // MARK: - Presentation Style Tests
    
    func testPresentationStyleTransitions() {
        // Test that transition methods don't crash
        viewController.willTransition(to: .compact)
        viewController.didTransition(to: .compact)
        
        viewController.willTransition(to: .expanded)
        viewController.didTransition(to: .expanded)
        
        // These are mainly for logging, so just verify they don't crash
        XCTAssertTrue(true) // If we get here, no crashes occurred
    }
    
    // MARK: - Message Lifecycle Tests
    
    func testDidStartSendingMessage() {
        let mockMessage = MockMSMessage()
        
        // Should not crash
        viewController.didStartSending(mockMessage, conversation: mockConversation)
        XCTAssertTrue(true)
    }
    
    func testDidCancelSendingMessage() {
        let mockMessage = MockMSMessage()
        
        // Should not crash
        viewController.didCancelSending(mockMessage, conversation: mockConversation)
        XCTAssertTrue(true)
    }
    
    func testDidResignActive() {
        // Should not crash
        viewController.didResignActive(with: mockConversation)
        XCTAssertTrue(true)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidURLHandling() {
        let mockMessage = MockMSMessage()
        mockMessage.mockURL = URL(string: "invalid://url")
        
        // Should not crash with invalid URL
        viewController.didReceive(mockMessage, conversation: mockConversation)
        XCTAssertTrue(true)
    }
    
    func testNilURLHandling() {
        let mockMessage = MockMSMessage()
        mockMessage.mockURL = nil
        
        // Should not crash with nil URL
        viewController.didReceive(mockMessage, conversation: mockConversation)
        XCTAssertTrue(true)
    }
    
    func testMalformedGameStateURL() {
        let mockMessage = MockMSMessage()
        mockMessage.mockURL = URL(string: "pente://game?moves=InvalidData&current=InvalidPlayer")
        
        // Should handle malformed data gracefully
        viewController.didReceive(mockMessage, conversation: mockConversation)
        XCTAssertTrue(true)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteMessageFlow() {
        // 1. Start with new game
        viewController.willBecomeActive(with: mockConversation)
        
        // 2. Get game model
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        XCTAssertNotNil(gameModel)
        
        // 3. Send first move
        let conversationProperty = class_getInstanceVariable(MessagesViewController.self, "activeConversation")
        if let conversationProperty = conversationProperty {
            object_setIvar(viewController, conversationProperty, mockConversation)
        }
        
        gameModel?.sendFirstMove()
        
        // Should have sent first move message
        XCTAssertEqual(mockConversation.insertedMessages.count, 1)
        
        // 4. Make a regular move
        gameModel?.makeMove(row: 10, col: 10)
        gameModel?.confirmMove()
        
        // Should have sent second message
        XCTAssertEqual(mockConversation.insertedMessages.count, 2)
        
        // 5. Verify message content
        let lastMessage = mockConversation.insertedMessages.last
        XCTAssertNotNil(lastMessage?.url)
        
        if let urlString = lastMessage?.url?.absoluteString {
            XCTAssertTrue(urlString.contains("moves="))
            XCTAssertTrue(urlString.contains("current="))
        }
    }
    
    // MARK: - Performance Tests
    
    func testViewControllerSetupPerformance() {
        measure {
            let testViewController = MessagesViewController()
            testViewController.loadViewIfNeeded()
            testViewController.viewDidLoad()
        }
    }
    
    func testMessageCreationPerformance() {
        // Set up game with some moves
        let mirror = Mirror(reflecting: viewController)
        var gameModel: PenteGameModel?
        
        for child in mirror.children {
            if child.label == "gameModel" {
                gameModel = child.value as? PenteGameModel
                break
            }
        }
        
        // Add some moves for complexity
        for i in 0..<10 {
            gameModel?.makeMove(row: i, col: i)
            gameModel?.confirmMove()
        }
        
        let selector = NSSelectorFromString("createMessage")
        
        measure {
            if viewController.responds(to: selector) {
                _ = viewController.perform(selector)
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testDelegateRetainCycle() {
        weak var weakViewController: MessagesViewController? = viewController
        weak var weakGameModel: PenteGameModel?
        
        // Get game model
        let mirror = Mirror(reflecting: viewController)
        for child in mirror.children {
            if child.label == "gameModel" {
                weakGameModel = child.value as? PenteGameModel
                break
            }
        }
        
        // Clear strong reference
        viewController = nil
        
        // Should not create retain cycle
        XCTAssertNil(weakViewController)
        XCTAssertNil(weakGameModel)
    }
}