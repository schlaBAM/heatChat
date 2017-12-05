//
//  SettingsVC.swift
//  HeatChat
//
//  Created by BAM on 2017-12-03.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation
import UIKit

class FilterWordsCustomCell : UITableViewCell {
    
    @IBOutlet weak var cellText: UILabel!
    @IBOutlet weak var subText: UILabel!
    @IBOutlet weak var cellSwitch: UISwitch!
}

class SettingsVC : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterCell") as! FilterWordsCustomCell
        if let filtered = defaults.bool(forKey: "filterEnabled") as? Bool, filtered {
            cell.cellSwitch.isOn = true
        } else {
            cell.cellSwitch.isOn = false
        }
        return cell
    }

    @IBAction func switchToggled(_ sender: UISwitch!) {
        if sender.isOn {
            defaults.set(true, forKey: "filterEnabled")
        } else {
           defaults.set(false, forKey: "filterEnabled")
        }
        
        defaults.set(true, forKey: "filterChanged")
    }
    
}
