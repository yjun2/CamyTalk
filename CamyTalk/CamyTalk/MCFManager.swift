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
    func mpcManagerConnectedPeer(connectedPeerId: MCPeerID)
}

class MCFManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    let SERVIVCE_TYPE = "camytalk"
    
    var coreDataHelper: CoreDataHelper?
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
                println("Connected to \(peerID.displayName)")
                delegate?.mpcManagerConnectedPeer(peerID)
            case .Connecting:
                println("Connecting to \(peerID.displayName)")
            case .NotConnected:
                println("Not connected: \(peerID.displayName)")
                coreDataHelper?.changeAllPeersToOffline()
                delegate?.mpcManagerAvailablePeers()
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        
        let message = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        println("Received message from peer: \(peerID.displayName), message: \(message)")
        
        let messageDict: [String: String] = ["from": peerID.displayName, "message": message]
        NSNotificationCenter.defaultCenter().postNotificationName("receivedMessageDataNotification", object: messageDict)
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {}
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {}
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {}
    
    // MARK: Browser delegate
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        println("found peer id: \(peerID.displayName)")
        
        // fetch core data to see if the peer is already saved
        if let count = coreDataHelper?.fetchPeerCount(peerID) {
            if count == 0 { // not saved in core data yet
                println("adding new peer '\(peerID.displayName)' to core data")
                coreDataHelper?.savePeer(peerID)
            } else {
                println("\(peerID.displayName) already exist in core data")
                
                // change the online status to true
                coreDataHelper?.changeOnlineStatus(peerID.displayName, status: true)
            }
        }
        
        // invite peer
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 10)
        
        delegate?.mpcManagerAvailablePeers()
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        
        println("lost peer id: \(peerID.displayName)")
        coreDataHelper?.changeOnlineStatus(peerID.displayName, status: false)
        
        // end session
        println("disconnecting session")
        session?.disconnect()
        
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
    
    // MARK: MCFManager methods
    func sendMessage(message: String, toPeer: MCPeerID, sentDate: NSDate) -> Bool {
        let data = (message as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        let toPeersArray = [toPeer]
        var error: NSError?
        
        println("sent message: \(message); to: \(toPeer.displayName)")
        if let dataString = data {
            if session?.sendData(dataString, toPeers: toPeersArray, withMode: MCSessionSendDataMode.Unreliable, error: &error) == nil {
                println(error?.description)
                return false
            }
        }
        
        return true
    }

    
}

