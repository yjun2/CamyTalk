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

class PeerListViewController: UITableViewController, MCFManagerDelegate {
    
    var mpcManager: MCFManager?
    var coreDataHelper: CoreDataHelper?
    var connectedPeer: MCPeerID?
    var conversationVC: ConversationTableViewController!
    var settingsVC: SettingsViewController!
    
    @IBOutlet weak var statusLabl: UILabel!
    var peers = [Peer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Available Peers"
        
        if let results = coreDataHelper?.fetchAllObjectsWithEntityName("Peer", includeBlocked: false) as? [Peer] {
            peers = results
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "fetchAllAgain",
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)
        
        
        // share core data helper object with ConversationViewController
        let tabBarVCs = self.tabBarController?.viewControllers
        var navVC = tabBarVCs![1] as! UINavigationController
        conversationVC = navVC.topViewController as! ConversationTableViewController
        conversationVC.coreDataHelper = self.coreDataHelper
        conversationVC.mpcManager = self.mpcManager
        
        navVC = tabBarVCs![2] as! UINavigationController
        settingsVC = navVC.topViewController as! SettingsViewController
        settingsVC.coreDataHelper = self.coreDataHelper
        settingsVC.mpcManager = self.mpcManager
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mpcManager?.delegate = self
        
        if let results = coreDataHelper?.fetchAllObjectsWithEntityName("Peer", includeBlocked: false) as? [Peer] {
            peers = results
            tableView.reloadData()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "notifyNewMessageDataNotification:",
            name: "newMessageDataNotification",
            object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: "newMessageDataNotification",
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
        
        let peerLabel = cell.viewWithTag(1000) as? UILabel
        peerLabel?.text = peers[indexPath.row].displayName
        
        let statusLabel = cell.viewWithTag(1002) as? UILabel

        let attrOfflineString = NSAttributedString (
            string: peers[indexPath.row].displayName,
            attributes: [NSForegroundColorAttributeName: UIColor.darkGrayColor(),
                NSFontAttributeName: UIFont.italicSystemFontOfSize(16)])
    
        let attrOnlineString = NSAttributedString (
            string: peers[indexPath.row].displayName,
            attributes: [NSForegroundColorAttributeName: UIColor.blackColor()])
        
        if status == false {
            indicator?.image = UIImage(named: "red-circle-16.png")
            peerLabel?.attributedText = attrOfflineString
        } else {
            indicator?.image = UIImage(named: "green-circle-16.png")
            peerLabel?.attributedText = attrOnlineString
        }
    
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "Block"
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let peer = peers[indexPath.row] as Peer
            coreDataHelper?.updatePeerBlockedStatus(peer, blocked: true)
            fetchAllAgain()
        }
    }
    
    // MARK: MCFManagerDelegate
    func mpcManagerAvailablePeers() {
        fetchAllAgain()
    }
   
    func mpcManagerConnectedPeer(connectedPeerId: MCPeerID) {
        self.connectedPeer = connectedPeerId
        conversationVC.connectedPeer = self.connectedPeer
    }
    
    func fetchAllAgain() {
        if let results = coreDataHelper?.fetchAllObjectsWithEntityName("Peer", includeBlocked: false) as? [Peer] {
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
                chattingVC.coreDataHelper = self.coreDataHelper
                
                let conversation = coreDataHelper?.fetchOrCreateConversation(mpcManager!.myPeerId, to: self.connectedPeer!)
                chattingVC.currentConversation = conversation
            }
            
        }

    }

    // MARK: NSNotification
    func notifyNewMessageDataNotification(notification: NSNotification) {
        view.makeToast("New message received", duration: 3.0, position: CSToastPositionCenter)
    }
}
