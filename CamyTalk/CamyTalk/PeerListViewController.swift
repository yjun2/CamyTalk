//
//  PeerListViewController.swift
//  CamyTalk
//
//  Created by Yong Jun on 7/27/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreData

class PeerListViewController: UITableViewController, MCFManagerDelegate{
    
    var mpcManager: MCFManager?
    var coreDataHelper: CoreDataHelper?
    var connectedPeer: MCPeerID?
    
    var peers = [Peer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Avaiilable Peers"
        
        if let results = coreDataHelper?.fetchAll() {
            peers = results
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "fetchAllAgain",
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mpcManager?.delegate = self
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Peer", forIndexPath: indexPath) as! UITableViewCell
        
        let indicator = cell.viewWithTag(1001) as? UIImageView
        let status = peers[indexPath.row].isOnline
        
        if status == false {
            indicator?.image = UIImage(named: "red-circle-16.png")
        } else {
            indicator?.image = UIImage(named: "green-circle-16.png")
        }
        
        let label = cell.viewWithTag(1000) as? UILabel
        label?.text = peers[indexPath.row].displayName
        
        return cell
    }
    
    // MARK: MCFManagerDelegate
    func mpcManagerAvailablePeers() {
        fetchAllAgain()
    }
   
    func mpcManagerConnectedPeer(connectedPeerId: MCPeerID) {
        self.connectedPeer = connectedPeerId
    }
    
    func fetchAllAgain() {
        if let results = coreDataHelper?.fetchAll() {
            peers = results
            tableView.reloadData()
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Chatting" {
            let chattingVC = segue.destinationViewController as! ChattingViewController
            chattingVC.hidesBottomBarWhenPushed = true
            
            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
                chattingVC.mpcManager = self.mpcManager
                chattingVC.userName = peers[indexPath.row].displayName
                chattingVC.connectedPeer = self.connectedPeer
                
                // fetch or create a conversation object from core data and 
                // send it over to ChattingViewController
                // TBD
            }
            
        }

    }


}
