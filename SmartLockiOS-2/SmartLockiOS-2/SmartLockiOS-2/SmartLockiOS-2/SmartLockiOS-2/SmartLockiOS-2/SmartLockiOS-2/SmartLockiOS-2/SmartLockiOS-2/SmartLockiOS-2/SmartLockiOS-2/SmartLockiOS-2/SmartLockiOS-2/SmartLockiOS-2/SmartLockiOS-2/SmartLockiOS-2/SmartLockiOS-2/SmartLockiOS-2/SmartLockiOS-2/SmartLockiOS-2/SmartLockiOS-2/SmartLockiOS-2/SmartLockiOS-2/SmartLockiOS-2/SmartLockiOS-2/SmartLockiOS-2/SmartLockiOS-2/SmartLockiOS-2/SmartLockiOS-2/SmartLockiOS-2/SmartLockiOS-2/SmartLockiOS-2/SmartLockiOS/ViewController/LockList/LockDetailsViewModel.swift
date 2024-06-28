//
//  LockDetailsViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 13/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class LockDetailsViewModel: NSObject {
    func getLockListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: Array<Any>?, _ error: NSError?) -> Void) {
        DataStoreManager().getLockListServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            //print("Result =>> \(result)")
            if result != nil {
                var resultArray = [LockListModel]()
//                var userLockDetailsArray = [LockDetailsModel]()
                
                var userLockArray = NSMutableArray()
                var ownerId = ""
                var userKey = ""
                var role = UserRoles.user
                if result!["data"].count > 0 {
                    for i in 0..<result!["data"].count {
                        let lockListObj = LockListModel(json: result!["data"][i].rawValue as! NSDictionary)
                        lockListObj.lockname = result!["data"][i]["name"].rawValue as? String
                        lockListObj.uuid = result!["data"][i]["uuid"].rawValue as? String // result![i]["uuid"].rawValue as! String
                        lockListObj.id = result!["data"][i]["id"].rawValue as? String
                        lockListObj.battery = result!["data"][i]["battery"].rawString() ?? "100"
//                        lockListObj.reference_no = result!["data"][i]["reference_no"].rawValue as! String
                        lockListObj.serial_number = result!["data"][i]["serial_number"].rawValue as? String
                        lockListObj.scratch_code = result!["data"][i]["scratch_code"].rawValue as? String
                        lockListObj.lockVersion = result!["data"][i]["lock_version"].rawValue as? String
                        lockListObj.is_secured = result!["data"][i]["is_secured"].rawValue as? String ?? "0"
                        lockListObj.enable_pin = result!["data"][i]["enable_pin"].rawValue as? String ?? "0"
                        lockListObj.enable_fp = result!["data"][i]["enable_fp"].rawValue as? String ?? "0"
                        print("Encrypted009 \(lockListObj.is_secured)")
                        if result!["data"][i]["user_privileges"].rawValue is NSNull {
                            lockListObj.userPrivileges = ""
                            
                        } else {
                            lockListObj.userPrivileges = result!["data"][i]["user_privileges"].rawValue as? String
                        }
                        
//                        lockListObj.lock_owner_id = result!["data"][i]["lock_owner_id"].rawValue as! String
                        
                        
                        var lockOwnerDetailsArray = [LockOwnerDetailsModel]()
                        
                        if result!["data"][i]["lock_owner_id"].count > 0 {
                            let lockOwnerDetailsDict = result!["data"][i]["lock_owner_id"][0].rawValue as! NSDictionary
                            
                            
                            let lockOwnerDetailsObj = LockOwnerDetailsModel(json: [:])
                            lockOwnerDetailsObj.id = lockOwnerDetailsDict["id"] as? String
                            lockOwnerDetailsObj.slot_number = lockOwnerDetailsDict["slot_number"] as? String
                            lockOwnerDetailsObj.lock_id = lockOwnerDetailsDict["lock_id"] as? String
                            lockOwnerDetailsObj.user_type = lockOwnerDetailsDict["user_type"] as? String
                            lockOwnerDetailsObj.status = lockOwnerDetailsDict["status"] as? String
                            
                            lockOwnerDetailsArray.append(lockOwnerDetailsObj)
                        }
                        lockListObj.lock_owner_id = lockOwnerDetailsArray
                        
                        var lockKeysArray = [UserLockRoleDetails]()
                        if result!["data"][i]["lock_keys"].count > 0 {
                            for j in 0..<result!["data"][i]["lock_keys"].count {
                                let userLockDetails = result!["data"][i]["lock_keys"][j].rawValue as! NSDictionary
                                
                                let userLockRoleDetailsObj = UserLockRoleDetails(json: [:])
                                userLockRoleDetailsObj.id = userLockDetails["id"] as? String
                                userLockRoleDetailsObj.key = userLockDetails["key"] as? String
                                userLockRoleDetailsObj.user_type = userLockDetails["user_type"] as? String
                                userLockRoleDetailsObj.slot_number = userLockDetails["slot_number"] as? String
                                userLockRoleDetailsObj.lock_id = userLockDetails["lock_id"] as? String
                                userLockRoleDetailsObj.status = userLockDetails["status"] as? String
                                userLockRoleDetailsObj.is_schedule_access = userLockDetails["is_schedule_access"] as? String
                                userLockRoleDetailsObj.schedule_date_from = userLockDetails["schedule_date_from"] as? String
                                userLockRoleDetailsObj.schedule_date_to = userLockDetails["schedule_date_to"] as? String
                                userLockRoleDetailsObj.schedule_time_from = userLockDetails["schedule_time_from"] as? String
                                userLockRoleDetailsObj.schedule_time_to = userLockDetails["schedule_time_to"] as? String
                                userLockRoleDetailsObj.userID = userLockDetails["user_id"] as? String

                                /*if userLockRoleDetailsObj.schedule_date_from != nil && userLockRoleDetailsObj.schedule_time_from != nil
                                {
                                if userLockRoleDetailsObj.schedule_date_from.count > 0 && userLockRoleDetailsObj.schedule_time_from.count > 0
                                {
                                    let startDateTime = Utilities().UTCToLocal(date: userLockRoleDetailsObj.schedule_date_from + " " + userLockRoleDetailsObj.schedule_time_from, true)
                                    let arrStartDateTime = startDateTime.components(separatedBy: " ")
                                    if arrStartDateTime.count>0
                                    {
                                        userLockRoleDetailsObj.schedule_date_from = arrStartDateTime[0]
                                        userLockRoleDetailsObj.schedule_time_from = arrStartDateTime[1]
                                    }
                                    }
                                }

                                if userLockRoleDetailsObj.schedule_date_to != nil && userLockRoleDetailsObj.schedule_time_to != nil
                                {
                                    if userLockRoleDetailsObj.schedule_time_to.count > 0 && userLockRoleDetailsObj.schedule_time_to.count > 0
                                    {
                                        let startDateTime = Utilities().UTCToLocal(date: userLockRoleDetailsObj.schedule_time_to + " " + userLockRoleDetailsObj.schedule_time_to, true)
                                        let arrStartDateTime = startDateTime.components(separatedBy: " ")
                                        if arrStartDateTime.count>0
                                        {
                                            userLockRoleDetailsObj.schedule_date_to = arrStartDateTime[0]
                                            userLockRoleDetailsObj.schedule_time_to = arrStartDateTime[1]
                                        }
                                    }
                                }*/
                                
                                
                                if userLockRoleDetailsObj.isTypeOwnerID(){
                                    ownerId = userLockRoleDetailsObj.key
                                }
                                else {
                                    userKey = userLockRoleDetailsObj.key
                                    role = userLockRoleDetailsObj.userRoleType()

                                }
                                lockKeysArray.append(userLockRoleDetailsObj)
                            }
                        }
                        UserController.sharedController.save(ownerId: ownerId, userKey: userKey, userRole: role,serialNumber:  lockListObj.serial_number)
                        
                        lockListObj.lock_keys = lockKeysArray
                        
                        //print("lockListObj.lock_keys ==> \(lockListObj.lock_keys)")
                        //print("lockListObj.lock_keys count ==> \(lockListObj.lock_keys.count)")
                        
                        resultArray.append(lockListObj)
                    }
                }
                
                //Push Data to core Data
             
                let locaDB = CoreDataController()
                for lock in resultArray{
                    locaDB.saveLock(lockobject: lock)
                }
            
                
                
                // working code
//                let archivedObject = NSKeyedArchiver.archivedData(withRootObject: resultArray)
//                let defaults = UserDefaults.standard
//                defaults.set(archivedObject, forKey: UserdefaultsKeys.usersLockList.rawValue)
//                defaults.synchronize()
                
                //if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.usersLockList.rawValue) as? NSData {
                    if let savedUser = locaDB.fetchLockList() as? [LockListModel] {
                        //print("savedUser ==> \(savedUser)")
                    }
              //  }
                
                callback(resultArray, error)
                
            } else {
            }
        }
    }
    
    func addLockDetailsServiceViewModel(url: String, userDetails: [String: Any], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().addLockDetailsServiceDataStore(url: url, userDetails: userDetails as [String: Any]) { result, error in
            callback(result, error)
            
            if result != nil {
                // integrate model
                
            } else {
            }
        }
    }
    
    func updateLockDetailsServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().updateLockDetailsServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
            
            //print("result lock name edit  ==> \(result)")
            if result != nil {
                // integrate model
                
            } else {
            }
        }
    }
    
    func addLockViaMqttViewModel(url: String, lockDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().addLockViaMqtt(url: url, lockDetails: lockDetails as [String: AnyObject]) { result, error in
            callback(result, error)
            //print("result lock name edit  ==> \(result)")
            if result != nil {
                // integrate model
                
            } else {
            }
        }
    }
    
    func engageLockViaMqttViewModel(url: String, lockDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().engageLockViaMqtt(url: url, lockDetails: lockDetails as [String: AnyObject]) { result, error in
            callback(result, error)
            //print("result lock name edit  ==> \(result)")
            if result != nil {
                // integrate model
                
            } else {
            }
        }
    }
}
