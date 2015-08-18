//
//  AppDelegate.swift
//  CamyTalk
//
//  Created by Yong Jun on 7/27/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coreDataStack = CoreDataStack()
    let mpcManager = MCFManager()
    lazy var coreDataHelper: CoreDataHelper = {
        return CoreDataHelper(managedContext: self.coreDataStack.getCoreDataContext())
    }()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // initialize CoreDataHelper
        mpcManager.coreDataHelper = coreDataHelper
        
        // start the multipeer connectivity browser and advertiser
        mpcManager.startServices()
        
        let tabBarController = self.window!.rootViewController as! UITabBarController
        let navController = tabBarController.childViewControllers[0] as! UINavigationController
        let viewController = navController.topViewController as! PeerListViewController
        viewController.mpcManager = mpcManager
        viewController.coreDataHelper = coreDataHelper
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // change all peers to offline
        coreDataHelper.changeAllPeersToOffline()
        
        coreDataStack.saveContext()
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }
    
    func applicationWillTerminate(application: UIApplication) {
        
        // change all peers to offline
        coreDataHelper.changeAllPeersToOffline()
        
        coreDataStack.saveContext()
    }

    
}

