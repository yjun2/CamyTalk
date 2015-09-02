//
//  ChatViewController.swift
//  CamyTalk
//
//  Created by Yong Jun on 8/10/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChattingViewController: JSQMessagesViewController {

    var userName: String!
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    
    var mpcManager: MCFManager!
    var connectedPeer: MCPeerID?
    var currentConversation: Conversation!
    var coreDataHelper: CoreDataHelper!
    
    lazy var conversationTitle: String = {
       return self.currentConversation.title
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = userName
        self.senderDisplayName = mpcManager?.myPeerId.displayName
        self.senderId = mpcManager?.myPeerId.displayName
        self.automaticallyScrollsToMostRecentMessage = true
     
        // mark that all messages were received
        coreDataHelper?.updateConversationStatus(currentConversation, isMessagesAllReceived: true)
        
        if connectedPeer == nil {
            self.inputToolbar.contentView.textView.editable = false
            
            let msg = "\(userName) is not connected.  Message cannot be sent to \(userName)"
            view.makeToast(msg, duration: 3.0, position: CSToastPositionCenter)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleReceivedMessageDataNotification:",
            name: "receivedMessageDataNotification",
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "displayToast:",
            name: "peerStatusNotification",
            object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: "receivedMessageDataNotification",
            object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: "peerStatusNotification",
            object: nil)
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: JSQMessage delegate methods
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        var data = coreDataHelper.retrieveMessagesWithConversationTitle(conversationTitle)[indexPath.item]
        return data
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        var data = coreDataHelper.retrieveMessagesWithConversationTitle(conversationTitle)[indexPath.item]
        if data.senderId == self.senderId {
            return self.outgoingBubble
        } else {
            return self.incomingBubble
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return coreDataHelper.retrieveMessagesWithConversationTitle(conversationTitle).count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let data = coreDataHelper.retrieveMessagesWithConversationTitle(conversationTitle)[indexPath.item]
        
        // Sent by me, skip
        if data.senderId == self.senderId {
            return nil;
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = coreDataHelper.retrieveMessagesWithConversationTitle(conversationTitle)[indexPath.item - 1]
            if previousMessage.senderId == data.senderId {
                return nil;
            }
        }
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        let dateString = formatter.stringFromDate(NSDate())
        
        let attrString = NSAttributedString (
            string: dateString,
            attributes: [NSForegroundColorAttributeName: UIColor.darkGrayColor()])
        
        return attrString
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = coreDataHelper.retrieveMessagesWithConversationTitle(conversationTitle)[indexPath.item]
        
        // Sent by me, skip
        if message.senderId == self.senderId {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = coreDataHelper.retrieveMessagesWithConversationTitle(conversationTitle)[indexPath.item - 1]
            if previousMessage.senderId == message.senderId {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        let dateSent = NSDate()
        var message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        
        // save to core data
        coreDataHelper.addMessage(currentConversation, jsqMessage: message, sentDate: dateSent)
        
        if let cp = self.connectedPeer {
            mpcManager?.sendMessage(message.text, toPeer: cp, sentDate: dateSent)
        }
        
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
    }
    
    // MARK: NSNotification method
    func handleReceivedMessageDataNotification(notification: NSNotification) {
        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
        
        // mark that all messages were received
        coreDataHelper?.updateConversationStatus(currentConversation, isMessagesAllReceived: true)
        
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.finishReceivingMessage()
        })
    }
    
    // Mark: Toast method
    func displayToast(notification: NSNotification) {
        let messageData = notification.object as! Dictionary<String, AnyObject>
        if (connectedPeer?.displayName == (messageData["peer"] as? MCPeerID)?.displayName) {
            let isFound = messageData["isFound"] as! Bool
            changeTextViewStatus(isFound)
        }
        
        view.makeToast(messageData["message"] as? String, duration: 3.0, position: CSToastPositionCenter)
    }
    
    private func changeTextViewStatus(isFound: Bool) {
        if isFound {
            self.inputToolbar.contentView.textView.editable = true
        } else {
            self.inputToolbar.contentView.textView.editable = false
        }
    }
}
