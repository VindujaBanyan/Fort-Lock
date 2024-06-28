//
//  LockListModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 14/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation

class LockListModel: NSObject, NSCoding {
    var id: String!
    var lockname: String!
    var lock_keys: [UserLockRoleDetails]!
    var scratch_code: String!
    var serial_number: String!
    var uuid: String!
    var ssid: String!
    var status: String!
    var lock_owner_id: [LockOwnerDetailsModel]!
    var wasAddedOffline: Bool = false
    var battery:String = "100"
    var lockVersion: String!
    var is_secured: String = "0"
    var userPrivileges: String? = ""
    var enable_fp : String!
    var enable_pin : String!
    var enable_passage : String!
    
   func updatePassageModeState(isEnabled: Bool,lockId : String) {
            self.enable_passage = isEnabled ? "1" : "0"
        print("value is \(String(describing: self.enable_passage))")
//        if let lockIndex = self.lock_keys.firstIndex(where: { $0.lock_id == lockId }) {
//                self.lock_keys[lockIndex].enable_passage = self.enable_passage
//            }
        
        }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.lockname, forKey: "lockname")
        aCoder.encode(self.uuid, forKey: "uuid")
        aCoder.encode(self.id, forKey: "id")
        aCoder.encode(self.serial_number, forKey: "serial_number")
        aCoder.encode(self.lock_keys, forKey: "lock_keys")
        aCoder.encode(self.lock_owner_id, forKey: "lock_owner_id")
        aCoder.encode(self.scratch_code, forKey: "scratch_code")
        aCoder.encode(self.ssid, forKey: "ssid")
        aCoder.encode(self.status, forKey: "status")
        aCoder.encode(self.wasAddedOffline, forKey: "wasAddedOffline")
        aCoder.encode(self.battery, forKey: "battery")
        aCoder.encode(self.lockVersion, forKey: "lockVersion")
        aCoder.encode(self.userPrivileges, forKey: "user_privileges")
        aCoder.encode(self.is_secured, forKey: "is_secured")
        aCoder.encode(self.enable_fp, forKey: "enable_fp")
        aCoder.encode(self.enable_pin, forKey: "enable_pin")
        aCoder.encode(self.enable_passage, forKey: "enable_passage")
        

    }
    
    init(json: NSDictionary) { // Dictionary object
        self.lockname = json["lockname"] as? String
        self.uuid = json["uuid"] as? String // Location of the JSON file
        self.id = json["id"] as? String
//        if let enablePassage = json["enable_passage"] as? String {
//                self.enable_passage = enablePassage
//            print("~~~~~~~~~~\(enablePassage) of \(self.id)")
//            }
    }
    
    // MARK: - NSCoding
    
    required init(coder aDecoder: NSCoder) {
        self.lockname = aDecoder.decodeObject(forKey: "lockname") as? String
        self.uuid = aDecoder.decodeObject(forKey: "uuid") as? String
        self.id = aDecoder.decodeObject(forKey: "id") as? String
        self.serial_number = aDecoder.decodeObject(forKey: "serial_number") as? String
        self.lock_keys = aDecoder.decodeObject(forKey: "lock_keys") as? [UserLockRoleDetails]
        self.lock_owner_id = aDecoder.decodeObject(forKey: "lock_owner_id") as? [LockOwnerDetailsModel]
        self.scratch_code = aDecoder.decodeObject(forKey: "scratch_code") as? String
        self.ssid = aDecoder.decodeObject(forKey: "ssid") as? String
        self.status = aDecoder.decodeObject(forKey: "status") as? String
        self.wasAddedOffline = aDecoder.decodeBool(forKey: "wasAddedOffline")
        self.battery = aDecoder.decodeObject(forKey: "battery") as? String ?? "100"
        self.lockVersion = aDecoder.decodeObject(forKey: "lockVersion") as? String
        self.userPrivileges = aDecoder.decodeObject(forKey: "user_privileges") as? String
        self.is_secured = (aDecoder.decodeObject(forKey: "is_secured")) as? String ?? "0"
        self.enable_fp = (aDecoder.decodeObject(forKey: "enable_fp")) as? String
        self.enable_pin = (aDecoder.decodeObject(forKey: "enable_pin")) as? String
        self.enable_passage = (aDecoder.decodeObject(forKey: "enable_passage")) as? String
        
    }
}