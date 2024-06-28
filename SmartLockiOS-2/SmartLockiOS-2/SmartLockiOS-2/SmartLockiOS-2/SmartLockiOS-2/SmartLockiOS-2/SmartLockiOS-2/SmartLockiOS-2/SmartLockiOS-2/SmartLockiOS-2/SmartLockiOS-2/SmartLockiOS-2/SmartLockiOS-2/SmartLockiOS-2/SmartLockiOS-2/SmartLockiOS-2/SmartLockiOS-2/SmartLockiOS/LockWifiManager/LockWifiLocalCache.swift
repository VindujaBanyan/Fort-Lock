//
//  LockWifiLocalCache.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/17/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
class LockWifiLocalCache {

    func saveNewOwnerId(newOwnerId:String,oldOwnerId:String,lockSerialNumber:String) {
        debugPrint("saveNewOwnerId")
        var lockDictionary = dictionaryForLock(serialNumber:lockSerialNumber)
        var dictionary:[String:String] =  [:]
        dictionary["new_owner_id"] = newOwnerId
        dictionary["old_owner_id"] = oldOwnerId
       lockDictionary["ownerIdUpdate"] = dictionary
        setDictionaryForLock(lockDict: lockDictionary, serialNumber: lockSerialNumber)
        var tobeUpdatedOwnerIdArray = ownerIdsToBeUpdated()
        if tobeUpdatedOwnerIdArray.contains(lockSerialNumber) == false{
        tobeUpdatedOwnerIdArray.append(lockSerialNumber)
        }
        debugPrint("tobeUpdatedOwnerIdArray ==> \(tobeUpdatedOwnerIdArray)")
        setOwnerIdsToBeUpdated(lockSerialNumberArray: tobeUpdatedOwnerIdArray)
        debugPrint("---------- ------------ ----------")
    }

    func checkAndUpdateOwnerId(completion: @escaping (Bool) -> Void) {
        //key - new owner id, keyid = lock_owner_id's id ==> for revoke user/master and owner
        debugPrint("checkAndUpdateOwnerId ==>  lock first engage")
        if UserDefaults.standard.bool(forKey: "requires_owner_update") == true {
            LoaderView.sharedInstance.showShadowView(title: "Loading...", isFromNotifiation: false)
            let lockSerialNumberArray = ownerIdsToBeUpdated()
            for lockSerialNumber in lockSerialNumberArray{
                let lockDictionary = dictionaryForLock(serialNumber: lockSerialNumber)
                let ownerIdUpdateDictionary = lockDictionary["ownerIdUpdate"]!
                let key = ownerIdUpdateDictionary["new_owner_id"] as String?
                let keyId = ownerIdUpdateDictionary["old_owner_id"] as String?
                let urlString = ServiceUrl.BASE_URL + "keys/updatekey?id=\(keyId!)"
                
                let userDetailsDict = [
                    "user_id": "",
                    "key": key!,
                    "status": "0",
                    ]
                
                var userDetails = [String: String]()
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
                    
                    let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
                    
                    if let dictFromJSON = decoded as? [String: String] {
                        userDetails = dictFromJSON
                        //print("dictFromJSON ==> \(dictFromJSON)")
                    }
                } catch {
                    //print(error.localizedDescription)
                }
                
                debugPrint("urlString ==> \(urlString)")
                debugPrint("userDetails ==> \(userDetails)")
                debugPrint("update key ==>> checkAndUpdateOwnerId")
                
                AssignUsersViewModel().revokeRequestUserServiceViewModel(url: urlString, userDetails: userDetails, serialNumber: lockSerialNumber, callback: { [unowned self](result, error, serialNumber) in
                    LoaderView.sharedInstance.hideShadowview()
                    if result != nil {
                        debugPrint("owner key updated")
                        
                        self.resetNewOwnerUpdate(serialNumber: serialNumber)
                        completion(true)
                    } else {
                        //Utilities.showErrorAlertView(message: "Failed to update new owner key", presenter: nil)
                        debugPrint("** failed to update owner key")
                        completion(false)
                    }
                })
            }
        }
        else{
            completion(true)
            //print("Nothing to update for owner id")
        }

    }

    func resetNewOwnerUpdate(serialNumber:String){
        debugPrint("resetNewOwnerUpdate")
        var lockDictionary = dictionaryForLock(serialNumber:serialNumber)
        lockDictionary.removeValue(forKey: "ownerIdUpdate")
        var lockSerialNumberArray = ownerIdsToBeUpdated()
        if let index = lockSerialNumberArray.index(of: serialNumber) {
            lockSerialNumberArray.remove(at: index)
        }
        setDictionaryForLock(lockDict: lockDictionary, serialNumber: serialNumber)
        setOwnerIdsToBeUpdated(lockSerialNumberArray: lockSerialNumberArray)
        
        if lockSerialNumberArray.count == 0 {
            UserDefaults.standard.set(false, forKey: "requires_owner_update")
        }
    }


    func saveNewUserKey(newUserKey:String,oldUserKey:String,lockSerialNumber:String) {
        var lockDictionary = dictionaryForLock(serialNumber:lockSerialNumber)
        var dictionary:[String:String] =  [:]
        dictionary[oldUserKey] = newUserKey
        lockDictionary["user_key_update"] = dictionary
        setDictionaryForLock(lockDict: lockDictionary, serialNumber: lockSerialNumber)
        var tobeUpdatedUserKeyArray = userKeysToBeUpdated()
        if tobeUpdatedUserKeyArray.contains(lockSerialNumber) == false{
        tobeUpdatedUserKeyArray.append(lockSerialNumber)
        }
        setUserKeysToBeUpdated(lockSerialNumberArray: tobeUpdatedUserKeyArray)
    }

    func checkAndUpdateUserKey(completion: @escaping (Bool) -> Void) {
        //key - new owner id, keyid = lock_owner_id's id
        debugPrint("checkAndUpdateUserKey")
        if UserDefaults.standard.bool(forKey: "requires_user_key_update") == true {
            LoaderView.sharedInstance.showShadowView(title: "Loading...", isFromNotifiation: false)
            let lockSerialNumberArray = userKeysToBeUpdated()
            for lockSerialNumber in lockSerialNumberArray{
                let lockDictionary = dictionaryForLock(serialNumber: lockSerialNumber)
                let ownerIdUpdateDictionary = lockDictionary["user_key_update"]!
                let allKeys = ownerIdUpdateDictionary.keys
                for keyId in allKeys{
                    let key = ownerIdUpdateDictionary[keyId] as String?


                let urlString = ServiceUrl.BASE_URL + "keys/updatekey?id=\(keyId)"

                let userDetailsDict = [
                    "user_id": "",
                    "key": key!,
                    "status": "0",
                    ]

                var userDetails = [String: String]()
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)

                    let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])

                    if let dictFromJSON = decoded as? [String: String] {
                        userDetails = dictFromJSON
                        //print("dictFromJSON ==> \(dictFromJSON)")
                    }
                } catch {
                    //print(error.localizedDescription)
                }

                    print("update key ==>> checkAndUpdateUserKey")
                AssignUsersViewModel().revokeRequestUserServiceViewModel(url: urlString, userDetails: userDetails, serialNumber: lockSerialNumber, callback: { [unowned self](result, error, serialNumber) in
                    LoaderView.sharedInstance.hideShadowview()
                    if result != nil {
                        //print("user key updated")
                        self.resetNewUserKeyUpdate(serialNumber: serialNumber)

                        completion(true)
                    } else {
                        //Utilities.showErrorAlertView(message: "Failed to update new user key", presenter: nil)
                        //print("** failed to update user key")
                    }
                })
                }
            }
        }
        else{
            completion(true)
            //print("Nothing to update for user keys")
        }

    }

    func resetNewUserKeyUpdate(serialNumber:String){
        var lockDictionary = dictionaryForLock(serialNumber:serialNumber)
        lockDictionary.removeValue(forKey: "user_key_update")
        setDictionaryForLock(lockDict: lockDictionary, serialNumber: serialNumber)
        var lockSerialNumberArray = userKeysToBeUpdated()
        if let index = lockSerialNumberArray.index(of: serialNumber) {
            lockSerialNumberArray.remove(at: index)
        }
        setUserKeysToBeUpdated(lockSerialNumberArray: lockSerialNumberArray)
        if lockSerialNumberArray.count == 0 {
            UserDefaults.standard.set(false, forKey: "requires_user_key_update")
        }
    }
    
    // Save offline for add FP key access
    func saveAddFPKey(with addDictionary: [String:String]) {
        var tobeUpdatedUserKeyArray = [[String:String]]()
        tobeUpdatedUserKeyArray.append(addDictionary)
        setAddFPKeyToBeUpdated(fpKeyList: tobeUpdatedUserKeyArray)
    }
    
    func checkAndAddFPKey(completion: @escaping (Bool) -> Void) {
        debugPrint("checkAndAddFPKey")
        
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_add_fp_key_update") == true && UserDefaults.standard.bool(forKey: "addFp_inprogress") == false {
            UserDefaults.standard.set(true, forKey: "addFp_inprogress")
            var fpKeyListArray = addFPKeysToBeUpdated() ?? [[:]]
            debugPrint("fpKeyListArray ==>> \(fpKeyListArray) ")
            var tempArray = fpKeyListArray
            for i in  0...fpKeyListArray.count-1 {
                tempArray.remove(at: i)
                let urlString = ServiceUrl.BASE_URL + "locks/addfingerprint"
                //        {"lock_id":"449","name":"David Albert","key":"[6]","user_id":"355"}
                //            ["04"]
                let userDetails = fpKeyListArray[i] as [String:String]
                
                FPViewModel().createFingerPrintServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                   
                    if result != nil {
//                        print("tempArray ==>> \(tempArray) ")
                        if tempArray.count == 0 {
                            UserDefaults.standard.set(true, forKey: "addFp_inprogress")
                            UserDefaults.standard.set(false, forKey: "requires_add_fp_key_update")
                        }
                        completion(true)
                    } else {
                        UserDefaults.standard.set(false, forKey: "addFp_inprogress")
                        tempArray.insert(fpKeyListArray[i] as [String:String], at: i)
                    }
                }
            }
            if tempArray.count > 0 {
                setAddFPKeyToBeUpdated(fpKeyList: tempArray)
            }
        }
        else{
            completion(true)
            //print("Nothing to update for user keys")
        }

    }
    
    // Save offline for update and revoke FP key access
    func saveUpdateFPKey(with updateDictionary: [String:String], keyID: String) {
        var dictionary:[String:Any] =  [:]
        dictionary[keyID] = updateDictionary

        var tobeUpdatedFPKeyArray = [[String:Any]]()
        tobeUpdatedFPKeyArray.append(dictionary)
        setUpdateFPKeyToBeUpdated(fpKeyList: tobeUpdatedFPKeyArray)
    }
    
    // For update FP key access
    func checkAndUpdateFPKey(completion: @escaping (Bool) -> Void) {
        debugPrint("checkAndUpdateFPKey")
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_fp_key_update") == true {
            var fpKeyListArray = updateFPKeysToBeUpdated() ?? [[:]]
            var tempArray = fpKeyListArray
            for i in 0...fpKeyListArray.count-1 {
                let dict = fpKeyListArray[i] as [String: Any]
                let allKeys = dict.keys
                tempArray.remove(at: i)
                for keyId in allKeys {
                    
                    let urlString = ServiceUrl.BASE_URL + "keys/updatekey?id=\(keyId)"
                    let userDetails = dict[keyId] as! [String: String]
                    
                    FPViewModel().updateFingerPrintServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                        
                        if result != nil {
                            if tempArray.count == 0 {
                                UserDefaults.standard.set(false, forKey: "requires_fp_key_update")
                            }
                            completion(true)
                        } else {
                            tempArray.insert(fpKeyListArray[i] as [String: Any], at: i)
                        }
                    }
                }
            }
            if tempArray.count > 0 {
                setUpdateFPKeyToBeUpdated(fpKeyList: tempArray)
            }
        }
        else{
            completion(true)
            //print("Nothing to update for user keys")
        }
    }

    // Save offline for revoke FP key access
    func saveRevokeFPKey(with updateDictionary: [String:String], keyID: String) {
        var dictionary:[String:Any] =  [:]
        dictionary[keyID] = updateDictionary

        var tobeUpdatedFPKeyArray = [[String:Any]]()
        tobeUpdatedFPKeyArray.append(dictionary)
        setRevokeFPKeyToBeUpdated(fpKeyList: tobeUpdatedFPKeyArray)
    }
    
    // For revoke FP key access
    func checkAndUpdateRevokeFPKey(completion: @escaping (Bool) -> Void) {
        debugPrint("checkAndUpdateRevokeFPKey")
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_revoke_fp_key_update") == true {
            var fpKeyListArray = revokeFPKeysToBeUpdated() ?? [[:]]
            var tempArray = fpKeyListArray
            for i in 0...fpKeyListArray.count-1 {
                let dict = fpKeyListArray[i] as [String: Any]
                let allKeys = dict.keys
                tempArray.remove(at: i)
                for keyId in allKeys {
                    
                    let urlString = ServiceUrl.BASE_URL + "keys/updatekey?id=\(keyId)"
                    let userDetails = dict[keyId] as! [String: String]
                    
                    FPViewModel().updateFingerPrintServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                        
                        if result != nil {
                            if tempArray.count == 0 {
                                UserDefaults.standard.set(false, forKey: "requires_revoke_fp_key_update")
                            }
                            completion(true)
                        } else {
                            tempArray.insert(fpKeyListArray[i] as [String: Any], at: i)
                        }
                    }
                }
            }
            if tempArray.count > 0 {
                setRevokeFPKeyToBeUpdated(fpKeyList: tempArray)
            }
        }
        else{
            completion(true)
            //print("Nothing to update for user keys")
        }
    }

    // MARK: -  RFID
    
    // Save offline for revoke RFID key access
    func saveUpdateRFIDKey(with updateDictionary: [String:String], keyID: String) {
        var dictionary:[String:Any] =  [:]
        dictionary[keyID] = updateDictionary

        var tobeUpdatedFPKeyArray = [[String:Any]]()
        tobeUpdatedFPKeyArray.append(dictionary)
        setaddRFIDKeyToBeUpdated(rfidKeyList: tobeUpdatedFPKeyArray)
    }
    
    // For add/update RFID key access
    func checkAndUpdateRFIDKey(completion: @escaping (Bool) -> Void) {
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_add_rfid_key_update") == true {
            var rifdKeyListArray = addRFIDKeysToBeUpdated() ?? [[:]]
            var tempArray = rifdKeyListArray
            for i in 0...rifdKeyListArray.count-1 {
                let dict = rifdKeyListArray[i] as [String: Any]
                let allKeys = dict.keys
                tempArray.remove(at: i)
                for keyId in allKeys {
                    
                    let urlString = ServiceUrl.BASE_URL + "keys/updatekey?id=\(keyId)"
                    let userDetails = dict[keyId] as! [String: String]
                    
                    FPViewModel().updateFingerPrintServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                        
                        if result != nil {
                            if tempArray.count == 0 {
                                UserDefaults.standard.set(false, forKey: "requires_add_rfid_key_update")
                            }
                            completion(true)
                        } else {
                            tempArray.insert(rifdKeyListArray[i] as [String: Any], at: i)
                        }
                    }
                }
            }
            if tempArray.count > 0 {
                setaddRFIDKeyToBeUpdated(rfidKeyList: tempArray)
            }
        }
        else{
            completion(true)
            //print("Nothing to update for user keys")
        }
    }
    
    // Save offline for revoke RFID key access
       func saveRevokeRFIDKey(with updateDictionary: [String:String], keyID: String) {
           var dictionary:[String:Any] =  [:]
           dictionary[keyID] = updateDictionary

           var tobeUpdatedFPKeyArray = [[String:Any]]()
           tobeUpdatedFPKeyArray.append(dictionary)
           setRevokeRFIDKeyToBeUpdated(rfidKeyList: tobeUpdatedFPKeyArray)
       }
    
    // For revoke RFID key access
    func checkAndUpdateRevokeRFIDKey(completion: @escaping (Bool) -> Void) {
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_revoke_rfid_key_update") == true {
            var rifdKeyListArray = revokeRFIDKeysToBeUpdated() ?? [[:]]
            var tempArray = rifdKeyListArray
            for i in 0...rifdKeyListArray.count-1 {
                let dict = rifdKeyListArray[i] as [String: Any]
                let allKeys = dict.keys
                tempArray.remove(at: i)
                for keyId in allKeys {
                    
                    let urlString = ServiceUrl.BASE_URL + "keys/updatekey?id=\(keyId)"
                    let userDetails = dict[keyId] as! [String: String]
                    
                    FPViewModel().updateFingerPrintServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                        
                        if result != nil {
                            if tempArray.count == 0 {
                                UserDefaults.standard.set(false, forKey: "requires_revoke_rfid_key_update")
                            }
                            completion(true)
                        } else {
                            tempArray.insert(rifdKeyListArray[i] as [String: Any], at: i)
                        }
                    }
                }
            }
            if tempArray.count > 0 {
                setRevokeRFIDKeyToBeUpdated(rfidKeyList: tempArray)
            }
        }
        else{
            completion(true)
            //print("Nothing to update for user keys")
        }
    }
}

extension LockWifiLocalCache{
    func dictionaryForLock(serialNumber:String) -> [String:[String:String]]{
        let key = generateCustomKey(lockSerialNumber: serialNumber)
        let lockDict = UserDefaults.standard.dictionary(forKey: key) as? [String:[String:String]]
        if lockDict == nil {
            return [:]
        }
        return lockDict!
    }
    func setDictionaryForLock(lockDict:[String:[String:String]]?,serialNumber:String) {

        let key = generateCustomKey(lockSerialNumber: serialNumber)
        if lockDict == nil {
            UserDefaults.standard.set([:], forKey: key)
        }
        else{
            UserDefaults.standard.set(lockDict, forKey: key)
        }
    }

    func ownerIdsToBeUpdated() -> [String] {

        let tobeUpdatedOwnerIdArray = UserDefaults.standard.array(forKey: "to_be_updated_owner_ids") as? [String]
        if tobeUpdatedOwnerIdArray == nil {
            return []
        }
        print("tobeUpdatedOwnerIdArray ==> \(tobeUpdatedOwnerIdArray)")
        return tobeUpdatedOwnerIdArray!
    }

    func setOwnerIdsToBeUpdated(lockSerialNumberArray:[String]?) {
        
        if lockSerialNumberArray == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_owner_ids")
            print("tobeUpdatedOwnerIdArray ==> empty")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_owner_update")
            print("tobeUpdatedOwnerIdArray ==> have values")
            print("tobeUpdatedOwnerIdArray ==> \(lockSerialNumberArray)")
            UserDefaults.standard.set(lockSerialNumberArray, forKey: "to_be_updated_owner_ids")
            
        }
    }

    func userKeysToBeUpdated() -> [String] {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.array(forKey: "to_be_updated_user_keys") as? [String]
        if tobeUpdatedUserKeyArray == nil {
            return []
        }
        return tobeUpdatedUserKeyArray!
    }

    func setUserKeysToBeUpdated(lockSerialNumberArray:[String]?) {
        if lockSerialNumberArray == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_user_keys")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_user_key_update")
            UserDefaults.standard.set(lockSerialNumberArray, forKey: "to_be_updated_user_keys")
        }
    }
    
    func addFPKeysToBeUpdated() -> [[String:String]]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.array(forKey: "to_be_updated_add_fp_keys") as? [[String:String]]
        if tobeUpdatedUserKeyArray == nil {
            return []
        }
        return tobeUpdatedUserKeyArray!
    }
    
    func setAddFPKeyToBeUpdated(fpKeyList: [[String:String]]?) {
        if fpKeyList == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_add_fp_keys")
        }
        else{
            print("addFp_inprogress  set to false")
            UserDefaults.standard.set(false, forKey: "addFp_inprogress")
            UserDefaults.standard.set(true, forKey: "requires_add_fp_key_update")
            UserDefaults.standard.set(fpKeyList, forKey: "to_be_updated_add_fp_keys")
        }
    }
    
    func updateFPKeysToBeUpdated() -> [[String: Any]]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.array(forKey: "to_be_updated_fp_keys") as? [[String: Any]]
        if tobeUpdatedUserKeyArray == nil {
            return []
        }
        return tobeUpdatedUserKeyArray!
    }
    
    func setUpdateFPKeyToBeUpdated(fpKeyList: [[String:Any]]?) {
        if fpKeyList == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_fp_keys")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_fp_key_update")
            UserDefaults.standard.set(fpKeyList, forKey: "to_be_updated_fp_keys")
        }
    }
    
    func revokeFPKeysToBeUpdated() -> [[String: Any]]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.array(forKey: "to_be_updated_revoke_fp_keys") as? [[String: Any]]
        if tobeUpdatedUserKeyArray == nil {
            return []
        }
        return tobeUpdatedUserKeyArray!
    }
    
    func setRevokeFPKeyToBeUpdated(fpKeyList: [[String:Any]]?) {
        if fpKeyList == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_revoke_fp_keys")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_revoke_fp_key_update")
            UserDefaults.standard.set(fpKeyList, forKey: "to_be_updated_revoke_fp_keys")
        }
    }
    func addRFIDKeysToBeUpdated() -> [[String: Any]]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.array(forKey: "to_be_updated_add_rfid_keys") as? [[String: Any]]
        if tobeUpdatedUserKeyArray == nil {
            return []
        }
        return tobeUpdatedUserKeyArray!
    }
    
    func setaddRFIDKeyToBeUpdated(rfidKeyList: [[String:Any]]?) {
        if rfidKeyList == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_add_rfid_keys")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_add_rfid_key_update")
            UserDefaults.standard.set(rfidKeyList, forKey: "to_be_updated_add_rfid_keys")
        }
    }
    
    func revokeRFIDKeysToBeUpdated() -> [[String: Any]]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.array(forKey: "to_be_updated_revoke_rfid_keys") as? [[String: Any]]
        if tobeUpdatedUserKeyArray == nil {
            return []
        }
        return tobeUpdatedUserKeyArray!
    }
    
    func setRevokeRFIDKeyToBeUpdated(rfidKeyList: [[String:Any]]?) {
        if rfidKeyList == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_revoke_rfid_keys")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_revoke_rfid_key_update")
            UserDefaults.standard.set(rfidKeyList, forKey: "to_be_updated_revoke_rfid_keys")
        }
    }

    func batteryToBeUpdated() -> [String:String] {
        let tobeUpdatedOwnerIdArray = UserDefaults.standard.dictionary(forKey: "battery_updates") as? [String:String]
        if tobeUpdatedOwnerIdArray == nil {
            return [:]
        }
        return tobeUpdatedOwnerIdArray!
    }

    func removeBatteryUpdate(key:String){
        var dict = batteryToBeUpdated()
        dict.removeValue(forKey: key)
        setBatteryArrayToBeUpdated(batteryDict: dict)
    }
    func setBatteryArrayToBeUpdated(batteryDict:[String:String]?) {
        if batteryDict == nil || batteryDict?.keys.count == 0 {
            UserDefaults.standard.set([:], forKey: "battery_updates")
            UserDefaults.standard.set(false, forKey: "requires_battery_update")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_battery_update")
            UserDefaults.standard.set(batteryDict, forKey: "battery_updates")
        }
    }

    func appendLogsFor(lockId:String,log:String){
        if log.isEmpty{
            return
        }
        var logs = logsToBeUpdated()
        var logDict:[String] = []
        if logs.keys.contains(lockId){
            logDict = logs[lockId]!
        }
        logDict.append(log)
        logs[lockId] = logDict

        print("After saved ======>>>>>>> \(logs)")
        setLogsArrayToBeUpdated(batteryDict: logs)
    }

    func logsToBeUpdated() -> [String:[String]] {
        let tobeUpdatedLogsArray = UserDefaults.standard.dictionary(forKey: "logs_updates") as? [String:[String]]
        if tobeUpdatedLogsArray == nil {
            return [:]
        }
        return tobeUpdatedLogsArray!
    }

    func removelogsUpdate(key:String){
        var dict = logsToBeUpdated()
        dict.removeValue(forKey: key)
        setLogsArrayToBeUpdated(batteryDict: dict)
    }
    func setLogsArrayToBeUpdated(batteryDict:[String:[String]]?) {
        if batteryDict == nil || batteryDict?.keys.count == 0 {
            UserDefaults.standard.set([:], forKey: "logs_updates")
            UserDefaults.standard.set(false, forKey: "requires_log_update")
        }
        else{
            //print("Logs dict \(batteryDict.debugDescription)")
            UserDefaults.standard.set(true, forKey: "requires_log_update")
            UserDefaults.standard.set(batteryDict, forKey: "logs_updates")
        }
    }

    func checkAndUpdateLogs(completion: @escaping (Bool) -> Void) {
        print("checkAndUpdateLogs")
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_log_update") == true {
            //LoaderView.sharedInstance.showShadowView(title: "Loading...", isFromNotifiation: false)
            let logsDict = logsToBeUpdated()
            let lockIds = logsDict.keys
            for lockId in lockIds{

                //print("lockId ==> \(lockId)")

                DataStoreManager().postLogsUpdate(logs: logsDict[lockId]!, lockId: lockId, callback: { (json, error) in
                    //LoaderView.sharedInstance.hideShadowview()
                    if json != nil {
                        //print("logs updated")
                        completion(true)
                        self.removelogsUpdate(key: lockId)
                    } else {
                        completion(false)
                        //print("** failed to update logs")
                    }

                })
            }
        }
        else{
            completion(true)
            //print("Nothing to update for logs")
        }

    }
    
    func checkAndUpdateLogsWithLockID(lockID: String, lockSerialNumber: String, isSerialNumber: Bool, completion: @escaping (Bool) -> Void) {
        print("checkAndUpdateLogsWithLockID")
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_log_update") == true {
            //LoaderView.sharedInstance.showShadowView(title: "Loading...", isFromNotifiation: false)
            let logsDict = logsToBeUpdated()
            
            var lockId = ""
            if isSerialNumber {
                lockId = lockSerialNumber
            } else {
                lockId = lockID
            }
            
            if lockId == lockSerialNumber {
                
            }
            
            
            DataStoreManager().postLogsUpdate(logs: logsDict[lockId]!, lockId: lockID, callback: { (json, error) in
                //LoaderView.sharedInstance.hideShadowview()
                if json != nil {
                    //print("logs updated")
                    completion(true)
                    self.removelogsUpdate(key: lockId)
                } else {
                    completion(false)
                    //print("** failed to update logs")
                }
                
            })
            
        }
        else{
            completion(true)
            //print("Nothing to update for logs")
        }
        
    }

    func checkAndUpdateFactoryReset(completion: @escaping (Bool) -> Void) {

        if UserDefaults.standard.bool(forKey: "requires_factory_reset") == true {
            //LoaderView.sharedInstance.showShadowView(title: "Loading...", isFromNotifiation: false)
            let frArray = locksToBeUpdatedForFactoryReset()
            for lockId in frArray{
                let urlString = ServiceUrl.BASE_URL + "locks/updatelock?id=\(lockId)"
                let userDetails = [
                    "status": "2",
                    "lock_id":lockId
                ]

                DataStoreManager().updateLockDetailsServiceDataStore(url: urlString, userDetails: userDetails as [String: AnyObject]) { result, error in
                    //print("result lock name edit  ==> \(String(describing: result))")
                    if result != nil {
                        let lockId = userDetails["lock_id"]
                        completion(true)
                        self.removeLocksForFactoryResetUpdate(key: lockId ?? "")

                    } else {
                        completion(false)
                        //print("FR failed")
                    }
                }
            }
        }
        else{
            completion(true)
            //print("Nothing to update for FR")
        }

    }
    func appendLocksForFactoryReset(lockId:String){
        var logs = locksToBeUpdatedForFactoryReset()
        if logs.contains(lockId){
            return
        }
        logs.append(lockId)
        setLocksToBeFactoryReset(frArray: logs)
    }
    func setLocksToBeFactoryReset(frArray:[String]?) {
        if frArray == nil || frArray?.count == 0 {
            UserDefaults.standard.set([], forKey: "factory_reset_updates")
            UserDefaults.standard.set(false, forKey: "requires_factory_reset")
        }
        else{
            //print("factory rest array \(frArray.debugDescription)")
            UserDefaults.standard.set(true, forKey: "requires_factory_reset")
            UserDefaults.standard.set(frArray, forKey: "factory_reset_updates")
        }
    }

    func locksToBeUpdatedForFactoryReset() -> [String] {
        let factoryResetUpdates = UserDefaults.standard.array(forKey: "factory_reset_updates") as? [String]
        if factoryResetUpdates == nil {
            return []
        }
        return factoryResetUpdates!
    }

    func removeLocksForFactoryResetUpdate(key:String){
        var array = locksToBeUpdatedForFactoryReset()
        if let index = array.index(of: key){
             array.remove(at: index)
        }
        else{
            //print("\(key) missing in remove lock for factory reset")
        }
        setLocksToBeFactoryReset(frArray: array)
    }

    func generateCustomKey(lockSerialNumber:String) -> String{
        return "\(lockSerialNumber)-cache"
    }
}

extension LockWifiLocalCache{

    func updateBattery(lockId:String, batteryLevel:String){
        var batteryDict = batteryToBeUpdated()
        batteryDict[lockId] = batteryLevel
        setBatteryArrayToBeUpdated(batteryDict: batteryDict)
    }


    func checkAndUpdateBatteryStatus(completion: @escaping (Bool) -> Void) {
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_battery_update") == true {
//            LoaderView.sharedInstance.showShadowView(title: "Loading...", isFromNotifiation: false)
            let batteryDict = batteryToBeUpdated()
            let batteryIds = batteryDict.keys
            for batteryId in batteryIds{
                DataStoreManager().postBatteryUpdate(batteryId: batteryId, batteryLevel: batteryDict[batteryId]!, callback: { (json, error) in
//                     LoaderView.sharedInstance.hideShadowview()
                    if json != nil {
                        //print("battery updated")
                        completion(true)
                        self.removeBatteryUpdate(key: batteryId)
                    } else {
                        completion(false)
                        //print("** failed to update battery")
                    }

                })
                }
            }
        else{
            completion(true)
            //print("Nothing to update for battery")
        }

    }
    
    func checkAndUpdateBatteryStatusWithLockID(lockID: String, lockSerialNumber: String, isSerialNumber: Bool, completion: @escaping (Bool) -> Void) {
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_battery_update") == true {
            
            let batteryDict = batteryToBeUpdated()
            
            var batteryId = ""
            if isSerialNumber {
                batteryId = lockSerialNumber
            } else {
                batteryId = lockID
            }
            
            DataStoreManager().postBatteryUpdate(batteryId: lockID, batteryLevel: batteryDict[batteryId]!, callback: { (json, error) in
                //                     LoaderView.sharedInstance.hideShadowview()
                if json != nil {
                    //print("battery updated")
                    completion(true)
                    self.removeBatteryUpdate(key: batteryId)
                } else {
                    completion(false)
                    //print("** failed to update battery")
                }
                
            })
            
        }
        else{
            completion(true)
            //print("Nothing to update for battery")
        }
        
    }
    
    func checkAndUpdateLogsWithLockID1(lockID: String, lockSerialNumber: String, isSerialNumber: Bool, completion: @escaping (Bool) -> Void) {
        print("checkAndUpdateLogsWithLockID1 1")
        //key - new owner id, keyid = lock_owner_id's id
        if UserDefaults.standard.bool(forKey: "requires_log_update") == true {
            //LoaderView.sharedInstance.showShadowView(title: "Loading...", isFromNotifiation: false)
            let logsDict = logsToBeUpdated()
            
            var lockId = ""
            if isSerialNumber {
                lockId = lockSerialNumber
            } else {
                lockId = lockID
            }
            
            DataStoreManager().postLogsUpdate(logs: logsDict[lockId]!, lockId: lockID, callback: { (json, error) in
                //LoaderView.sharedInstance.hideShadowview()
                if json != nil {
                    //print("logs updated")
                    completion(true)
                    self.removelogsUpdate(key: lockId)
                } else {
                    completion(false)
                    //print("** failed to update logs")
                }
                
            })
            
        }
        else{
            completion(true)
            //print("Nothing to update for logs")
        }
        
    }

}
extension LockWifiLocalCache{
    
    func updateOfflineItems(){
        DispatchQueue.global(qos: .background).async {
            //print("Trying to upload offline items")
            if Connectivity().isConnectedToInternet(){
                LockWifiManager.shared.localCache.checkAndUpdateOwnerId(completion: { (status) in
                    
                })
                LockWifiManager.shared.localCache.checkAndUpdateUserKey(completion: { (status) in
                    
                })
                
                LockWifiManager.shared.localCache.checkAndAddFPKey(completion: { (status) in
                    
                })
                
                LockWifiManager.shared.localCache.checkAndUpdateFPKey(completion: { (status) in
                    
                })
                
                LockWifiManager.shared.localCache.checkAndUpdateRevokeFPKey(completion: { (status) in
                    
                })
                LockWifiManager.shared.localCache.checkAndUpdateRFIDKey(completion: { (status) in
                    
                })
                LockWifiManager.shared.localCache.checkAndUpdateRevokeRFIDKey(completion: { (status) in
                    
                })
                LockWifiManager.shared.localCache.updateDigiPins(completion: { (status) in
                    
                })
                LockWifiManager.shared.localCache.updateOTP(completion: { (status) in
                    
                })
                LockWifiManager.shared.localCache.updatePinManagePrivilege(completion: { (status) in
                    
                })
                LockWifiManager.shared.localCache.updateFPManagePrivilege(completion: { (status) in
                    
                })
                
                
                
                self.getLockListServiceCall(completion: { (result, success) in
                    if (result?.count)! > 0 {
                        
                        let locklistArray = result as! [LockListModel]
                        let logsDict = self.logsToBeUpdated()
                        let lockIds = logsDict.keys
                        
                        
                        for lockListObj in locklistArray {
                            let lockID = lockListObj.lock_keys[1].lock_id!
                            let lockSerialNumber = lockListObj.serial_number!
                            if lockIds.contains(lockID) {
                                LockWifiManager.shared.localCache.checkAndUpdateLogsWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: false, completion: { (status) in
                                    
                                })

                            }
                        }
                        
                        for lockListObj in locklistArray {
                            let lockID = lockListObj.lock_keys[1].lock_id!
                            let lockSerialNumber = lockListObj.serial_number!
                            if lockIds.contains(lockSerialNumber) {
                                
                                LockWifiManager.shared.localCache.checkAndUpdateLogsWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: true, completion: { (status) in
                                })
                            }
                        }
                        
                        // Battery status
                        let logsDict1 = self.batteryToBeUpdated()
                        let lockIds1 = logsDict1.keys
                        
                        
                        for lockListObj in locklistArray {
                            let lockID = lockListObj.lock_keys[1].lock_id!
                            let lockSerialNumber = lockListObj.serial_number!
                            if lockIds1.contains(lockID) {
                                LockWifiManager.shared.localCache.checkAndUpdateBatteryStatusWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: false, completion: { (status) in
                                    
                                })
                                
                            }
                        }
                        
                        for lockListObj in locklistArray {
                            let lockID = lockListObj.lock_keys[1].lock_id!
                            let lockSerialNumber = lockListObj.serial_number!
                            if lockIds1.contains(lockSerialNumber) {
                                
                                LockWifiManager.shared.localCache.checkAndUpdateBatteryStatusWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: true, completion: { (status) in
                                })
                            }
                        }

                    } else {
                        
                    }
                })
                /*
                LockWifiManager.shared.localCache.checkAndUpdateLogs(completion: { (status) in
                })*/
               
//                self.getLockListServiceCall(completion: { (result, success) in
//                    if (result?.count)! > 0 {
//                        
//                        let locklistArray = result as! [LockListModel]
//                    } else {
//                        
//                    }
//                })
               /* LockWifiManager.shared.localCache.checkAndUpdateBatteryStatus(completion: { (status) in
                    
                })*/
                LockWifiManager.shared.localCache.checkAndUpdateFactoryReset(completion: { (status) in
                })
            }
        }
    }
    
    func getLockListServiceCall(completion: @escaping (_ json: Array<Any>?, Bool) -> Void ) {

        let urlString = ServiceUrl.BASE_URL + "locks/locklist"
        LockDetailsViewModel().getLockListServiceViewModel(url: urlString, userDetails: [:]) { result, _ in
            
            if result != nil {
                completion(result as! [LockListModel], true)
            } else {
                completion(nil, false)
            }
        }
    }
    
    
    
    
    
   
}

// MARK: DIgiPin Data
extension LockWifiLocalCache{

    func setUpdateDigiPinToBeUpdated(digiPinList: [String:AnyObject]) {
        print(digiPinList)
        if digiPinList == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_digi_pins")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_digi_pins_update")
            UserDefaults.standard.set(digiPinList, forKey: "to_be_updated_digi_pins")
        }
    }
    
    func digiPinsToBeUpdated() -> [String:AnyObject]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.value(forKey: "to_be_updated_digi_pins") as? [String:AnyObject]
        if tobeUpdatedUserKeyArray == nil {
            return [String:AnyObject]()
        }
        return tobeUpdatedUserKeyArray
    }
    
    func updateDigiPins(completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.bool(forKey: "requires_digi_pins_update") == true {
            let digiPinsListArray = digiPinsToBeUpdated() ?? [:]
                    let urlString = ServiceUrl.BASE_URL + "locks/addpins"
            let userDetails = digiPinsListArray
                    DigiPinViewModel().addDigiPinsServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                        
                        if result != nil {
                            UserDefaults.standard.set([], forKey: "to_be_updated_digi_pins")
                            UserDefaults.standard.set(false, forKey: "requires_digi_pins_update")
                            completion(true)
                        } else {
                        }
                    }
        }
        else{
            completion(true)
        }
    }
    
}

// MARK: OTP Data
extension LockWifiLocalCache{
   
    func setUpdateOTPToBeUpdated(OtpList: [String:AnyObject]) {
        if OtpList == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_otp")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_otp_update")
            UserDefaults.standard.set(OtpList, forKey: "to_be_updated_otp")
        }
    }
    
    func otpToBeUpdated() -> [String:AnyObject]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.value(forKey: "to_be_updated_otp") as? [String:AnyObject]
        if tobeUpdatedUserKeyArray == nil {
            return [String:AnyObject]()
        }
        return tobeUpdatedUserKeyArray
    }
    
    func updateOTP(completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.bool(forKey: "requires_otp_update") == true {
            let digiPinsListArray = otpToBeUpdated() ?? [:]
                    let urlString = ServiceUrl.BASE_URL + "locks/addotps"
            let userDetails = digiPinsListArray
                    DigiPinViewModel().addDigiPinsServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                        
                        if result != nil {
                            UserDefaults.standard.set([], forKey: "to_be_updated_otp")
                            UserDefaults.standard.set(false, forKey: "requires_otp_update")
                            completion(true)
                        } else {
                        }
                    }
        }
        else{
            completion(true)
        }
    }
}


// MARK: PIN Manage Privilege Data
extension LockWifiLocalCache{
   
    func setUpdatePinManagePrivilegeToBeUpdated(PinEnable: [String:AnyObject]) {
        if PinEnable == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_pin_manage_privilege")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_pin_manage_privilege_update")
            UserDefaults.standard.set(PinEnable, forKey: "to_be_updated_pin_manage_privilege")
        }
    }
    
    func pinManagePrivilegeToBeUpdated() -> [String:AnyObject]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.value(forKey: "to_be_updated_pin_manage_privilege") as? [String:AnyObject]
        if tobeUpdatedUserKeyArray == nil {
            return [String:AnyObject]()
        }
        return tobeUpdatedUserKeyArray
    }
    
    func updatePinManagePrivilege(completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.bool(forKey: "requires_pin_manage_privilege_update") == true {
            var digiPinsListArray = pinManagePrivilegeToBeUpdated() ?? [:]
            let lockId  = digiPinsListArray["lock_id"] as? String ?? ""
//            print(digiPinsListArray)
            let urlString = ServiceUrl.BASE_URL + "locks/updatelock?id=\(lockId))"
            digiPinsListArray.removeValue(forKey: "lock_id")
//            print(digiPinsListArray)
            let userDetails = digiPinsListArray
                    DigiPinViewModel().addDigiPinsServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                        
                        if result != nil {
                            UserDefaults.standard.set([], forKey: "to_be_updated_pin_manage_privilege")
                            UserDefaults.standard.set(false, forKey: "requires_pin_manage_privilege_update")
                            completion(true)
                        } else {
                        }
                    }
        }
        else{
            completion(true)
        }
    }
}


// MARK: FP Manage Privilege Data
extension LockWifiLocalCache{
   
    func setUpdateFpManagePrivilegeToBeUpdated(FPEnable: [String:AnyObject]) {
        if FPEnable == nil {
            UserDefaults.standard.set([], forKey: "to_be_updated_fp_manage_privilege")
        }
        else{
            UserDefaults.standard.set(true, forKey: "requires_fp_manage_privilege_update")
            UserDefaults.standard.set(FPEnable, forKey: "to_be_updated_fp_manage_privilege")
        }
    }
    
    func fpManagePrivilegeToBeUpdated() -> [String:AnyObject]? {
        let tobeUpdatedUserKeyArray = UserDefaults.standard.value(forKey: "to_be_updated_fp_manage_privilege") as? [String:AnyObject]
        if tobeUpdatedUserKeyArray == nil {
            return [String:AnyObject]()
        }
        return tobeUpdatedUserKeyArray
    }
    
    func updateFPManagePrivilege(completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.bool(forKey: "requires_fp_manage_privilege_update") == true {
            var digiPinsListArray = fpManagePrivilegeToBeUpdated() ?? [:]
            let lockId  = digiPinsListArray["lock_id"] as? String ?? ""
//            print(digiPinsListArray)
            let urlString = ServiceUrl.BASE_URL + "locks/updatelock?id=\(lockId))"
            digiPinsListArray.removeValue(forKey: "lock_id")
//            print(digiPinsListArray)
            let userDetails = digiPinsListArray
                    DigiPinViewModel().addDigiPinsServiceViewModel(url: urlString, userDetails: userDetails) { (result, error) in
                        
                        if result != nil {
                            UserDefaults.standard.set([], forKey: "to_be_updated_fp_manage_privilege")
                            UserDefaults.standard.set(false, forKey: "requires_fp_manage_privilege_update")
                            completion(true)
                        } else {
                        }
                    }
        }
        else{
            completion(true)
        }
    }
}
