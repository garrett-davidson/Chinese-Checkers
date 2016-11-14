import SpriteKit
import XCPlayground
import PlaygroundSupport

let dx = CGFloat(12)
let dy = CGFloat(-21.16)
var startX = CGFloat(0)
var startY = CGFloat(170)

enum MarbleColor: String {
    case red
    case green
    case orange
    case purple
    case cyan
    case yellow

    static let allColors = [MarbleColor.red, .green, .orange, .purple, .cyan, .yellow]
}

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

    func highlight() {
        self.alpha = 0.7
    }

    func unHighlight() {
        self.alpha = 1
    }
}

let view = SKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))

PlaygroundPage.current.liveView = view
let scene = SKScene(fileNamed: "GameScene")!
scene.scaleMode = SKSceneScaleMode.aspectFit
view.presentScene(scene)

func drawMarble(atPoint point: CGPoint, color: MarbleColor, radius: CGFloat = 12) -> MarbleNode {
    let marbleSprite = MarbleNode(color: color)
    marbleSprite.size = CGSize(width: radius, height: radius)
    marbleSprite.position = point
    marbleSprite.isUserInteractionEnabled = true
    scene.addChild(marbleSprite)

    return marbleSprite
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

func coordinatesFor(index: MarbleIndex) -> CGPoint {
    let y = startY + (dy * CGFloat(index.row))
    var x = startX + ((dx * CGFloat(index.column - 6)) * 2)
    if index.row % 2 == 1 { x += dx }

    return CGPoint(x: x, y: y)
}

func drawMarbleAt(index: MarbleIndex, color: MarbleColor) {
    drawMarble(atPoint: coordinatesFor(index: index), color: color)
}

let boardWidth = 13
let boardHeight = 17

let rowWidths = [1, 2, 3, 4, 13, 12, 11, 10, 9, 10, 11, 12, 13, 4, 3, 2, 1]
let rowStarts = [6, 5, 5, 4,  0,  0,  1,  1, 2,  1,  1,  0,  0, 4, 5, 5, 6]

func isValid(index: MarbleIndex) -> Bool {
    guard index.row >= 0 && index.row < boardHeight else {
        return false
    }

    guard index.column >= 0 && index.column < boardWidth else {
        return false
    }

    return ((rowStarts[index.row])..<(rowStarts[index.row] + rowWidths[index.row])).contains(index.column)
}

for i in 0..<15 {
    for j in 0..<boardWidth {
        let index = MarbleIndex((i, j))
        if isValid(index: index) {
            drawMarbleAt(index: index, color: .red)
        }
    }
}
