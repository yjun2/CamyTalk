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
    
    func changeAllPeersToOffline() {
        if let peers = fetchAll() {
            for peer in peers {
                changeOnlineStatus(peer.displayName, status: false)
            }
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
    
    func fetchAll() -> [Peer]? {
        let fetchRequest = NSFetchRequest(entityName: "Peer")
        
        var error: NSError?
        let fetchResults = managedContext?.executeFetchRequest(fetchRequest, error: &error) as? [Peer]
        
        if let results = fetchResults {
            return results
        } else {
            println("Could not fetch \(error)")
            return nil
        }
        
    }

}