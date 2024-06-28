//
//  AssignUsersViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 16/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class AssignUsersViewModel: NSObject {
    func getAssignUserKeyListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [String:[AssignUserModel]]?, _ error: NSError?) -> Void) {
        DataStoreManager().getLockUsersListServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            if result != nil {
                
//                print("getAssignUserKeyListServiceViewModel ==> result ==> ")
//                print(result)
                
                var masterDetailsDict = [String:[AssignUserModel]]()
                var masterListArray1 = [AssignUserModel]()
                var masterListArray2 = [AssignUserModel]()
                var masterListArray3 = [AssignUserModel]()

                var fingerprintArray = [AssignUserModel]()
                
                var masterListArray = [AssignUserModel]()
                var userListArray = [AssignUserModel]()
                var resultArray = NSArray()
                for i in 0..<result!["data"].count {
                    let auObj = AssignUserModel()
                    let userDetailsObj = AssignUserDetailsModel()
                    let requestDetailsObj = AssignUsersRequestDetailsModel()
                    
                    if result!["data"][i]["userDetails"].rawValue is NSNull {
                        auObj.name = result!["data"][i]["name"].rawValue as? String
                    } else {
                        let userDetailsDict = result!["data"][i]["userDetails"].rawValue as! NSDictionary
                        auObj.name = userDetailsDict["username"] as? String
                        userDetailsObj.id = userDetailsDict["id"] as? String
                        userDetailsObj.username = userDetailsDict["username"] as? String
                        userDetailsObj.email = userDetailsDict["email"] as? String
                        userDetailsObj.countryCode = userDetailsDict["country_code"] as? String
                        userDetailsObj.mobile = userDetailsDict["mobile"] as? String
                        userDetailsObj.address = userDetailsDict["address"] as? String
                        userDetailsObj.status = userDetailsDict["status"] as? String
                    }
                    
                    if result!["data"][i]["requestDetails"].rawValue is NSNull {
                    } else {
                        let requestDetailsDict = result!["data"][i]["requestDetails"].rawValue as! NSDictionary
                        requestDetailsObj.id = requestDetailsDict["id"] as? String
                        requestDetailsObj.lockId = requestDetailsDict["lock_id"] as? String
                        requestDetailsObj.keyId = requestDetailsDict["key_id"] as? String
                        requestDetailsObj.requestTo = requestDetailsDict["request_to"] as? String
                        requestDetailsObj.status = requestDetailsDict["status"] as? String
                        requestDetailsObj.modified_date = requestDetailsDict["modified_date"] as? String
                    }
                    
                    auObj.status = result!["data"][i]["status"].rawValue as? String
                    auObj.slotNumber = result!["data"][i]["slot_number"].rawValue as? String
                    if result!["data"][i]["user_id"].rawValue is NSNull {
                        auObj.userId = ""
                        
                    } else {
                        auObj.userId = result!["data"][i]["user_id"].rawValue as? String
                    }
                    
                    // Start Date & Time
                    if result!["data"][i]["schedule_date_from"].rawValue is NSNull {
                        auObj.schedule_date_from = ""
                    } else {
                        auObj.schedule_date_from = result!["data"][i]["schedule_date_from"].rawValue as? String
                    }
                    
                    
                    if result!["data"][i]["schedule_time_from"].rawValue is NSNull {
                        auObj.schedule_time_from = ""
                    } else {
                        auObj.schedule_time_from = result!["data"][i]["schedule_time_from"].rawValue as? String
                    }
                    
                    if auObj.schedule_date_from != "" && auObj.schedule_time_from != ""
                    {
                        let startDateTime = Utilities().UTCToLocal(date: auObj.schedule_date_from + " " + auObj.schedule_time_from, true)
                        let arrStartDateTime = startDateTime.components(separatedBy: " ")
                        if arrStartDateTime.count>0
                        {
                            auObj.schedule_date_from = arrStartDateTime[0]
                            auObj.schedule_time_from = arrStartDateTime[1]
                        }
                    }

                    
                    
                    // End Date & Time
                    if result!["data"][i]["schedule_date_to"].rawValue is NSNull {
                        auObj.schedule_date_to = ""
                    } else {
                        auObj.schedule_date_to = result!["data"][i]["schedule_date_to"].rawValue as? String
                    }

                    if result!["data"][i]["schedule_time_to"].rawValue is NSNull {
                        auObj.schedule_time_to = ""
                    } else {
                        auObj.schedule_time_to = result!["data"][i]["schedule_time_to"].rawValue as? String
                    }

                    if auObj.schedule_date_to != "" && auObj.schedule_time_to != ""
                    {
                        let endDateTime = Utilities().UTCToLocal(date: auObj.schedule_date_to + " " + auObj.schedule_time_to, true)
                        let arrEndDateTime = endDateTime.components(separatedBy: " ")
                        if arrEndDateTime.count>0
                        {
                            auObj.schedule_date_to = arrEndDateTime[0]
                            auObj.schedule_time_to = arrEndDateTime[1]
                        }
                    }
                    
                    auObj.is_schedule_access = result!["data"][i]["is_schedule_access"].rawValue as? String
                    
                    auObj.userType = result!["data"][i]["user_type"].rawValue as? String
                    auObj.lockId = result!["data"][i]["lock_id"].rawValue as? String
                    auObj.id = result!["data"][i]["id"].rawValue as? String
                    auObj.key = result!["data"][i]["key"].rawValue as! String
                    auObj.userDetails = userDetailsObj
                    auObj.requestDetails = requestDetailsObj
                    
                    /*
                    if result!["data"].count > 5 {
                        if i < 3 {
                            masterListArray.append(auObj)
                        } else {
                            userListArray.append(auObj)
                        }
                        
                    } else {
                        userListArray.append(auObj)
                    }
                    */
                    
                    if auObj.userType != "Fingerprint" && auObj.userType != "RFID" {
                       
                        switch auObj.slotNumber {
                        case "01","02","03":
                            masterListArray.append(auObj)
                        case "04","05","06","07","08":
                            userListArray.append(auObj)
                        case "09", "10", "11", "12", "13":
                            masterListArray1.append(auObj)
                        case "14", "15", "16", "17", "18":
                            masterListArray2.append(auObj)
                        case "19", "20", "21", "22", "23":
                            masterListArray3.append(auObj)
                        default:
                            break
                        }
                        
                        /*
                        if result!["data"].count > 22 {
                            
                            if i < 3 {
                                masterListArray.append(auObj)
                            } else {
                                if i < 8 {
                                    userListArray.append(auObj)
                                } else if i < 13 {
                                    masterListArray1.append(auObj)
                                } else if i < 18 {
                                    masterListArray2.append(auObj)
                                } else if i < 23 {
                                    masterListArray3.append(auObj)
                                    
                                }
                            }
                        } else {
                            
                            switch auObj.slotNumber {
                            case "04","05","06","07","08":
                                userListArray.append(auObj)
                            case "09", "10", "11", "12", "13":
                                masterListArray1.append(auObj)
                            case "14", "15", "16", "17", "18":
                                masterListArray2.append(auObj)
                            case "19", "20", "21", "22", "23":
                                masterListArray3.append(auObj)
                                
                            default:
                                break
                            }
                            
                        }
                        */
                        
                    }
                    
                    if auObj.userType == "Fingerprint" && auObj.status == "2" { // Active finger print list
                        fingerprintArray.append(auObj)
                    }
                    
                    resultArray = [masterListArray, userListArray]
                }
                
                masterDetailsDict["master"] = masterListArray
                masterDetailsDict["master1User"] = masterListArray1
                masterDetailsDict["master2User"] = masterListArray2
                masterDetailsDict["master3User"] = masterListArray3
                masterDetailsDict["ownerUser"] = userListArray
                masterDetailsDict["fingerPrintUsers"] = fingerprintArray

                /*
 masterDetailsDict.setValue(masterListArray, forKey: "master")
 masterDetailsDict.setValue(masterListArray1, forKey: "master1User")
 masterDetailsDict.setValue(masterListArray2, forKey: "master2User")
 masterDetailsDict.setValue(masterListArray3, forKey: "master3User")
 masterDetailsDict.setValue(userListArray, forKey: "ownerUser")
*/
                //print("masterDetailsDict ==> ")
                //print(masterDetailsDict)
                
                callback(masterDetailsDict, error)
            } else {
                callback(nil, error)
            }
        }
    }
    
    func createRequestUserServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().createRequestUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
    
    func updateRequestUserServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().updateRequestUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
    
    func revokeRequestUserServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().revokeRequestUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }

    func revokeRequestUserServiceViewModel(url: String, userDetails: [String: String],serialNumber:String, callback: @escaping (_ json: JSON?, _ error: NSError?,_ serialNumber:String) -> Void) {
        DataStoreManager().revokeRequestUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in

            callback(result, error,serialNumber)
        }
    }
    
    // MARK: - Schedule Access
    
    func createOrUpdateScheduleAccessServiceViewModel(url: String, userDetails: [String: Any], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().createOrUpdateScheduleAccessServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
    
    // MARK: - Finger print Privilege
    
    func updateFingerPrintUserPrivilegeViewModel(url: String, userDetails: [String: Any], callback: @escaping (_ json: [String: Any]?, _ error: NSError?) -> Void) {
        DataStoreManager().updateFingerPrintUserPrivilegeServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            if result != nil {
                                
                var lockListObj = LockListModel(json: result!["data"].rawValue as! NSDictionary)
                
                lockListObj.lockname = result!["data"]["name"].rawValue as? String
                lockListObj.uuid = result!["data"]["uuid"].rawValue as? String // result![i]["uuid"].rawValue as! String
                lockListObj.id = result!["data"]["id"].rawValue as? String
                lockListObj.battery = result!["data"]["battery"].rawString() ?? "100"
                //                        lockListObj.reference_no = result!["data"][i]["reference_no"].rawValue as! String
                lockListObj.serial_number = result!["data"]["serial_number"].rawValue as? String
                lockListObj.scratch_code = result!["data"]["scratch_code"].rawValue as? String
                lockListObj.lockVersion = result!["data"]["lock_version"].rawValue as? String
                
                if result!["data"]["user_privileges"].rawValue is NSNull {
                    lockListObj.userPrivileges = ""
                } else {
                    let x : Int = result!["data"]["user_privileges"].rawValue as! Int
                    lockListObj.userPrivileges = String(x)
                }
                
                var resultDict = [String:Any]()
                resultDict["lockObj"] = lockListObj
                resultDict["message"] = result!["message"].rawValue as! String
                
                callback(resultDict, error)
            } else {
                callback(nil, error)
            }
        }
    }
    
    // Revoke user via MQTT
    func revokeUserServiceViewModel(url: String, userDetails: [String: Any], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void){
        DataStoreManager().revokeUserViaMqtt(url: url, lockDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
            //print("result lock name edit  ==> \(result)")
            if result != nil {
                // integrate model
                
            } else {
            }
        }
    }
}
