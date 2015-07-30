//
//  MCFManager.swift
//  CamyTalk
//
//  Created by Yong Jun on 7/27/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreData

protocol MCFManagerDelegate: class {
    func mpcManagerAvailablePeers()
}

class MCFManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    let SERVIVCE_TYPE = "camytalk"
    
    var managedContext: NSManagedObjectContext?
    
    var session: MCSession?
    var browser: MCNearbyServiceBrowser?
    var advertiser: MCNearbyServiceAdvertiser?
    weak var delegate: MCFManagerDelegate?
    
    lazy var myPeerId: MCPeerID = {
        let peerId = MCPeerID(displayName: UIDevice.currentDevice().name)
        return peerId
    }()
    
    override init() {
        super.init()
        
        // initialize session
        session = MCSession(peer: myPeerId)
        session?.delegate = self
        
        // initialize browser
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: SERVIVCE_TYPE)
        browser?.delegate = self
        
        // initialize advertiser
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: SERVIVCE_TYPE)
        advertiser?.delegate = self
    }
    
    // MARK: MCFManager methods
    func startServices() {
        
        // start browser
        browser?.startBrowsingForPeers()
        println("brower started on \(myPeerId.displayName)...")
        
        // start advertiser
        advertiser?.startAdvertisingPeer()
        println("advertiser started on \(myPeerId.displayName)...")
    }
    
    func stopServices() {
        
        // stop browser
        browser?.stopBrowsingForPeers()
        println("browser stopped on \(myPeerId.displayName)...")
        
        // stop advertiser
        advertiser?.stopAdvertisingPeer()
        println("advertiser stopped on \(myPeerId.displayName)...")
    }
    
    // MARK: MCSessionDelegate
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch state {
            case .Connected:
                println("connected to \(peerID.displayName)")
            case .Connecting:
                println("Connecting to \(peerID.displayName)")
            default:
                println("Did not connect to session: \(session)")
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {}
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {}
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {}
    
    // MARK: Browser delegate
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        println("found peer id: \(peerID.displayName)")
        
        // fetch core data to see if the peer is already saved
        if let count = fetchPeerCount(peerID) {
            if count == 0 { // not saved in core data yet
                println("adding new peer '\(peerID.displayName)' to core data")
                savePeer(peerID)
            } else {
                println("\(peerID.displayName) already exist in core data")
                
                // change the online status to true
                changeOnlineStatus(peerID, status: true)
            }
        }
        
        // invite peer
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 10)
        
        delegate?.mpcManagerAvailablePeers()
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        println("lost peer id: \(peerID.displayName)")
        
        changeOnlineStatus(peerID, status: false)
        delegate?.mpcManagerAvailablePeers()
    }
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        println("Browser did not start: \(error)")
    }
    
    // MARK: Advertiser delegate
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        
        invitationHandler(true, session)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println("Advertiser did not start: \(error)")
    }
    
    // MARK: Core Data
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
    
    func changeOnlineStatus(peer: MCPeerID, status: Bool) {
        let peerPredicate = NSPredicate(format: "displayName == %@", peer.displayName)
        
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
            } else {
                println("Peer online status changed to \(status)")
            }
            
        } else {
            println("Could not fetch \(error)")
        }

    }

}

