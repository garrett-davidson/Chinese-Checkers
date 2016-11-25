//
//  SetingsTableViewController.swift
//  Chinese Checkers
//
//  Created by Noah Maxey on 11/24/16.
//  Copyright © 2016 Garrett Davidson. All rights reserved.
//

import UIKit

class SetingsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let settingsTable = ["Bitch Mode (Local)", "Bitch Mode (Global)", "other settings?"]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return settingsTable.count
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "cancel" {
            //Make it so the screen doesn't change???
        } else if segue.identifier == "save" {
            //Save the settings bitch
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! SettingsCell
        // Configure the cell...
        let title = settingsTable[(indexPath as NSIndexPath).row]
        cell.titleLabel?.text = title
        var isChecked = false
        if title == "Bitch Mode (Local)" {
            //todo: USER YOU ARE FACING
            isChecked = Settings.isBitchMode(forUser: "SOMETHING")
        } else if title == "Bitch Mode (Global)" {
            isChecked = Settings.isBitchMode()
        } else {
            isChecked = UserDefaults.standard.bool(forKey: settingsTable[(indexPath as NSIndexPath).row])
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
