//
//  LockHardwareDetails.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/16/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation

class LockHardwareDetails {
    var lockOwnerIds: [String] = []
    var slotKeyArray: [SlotKey] = []
    var macAddress:String = ""
    var lockVersion: String = ""
    var batteryLevel:String = ""
    var lockAdvertisementData:BluetoothAdvertismentData?
    var ssid:String = ""
    init() {
    }
    
    func lockOwnerIdForWifi() -> String? {
        if lockOwnerIds.count > 0 {
            return lockOwnerIds[0]
        }
        return nil
    }
    
    func lockOwnerKeyForWifi() -> String? {
        if slotKeyArray.count > 0 {
            let key = slotKeyArray.first{$0.slotId == "00"}
            return key?.slotKey
        }
        return nil
    }
    
    func lockOwnerIdAsKVPair() -> [[String:String]] {
        var dictionary: [String:String] = [:]
        dictionary["key"] = lockOwnerIds[0]
        dictionary["slot_number"] = "00"
        
        var dictionary1: [String:String] = [:]
        dictionary1["key"] = lockOwnerIds[1]
        dictionary1["slot_number"] = "01"
        return [dictionary,dictionary1]
    }
    
    func slotDataAsKVPair() -> [[String:String]] {
        let array = slotKeyArray.map { (slotKey) in
            return ["slot_number" : slotKey.slotId,
                    "key" : slotKey.slotKey]
        }
        return array
    }
    
    func convertToLockListModel(lockName:String,scratchCode:String) -> AddLockModel{
        let lockDetails = LockListModel(json: [:])
        
        
        let lockOwnerIdObj = LockOwnerDetailsModel(json: [:])
        lockOwnerIdObj.user_type = "Owner"
        lockOwnerIdObj.status = "0"
        lockOwnerIdObj.lock_id = ""
        lockOwnerIdObj.id = ""
        lockOwnerIdObj.slot_number = ""
        
        lockDetails.lock_owner_id = [lockOwnerIdObj]
        debugPrint("lockDetails.lock_owner_id===>>> \(String(describing: lockDetails.lock_owner_id))")
        lockDetails.lockname = lockName
        lockDetails.uuid = self.macAddress
        lockDetails.ssid = self.ssid
        lockDetails.scratch_code = scratchCode
        lockDetails.serial_number = self.ssid
        lockDetails.status = "2"
        lockDetails.is_secured = "1"
        
        // owner id
        let lockKeysObj1 = UserLockRoleDetails(json: [:])
        lockKeysObj1.user_type = "OwnerID"
        lockKeysObj1.key = ""
        lockKeysObj1.lock_id = ""
        lockKeysObj1.id = ""
        lockKeysObj1.slot_number = ""
        lockKeysObj1.status = "0"
        lockKeysObj1.is_schedule_access = "0"
        lockKeysObj1.schedule_date_from = ""
        lockKeysObj1.schedule_date_to = ""
        lockKeysObj1.schedule_time_from = ""
        lockKeysObj1.schedule_time_to = ""

        
        
        // user type to access key(owner/master/user)
        let lockKeysObj2 = UserLockRoleDetails(json: [:])
        lockKeysObj2.user_type = "Owner"
        lockKeysObj2.key = ""
        lockKeysObj2.lock_id = ""
        lockKeysObj2.id = ""
        lockKeysObj2.slot_number = ""
        lockKeysObj2.status = "0"
        lockKeysObj2.is_schedule_access = "0"
        lockKeysObj2.schedule_date_from = ""
        lockKeysObj2.schedule_date_to = ""
        lockKeysObj2.schedule_time_from = ""
        lockKeysObj2.schedule_time_to = ""
        
        
        var lockKeysArray = [UserLockRoleDetails]()
        lockKeysArray.append(lockKeysObj1)
        lockKeysArray.append(lockKeysObj2)
        
        lockDetails.lock_keys = lockKeysArray
        
        let addLockObj = AddLockModel(json: [:])
        addLockObj.lockListDetails = lockDetails
        
        let ownerIDArray = ["00", "01"]
        let keyArray = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"]
        let lockIDSlotArray: NSMutableArray = []
        let lockKeysSlotArray: NSMutableArray = []
        
        for i in 0..<ownerIDArray.count {
            let tempDict = ["key":lockOwnerIds[i],"slot_number":String(i)]
            lockIDSlotArray.add(tempDict)
        }
        
        for i in 0..<keyArray.count {
            let slotKey = slotKeyArray[i]
            let tempDict = ["key":slotKey.slotKey,"slot_number":String(i)]
            lockKeysSlotArray.add(tempDict)
        }
        addLockObj.lock_ids = lockIDSlotArray
        debugPrint("addLockObj.lock_ids===>>> \(addLockObj.lock_ids)")
        addLockObj.lock_keys = lockKeysSlotArray
        debugPrint("convertToLockListModel")
        debugPrint("addLockObj.lock_keys ====>>> \(addLockObj.lock_keys)")
        
        addLockObj.lockListDetails.lockVersion = lockVersion
        addLockObj.lockListDetails.is_secured = "1"
        return addLockObj
        
    }
}
