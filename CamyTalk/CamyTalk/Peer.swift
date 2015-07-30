//
//  Peer.swift
//  CamyTalk
//
//  Created by Yong Jun on 7/28/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import Foundation
import CoreData

class Peer: NSManagedObject {

    @NSManaged var displayName: String
    @NSManaged var isBlocked: NSNumber
    @NSManaged var dateLastConnected: NSDate
    @NSManaged var isOnline: NSNumber

}
