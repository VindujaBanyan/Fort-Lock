//
//  LockOwnerDetailsModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 29/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation

class LockOwnerDetailsModel: NSObject, NSCoding, Codable {
    var id: String!
    var slot_number: String!
    var lock_id: String!
    var user_type: String!
    var status: String!
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: "id")
        aCoder.encode(self.slot_number, forKey: "slot_number")
        aCoder.encode(self.lock_id, forKey: "lock_id")
        aCoder.encode(self.user_type, forKey: "user_type")
        aCoder.encode(self.status, forKey: "status")
    }
    
    init(json: NSDictionary) { // Dictionary object
        self.id = json["id"] as? String
        self.slot_number = json["slot_number"] as? String
        self.lock_id = json["lock_id"] as? String
        self.user_type = json["user_type"] as? String
        self.id = json["id"] as? String
    }
    
    // MARK: - NSCoding
    
    required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: "id") as? String
        self.slot_number = aDecoder.decodeObject(forKey: "slot_number") as? String
        self.lock_id = aDecoder.decodeObject(forKey: "lock_id") as? String
        self.user_type = aDecoder.decodeObject(forKey: "user_type") as? String
        self.status = aDecoder.decodeObject(forKey: "status") as? String
    }
}
