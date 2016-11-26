//
//  Settings.swift
//  Chinese Checkers
//
//  Created by Garrett Davidson on 11/22/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import Foundation

class StringManager {
    static func newGameText(forUsers users: [String]) -> (String, String?) {
        if Settings.isBitchMode(forUsers: users) {
            return [("Let's play bitch.", nil),
                    ("Do you wanna play a game, bitch?", nil),
                    ].random
        } else {
            return [("Let's play!", nil),
                    ("Play Chinese Checkers with me!", nil),
                    ].random
        }
    }

    static func yourTurnText(forUsers users: [String]) -> (String, String?) {
        if Settings.isBitchMode(forUsers: users) {
            return [("Hurry the fuck up.", nil),
                    ("Go bitch.", nil),
                    ("You're going down bitch.", nil),
                    ("Y u take soooo long?", nil),
                    ("🖕", nil),
                    ("Hurry up! I'm about to win!", nil),
                    ("Bitch I'm waiting.", nil),
                    ].random
        } else {
            return [("Your turn.", nil),
                    ].random
        }
    }

    static func gameOverText(forUsers users: [String]) -> (String, String?) {
        if Settings.isBitchMode(forUsers: users) {
            return [("gg", "(not really)"),
                    ("Damn that was easy", nil),
                    ("Damn that was easy", "Like your mom"),
                    ("Wow u suck", nil),
                    ("😘", nil),
                    ("😁", nil),
                    ("😉", nil),
                    ("🍆", "Suck it"),
                    ("Get on my level", ":p"),
                    ].random
        } else {
            return [("I win!", nil),
                    ].random
        }
    }
}

class Settings {
    private static let bitchModeKey = "Bitch Mode"
    private static let sendImagesKey = "Send Images"

    static func isBitchMode(forUser user: String? = nil) -> Bool {
        var ret = false
        if let user = user {
            ret = UserDefaults.standard.bool(forKey: bitchModeKey + user)
        }
        return ret || UserDefaults.standard.bool(forKey: bitchModeKey)
    }

    static func isBitchMode(forUsers users: [String]) -> Bool {
        for user in users {
            if !isBitchMode(forUser: user) {
                return false
            }
        }

        return true
    }

    static func set(bitchMode: Bool, forUsers users: [String]? = nil) {
        if let users = users {
            for user in users {
                UserDefaults.standard.set(bitchMode, forKey: bitchModeKey + user)
            }
        } else {
            UserDefaults.standard.set(bitchMode, forKey: bitchModeKey)
        }
    }

    static func shouldSendImages() -> Bool {
        return UserDefaults.standard.bool(forKey: sendImagesKey)
    }

    static func set(shouldSendImage: Bool) {
        UserDefaults.standard.set(shouldSendImage, forKey: sendImagesKey)
    }
}

extension Array {
    var random: Element {
        get {
            let i = Int(arc4random_uniform(UInt32(self.count)))
            return self[i]
        }
    }
}
