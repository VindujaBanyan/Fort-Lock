//
//  UserLockRoleDetails.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 16/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation

class UserLockRoleDetails: NSObject, NSCoding, Codable {
    
    var id: String!
    var lock_id: String!
    var user_type: String!
    var key: String!
    var slot_number: String!
    var status: String!
    var is_schedule_access: String!
    var schedule_date_from: String!
    var schedule_date_to: String!
    var schedule_time_from: String!
    var schedule_time_to: String!
    var userID: String!
    //var enable_passage : String!
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: "id");
        aCoder.encode(self.lock_id, forKey: "lock_id");
        aCoder.encode(self.key, forKey: "key");
        aCoder.encode(self.user_type, forKey: "user_type");
        aCoder.encode(self.slot_number, forKey: "slot_number");
        aCoder.encode(self.status, forKey: "status");
        aCoder.encode(self.is_schedule_access, forKey: "is_schedule_access");
        aCoder.encode(self.schedule_date_from, forKey: "schedule_date_from");
        aCoder.encode(self.schedule_date_to, forKey: "schedule_date_to");
        aCoder.encode(self.schedule_time_from, forKey: "schedule_time_from");
        aCoder.encode(self.schedule_time_to, forKey: "schedule_time_to");
        aCoder.encode(self.userID, forKey: "user_id");
        //aCoder.encode(self.enable_passage, forKey: "enable_passage");

    }
    
    init(json: NSDictionary) { // Dictionary object
        self.id = json["id"] as? String
        self.lock_id = json["lock_id"] as? String // Location of the JSON file
        self.user_type = json["user_type"] as? String
        //self.enable_passage = json["enable_passage"] as? String
    }
    
    required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: "id") as? String;
        self.user_type = aDecoder.decodeObject(forKey: "user_type") as? String;
        self.slot_number = aDecoder.decodeObject(forKey: "slot_number") as? String;
        self.key = aDecoder.decodeObject(forKey: "key") as? String;
        self.lock_id = aDecoder.decodeObject(forKey: "lock_id") as? String
        self.status = aDecoder.decodeObject(forKey: "status") as? String
        self.is_schedule_access = aDecoder.decodeObject(forKey: "is_schedule_access") as? String
        self.schedule_date_from = aDecoder.decodeObject(forKey: "schedule_date_from") as? String
        self.schedule_date_to = aDecoder.decodeObject(forKey: "schedule_date_to") as? String
        self.schedule_time_from = aDecoder.decodeObject(forKey: "schedule_time_from") as? String
        self.schedule_time_to = aDecoder.decodeObject(forKey: "schedule_time_to") as? String
        self.userID = aDecoder.decodeObject(forKey: "user_id") as? String
       // self.enable_passage = aDecoder.decodeObject(forKey: "enable_passage") as? String
    }

    func isTypeOwnerID() -> Bool {
        if user_type == "OwnerID"{
            return true
        }
        else{
            return false
        }
    }

    func isTypeOwnerKey() -> Bool {
        if user_type == "OwnerID"{
            return true
        }
        else{
            return false
        }
    }

    func userRoleType() -> UserRoles {
        if user_type.lowercased() == "owner"{
            return UserRoles.owner
        }
        else if user_type.lowercased() == "master"{
            return UserRoles.master
        }
        else if user_type.lowercased() == "user"{
            return UserRoles.user
        }
        return .ownerid

    }
}
