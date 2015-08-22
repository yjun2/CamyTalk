//
//  Message.swift
//  CamyTalk
//
//  Created by Yong Jun on 8/12/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import Foundation
import CoreData

class Message: NSManagedObject {

    @NSManaged var sender: String
    @NSManaged var dateSent: NSDate
    @NSManaged var msg: String
    @NSManaged var conversation: Conversation

}
