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

    var gameScene: GameScene!
    var currentConversation: MSConversation!
    var currentGameIdentifier: String?

    static var sharedMessagesViewController: MessagesViewController!

    @IBOutlet weak var gameView: SKView!
    @IBOutlet weak var startGameButton: UIButton!

    enum GameCommand: String {
        case newGame
        case move
    }

    enum GameStateParameter: String {
        case command
        case playerColor
        case players
        case move
    }

    struct GameState: CustomStringConvertible {
        var command: GameCommand!
        var playerColor: MarbleColor!
        var move: (MarbleIndex, MarbleIndex)?
        var players: [String: String]!

        var description: String {
            get {
                var ret = "\(GameStateParameter.command)=\(command!);\(GameStateParameter.playerColor)=\(playerColor!);\(GameStateParameter.players)=\(players.toBase64String()!)"
                if move != nil {
                    ret += ";\(GameStateParameter.move)=\(move!.0):\(move!.1)"
                }
                return ret
            }
        }

        init() {
            self.command = nil
            self.playerColor = nil
            self.move = nil
            self.players = nil
        }
        init(command: GameCommand?, playerColor: MarbleColor?, players: [String: String]?, move: (MarbleIndex, MarbleIndex)? = nil) {
            self.command = command
            self.playerColor = playerColor
            self.players = players
            self.move = move
        }

        init(description: String) {
            let parameters = description.components(separatedBy: ";")
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
                    self.move = (from, to)
                }
            }
        }
    }

    var nextGameState: GameState?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

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
            showGameScene(identifier: currentGameIdentifier)
            handle(newMessage: currentConversation.selectedMessage!, forConversation: conversation)
        } else {
            startGameButton.isHidden = false
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
            showGameScene(identifier: currentGameIdentifier)
        } else {
            startGameButton.isHidden = false
            gameView.isHidden = true
        }
    }

    func sendReply(session: MSSession) {
        let newGameMessage = MSMessage(session: session)

        let url = URL(string: "\(currentGameIdentifier!)?\(nextGameState!)")!
        newGameMessage.url = url
        currentConversation.insert(newGameMessage, completionHandler: nil)
    }

    @IBAction func startGame(_ sender: Any) {
        let newGameSession = MSSession()
        nextGameState = GameState(command: .newGame, playerColor: .blue, players: [currentConversation.localParticipantIdentifier.uuidString: MarbleColor.blue.rawValue])

        currentGameIdentifier = UUID().uuidString

        sendReply(session: newGameSession)
    }

    func showGameScene(identifier: String? = nil) {
        if gameScene == nil {
            loadGameScene(identifier: identifier)
        }

        startGameButton.isHidden = true
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

        switch previousGameState.command! {
        case .newGame:
            // Append my color/uuid to the player list
            print("New game")
            var previousPlayers = previousGameState.players
            for color in MarbleColor.allColors {
                if !(previousPlayers!.values.contains(color.rawValue)) {
                    nextGameState?.playerColor = color
                    previousPlayers![conversation.localParticipantIdentifier.uuidString] = color.rawValue
                    nextGameState?.players = previousPlayers
                }
            }

        case .move:
            print("Move")
            let move = previousGameState.move!
            nextGameState?.players = previousGameState.players
            nextGameState?.playerColor = MarbleColor(rawValue: previousGameState.players[conversation.localParticipantIdentifier.uuidString]!)
            GameScene.sharedGame.moveMarble(from: move.0, to: move.1)
        }
    }

    func sendMove(from: MarbleIndex, to: MarbleIndex) {
        nextGameState!.command = .move
        nextGameState?.playerColor = MarbleColor(rawValue: nextGameState!.players![currentConversation.localParticipantIdentifier.uuidString]!)
        nextGameState?.move = (from, to)
        sendReply(session: currentConversation.selectedMessage!.session!)
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
}
