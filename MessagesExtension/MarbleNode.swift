//
//  MarbleNode.swift
//  Chinese Checkers
//
//  Created by Garrett Davidson on 11/11/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import Foundation
import SpriteKit

class MarbleNode: SKSpriteNode {

    let marbleColor: MarbleColor

    init(color: MarbleColor) {
        self.marbleColor = color
        let texture = SKTexture(imageNamed: color.rawValue)
        super.init(texture: texture, color: .clear, size: texture.size())
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let colorString = aDecoder.decodeObject(forKey: "color")! as? String else {
            return nil
        }
        self.init(color: MarbleColor(rawValue: colorString)!)
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(marbleColor.rawValue, forKey: "color")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        GameScene.sharedGame.selectedMarble = self
    }

    func highlight() {
        self.alpha = 0.7
    }

    func unHighlight() {
        self.alpha = 1
    }
}

class MarbleJump {
    var leftJump: MarbleJump?
    var rightJump: MarbleJump?
    var upLeftJump: MarbleJump?
    var upRightJump: MarbleJump?
    var downLeftJump: MarbleJump?
    var downRightJump: MarbleJump?

    let index: MarbleIndex

    init(index: MarbleIndex) {
        self.index = index
    }

    var jumps: [MarbleJump?] {
        get {
            return [leftJump, rightJump, upLeftJump, upRightJump, downLeftJump, downRightJump]
        }
    }

    func reversedPathToIndex(index: MarbleIndex) -> [MarbleIndex]? {
        for jump in jumps {
            if let jump = jump {
                if jump.index == index {
                    return [index, self.index]
                } else {
                    if var indices = jump.reversedPathToIndex(index: index) {
                        indices.append(self.index)
                        return indices
                    }
                }
            }
        }

        return nil
    }
}
