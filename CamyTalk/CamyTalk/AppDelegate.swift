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
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        println("app entered background")
        coreDataStack.saveContext()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        println("app entered foreground")
    }

    func applicationDidBecomeActive(application: UIApplication) {

    }

    func applicationWillTerminate(application: UIApplication) {
        println("app terminated")
        coreDataStack.saveContext()
    }

}

