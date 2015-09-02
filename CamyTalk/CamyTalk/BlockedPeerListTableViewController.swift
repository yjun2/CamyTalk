//
//  BlockedPeerListTableViewController.swift
//  CamyTalk
//
//  Created by Yong Jun on 8/31/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import UIKit

class BlockedPeerListTableViewController: UITableViewController {

    var coreDataHelper: CoreDataHelper?
    var mpcManager: MCFManager?
    var peers = [Peer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Blocked Peers"
        
        if let results = coreDataHelper?.fetchAllObjectsWithEntityName("Peer", includeBlocked: true) as? [Peer] {
            peers = results
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peers.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BlockedPeer", forIndexPath: indexPath) as! UITableViewCell

        let peerLabel = cell.viewWithTag(5000) as? UILabel
        peerLabel?.text = peers[indexPath.row].displayName

        return cell
    }

    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "Unblock"
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let peer = peers[indexPath.row] as Peer
            coreDataHelper?.updatePeerBlockedStatus(peer, blocked: false)
            
            if let results = coreDataHelper?.fetchAllObjectsWithEntityName("Peer", includeBlocked: true) as? [Peer] {
                peers = results
                tableView.reloadData()
            }
        }
    }
    
}
