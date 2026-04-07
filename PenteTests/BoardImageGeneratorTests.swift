import XCTest
import UIKit
import PenteCore

final class BoardImageGeneratorTests: XCTestCase {
    
    // MARK: - Basic Image Generation Tests
    
    func testGenerateEmptyBoardLight() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 300)
        XCTAssertEqual(image?.size.height, 300)
    }
    
    func testGenerateEmptyBoardDark() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .dark
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 300)
        XCTAssertEqual(image?.size.height, 300)
    }
    
    func testGenerateBoardWithSingleStone() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        let moveHistory = [(row: 9, col: 9, player: Player.black)]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 300)
        XCTAssertEqual(image?.size.height, 300)
    }
    
    func testGenerateBoardWithMultipleStones() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        board[8][8] = .black
        board[11][11] = .white
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
            (row: 8, col: 8, player: Player.black),
            (row: 11, col: 11, player: Player.white)
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
    }
    
    // MARK: - Size Variation Tests
    
    func testVariousImageSizes() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let sizes = [
            CGSize(width: 100, height: 100),
            CGSize(width: 200, height: 200),
            CGSize(width: 400, height: 400),
            CGSize(width: 150, height: 150),
            CGSize(width: 300, height: 300)
        ]
        
        for size in sizes {
            let image = BoardImageGenerator.generateBoardImage(
                board: emptyBoard,
                moveHistory: moveHistory,
                size: size,
                colorScheme: .light
            )
            
            XCTAssertNotNil(image, "Image should be generated for size \(size)")
            XCTAssertEqual(image?.size.width, size.width)
            XCTAssertEqual(image?.size.height, size.height)
        }
    }
    
    func testSquareImageSizes() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let squareSizes: [CGFloat] = [50, 100, 200, 300, 500]
        
        for sideLength in squareSizes {
            let size = CGSize(width: sideLength, height: sideLength)
            let image = BoardImageGenerator.generateBoardImage(
                board: emptyBoard,
                moveHistory: moveHistory,
                size: size,
                colorScheme: .light
            )
            
            XCTAssertNotNil(image)
            XCTAssertEqual(image?.size.width, sideLength)
            XCTAssertEqual(image?.size.height, sideLength)
        }
    }
    
    // MARK: - Color Scheme Tests
    
    func testBothColorSchemes() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white)
        ]
        
        let lightImage = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        let darkImage = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .dark
        )
        
        XCTAssertNotNil(lightImage)
        XCTAssertNotNil(darkImage)
        
        // Images should be different due to different color schemes
        // Note: Comparing image data would be complex, so we just verify they generate
        XCTAssertEqual(lightImage?.size, darkImage?.size)
    }
    
    // MARK: - Last Move Highlighting Tests
    
    func testLastMoveHighlighting() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        board[11][11] = .black
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
            (row: 11, col: 11, player: Player.black) // Last move
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Last move should be highlighted with blue ring, but we can't easily test visual content
    }
    
    func testNoLastMoveWhenHistoryEmpty() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        
        let moveHistory: [(row: Int, col: Int, player: Player)] = [] // Empty history
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should not crash when there's no last move to highlight
    }
    
    // MARK: - Edge Position Tests
    
    func testStonesAtEdgesAndCorners() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        
        // Place stones at corners
        board[0][0] = .black
        board[0][18] = .white
        board[18][0] = .white
        board[18][18] = .black
        
        // Place stones at edge midpoints
        board[0][9] = .black
        board[18][9] = .white
        board[9][0] = .white
        board[9][18] = .black
        
        let moveHistory = [
            (row: 0, col: 0, player: Player.black),
            (row: 0, col: 18, player: Player.white),
            (row: 18, col: 0, player: Player.white),
            (row: 18, col: 18, player: Player.black),
            (row: 0, col: 9, player: Player.black),
            (row: 18, col: 9, player: Player.white),
            (row: 9, col: 0, player: Player.white),
            (row: 9, col: 18, player: Player.black)
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should handle edge positions without issues
    }
    
    // MARK: - Full Board Tests
    
    func testFullBoard() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        // Fill board with alternating pattern
        for row in 0..<19 {
            for col in 0..<19 {
                let player: Player = (row + col) % 2 == 0 ? .black : .white
                board[row][col] = player
                moveHistory.append((row: row, col: col, player: player))
            }
        }
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should handle full board without performance issues
    }
    
    // MARK: - Error Handling Tests
    
    func testEmptyBoardArray() {
        let emptyBoard: [[Player?]] = []
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        // Should either return nil or a blank image without crashing
        // The exact behavior depends on implementation, but it shouldn't crash
    }
    
    func testInvalidBoardSize() {
        // Create board that's not 19x19
        let invalidBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 10), count: 10)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: invalidBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        // Should return nil for invalid board dimensions
        XCTAssertNil(image)
    }
    
    func testZeroSize() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 0, height: 0),
            colorScheme: .light
        )
        
        // Should handle zero size gracefully
        if let image = image {
            XCTAssertEqual(image.size.width, 0)
            XCTAssertEqual(image.size.height, 0)
        }
    }
    
    func testVerySmallSize() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 1, height: 1),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 1)
        XCTAssertEqual(image?.size.height, 1)
    }
    
    func testVeryLargeSize() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 2000, height: 2000),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 2000)
        XCTAssertEqual(image?.size.height, 2000)
    }
    
    // MARK: - Move History Mismatch Tests
    
    func testMoveHistoryMismatchBoard() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        
        // Move history doesn't match board state
        let moveHistory = [
            (row: 5, col: 5, player: Player.black),
            (row: 6, col: 6, player: Player.white)
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should render board as-is and highlight last move from history if valid
    }
    
    func testInvalidLastMovePosition() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        
        // Last move is out of bounds
        let moveHistory = [
            (row: -1, col: 20, player: Player.black) // Invalid position
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should not crash even with invalid last move position
    }
    
    // MARK: - Performance Tests
    
    func testGenerateMultpleImagesQuickly() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white)
        ]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate multiple images
        for _ in 0..<10 {
            let image = BoardImageGenerator.generateBoardImage(
                board: board,
                moveHistory: moveHistory,
                size: CGSize(width: 300, height: 300),
                colorScheme: .light
            )
            XCTAssertNotNil(image)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Should complete reasonably quickly (less than 1 second for 10 images)
        XCTAssertLessThan(totalTime, 1.0, "Image generation should be reasonably fast")
    }
    
    // MARK: - Consistency Tests
    
    func testConsistentImageGeneration() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white)
        ]
        
        let image1 = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        let image2 = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertEqual(image1?.size, image2?.size)
        
        // Images should be identical for same input
        // Note: Direct pixel comparison would be complex, but size should match
    }

    // MARK: - Last Move Indicator Pixel Tests

    /// The thumbnail must NOT render a blue ring anywhere. The only allowed
    /// ring in thumbnails is the green committed-move ring — blue is a live-
    /// view-only pending indicator. If someone accidentally starts rendering
    /// `pendingMove` state in BoardImageGenerator, this test catches it:
    /// place a board with two stones, mark neither as the "last" move (empty
    /// moveHistory), and verify nothing blue-dominant appears at the ring
    /// outline of either stone.
    func testThumbnailNeverRendersBlueRing() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white

        // Empty moveHistory → no green ring should render, and no blue ring
        // should ever render in the thumbnail regardless of state.
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: [],
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        guard let image = image else {
            XCTFail("thumbnail generation failed")
            return
        }

        // Stone (9,9) center = (150, 150), ring outline sample at (155, 150).
        // Stone (10,10) center = (165, 165), ring outline sample at (170, 165).
        let samples = [
            CGPoint(x: 155, y: 150),
            CGPoint(x: 170, y: 165),
        ]
        for point in samples {
            guard let pixel = image.pixelColor(at: point) else {
                XCTFail("failed to sample pixel at \(point)")
                continue
            }
            XCTAssertFalse(pixel.b > pixel.r && pixel.b > pixel.g,
                "thumbnail should never render blue-dominant pixels at ring outlines, got RGB(\(pixel.r),\(pixel.g),\(pixel.b)) at \(point)")
        }
    }

    /// Thumbnail with an empty moveHistory must not render any green ring —
    /// guards against a bug where BoardImageGenerator defaults to drawing a
    /// ring on a non-existent "last" move. Samples the ring-outline positions
    /// on both stones on the board and asserts neither is green-dominant.
    func testThumbnailNoRingWhenMoveHistoryEmpty() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black

        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: [],
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        guard let image = image,
              let pixel = image.pixelColor(at: CGPoint(x: 155, y: 150)) else {
            XCTFail("thumbnail or pixel sample failed")
            return
        }
        // No green ring should be present → pixel at ring outline should not
        // be green-dominant. Any color (board background, stone edge) is fine.
        XCTAssertFalse(pixel.g > pixel.r && pixel.g > pixel.b && pixel.g > 150,
            "thumbnail should not render a green ring with empty moveHistory; got RGB(\(pixel.r),\(pixel.g),\(pixel.b))")
    }

    /// Full cross-player roundtrip: Alice confirms a move in her model,
    /// encodes to URL, Bob decodes into his model, Bob generates the
    /// thumbnail, and the green ring appears at Alice's last move. This
    /// exercises PenteGameModel.encodeToQueryItems + loadFromURL + the
    /// thumbnail renderer as a single pipeline — the same pipeline that
    /// runs between two iMessage devices in production.
    func testCrossPlayerRoundTripRendersGreenRingAtCorrectStone() {
        // Alice sets up and makes a move.
        let alice = PenteGameModel()
        alice.startNewGame() // places (9,9) black, currentPlayer=.white
        alice.sendFirstMove()
        alice.makeMove(row: 10, col: 10)
        alice.confirmMove() // white at (10,10) is now last move

        // Encode exactly as MessagesViewController would.
        let items = alice.encodeToQueryItems()
        var comps = URLComponents()
        comps.scheme = "pente"
        comps.host = "game"
        comps.queryItems = items
        guard let url = comps.url else {
            XCTFail("URL build failed")
            return
        }

        // Bob decodes and renders thumbnail.
        let bob = PenteGameModel()
        bob.loadFromURL(url)
        XCTAssertEqual(bob.moveHistory.last?.row, 10)
        XCTAssertEqual(bob.moveHistory.last?.col, 10)
        XCTAssertEqual(bob.board[9][9], .black, "decoder should place center black stone")
        XCTAssertEqual(bob.board[10][10], .white, "decoder should place white stone at last move")
        XCTAssertEqual(bob.board.count, 19, "board should be 19 rows")
        XCTAssertEqual(bob.board[0].count, 19, "board should be 19 cols")

        let image = BoardImageGenerator.generateBoardImage(
            board: bob.board,
            moveHistory: bob.moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        guard let image = image else {
            XCTFail("Bob's thumbnail generation failed")
            return
        }

        // Stone (10, 10) center in a 300x300 image:
        //   margin = 15, cellSize = 15 → (165, 165)
        // The ring has anti-aliased sub-pixel edges and we also have to avoid
        // grid lines at x=165 and y=165, so single-point sampling is fragile.
        // Instead: scan an 11x11 window around the ring band and count
        // green-dominant pixels. A stone with a green ring has many; a stone
        // without one has zero or near-zero. Compare last-move stone (10,10)
        // vs non-last-move stone (9,9).
        let lastMoveGreenCount = countGreenDominantPixels(
            in: image,
            aroundCenter: CGPoint(x: 165, y: 165),
            windowRadius: 8
        )
        let nonLastMoveGreenCount = countGreenDominantPixels(
            in: image,
            aroundCenter: CGPoint(x: 150, y: 150),
            windowRadius: 8
        )
        XCTAssertGreaterThan(lastMoveGreenCount, 5,
            "Bob's thumbnail should have many green-dominant pixels in the ring neighborhood of Alice's last move at (10,10); got \(lastMoveGreenCount)")
        XCTAssertLessThan(nonLastMoveGreenCount, lastMoveGreenCount,
            "Bob's thumbnail should have fewer green pixels at the non-last-move stone (9,9) than at the last-move stone (10,10); got \(nonLastMoveGreenCount) vs \(lastMoveGreenCount)")
    }

    /// Counts green-dominant pixels (G > R AND G > B, with G high enough to
    /// rule out dark boards or shadows) in a square window around a center
    /// point in UIKit coordinates. Used to verify a ring-shaped indicator
    /// exists without being fragile to exact sub-pixel coordinates.
    private func countGreenDominantPixels(
        in image: UIImage,
        aroundCenter center: CGPoint,
        windowRadius: Int
    ) -> Int {
        var count = 0
        for dy in -windowRadius...windowRadius {
            for dx in -windowRadius...windowRadius {
                let p = CGPoint(x: center.x + CGFloat(dx), y: center.y + CGFloat(dy))
                guard let px = image.pixelColor(at: p) else { continue }
                if px.g > px.r && px.g > px.b && px.g > 100 {
                    count += 1
                }
            }
        }
        return count
    }

    func testLastMoveIndicatorRendersGreenPixels() {
        // Geometry reminder for a 300x300 image:
        //   margin    = 300 * 0.05 = 15
        //   cellSize  = (300 - 30) / 18 = 15
        //   stone 9,9 center = (15 + 9*15, 15 + 9*15) = (150, 150)
        //   stoneRadius = cellSize * 0.35 = 5.25
        // The green ring is stroked at the stone outline with lineWidth 2,
        // so the 2pt ring band sits between ~4.25 and ~6.25 pt from center.
        // Sample (155, 150) — 5pt right of center, squarely inside the band.
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black

        let withLastMove = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: [(row: 9, col: 9, player: Player.black)],
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        let withoutLastMove = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: [],
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )

        XCTAssertNotNil(withLastMove)
        XCTAssertNotNil(withoutLastMove)

        let samplePoint = CGPoint(x: 155, y: 150)
        guard let pixelWith = withLastMove?.pixelColor(at: samplePoint),
              let pixelWithout = withoutLastMove?.pixelColor(at: samplePoint) else {
            XCTFail("Failed to sample pixels from rendered images")
            return
        }

        // The ring should change the pixel relative to the no-ring render.
        XCTAssertFalse(pixelWith == pixelWithout,
            "Ring pixels should differ between last-move and no-last-move renders")

        // And the sampled pixel should be greenish (G channel dominates).
        XCTAssertGreaterThan(pixelWith.g, pixelWith.r,
            "green channel should dominate red at the ring edge")
        XCTAssertGreaterThan(pixelWith.g, pixelWith.b,
            "green channel should dominate blue at the ring edge")
    }
}

// MARK: - Pixel sampling helper

private struct PixelColor: Equatable {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let a: UInt8
}

private extension UIImage {
    /// Samples a single pixel from the image in sRGB space using UIKit
    /// coordinates (origin = top-left, y grows down). Returns nil if the point
    /// is out of bounds or the draw fails.
    func pixelColor(at point: CGPoint) -> PixelColor? {
        guard let cg = cgImage else { return nil }
        let width = cg.width
        let height = cg.height
        let px = Int(point.x * scale)
        let py = Int(point.y * scale)
        guard px >= 0, py >= 0, px < width, py < height else { return nil }

        // CGContext retains its `data` pointer for its entire lifetime, so we
        // need a buffer that stays alive and at a stable address (`&array` on a
        // Swift Array binds only a temporary inout pointer — UB here).
        let bytesPerRow = width * 4
        let totalBytes = height * bytesPerRow
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: totalBytes)
        buffer.initialize(repeating: 0, count: totalBytes)
        defer {
            buffer.deinitialize(count: totalBytes)
            buffer.deallocate()
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        // No Y flip: cgImage from UIGraphicsImageRenderer is already in
        // top-down memory order (row 0 = top of the UIKit image), and a
        // CGContext bitmap is also top-down in memory. Drawing the cgImage
        // into the bitmap at (0,0,w,h) preserves that orientation, so reading
        // memory row `point.y * scale` gives the pixel at the intended point.
        // (Empirically verified: an earlier flip read row `height - y`, which
        // happened to be correct *only* at the y-midline by coincidence.)
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        let offset = py * bytesPerRow + px * 4
        return PixelColor(
            r: buffer[offset],
            g: buffer[offset + 1],
            b: buffer[offset + 2],
            a: buffer[offset + 3]
        )
    }
}