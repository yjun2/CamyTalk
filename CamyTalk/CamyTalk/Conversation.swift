//
//  Conversation.swift
//  CamyTalk
//
//  Created by Yong Jun on 8/12/15.
//  Copyright (c) 2015 Yong Jun. All rights reserved.
//

import Foundation
import CoreData

class Conversation: NSManagedObject {

    @NSManaged var fromPeer: String
    @NSManaged var toPeer: String
    @NSManaged var title: String
    @NSManaged var messages: NSOrderedSet
    @NSManaged var peer: Peer

}
