//
//  HighlightNode.swift
//  Chinese Checkers
//
//  Created by Garrett Davidson on 11/11/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import Foundation
import SpriteKit

class HighlightNode: SKSpriteNode {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        GameScene.sharedGame.moveTo(highlightNode: self)
    }
}
