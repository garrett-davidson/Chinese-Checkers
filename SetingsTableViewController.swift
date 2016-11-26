//
//  SetingsTableViewController.swift
//  Chinese Checkers
//
//  Created by Noah Maxey on 11/24/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import UIKit

class SetingsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    enum SettingsCellTag: Int {
        case BitchModeCurrentConversation = 0
        case BitchModeGlobal
        case SendPictures
    }

    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func save(_ sender: Any) {

        for i in 0..<settingsTable.count {
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? SettingsCell {
                switch SettingsCellTag(rawValue: cell.tag)! {
                case .BitchModeCurrentConversation:
                    Settings.set(bitchMode: cell.settingSwitch.isOn, forUsers: MessagesViewController.sharedMessagesViewController.currentPlayers())
                case .BitchModeGlobal:
                    Settings.set(bitchMode: cell.settingSwitch.isOn)
                case .SendPictures:
                    print("Send pictures")
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }


    @IBOutlet weak var tableView: UITableView!
    let settingsTable = ["Bitch Mode (Current Conversation)", "Bitch Mode (Global)", "Send Pictures"]

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return settingsTable.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func createErrorCell() -> UITableViewCell {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Error"
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as? SettingsCell else {
            print("Couldn't load settings cell")
            return createErrorCell()
        }

        guard let setting = SettingsCellTag(rawValue: indexPath.row) else {
            print("Unknown setting type")
            return createErrorCell()
        }

        let settingTitle = settingsTable[setting.rawValue]

        cell.titleLabel?.text = settingTitle

        let isChecked: Bool
        switch setting {
        case .BitchModeCurrentConversation:
            isChecked = Settings.isBitchMode(forUsers: MessagesViewController.sharedMessagesViewController.currentPlayers())
        case .BitchModeGlobal:
            isChecked = Settings.isBitchMode()
        case .SendPictures:
            isChecked = true
            print("todo: implement send pictures settings")
        }

        cell.settingSwitch.isOn = isChecked
        return cell
    }
}

class SettingsCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var settingSwitch: UISwitch!
    @IBAction func switchChanged(_ sender: UISwitch) {
        if self.titleLabel.text == "Bitch Mode (Local)" {
            //todo: CHANGE TO THE USERS
            Settings.set(bitchMode: settingSwitch.isOn, forUsers: nil)
        } else if self.titleLabel.text == "Bitch Mode (Global)" {
            Settings.set(bitchMode: settingSwitch.isOn)
        } else {
            UserDefaults.standard.set(sender.isOn, forKey: (self.titleLabel?.text)!)
        }
    }

}
