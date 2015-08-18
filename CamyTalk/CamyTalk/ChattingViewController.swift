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
    var messages = [JSQMessage]()
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    
    var mpcManager: MCFManager?
    var connectedPeer: MCPeerID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = userName
        self.senderDisplayName = mpcManager?.myPeerId.displayName
        self.senderId = mpcManager?.myPeerId.displayName
        self.automaticallyScrollsToMostRecentMessage = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReceivedMessageDataNotification:", name: "receivedMessageDataNotification", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: "receivedMessageDataNotification",
            object: nil)
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: JSQMessage delegate methods
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        var data = self.messages[indexPath.item]
        return data
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        var data = self.messages[indexPath.item]
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
        return self.messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let data = messages[indexPath.item];
        
        // Sent by me, skip
        if data.senderId == self.senderId {
            return nil;
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
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
        let message = messages[indexPath.item]
        
        // Sent by me, skip
        if message.senderId == self.senderId {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.senderId == message.senderId {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        var message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        messages.append(message)
        
        // save the message to core data
        // TBD
        
        // send message using multipeer connectivity
        if let cp = self.connectedPeer {
            mpcManager?.sendMessage(message.text, toPeer: cp, sentDate: NSDate())
        }
        
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
    }
    
    // MARK: NSNotification method
    
    func handleReceivedMessageDataNotification(notification: NSNotification) {
        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
        
        let messageData = notification.object as! Dictionary<String, String>
        if let from = messageData["from"],
            message = messageData["message"] {
            
            let receivedMessage = JSQMessage(senderId: from, displayName: from, text: message)
            messages.append(receivedMessage)
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.finishReceivingMessage()
            })
        }
    }
}
