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

let dx = CGFloat(11.5)
let dy = CGFloat(-20)
var startX = CGFloat(0)
var startY = CGFloat(160) // Must equal -8 * dy
let boardWidth = 13
let boardHeight = 17

class GameScene: SKScene {

    static var sharedGame: GameScene!

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

    func indexFrom(point: CGPoint) -> MarbleIndex {
        let row = Int(round((point.y - startY) / dy))
        var column = row % 2 == 0 ? point.x : point.x - dx
        column = (((column - startX) / 2) / dx) + 6

        return MarbleIndex((row, Int(round(column))))
    }

    func drawMarbleAt(index: MarbleIndex, color: MarbleColor) {
        gameBoard[index.row][index.column] = drawMarble(atPoint: index.coordinates, color: color)
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

        highligtAdjacentSpotsForMarbleAt(index: index)
        knownJumps = highlightJumpsForMarbleAt(index: index)
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

    var knownJumps = MarbleJump(index: MarbleIndex((0, 0)))
    func highlightJumpsForMarbleAt(index: MarbleIndex) -> MarbleJump {

        let directions = MarbleIndex.directions

        let jump = MarbleJump(index: index)
        for i in 0..<directions.count {
            let direction = directions[i]
            let indexOfDirection = direction(index)()
            if marbleExistsAt(index: indexOfDirection) {
                let directionalJumpIndex = direction(indexOfDirection)()
                if knownJumps.pathToIndex(index: directionalJumpIndex) == nil {
                    if let highlightNode = highlightIfEmptyAt(index: directionalJumpIndex) {
                        highlightNodes.append(highlightNode)
                        let newJump = highlightJumpsForMarbleAt(index: directionalJumpIndex)
                        switch i {
                        case 0:
                            jump.leftJump = newJump

                        case 1:
                            jump.rightJump = newJump

                        case 2:
                            jump.upLeftJump = newJump

                        case 3:
                            jump.upRightJump = newJump

                        case 4:
                            jump.downLeftJump = newJump

                        case 5:
                            jump.downRightJump = newJump
                        default:
                            print("You fucked up")
                            fatalError("How many directions do you think there are??")
                        }
                    }
                }
            }
        }

        return jump
    }

    func highlightIfEmptyAt(index: MarbleIndex) -> HighlightNode? {
        guard !marbleExistsAt(index: index) else {
            return nil
        }

        let highlightNode = HighlightNode()
        highlightNode.position = index.coordinates
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

        let path = moveMarble(from: currentIndex, to: newIndex)
        MessagesViewController.sharedMessagesViewController.sendMove(from: currentIndex, to: newIndex, path: path)
    }

    @discardableResult
    func moveMarble(from: MarbleIndex, to: MarbleIndex, path: CGPath? = nil) -> CGPath {
        gameBoard[to.row][to.column] = gameBoard[from.row][from.column]!

        gameBoard[from.row][from.column] = nil

        let marblePath: CGPath

        if path != nil {
            marblePath = path!
        } else if from.isAdjacent(to: to) {
            let mutablePath = CGMutablePath()

            // This path is intentionally backwards because we reverse it later
            mutablePath.move(to: to.coordinates)
            mutablePath.addLine(to: from.coordinates)
            marblePath = mutablePath
        } else {
            marblePath = knownJumps.pathToIndex(index: to)!
        }

        let moveAction = SKAction.follow(marblePath, speed: 70).reversed()
        gameBoard[to.row][to.column]!.unHighlight()
        gameBoard[to.row][to.column]!.run(moveAction)

        return marblePath
    }

    func saveGameBoard() {
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: gameBoard), forKey: MessagesViewController.sharedMessagesViewController.currentGameIdentifier! + MessagesViewController.sharedMessagesViewController.currentConversation.localParticipantIdentifier.uuidString + "new")
    }

    func drawCoordinateLabel(forIndex index: MarbleIndex) {
        let node = SKLabelNode(text: "\(index)")
        node.position = index.coordinates
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

    static var directions: [(MarbleIndex) -> () -> MarbleIndex] {
        get {
            return [left, right, upLeft, upRight, downLeft, downRight]
        }
    }

    var coordinates: CGPoint {
        get {
            let y = startY + (dy * CGFloat(row))
            var x = startX + ((dx * CGFloat(column - 6)) * 2)
            if row % 2 == 1 { x += dx }

            return CGPoint(x: x, y: y)
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

    func isAdjacent(to: MarbleIndex) -> Bool {
        for direction in MarbleIndex.directions {
            if to == direction(self)() {
                return true
            }
        }

        return false
    }

    public static func == (lhs: MarbleIndex, rhs: MarbleIndex) -> Bool {
        return lhs.row == rhs.row && lhs.column == rhs.column
    }
}
