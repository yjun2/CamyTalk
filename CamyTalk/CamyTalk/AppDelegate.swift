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
        // Configure tracker from Google Analytics
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        var gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true
        gai.logger.logLevel = GAILogLevel.Verbose
        
        // initialize CoreDataHelper
        mpcManager.coreDataHelper = coreDataHelper
        
        // start the multipeer connectivity browser and advertiser
        mpcManager.startServices()
        
        let tabBarController = self.window!.rootViewController as! UITabBarController
        let navController = tabBarController.childViewControllers[0] as! UINavigationController
        let viewController = navController.topViewController as! PeerListViewController
        viewController.mpcManager = mpcManager
        viewController.coreDataHelper = coreDataHelper
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound |
            UIUserNotificationType.Alert | UIUserNotificationType.Badge, categories: nil))
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        coreDataStack.saveContext()
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }
    
    func applicationWillTerminate(application: UIApplication) {
        coreDataStack.saveContext()
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if application.applicationState == .Active {
            NSNotificationCenter.defaultCenter().postNotificationName("newMessageDataNotification", object: nil)
        }
        
        
    }
}

