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
