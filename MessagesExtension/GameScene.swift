//
//  GameScene.swift
//  Chinese Checkers
//
//  Created by Garrett Davidson on 11/11/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import Foundation
import SpriteKit

enum MarbleColor: String {
    case red
    case purple
    case blue
    case green
    case yellow
    case orange

    static let allColors = [MarbleColor.red, .purple, .blue, .green, .yellow, .orange]
}

class GameScene: SKScene {
    var redLabel: SKLabelNode!
    var greenLabel: SKLabelNode!
    static var sharedGame: GameScene!
    var waitLabel: SKLabelNode!

    let dx = CGFloat(11.5)
    let dy = CGFloat(-20)
    var startX = CGFloat(0)
    var startY = CGFloat(160) // Must equal -8 * dy
    let boardWidth = 13
    let boardHeight = 17

    // swiftlint:disable comma
    let rowWidths = [1, 2, 3, 4, 13, 12, 11, 10, 9, 10, 11, 12, 13, 4, 3, 2, 1]
    let rowStarts = [6, 5, 5, 4,  0,  0,  1,  1, 2,  1,  1,  0,  0, 4, 5, 5, 6]

    let redStartingIndices = [MarbleIndex(( 0, 6)), MarbleIndex(( 1, 5)), MarbleIndex(( 1, 6)), MarbleIndex(( 2, 5)), MarbleIndex(( 2, 6)), MarbleIndex(( 2, 7)), MarbleIndex(( 3, 4)), MarbleIndex(( 3, 5)), MarbleIndex(( 3, 6)), MarbleIndex(( 3, 7))]
    let purpleStartingIndices = [MarbleIndex((16, 6)), MarbleIndex((15, 5)), MarbleIndex((15, 6)), MarbleIndex((14, 5)), MarbleIndex((14, 6)), MarbleIndex((14, 7)), MarbleIndex((13, 4)), MarbleIndex((13, 5)), MarbleIndex((13, 6)), MarbleIndex((13, 7))]

    var gameBoard = [[MarbleNode?]]()

    var selectedMarble: MarbleNode? {
        didSet {
            guard let gameState = MessagesViewController.sharedMessagesViewController.nextGameState else {
                return
            }
            // todo: Validate that you own this marble
            if selectedMarble != nil {
                if selectedMarble!.marbleColor != gameState.playerColor {
                    selectedMarble = oldValue
                    return
                }
            }

            oldValue?.unHighlight()
            selectedMarble?.highlight()
            highlightMovesFor(marble: selectedMarble!)
        }
    }


    override init() {
        super.init()
        GameScene.sharedGame = self

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        GameScene.sharedGame = self

    }

    func setup(identifier: String? = nil) {
//        drawCoordinateOverlay()

        addScoreLabels()
        if identifier != nil {
            if let data = UserDefaults.standard.object(forKey: identifier! + MessagesViewController.sharedMessagesViewController.currentConversation.localParticipantIdentifier.uuidString) as? Data {
                if let gameBoard = NSKeyedUnarchiver.unarchiveObject(with: data) as? [[MarbleNode?]] {
                    self.gameBoard = gameBoard

                    redrawGameBoard()
                    return
                }
            }
        }

        resetGame()
    }
    func addScoreLabels() {

        redLabel = SKLabelNode(fontNamed: "Arial")
        redLabel.text = "RED: 0/10"
        redLabel.fontSize = 20
        redLabel.position = CGPoint(x: -self.frame.width/2 + redLabel.frame.width/2, y: self.frame.height/2 - 70)
        self.addChild(redLabel)
        greenLabel = SKLabelNode(fontNamed: "Arial")
        greenLabel.text = "GREEN: 0/10"
        greenLabel.fontSize = 20
        greenLabel.position = CGPoint(x: self.frame.width/2 - greenLabel.frame.width/2, y: self.frame.height/2 - 70)
        self.addChild(greenLabel)
    }
    func resetGame() {
        // todo: clear out old game

        gameBoard = [[MarbleNode?]](repeatElement([MarbleNode?](repeatElement(nil, count: boardWidth)), count: boardHeight))

        for index in redStartingIndices {
            drawMarbleAt(index: index, color: .red)
        }

        for index in purpleStartingIndices {
            drawMarbleAt(index: index, color: .green)
        }
    }

    func redrawGameBoard() {
        for i in 0..<gameBoard.count {
            for j in 0..<gameBoard[i].count {
                if let marble = gameBoard[i][j] {
                    drawMarbleAt(index: MarbleIndex((i, j)), color: marble.marbleColor)
                }
            }
        }
    }

    func drawMarble(atPoint point: CGPoint, color: MarbleColor, radius: CGFloat = 19) -> MarbleNode {
        let marbleSprite = MarbleNode(color: color)
        marbleSprite.size = CGSize(width: radius, height: radius)
        marbleSprite.position = point
        marbleSprite.isUserInteractionEnabled = true
        self.addChild(marbleSprite)

        return marbleSprite
    }

    func coordinatesFor(index: MarbleIndex) -> CGPoint {
        let y = startY + (dy * CGFloat(index.row))
        var x = startX + ((dx * CGFloat(index.column - 6)) * 2)
        if index.row % 2 == 1 { x += dx }

        return CGPoint(x: x, y: y)
    }

    func indexFrom(point: CGPoint) -> MarbleIndex {
        let row = Int(round((point.y - startY) / dy))
        var column = row % 2 == 0 ? point.x : point.x - dx
        column = (((column - startX) / 2) / dx) + 6

        return MarbleIndex((row, Int(round(column))))
    }

    func drawMarbleAt(index: MarbleIndex, color: MarbleColor) {
        gameBoard[index.row][index.column] = drawMarble(atPoint: coordinatesFor(index: index), color: color)
    }

    func isValid(index: MarbleIndex) -> Bool {
        guard index.row >= 0 && index.row < boardHeight else {
            return false
        }

        guard index.column >= 0 && index.column < boardWidth else {
            return false
        }

        return ((rowStarts[index.row])..<(rowStarts[index.row] + rowWidths[index.row])).contains(index.column)
    }

    var highlightNodes = [HighlightNode]()

    func highlightMovesFor(marble: MarbleNode) {
        let index = indexFrom(point: marble.position)

        clearHighlights()
        knownJumps = [index]

        highligtAdjacentSpotsForMarbleAt(index: index)
        highlightJumpsForMarbleAt(index: index)
    }

    func clearHighlights() {
        highlightNodes.forEach({ (node) in
            node.removeFromParent()
        })
        highlightNodes = []
    }

    func marbleExistsAt(index: MarbleIndex) -> Bool {
        guard isValid(index: index) else {
            // This simplifies checking for board boundaries
            return true
        }

        return gameBoard[index.row][index.column] != nil
    }

    func highligtAdjacentSpotsForMarbleAt(index: MarbleIndex) {
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.left()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.right()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.upLeft()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.upRight()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.downLeft()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.downRight()))
    }

    var knownJumps = [MarbleIndex]()
    func highlightJumpsForMarbleAt(index: MarbleIndex) {

        let directions = [MarbleIndex.left, MarbleIndex.right, MarbleIndex.upLeft, MarbleIndex.upRight, MarbleIndex.downLeft, MarbleIndex.downRight]

        for direction in directions {
            let indexOfDirection = direction(index)()
            if marbleExistsAt(index: indexOfDirection) {
                let directionalJump = direction(indexOfDirection)()
                if !knownJumps.contains(where: { (e) -> Bool in e == directionalJump }) {
                    if let highlightNode = highlightIfEmptyAt(index: directionalJump) {
                        knownJumps.append(directionalJump)
                        highlightNodes.append(highlightNode)
                        highlightJumpsForMarbleAt(index: directionalJump)
                    }
                }
            }
        }
    }

    func highlightIfEmptyAt(index: MarbleIndex) -> HighlightNode? {
        guard !marbleExistsAt(index: index) else {
            return nil
        }

        let highlightNode = HighlightNode()
        highlightNode.position = coordinatesFor(index: index)
        highlightNode.isUserInteractionEnabled = true
//        highlightNode.alpha = 0.7
        self.addChild(highlightNode)

        return highlightNode
    }

    func moveTo(highlightNode: HighlightNode) {
        clearHighlights()

        let index = indexFrom(point: highlightNode.position)
        moveSelectedMarble(toIndex: index)
    }

    func moveSelectedMarble(toIndex newIndex: MarbleIndex) {
        let currentIndex = indexFrom(point: selectedMarble!.position)

        moveMarble(from: currentIndex, to: newIndex)
        MessagesViewController.sharedMessagesViewController.sendMove(from: currentIndex, to: newIndex)
    }

    func moveMarble(from: MarbleIndex, to: MarbleIndex) {
        gameBoard[to.row][to.column] = gameBoard[from.row][from.column]!

        gameBoard[from.row][from.column] = nil
        gameBoard[to.row][to.column]!.position = coordinatesFor(index: to)
    }

    func saveGameBoard() {
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: gameBoard), forKey: MessagesViewController.sharedMessagesViewController.currentGameIdentifier! + MessagesViewController.sharedMessagesViewController.currentConversation.localParticipantIdentifier.uuidString + "new")
    }

    func drawCoordinateLabel(forIndex index: MarbleIndex) {
        let node = SKLabelNode(text: "\(index)")
        node.position = coordinatesFor(index: index)
        node.fontColor = .white
        node.fontSize = 10

        self.addChild(node)
    }

    func drawCoordinateOverlay() {
        for i in 0..<17 {
            for j in 0..<13 {
                guard isValid(index: MarbleIndex(i, j)) else {
                    continue
                }

                drawCoordinateLabel(forIndex: MarbleIndex(i, j))
            }
        }
    }
    func assignScores(color: MarbleColor, score: Int) {

        let homeColor = MarbleColor.allColors.opposite(element: color)

        switch homeColor {
        case .green:
            greenLabel.text = "GREEN: \(score)/10"
        case .red:
            redLabel.text = "RED: \(score)/10"
        default:
            print("Todo")
        }

    }
    func scoreFor(color: MarbleColor) -> Int {
        var score = 0

        let homeIndices: [MarbleIndex]
        let homeColor = MarbleColor.allColors.opposite(element: color)

        switch homeColor {
        case .purple:
            homeIndices = purpleStartingIndices

        case .red:
            homeIndices = redStartingIndices
        default:
            print("Todo")
            homeIndices = purpleStartingIndices // Temporary to please compiler gods
        }

        for index in homeIndices {
            if let marble = gameBoard[index.row][index.column] {
                if marble.marbleColor == color {
                    score += 1
                }
            }
        }

        if score == homeIndices.count {
            score = -1
        }

        print("Score for \(color) is \(score)")

        return score
    }
    func waitingTurn() {
        waitLabel = SKLabelNode(fontNamed: "Arial")
        waitLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        waitLabel.text = "Waiting on Opponent!"
        waitLabel.fontSize = 16
        self.addChild(waitLabel)

    }
    func checkTurn() {
        guard let gameState = MessagesViewController.sharedMessagesViewController.nextGameState else {
            waitingTurn()
            return
        }
        guard let playerColor = MessagesViewController.sharedMessagesViewController.currentConversation else {
            return
        }
        if gameState.playerColor != MarbleColor(rawValue: gameState.players[playerColor.localParticipantIdentifier.uuidString]!) {
            waitingTurn()
            self.isUserInteractionEnabled = false
        }
    }
}

extension Array {
    mutating func appendOptional(newElement: Element?) {
        if newElement != nil {
            self.append(newElement!)
        }
    }
}

struct MarbleIndex: Equatable, CustomStringConvertible {
    let row: Int
    let column: Int

    var description: String {
        get {
            return "(\(row),\(column))"
        }
    }

    init(_ tuple: (Int, Int)) {
        self.row = tuple.0
        self.column = tuple.1
    }

    init(string: String) {
        let indices = String(string.characters.dropFirst().dropLast()).components(separatedBy: ",")
        self.row = Int(indices[0])!
        self.column = Int(indices[1])!
    }

    func right() -> MarbleIndex {
        return MarbleIndex((row, column + 1))
    }

    func left() -> MarbleIndex {
        return MarbleIndex((row, column - 1))
    }

    func upLeft() -> MarbleIndex {
        return MarbleIndex((row - 1, column - 1 + (row % 2)))
    }

    func upRight() -> MarbleIndex {
        return MarbleIndex((row - 1, column + (row % 2)))
    }

    func downLeft() -> MarbleIndex {
        return MarbleIndex((row + 1, column - 1 + (row % 2)))
    }

    func downRight() -> MarbleIndex {
        return MarbleIndex((row + 1, column + (row % 2)))
    }

    public static func == (lhs: MarbleIndex, rhs: MarbleIndex) -> Bool {
        return lhs.row == rhs.row && lhs.column == rhs.column
    }
}
