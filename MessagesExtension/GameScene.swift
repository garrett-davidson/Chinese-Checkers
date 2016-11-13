//
//  GameScene.swift
//  Chinese Checkers
//
//  Created by Garrett Davidson on 11/11/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import Foundation
import SpriteKit

class GameScene: SKScene {

    static var sharedGame: GameScene!

    let dx = CGFloat(12.3)
    let dy = CGFloat(-21.25)
    let startX = CGFloat(0)
    let startY = CGFloat(170)
    let boardWidth = 13
    let boardHeight = 17

    typealias MarbleIndex = (Int, Int)

    // swiftlint:disable comma
    let rowWidths = [1, 2, 3, 4, 13, 12, 11, 10, 9, 10, 11, 12, 13, 4, 3, 2, 1]
    let rowStarts = [6, 5, 5, 4,  0,  0,  1,  1, 2,  1,  1,  0,  0, 4, 5, 5, 6]

    var gameBoard = [[MarbleNode?]]()

    var selectedMarble: MarbleNode? {
        didSet {
            // todo: Validate that you own this marble

            oldValue?.unHighlight()
            selectedMarble?.highlight()
            highlightMovesFor(marble: selectedMarble!)
        }
    }

    enum MarbleColor: String {
        case blue
        case green
        case red
    }

    override init() {
        super.init()
        GameScene.sharedGame = self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        GameScene.sharedGame = self
    }

    func setup() {
        drawCoordinateOverlay()
        resetGame()
    }

    func resetGame() {
        // todo: clear out old game

        gameBoard = [[MarbleNode?]](repeatElement([MarbleNode?](repeatElement(nil, count: boardWidth)), count: boardHeight))

        let player0StartingIndices = [( 0, 6), ( 1, 5), ( 1, 6), ( 2, 5), ( 2, 6), ( 2, 7), ( 3, 4), ( 3, 5), ( 3, 6), ( 3, 7), ( 4, 4), ( 4, 5), ( 4, 6), ( 4, 7), ( 4, 8)]
        let player1StartingIndices = [(16, 6), (15, 5), (15, 6), (14, 5), (14, 6), (14, 7), (13, 4), (13, 5), (13, 6), (13, 7), (12, 4), (12, 5), (12, 6), (12, 7), (12, 8)]

        for index in player0StartingIndices {
            drawMarbleAt(index: index, color: .blue)
        }
        for index in player1StartingIndices {
            drawMarbleAt(index: index, color: .red)
        }
    }

    func drawMarble(atPoint point: CGPoint, color: MarbleColor, radius: CGFloat = 15) -> MarbleNode {
        let marbleSprite = MarbleNode(imageNamed: color.rawValue)
        marbleSprite.size = CGSize(width: radius, height: radius)
        marbleSprite.position = point
        marbleSprite.isUserInteractionEnabled = true
        self.addChild(marbleSprite)

        return marbleSprite
    }

    func coordinatesFor(index: MarbleIndex) -> CGPoint {
        let y = startY + (dy * CGFloat(index.0))
        var x = startX + ((dx * CGFloat(index.1 - 6)) * 2)
        if index.0 % 2 == 1 { x += dx }

        return CGPoint(x: x, y: y)
    }

    func indexFrom(point: CGPoint) -> MarbleIndex {
        let row = Int((point.y - startY) / dy)
        var column = row % 2 == 0 ? point.x : point.x - dx
        column = (((column - startX) / 2) / dx) + 6

        return (row, Int(round(column)))
    }

    func drawMarbleAt(index: MarbleIndex, color: MarbleColor) {
        gameBoard[index.0][index.1] = drawMarble(atPoint: coordinatesFor(index: index), color: color)
    }

    func isValid(index: MarbleIndex) -> Bool {
        guard index.0 < boardHeight else {
            return false
        }

        guard index.1 < boardWidth else {
            return false
        }

        return ((rowStarts[index.0])..<(rowStarts[index.0] + rowWidths[index.0])).contains(index.1)
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

        return gameBoard[index.0][index.1] != nil
    }

    func highligtAdjacentSpotsForMarbleAt(index: MarbleIndex) {
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: (index.0, index.1 + 1))) // Right
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: (index.0, index.1 - 1))) // Left
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: (index.0 - 1, index.1 - 1 + (index.0 % 2)))) // Up left
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: (index.0 - 1, index.1 + (index.0 % 2)))) // Up right
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: (index.0 + 1, index.1 - 1 + (index.0 % 2)))) // Down left
        highlightNodes.appendOptional(newElement: highlightIfEmptyAt(index: (index.0 + 1, index.1 + (index.0 % 2)))) // Down right
    }

    var knownJumps = [MarbleIndex]()
    func highlightJumpsForMarbleAt(index: MarbleIndex) {

        // Right
        if marbleExistsAt(index: (index.0, index.1 + 1)) {
            let rightJump = (index.0, index.1 + 2)
            if !knownJumps.contains(where: { (e) -> Bool in e == rightJump }) {
                if let highlightNode = highlightIfEmptyAt(index: rightJump) {
                    knownJumps.append(rightJump)
                    highlightNodes.append(highlightNode)
                    highlightJumpsForMarbleAt(index: rightJump)
                }
            }
        }

        // Left
        if marbleExistsAt(index: (index.0, index.1 - 1)) {
            let rightJump = (index.0, index.1 - 2)
            if !knownJumps.contains(where: { (e) -> Bool in e == rightJump }) {
                if let highlightNode = highlightIfEmptyAt(index: rightJump) {
                    knownJumps.append(rightJump)
                    highlightNodes.append(highlightNode)
                    highlightJumpsForMarbleAt(index: rightJump)
                }
            }
        }

        // Up left
        if marbleExistsAt(index: (index.0 - 1, index.1 - 1 + (index.0 % 2))) {
            let rightJump = (index.0 - 2, index.1 - 1)
            if !knownJumps.contains(where: { (e) -> Bool in e == rightJump }) {
                if let highlightNode = highlightIfEmptyAt(index: rightJump) {
                    knownJumps.append(rightJump)
                    highlightNodes.append(highlightNode)
                    highlightJumpsForMarbleAt(index: rightJump)
                }
            }
        }

        // Up right
        if marbleExistsAt(index: (index.0 - 1, index.1 + (index.0 % 2))) {
            let rightJump = (index.0 - 2, index.1 + 1)
            if !knownJumps.contains(where: { (e) -> Bool in e == rightJump }) {
                if let highlightNode = highlightIfEmptyAt(index: rightJump) {
                    knownJumps.append(rightJump)
                    highlightNodes.append(highlightNode)
                    highlightJumpsForMarbleAt(index: rightJump)
                }
            }
        }

        // Down left
        if marbleExistsAt(index: (index.0 + 1, index.1 - 1 + (index.0 % 2))) {
            let rightJump = (index.0 + 2, index.1 - 1)
            if !knownJumps.contains(where: { (e) -> Bool in e == rightJump }) {
                if let highlightNode = highlightIfEmptyAt(index: rightJump) {
                    knownJumps.append(rightJump)
                    highlightNodes.append(highlightNode)
                    highlightJumpsForMarbleAt(index: rightJump)
                }
            }
        }

        // Down right
        if marbleExistsAt(index: (index.0 + 1, index.1 + (index.0 % 2))) {
            let rightJump = (index.0 + 2, index.1 + 1)
            if !knownJumps.contains(where: { (e) -> Bool in e == rightJump }) {
                if let highlightNode = highlightIfEmptyAt(index: rightJump) {
                    knownJumps.append(rightJump)
                    highlightNodes.append(highlightNode)
                    highlightJumpsForMarbleAt(index: rightJump)
                }
            }
        }
    }

    func highlightIfEmptyAt(index: MarbleIndex) -> HighlightNode? {
        guard !marbleExistsAt(index: index) else {
            return nil
        }

        let highlightNode = HighlightNode(color: .green, size: CGSize(width: 15, height: 15))
        highlightNode.position = coordinatesFor(index: index)
        highlightNode.isUserInteractionEnabled = true
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
        gameBoard[currentIndex.0][currentIndex.1] = nil
        gameBoard[newIndex.0][newIndex.1] = selectedMarble!
        selectedMarble!.position = coordinatesFor(index: newIndex)
    }

    func drawCoordinateLabel(forIndex index: MarbleIndex) {
        let node = SKLabelNode(text: "\(index)")
        node.position = coordinatesFor(index: index)
        node.fontColor = .black
        node.fontSize = 10

        self.addChild(node)
    }

    func drawCoordinateOverlay() {
        for i in 0..<17 {
            for j in 0..<13 {
                guard isValid(index: (i, j)) else {
                    continue
                }

                drawCoordinateLabel(forIndex: (i, j))
            }
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
