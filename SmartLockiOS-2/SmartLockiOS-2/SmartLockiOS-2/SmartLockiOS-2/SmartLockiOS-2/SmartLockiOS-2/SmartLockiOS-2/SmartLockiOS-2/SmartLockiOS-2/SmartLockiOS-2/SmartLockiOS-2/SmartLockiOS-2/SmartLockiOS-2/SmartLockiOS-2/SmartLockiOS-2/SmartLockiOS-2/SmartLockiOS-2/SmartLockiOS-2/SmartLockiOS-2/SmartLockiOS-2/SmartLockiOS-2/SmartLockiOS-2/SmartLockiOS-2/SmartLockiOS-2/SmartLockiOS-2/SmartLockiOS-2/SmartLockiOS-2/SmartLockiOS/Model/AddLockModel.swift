//
//  AddLockModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 20/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation

class AddLockModel: NSObject, NSCoding {
    var lockListDetails: LockListModel!
    var lock_ids: NSMutableArray!
    var lock_keys: NSMutableArray!
//    var keys: [String]!
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.lockListDetails, forKey: "lockListDetails")
        aCoder.encode(self.lock_ids, forKey: "lock_ids")
        aCoder.encode(self.lock_keys, forKey: "lock_keys")
//        aCoder.encode(self.keys, forKey: "keys")
        
    }
    
    init(json: NSDictionary) { // Dictionary object
        self.lockListDetails = json["lockListDetails"] as? LockListModel
        self.lock_ids = json["lock_ids"] as? NSMutableArray // Location of the JSON file
        self.lock_keys = json["lock_keys"] as? NSMutableArray
//        self.keys = json["keys"] as? [String]
    }
    
    required init(coder aDecoder: NSCoder) {
        self.lockListDetails = aDecoder.decodeObject(forKey: "lockListDetails") as? LockListModel
        self.lock_ids = aDecoder.decodeObject(forKey: "lock_ids") as? NSMutableArray
        self.lock_keys = aDecoder.decodeObject(forKey: "lock_keys") as? NSMutableArray
//        self.keys = aDecoder.decodeObject(forKey: "keys") as? [String]
    }
}
