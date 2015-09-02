//
//  CoreDataHelper.swift
//  CamyTalk
//
//  Created by Yong Jun on 7/29/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import Foundation
import CoreData
import MultipeerConnectivity

class CoreDataHelper {
    let managedContext: NSManagedObjectContext!
    
    init(managedContext: NSManagedObjectContext) {
        self.managedContext = managedContext
    }
    
    func changeOnlineStatus(peer: String, status: Bool) {
        let peerPredicate = NSPredicate(format: "displayName == %@", peer)
        
        let fetchRequest = NSFetchRequest(entityName: "Peer")
        fetchRequest.predicate = peerPredicate
        
        var error: NSError?
        let fetchResults = managedContext?.executeFetchRequest(fetchRequest, error: &error) as? [Peer]
        
        if let results = fetchResults {
            // there is always only one unique peer
            results[0].isOnline = status
            
            var error: NSError?
            if !managedContext!.save(&error) {
                println("Could not save: \(error)")
            }
            
        } else {
            println("Could not fetch \(error)")
        }
        
    }
    
    func fetchConversationWithTitle(title: String) -> Conversation? {
        let conversationPredicate = NSPredicate(format: "title == %@", title)
        
        let fetchRequest = NSFetchRequest(entityName: "Conversation")
        fetchRequest.predicate = conversationPredicate
        
        var error: NSError?
        let result = managedContext?.executeFetchRequest(fetchRequest, error: &error) as? [Conversation]
        
        if let conversations = result {
            return conversations[0]
        } else {
            return nil
        }
    }
    
    func fetchOrCreateConversation(from: MCPeerID, to: MCPeerID) -> Conversation? {
        
        // try fetching first
        let title = "\(from.displayName)_\(to.displayName)"
        let conversationPredicate = NSPredicate(format: "title == %@", title)
        
        let fetchRequest = NSFetchRequest(entityName: "Conversation")
        fetchRequest.predicate = conversationPredicate
        
        var error: NSError?
        let result = managedContext?.executeFetchRequest(fetchRequest, error: &error) as? [Conversation]
        
        if let conversations = result {
            if conversations.count == 0 { // no conversations found, persist a new conversation
                let conversationEntity = NSEntityDescription.entityForName("Conversation", inManagedObjectContext: managedContext!)
                let conversation = Conversation(entity: conversationEntity!, insertIntoManagedObjectContext: managedContext)
                conversation.title = title
                conversation.fromPeer = from.displayName
                conversation.toPeer = to.displayName
                
                var error: NSError?
                if !managedContext!.save(&error) {
                    println("Could not save: \(error)")
                } else {
                    println("A converation \(title) is saved")
                }
                
                return conversation
                
            } else { // found one.  return the found one
                println("found conversation: \(conversations[0].title)")
                return conversations[0]
            }
        } else {
            println("Could not fetch \(error)")
            return nil
        }
        
    }
    
    func addMessage(conversation: Conversation, jsqMessage: JSQMessage, sentDate: NSDate) {
        let messageEntity = NSEntityDescription.entityForName("Message", inManagedObjectContext: managedContext!)
        let message = Message(entity: messageEntity!, insertIntoManagedObjectContext: managedContext)
        message.sender = jsqMessage.senderDisplayName
        message.msg = jsqMessage.text
        message.dateSent = sentDate

        var msgs = conversation.messages.mutableCopy() as? NSMutableOrderedSet
        msgs?.addObject(message)
        
        conversation.messages = msgs?.copy() as! NSOrderedSet
        
        var error: NSError?
        if !managedContext!.save(&error) {
            println("Could not save: \(error)")
        }
    }
    
    func retrieveMessagesWithConversationTitle(conversationTitle: String) -> [JSQMessage] {
        let conversationPredicate = NSPredicate(format: "title == %@", conversationTitle)
        
        let fetchRequest = NSFetchRequest(entityName: "Conversation")
        fetchRequest.predicate = conversationPredicate
        
        var error: NSError?
        let result = managedContext?.executeFetchRequest(fetchRequest, error: &error) as? [Conversation]
        
        var jsqMessages = [JSQMessage]()
        if let conversations = result {
            let conversation = conversations[0]
            let messages = conversation.messages.array as! [Message]
            for message in messages {
                let jsqMessage = JSQMessage(senderId: message.sender, displayName: message.sender, text: message.msg )
                jsqMessages.append(jsqMessage)
            }   
        }
        
        return jsqMessages
        
    }
    
    func changeAllPeersToOffline() {
        let peers = fetchAllObjectsWithEntityName("Peer") as [Peer]
        for peer in peers {
            changeOnlineStatus(peer.displayName, status: false)
        }
    }
    
    func fetchPeerCount(peer: MCPeerID) -> Int? {
        let peerPredicate = NSPredicate(format: "displayName == %@", peer.displayName)
        
        let fetchRequest = NSFetchRequest(entityName: "Peer")
        fetchRequest.predicate = peerPredicate
        
        var error: NSError?
        let count = managedContext?.countForFetchRequest(fetchRequest, error: &error)
        
        if count == NSNotFound {
            println("Could not fetch \(error)")
        }
        
        return count
    }
    
    func savePeer(newPeer: MCPeerID) {
        let peerEntity = NSEntityDescription.entityForName("Peer", inManagedObjectContext: managedContext!)
        let peer = Peer(entity: peerEntity!, insertIntoManagedObjectContext: managedContext)
        peer.displayName = newPeer.displayName
        peer.isBlocked = false
        peer.dateLastConnected = NSDate()
        peer.isOnline = true
        
        var error: NSError?
        if !managedContext!.save(&error) {
            println("Could not save: \(error)")
        } else {
            println("A peer \(newPeer.displayName) saved")
        }
    }
    
    func updatePeerBlockedStatus(peer: Peer, blocked: Bool) {
        peer.isBlocked = blocked
        
        var error: NSError?
        if !managedContext!.save(&error) {
            println("Could not save: \(error)")
        } else {
            println("\(peer.displayName) isBlocked status is changed to \(blocked.boolValue)")
        }
    }
    
    func updateConversationStatus(conversation: Conversation, isMessagesAllReceived: Bool) {
        conversation.messagesAllReceived = isMessagesAllReceived
        
        var error: NSError?
        if !managedContext!.save(&error) {
            println("Could not save: \(error)")
        }
    }
    
    func fetchPeer(displayName: String) -> Peer? {
        let peerPredicate = NSPredicate(format: "displayName == %@", displayName)
        
        let fetchRequest = NSFetchRequest(entityName: "Peer")
        fetchRequest.predicate = peerPredicate
        
        var error: NSError?
        let peers = managedContext?.executeFetchRequest(fetchRequest, error: &error) as? [Peer]
        
        if let peers = peers {
            return peers[0]
        } else {
            return nil
        }


    }
    
    func fetchAllObjectsWithEntityName<T: NSManagedObject>(entityName: String, includeBlocked: Bool? = nil) -> [T] {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        if let blockedPeer = includeBlocked {
            let blockedPredicate = NSPredicate(format: "isBlocked = %@", blockedPeer)
            fetchRequest.predicate = blockedPredicate
        }
        
        var error: NSError?
        let fetchResults = managedContext?.executeFetchRequest(fetchRequest, error: &error) as? [T]
        
        if let results = fetchResults {
            return results
        } else {
            return [T]()
        }
    }

}