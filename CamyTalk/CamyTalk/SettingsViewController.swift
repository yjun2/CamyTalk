//
//  SettingsViewController.swift
//  CamyTalk
//
//  Created by Yong Jun on 7/27/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    var coreDataHelper: CoreDataHelper?
    var mpcManager: MCFManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toBlockedVC" {
            let blockedVC = segue.destinationViewController as! BlockedPeerListTableViewController
            
            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
                blockedVC.mpcManager = self.mpcManager
                blockedVC.coreDataHelper = self.coreDataHelper
            }
            
        }
    }


}
