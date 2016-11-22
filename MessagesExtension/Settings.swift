//
//  Settings.swift
//  Chinese Checkers
//
//  Created by Garrett Davidson on 11/22/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import Foundation

class Settings {
    private static let bitchModeKey = "bitchMode"

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
}
