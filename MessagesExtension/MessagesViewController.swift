//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Garrett Davidson on 11/11/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import UIKit
import Messages
import SpriteKit

class MessagesViewController: MSMessagesAppViewController {

    @IBOutlet weak var startGameView: UIView!
    @IBOutlet weak var winLabel: UILabel!
    var gameScene: GameScene!
    var currentConversation: MSConversation!
    var currentGameIdentifier: String?

    static var sharedMessagesViewController: MessagesViewController!

    @IBOutlet weak var gameView: SKView!
    @IBOutlet weak var startGameButton: UIButton!

    enum GameCommand: String {
        case newGame
        case move
        case gameOver
    }

    enum GameStateParameter: String {
        case command
        case playerColor
        case players
        case move
        case gameBoard
    }

    struct GameState: CustomStringConvertible {
        var command: GameCommand!
        var playerColor: MarbleColor!
        var move: (MarbleIndex, MarbleIndex, [MarbleIndex])?
        var players: [String: String]!
        var gameBoard: [[MarbleNode?]]!

        var description: String {
            get {
                var ret = "\(GameStateParameter.command)=\(command!);\(GameStateParameter.playerColor)=\(playerColor!);\(GameStateParameter.players)=\(players.toBase64String()!)"
                if move != nil {
                    ret += ";\(GameStateParameter.move)=\(move!.0):\(move!.1):\(move!.2)"
                }
                ret += ";\(GameStateParameter.gameBoard)=\(stringFrom(gameBoard: gameBoard))"
                return ret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            }
        }

        init() {
            self.command = nil
            self.playerColor = nil
            self.move = nil
            self.players = nil
            self.gameBoard = nil
        }

        init(command: GameCommand?, playerColor: MarbleColor?, players: [String: String]?, move: (MarbleIndex, MarbleIndex, [MarbleIndex])? = nil, gameBoard: [[MarbleNode?]]) {
            self.command = command
            self.playerColor = playerColor
            self.players = players
            self.move = move
            self.gameBoard = gameBoard
        }

        init(description: String) {
            let parameters = description.removingPercentEncoding!.components(separatedBy: ";")
            for parameter in parameters {
                let values = parameter.components(separatedBy: "=")
                guard values.count > 1 else {
                    print("Could not parse game state")
                    continue
                }

                guard let parameter = GameStateParameter(rawValue: values[0]) else {
                    print("Invalid parameter")
                    continue
                }

                switch parameter {
                case .command:
                    guard let command = GameCommand(rawValue: values[1]) else {
                        print("Invalid game command")
                        continue
                    }
                    self.command = command

                case .playerColor:
                    self.playerColor = MarbleColor(rawValue: values[1])

                case .players:
                    self.players = Dictionary<String, String>(base64String: values.dropFirst().joined(separator: "="))

                case .move:
                    let movePositions = values[1].components(separatedBy: ":")
                    let from = MarbleIndex(string: movePositions[0])
                    let to = MarbleIndex(string: movePositions[1])

                    let indexStrings = String(movePositions[2].characters.dropFirst().dropLast()).components(separatedBy: ", ")
                    var indices = [MarbleIndex]()
                    for indexString in indexStrings {
                        indices.append(MarbleIndex(string: indexString))
                    }
                    self.move = (from, to, indices)

                case .gameBoard:
                    self.gameBoard = gameBoardFrom(string: values[1])
                }
            }
        }

        func stringFrom(gameBoard: [[MarbleNode?]]) -> String {
            var ret = ""
            for i in 0..<gameBoard.count {
                let row = gameBoard[i]
                for j in 0..<row.count {
                    if let node = row[j] {
                        ret += "\(node.marbleColor),\(i),\(j)"
                    }

                    ret += ":"
                }
                ret += "],"
            }
            return ret
        }

        func gameBoardFrom(string boardString: String) -> [[MarbleNode?]] {
            var board = [[MarbleNode?]](repeatElement([MarbleNode?](repeatElement(nil, count: boardWidth)), count: boardHeight))

            // Drop the last (empty) component
            let rows = Array(boardString.components(separatedBy: "],").dropLast())
            for row in rows {

                // Drop the last (empty) component
                let nodes = Array(row.components(separatedBy: ":").dropLast())
                for node in nodes {
                    if node != "" {
                        let attributes = node.components(separatedBy: ",")
                        let color = MarbleColor(rawValue: attributes[0])!
                        let i = Int(attributes[1])!
                        let j = Int(attributes[2])!
                        let newNode = MarbleNode(color: color)
                        board[i][j] = newNode
                    }
                }
            }
            return board
        }
    }

    var nextGameState: GameState?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        winLabel.text = "Wins: \(UserDefaults.standard.integer(forKey: "totalWins"))"
        MessagesViewController.sharedMessagesViewController = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Conversation Handling

    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.

        // Use this method to configure the extension and restore previously stored state.
        currentConversation = conversation

        print(currentConversation.selectedMessage?.url as Any)

        if presentationStyle == .expanded {
            currentGameIdentifier = currentConversation.selectedMessage?.url?.path
            handle(newMessage: currentConversation.selectedMessage!, forConversation: conversation)
        } else {
            startGameView.isHidden = false
            gameView.isHidden = true
        }
    }

    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.

        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.

        // Use this method to trigger UI updates in response to the message.
        handle(newMessage: message, forConversation: conversation)
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.

        let key = message.url!.path + MessagesViewController.sharedMessagesViewController.currentConversation.localParticipantIdentifier.uuidString
        let board = UserDefaults.standard.object(forKey: key + "new")
        UserDefaults.standard.set(board, forKey: key)
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.

        // Use this to clean up state related to the deleted message.
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.

        // Use this method to prepare for the change in presentation style.
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.

        // Use this method to finalize any behaviors associated with the change in presentation style.

        if presentationStyle == .expanded {
            currentGameIdentifier = currentConversation.selectedMessage?.url?.path
            handle(newMessage: currentConversation.selectedMessage!, forConversation: currentConversation)
        } else {
            startGameView.isHidden = false
            gameView.isHidden = true
        }
    }

    func sendReply(session: MSSession? = nil) {
        let currentSession = session ?? currentConversation.selectedMessage!.session!
        let newGameMessage = MSMessage(session: currentSession)

        let url = URL(string: "\(currentGameIdentifier!)?\(nextGameState!)")!
        newGameMessage.url = url

        let layout = MSMessageTemplateLayout()
        layout.image = getScreenshot()

        let messageText: String
        switch nextGameState!.command! {
        case .newGame:
            messageText = "Play Chinese Checkers with me!"
        case .move:
            messageText = "Your turn..."

        case .gameOver:
            messageText = "I win!"
        }
        newGameMessage.summaryText = messageText
        layout.caption = messageText
        if Settings.isBitchMode(forUsers: Array(nextGameState!.players.keys)) {
            layout.trailingSubcaption = "Bitch."
        }

        newGameMessage.layout = layout
        currentConversation.insert(newGameMessage, completionHandler: nil)
//        dismiss()
    }

    func getScreenshot() -> UIImage {
        let size = CGSize(width: 300, height: 450)
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        let rect = CGRect(origin: CGPoint(x: 0, y: -100), size: gameView.bounds.size)
        gameView.drawHierarchy(in: rect, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }

    @IBAction func startGame(_ sender: Any) {
        let newGameSession = MSSession()
        nextGameState = GameState(command: .newGame, playerColor: .red, players: [currentConversation.localParticipantIdentifier.uuidString: MarbleColor.red.rawValue], gameBoard: GameScene.resetGame())

        currentGameIdentifier = UUID().uuidString

        sendReply(session: newGameSession)
    }

    func showGameScene(identifier: String? = nil) {
        if gameScene == nil {
            loadGameScene(identifier: identifier)
        } else {
            gameScene.setup(identifier: identifier)
        }
        startGameView.isHidden = true
        gameView.isHidden = false
        gameView.presentScene(gameScene)

    }

    func loadGameScene(identifier: String? = nil) {
        if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
            gameScene = scene
            gameScene.setup(identifier: identifier)
            scene.scaleMode = .aspectFit

            gameView.ignoresSiblingOrder = true

            gameView.showsFPS = true
            gameView.showsNodeCount = true
        }
    }

    func handle(newMessage: MSMessage, forConversation conversation: MSConversation) {
        guard let query = newMessage.url?.query else {
            print("Message URL did not contain query")
            return
        }

        nextGameState = GameState()
        let previousGameState = GameState(description: query)

        if let previousMessageColorString = previousGameState.players[conversation.localParticipantIdentifier.uuidString] {
            guard previousGameState.playerColor != MarbleColor(rawValue: previousMessageColorString) else {
                // This means we clicked on our own message
                // So we shouldn't replay the last move
                nextGameState?.gameBoard = previousGameState.gameBoard
                showGameScene(identifier: currentGameIdentifier)
                return
            }
        }

        func playMove() {
            nextGameState?.gameBoard = previousGameState.gameBoard
            nextGameState?.players = previousGameState.players
            nextGameState?.playerColor = MarbleColor(rawValue: previousGameState.players[conversation.localParticipantIdentifier.uuidString]!)
            showGameScene(identifier: currentGameIdentifier)

            let move = previousGameState.move!
            GameScene.sharedGame.moveMarble(from: move.0, to: move.1, path: move.2, updateBoard: true)
        }

        switch previousGameState.command! {
        case .newGame:
            // Append my color/uuid to the player list
            print("New game")
            var previousPlayers = previousGameState.players
            for color in [MarbleColor.red, .green, .purple, .yellow, .blue, .orange] {
                if !(previousPlayers!.values.contains(color.rawValue)) {
                    nextGameState?.playerColor = color
                    previousPlayers![conversation.localParticipantIdentifier.uuidString] = color.rawValue
                    nextGameState?.players = previousPlayers
                    break
                }
            }
            nextGameState?.gameBoard = GameScene.resetGame()
            showGameScene(identifier: currentGameIdentifier)

        case .move:
            print("Move")
            playMove()

        case .gameOver:
            playMove()
            print("I lost")
            // todo: Show gameover UI.
            nextGameState = nil
        }
    }

    func sendMove(from: MarbleIndex, to: MarbleIndex, path: [MarbleIndex]) {
        nextGameState!.command = .move
        nextGameState?.playerColor = MarbleColor(rawValue: nextGameState!.players![currentConversation.localParticipantIdentifier.uuidString]!)
        nextGameState?.move = (from, to, path)

        let move = (from, to)
        let score = gameScene.scoreFor(color: nextGameState!.playerColor, forMove: move)
        print(score)
        gameScene.assignScores(color: nextGameState!.playerColor, forMove: move)
        if score == -1 {
            print("I win")
            nextGameState!.command = .gameOver
            let totalWins = UserDefaults.standard.integer(forKey: "totalWins")
            UserDefaults.standard.set(totalWins + 1, forKey: "totalWins")
        }
    }

}

extension Dictionary {
    func toBase64String() -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: self, options: []) {
            return data.base64EncodedString()
        }

        return nil
    }

    init?(base64String: String) {
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        guard let s = json as? Dictionary else {
            return nil
        }

        self = s
    }
}

extension Array where Element: Equatable {
    func elementAfter(element: Element) -> Element {
        let index = self.index(of: element)!
        return self[index + 1 % self.count]
    }

    func opposite(element: Element) -> Element {
        let index = self.index(of: element)!
        let count = self.count
        return self[(index + (count/2)) % count]
    }
}
