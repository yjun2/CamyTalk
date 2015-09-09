//
//  ConversationTableViewController.swift
//  
//
//  Created by Yong Jun on 8/10/15.
//
//

import UIKit
import CoreData
import MultipeerConnectivity

class ConversationTableViewController: UITableViewController {

    var coreDataHelper: CoreDataHelper?
    var mpcManager: MCFManager?
    var connectedPeer: MCPeerID?
    
    var conversations = [Conversation]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Conversations"
        
        if let results = coreDataHelper?.fetchAllObjectsWithEntityName("Conversation") as? [Conversation] {
            conversations = results
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Track this controller using Google Analytics
        var tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Conversation View Controller")
        
        var builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "displayToast:",
            name: "peerStatusNotification",
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "notifyNewMessageDataNotification:",
            name: "newMessageDataNotification",
            object: nil)
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: "peerStatusNotification",
            object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: "newMessageDataNotification",
            object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("Conversation", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = conversations[indexPath.row].toPeer
        
        let latestMsgIndex = coreDataHelper?.retrieveMessagesWithConversationTitle(conversations[indexPath.row].title).count
        let message = conversations[indexPath.row].messages[latestMsgIndex! - 1] as? Message
        cell.detailTextLabel?.text = message?.msg
        
        var badge = MLPAccessoryBadge()
        badge.cornerRadius = 100
        badge.setText("New")
        badge.backgroundColor = UIColor.redColor()
        
        let didReceiveAllMessages = conversations[indexPath.row].messagesAllReceived
        if didReceiveAllMessages == false {
            cell.accessoryView = badge
        } else {
            cell.accessoryView = nil
        }
        

        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toChatVC" {
            let chattingVC = segue.destinationViewController as! ChattingViewController
            chattingVC.hidesBottomBarWhenPushed = true
            
            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
                chattingVC.mpcManager = self.mpcManager
                chattingVC.userName = conversations[indexPath.row].toPeer
                chattingVC.connectedPeer = self.connectedPeer
                chattingVC.coreDataHelper = self.coreDataHelper
                
                let conversation = coreDataHelper!.fetchConversationWithTitle(conversations[indexPath.row].title)
                chattingVC.currentConversation = conversation
            }
        }
    }
    
    // Mark: Toast method
    func displayToast(notification: NSNotification) {
        let messageData = notification.object as! Dictionary<String, AnyObject>
        if let msg = messageData["message"] as? String {
            view.makeToast(msg, duration: 3.0, position: CSToastPositionCenter)
        }
    }
    
    func notifyNewMessageDataNotification(notification: NSNotification) {
        view.makeToast("New message received", duration: 3.0, position: CSToastPositionCenter)
        tableView.reloadData()
    }

}
