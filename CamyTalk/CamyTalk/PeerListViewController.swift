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
    
    var peers = [Peer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Avaiilable Peers"
        
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
        
        // start the multipeer connectivity browser and advertiser
        mpcManager?.startServices()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)
        
        // this is just to simulate a peer is lost.
        // you would not want to stop the services because the view is disappered
        mpcManager?.stopServices()
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
        println("peer status: \(status)")
        
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
   
    func fetchAllAgain() {
        println("fetch all again")
        if let results = coreDataHelper?.fetchAll() {
            peers = results
            tableView.reloadData()
        }
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */

}
