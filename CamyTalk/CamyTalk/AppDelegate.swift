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
        coreDataStack.saveContext()
        
        // change all peers to offline
        coreDataHelper.changeAllPeersToOffline()
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
        coreDataStack.saveContext()
    }

    
}

