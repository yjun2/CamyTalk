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
    
    var peers = [Peer]()
    var status: String = "Not connected"
    
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
        
        // Track this controller using Google Analytics
        var tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Peer Listview Controller")
        
        var builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
        
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
        
        let rowPeer = peers[indexPath.row].displayName
        let peerLabel = cell.viewWithTag(1000) as? UILabel
        peerLabel?.text = rowPeer
        
        let lastConnectLabel = cell.viewWithTag(1002) as? UILabel
        lastConnectLabel?.text = formatDate(peers[indexPath.row].dateLastConnected)
        
        let statusLabel = cell.viewWithTag(1003) as? UILabel
        
        if self.connectedPeer?.displayName == rowPeer {
            if self.status == "Not connected" {
                statusLabel?.attributedText = attrOfflineString(self.status)
                cell.backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0)
            } else {
                statusLabel?.attributedText = attrOnlineString(self.status)
                cell.backgroundColor = UIColor.whiteColor()
            }
        } else {
            statusLabel?.attributedText = attrOfflineString("Not connected")
            cell.backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0)
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
    func mpcManagerAvailablePeers(status: String) {
        self.status = status
        fetchAllAgain()
    }
   
    func mpcManagerConnectedPeer(connectedPeerId: MCPeerID, status: String) {
        self.connectedPeer = connectedPeerId
        self.status = status
        conversationVC.connectedPeer = self.connectedPeer
        fetchAllAgain()
        
        // Send an event to Google analytics
        var tracker = GAI.sharedInstance().defaultTracker
        
        var builder = GAIDictionaryBuilder.createEventWithCategory("Connect Peer", action: "Found peer", label: "Connect", value: nil)
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    func fetchAllAgain() {
        if let results = coreDataHelper?.fetchAllObjectsWithEntityName("Peer", includeBlocked: false) as? [Peer] {
            peers = results
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.tableView.reloadData()
        })
        
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
    
    // MARK: private methods
    private func attrOfflineString(str: String) -> NSAttributedString {
        let offlineString = NSAttributedString (
            string: str,
            attributes: [NSForegroundColorAttributeName: UIColor.redColor(),
                NSFontAttributeName: UIFont.italicSystemFontOfSize(14)])
        
        return offlineString
    }
    
    private func attrOnlineString(str: String) -> NSAttributedString {
        let onlineString = NSAttributedString (
            string: str,
            attributes: [NSForegroundColorAttributeName: UIColor.blueColor()])
        
        return onlineString
    }
    
    private func formatDate(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        formatter.timeStyle = .ShortStyle
        
        let dateString = formatter.stringFromDate(date)
        
        return dateString
    }
}
