//
//  LockWifiApiTransformer.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/16/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
class LockWifiApiTransformer {
    static func transformActivateResponseToLockHardwareData(response:[String:AnyObject]) -> LockHardwareDetails{
        let lockHardwareDetails = LockHardwareDetails()
        if response.keys.count == 0{
            return lockHardwareDetails
        }
        // Addlock isSecured for oener ids are always true
        // Encrypt lockOwnerIds also
        let encryptedOwnerID0 = Utilities().convertStringToEncryptedString(plainString: response["owner-id-0"] as? String ?? "", isSecured: true)
        let encryptedOwnerID1 = Utilities().convertStringToEncryptedString(plainString: response["owner-id-1"] as? String ?? "", isSecured: true)

        lockHardwareDetails.lockOwnerIds.append(encryptedOwnerID0)
        lockHardwareDetails.lockOwnerIds.append(encryptedOwnerID1)
        for i in 0..<24 {
            var slotIdAsString = ""
            let slotDictKey = "slot-key-\(i)"
            let response = response[slotDictKey] as? String
            if i<10{
                slotIdAsString = String("0\(i)")
            }
            else{
                slotIdAsString = String("\(i)")
            }
            // Addlock isSecured for slot keys are always true
            // Encrypt slot key value and then store in local
            let encryptedSlotKey = Utilities().convertStringToEncryptedString(plainString: response ?? "", isSecured: true)
            let slotKey = SlotKey(slotId: slotIdAsString, slotKey: encryptedSlotKey)
            lockHardwareDetails.slotKeyArray.append(slotKey)
        }
        lockHardwareDetails.macAddress = response["mac-addr"] as! String
        if let version = response["HW-Version"] {
            debugPrint("version avail")
            lockHardwareDetails.lockVersion = (version as? String != nil) ? version as! String : "v1.0"
        } else {
            debugPrint("version not")
            lockHardwareDetails.lockVersion = "v1.0"
        }
        lockHardwareDetails.lockAdvertisementData = nil
        return lockHardwareDetails
    }
}


