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
    var redLabel: SKLabelNode!
    var redImage: SKSpriteNode!
    var greenLabel: SKLabelNode!
    var greenImage: SKSpriteNode!
    static var sharedGame: GameScene!
    var waitLabel: SKLabelNode!

    // swiftlint:disable comma
    let rowWidths = [1, 2, 3, 4, 13, 12, 11, 10, 9, 10, 11, 12, 13, 4, 3, 2, 1]
    let rowStarts = [6, 5, 5, 4,  0,  0,  1,  1, 2,  1,  1,  0,  0, 4, 5, 5, 6]

    static let redStartingIndices = [MarbleIndex(( 0, 6)), MarbleIndex(( 1, 5)), MarbleIndex(( 1, 6)), MarbleIndex(( 2, 5)), MarbleIndex(( 2, 6)), MarbleIndex(( 2, 7)), MarbleIndex(( 3, 4)), MarbleIndex(( 3, 5)), MarbleIndex(( 3, 6)), MarbleIndex(( 3, 7))]
    static let greenStartingIndices = [MarbleIndex((16, 6)), MarbleIndex((15, 5)), MarbleIndex((15, 6)), MarbleIndex((14, 5)), MarbleIndex((14, 6)), MarbleIndex((14, 7)), MarbleIndex((13, 4)), MarbleIndex((13, 5)), MarbleIndex((13, 6)), MarbleIndex((13, 7))]

    var selectedMarble: MarbleNode? {
        didSet {
            guard let gameState = MessagesViewController.sharedMessagesViewController.nextGameState else {
                return
            }
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
        drawCoordinateOverlay()

        if identifier != nil {
            draw(gameBoard: MessagesViewController.sharedMessagesViewController.nextGameState!.gameBoard!)
            addScoreLabels()
            checkTurn()
            return
        }

        GameScene.resetGame()
    }

    func addScoreLabels() {
        redImage = SKSpriteNode(imageNamed: "red")
        redImage.size = CGSize(width: 35, height: 35)
        redImage.position = CGPoint(x: -self.frame.width/2 + redImage.frame.width/2, y: self.frame.height/2 - 70)
        self.addChild(redImage)
        redLabel = SKLabelNode(fontNamed: "Arial")
        redLabel.fontSize = 20
        redLabel.fontColor = .black
        assignScores(color: .red)
        redLabel.position = CGPoint(x: -self.frame.width/2 + 35 + redLabel.frame.width/2, y: self.frame.height/2 - 70 - redImage.frame.height/4)
        self.addChild(redLabel)
        greenLabel = SKLabelNode(fontNamed: "Arial")
        greenLabel.fontSize = 20
        greenLabel.fontColor = .black
        assignScores(color: .green)
        self.addChild(greenLabel)
        greenImage = SKSpriteNode(imageNamed: "green")
        greenImage.size = CGSize(width: 35, height: 35)
        greenImage.position = CGPoint(x: self.frame.width/2 - greenImage.frame.width/2 - greenLabel.frame.width, y: self.frame.height/2 - 70)
        self.addChild(greenImage)
        greenLabel.position = CGPoint(x: self.frame.width/2 - greenLabel.frame.width/2, y: self.frame.height/2 - 70 - greenImage.frame.height/4)
    }

    @discardableResult
    static func resetGame() -> [[MarbleNode?]] {
        // todo: clear out old game

        var gameBoard = [[MarbleNode?]](repeatElement([MarbleNode?](repeatElement(nil, count: boardWidth)), count: boardHeight))

        for index in redStartingIndices {
            gameBoard[index.row][index.column] = MarbleNode(color: .red)
        }

        for index in greenStartingIndices {
            gameBoard[index.row][index.column] = MarbleNode(color: .green)
        }

        return gameBoard
    }

    func draw(gameBoard: [[MarbleNode?]]) {
        self.childNode(withName: "marbles")!.removeAllChildren()
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
        self.childNode(withName: "marbles")!.addChild(marbleSprite)

        return marbleSprite
    }

    func indexFrom(point: CGPoint) -> MarbleIndex {
        let row = Int(round((point.y - startY) / dy))
        var column = row % 2 == 0 ? point.x : point.x - dx
        column = (((column - startX) / 2) / dx) + 6

        return MarbleIndex((row, Int(round(column))))
    }

    func drawMarbleAt(index: MarbleIndex, color: MarbleColor) {
        MessagesViewController.sharedMessagesViewController.nextGameState!.gameBoard[index.row][index.column] = drawMarble(atPoint: index.coordinates, color: color)
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

        knownJumps = MarbleJump(index: MarbleIndex((-1, -1)))
        jumpableIndices = []
    }

    func marbleExistsAt(index: MarbleIndex) -> Bool {
        guard isValid(index: index) else {
            // This simplifies checking for board boundaries
            return true
        }

        return MessagesViewController.sharedMessagesViewController.nextGameState!.gameBoard[index.row][index.column] != nil
    }

    func highligtAdjacentSpotsForMarbleAt(index: MarbleIndex) {
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.left()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.right()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.upLeft()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.upRight()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.downLeft()))
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: index.downRight()))
    }

    var knownJumps = MarbleJump(index: MarbleIndex((-1, -1)))
    var jumpableIndices = [MarbleIndex]()

    func highlightJumpsForMarbleAt(index: MarbleIndex) -> MarbleJump {
        let startJump = MarbleJump(index: index)
        jumpableIndices = []

        var queue = [startJump]

        while let currentJump = queue.first {
            queue = Array(queue.dropFirst())

            for i in 0..<MarbleIndex.directions.count {
                let direction = MarbleIndex.directions[i]
                let adjacentIndex = direction(currentJump.index)()
                if marbleExistsAt(index: adjacentIndex) {
                    let jumpIndex = direction(adjacentIndex)()
                    if !jumpableIndices.contains(jumpIndex) {
                        if let highlightNode = highlightIfEmptyAt(index: jumpIndex) {
                            highlightNodes.append(highlightNode)

                            let newJump = MarbleJump(index: jumpIndex)
                            jumpableIndices.append(jumpIndex)
                            switch i {
                            case 0:
                                currentJump.leftJump = newJump

                            case 1:
                                currentJump.rightJump = newJump

                            case 2:
                                currentJump.upLeftJump = newJump

                            case 3:
                                currentJump.upRightJump = newJump

                            case 4:
                                currentJump.downLeftJump = newJump

                            case 5:
                                currentJump.downRightJump = newJump
                            default:
                                print("You fucked up")
                                fatalError("How many directions do you think there are??")
                            }

                            queue.append(newJump)
                        }
                    }
                }
            }
        }

        return startJump
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
        draw(gameBoard: MessagesViewController.sharedMessagesViewController.nextGameState!.gameBoard!)

        let index = indexFrom(point: highlightNode.position)
        moveSelectedMarble(toIndex: index)

        clearHighlights()
    }

    func moveSelectedMarble(toIndex newIndex: MarbleIndex) {
        let currentIndex = indexFrom(point: selectedMarble!.position)

        let path = moveMarble(from: currentIndex, to: newIndex)
        MessagesViewController.sharedMessagesViewController.sendMove(from: currentIndex, to: newIndex, path: path)
    }

    @discardableResult
    func moveMarble(from: MarbleIndex, to: MarbleIndex, path: [MarbleIndex]? = nil, updateBoard: Bool = false) -> [MarbleIndex] {
        // This occasionally crashes and I have no idea
        // Race condition somewhere?
        // Maybe resolved after changing to sending entire gameBoard each message?
        let movingMarble = MessagesViewController.sharedMessagesViewController.nextGameState!.gameBoard[from.row][from.column]!

        if updateBoard {
            MessagesViewController.sharedMessagesViewController.nextGameState!.gameBoard[to.row][to.column] = movingMarble
            MessagesViewController.sharedMessagesViewController.nextGameState!.gameBoard[from.row][from.column] = nil
        }

        let marblePath: CGMutablePath
        let indices: [MarbleIndex]

        if path != nil {
            marblePath = pathFrom(indices: path!)
            indices = path!
        } else if from.isAdjacent(to: to) {
            let mutablePath = CGMutablePath()

            mutablePath.move(to: from.coordinates)
            mutablePath.addLine(to: to.coordinates)
            marblePath = mutablePath
            indices = [from, to]
        } else {
            indices = knownJumps.reversedPathToIndex(index: to)!.reversed()
            marblePath = pathFrom(indices: indices)
        }

        let moveToTop = SKAction.perform(Selector(("moveToTop")), onTarget: movingMarble)
        let moveToNewPosition = SKAction.follow(marblePath, asOffset: false, orientToPath: false, speed: 70)
        let moveToMiddle = SKAction.perform(Selector(("moveToMiddle")), onTarget: movingMarble)

        let moveAction = SKAction.sequence([moveToTop, moveToNewPosition, moveToMiddle])
        movingMarble.unHighlight()
        movingMarble.run(moveAction, completion: {
            if !updateBoard {
                MessagesViewController.sharedMessagesViewController.sendReply()
            }
        })

        return indices
    }

    func pathFrom(indices: [MarbleIndex]) -> CGMutablePath {
        let path = CGMutablePath()
        path.move(to: indices[0].coordinates)
        for index in indices.dropFirst() {
            path.addLine(to: index.coordinates)
        }

        return path
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

    func assignScores(color: MarbleColor, forMove move: (MarbleIndex, MarbleIndex)? = nil) {

        switch color {
        case .green:
            greenLabel.text = "\(scoreFor(color: color, forMove: move))/10"
        case .red:
            redLabel.text = "\(scoreFor(color: color, forMove: move))/10"
        default:
            print("Todo")
        }

    }

    func scoreFor(color: MarbleColor, forMove move: (MarbleIndex, MarbleIndex)? = nil) -> Int {
        var score = 0
        let homeIndices: [MarbleIndex]
        let homeColor = MarbleColor.allColors.opposite(element: color)

        switch homeColor {
        case .green:
            homeIndices = GameScene.greenStartingIndices

        case .red:
            homeIndices = GameScene.redStartingIndices
        default:
            print("Todo")
            homeIndices = GameScene.greenStartingIndices // Temporary to please compiler gods 🙌
        }

        var board = MessagesViewController.sharedMessagesViewController.nextGameState!.gameBoard!

        if let move = move {
            board[move.1.row][move.1.column] = board[move.0.row][move.0.column]
            board[move.0.row][move.0.column] = nil
        }

        for index in homeIndices {
            if let marble = board[index.row][index.column] {
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

    func showWaitingOverlay() {
        self.alpha = 0.5
        view?.tintColor = .black
        waitLabel = SKLabelNode(fontNamed: "Arial")
        waitLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        waitLabel.text = "Waiting on Opponent!"
        waitLabel.fontSize = 16
        self.addChild(waitLabel)
    }

    func hideWaitOverlay() {
        self.alpha = 1
        view?.tintColor = .clear
        waitLabel?.removeFromParent()
    }

    func checkTurn() {
        guard let gameState = MessagesViewController.sharedMessagesViewController.nextGameState else {
            showWaitingOverlay()
            return
        }
        
        guard let playerColor = MessagesViewController.sharedMessagesViewController.currentConversation else {
            showWaitingOverlay()
            return
        }

        if gameState.playerColor == nil {
            showWaitingOverlay()
            self.isUserInteractionEnabled = false
            return
        }

        if gameState.playerColor != MarbleColor(rawValue: gameState.players[playerColor.localParticipantIdentifier.uuidString]!) {
            showWaitingOverlay()
            self.isUserInteractionEnabled = false
            return
        }

        hideWaitOverlay()
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
