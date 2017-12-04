//
//  SettingsVC.swift
//  HeatChat
//
//  Created by BAM on 2017-12-03.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation
import UIKit

class SettingsVC : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        
        super.viewDidLoad()
    
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterCell")
        return cell!
    }

    @IBAction func switchChanged(_ sender: Any) {
        
    }
}
