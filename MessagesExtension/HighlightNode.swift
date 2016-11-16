//
//  HighlightNode.swift
//  Chinese Checkers
//
//  Created by Garrett Davidson on 11/11/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import Foundation
import SpriteKit

class HighlightNode: SKShapeNode {
    override init() {
        super.init()

        self.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0), radius: 9.5, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        self.strokeColor = .cyan
        self.lineWidth = 3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        GameScene.sharedGame.moveTo(highlightNode: self)
    }
}
