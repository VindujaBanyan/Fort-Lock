//
//  FPViewModel.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/7/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit
import SwiftyJSON
import Foundation

class FPViewModel: NSObject {
    
    func getFPListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [FPModel]?, _ error: NSError?) -> Void) {
        
        DataStoreManager().getFPListServiceDataStore(url: url, userDetails: userDetails as [String : AnyObject]) { (result, error) in
            if result != nil {
                print(result)
                
                var fpListArray = [FPModel]()
                
                for i in 0..<result!["data"].count {
                    let fpObj = FPModel()
                    let userDetailsObj = AssignUserDetailsModel()
                    let requestDetailsObj = AssignUsersRequestDetailsModel()
                    let registrationDetailObj = RegistrationDetailsModel()
                    
                    if result!["data"][i]["userDetails"].rawValue is NSNull {
                        fpObj.name = result!["data"][i]["name"].rawValue as? String
                    } else {
                        let userDetailsDict = result!["data"][i]["userDetails"].rawValue as! NSDictionary
                        fpObj.name = userDetailsDict["username"] as? String
                        userDetailsObj.id = userDetailsDict["id"] as? String
                        userDetailsObj.username = userDetailsDict["username"] as? String
                        userDetailsObj.email = userDetailsDict["email"] as? String
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
                    
                    fpObj.status = result!["data"][i]["status"].rawValue as? String
                    fpObj.slotNumber = result!["data"][i]["slot_number"].rawValue as? String
                    if result!["data"][i]["user_id"].rawValue is NSNull {
                        fpObj.userId = ""
                        
                    } else {
                        fpObj.userId = result!["data"][i]["user_id"].rawValue as? String
                    }
                    
                    // Start Date & Time
                    if result!["data"][i]["schedule_date_from"].rawValue is NSNull {
                        fpObj.schedule_date_from = ""
                    } else {
                        fpObj.schedule_date_from = result!["data"][i]["schedule_date_from"].rawValue as? String
                    }
                    
                    
                    if result!["data"][i]["schedule_time_from"].rawValue is NSNull {
                        fpObj.schedule_time_from = ""
                    } else {
                        fpObj.schedule_time_from = result!["data"][i]["schedule_time_from"].rawValue as? String
                    }
                    
                    if fpObj.schedule_date_from != "" && fpObj.schedule_time_from != ""
                    {
                        let startDateTime = Utilities().UTCToLocal(date: fpObj.schedule_date_from + " " + fpObj.schedule_time_from, true)
                        let arrStartDateTime = startDateTime.components(separatedBy: " ")
                        if arrStartDateTime.count>0
                        {
                            fpObj.schedule_date_from = arrStartDateTime[0]
                            fpObj.schedule_time_from = arrStartDateTime[1]
                        }
                    }
                    
                    // End Date & Time
                    if result!["data"][i]["schedule_date_to"].rawValue is NSNull {
                        fpObj.schedule_date_to = ""
                    } else {
                        fpObj.schedule_date_to = result!["data"][i]["schedule_date_to"].rawValue as? String
                    }
                    
                    if result!["data"][i]["schedule_time_to"].rawValue is NSNull {
                        fpObj.schedule_time_to = ""
                    } else {
                        fpObj.schedule_time_to = result!["data"][i]["schedule_time_to"].rawValue as? String
                    }
                    
                    if fpObj.schedule_date_to != "" && fpObj.schedule_time_to != ""
                    {
                        let endDateTime = Utilities().UTCToLocal(date: fpObj.schedule_date_to + " " + fpObj.schedule_time_to, true)
                        let arrEndDateTime = endDateTime.components(separatedBy: " ")
                        if arrEndDateTime.count>0
                        {
                            fpObj.schedule_date_to = arrEndDateTime[0]
                            fpObj.schedule_time_to = arrEndDateTime[1]
                        }
                    }
                    
                    if result!["data"][i]["registrationDetails"].rawValue is NSNull {
                    } else {
                        let registrationDetailsDict = result!["data"][i]["registrationDetails"].rawValue as! NSDictionary
                        registrationDetailObj.id = registrationDetailsDict["id"] as? String
                        registrationDetailObj.name = registrationDetailsDict["name"] as? String
                        if registrationDetailsDict["name"] is NSNull {
                            registrationDetailObj.userId = registrationDetailsDict["user_id"] as? String
                        }
                    }
                    
                    if result!["data"][i]["registration_id"].rawValue is NSNull {
                        fpObj.registration_id = ""
                        
                    } else {
                        fpObj.registration_id = result!["data"][i]["registration_id"].rawValue as? String
                    }
                    
                    fpObj.is_schedule_access = result!["data"][i]["is_schedule_access"].rawValue as? String
                    fpObj.userType = result!["data"][i]["user_type"].rawValue as? String
                    fpObj.lockId = result!["data"][i]["lock_id"].rawValue as? String
                    fpObj.id = result!["data"][i]["id"].rawValue as? String
                    fpObj.key = result!["data"][i]["key"].rawValue as? String
                    fpObj.userDetails = userDetailsObj
                    fpObj.requestDetails = requestDetailsObj
                    fpObj.registrationDetails = registrationDetailObj
                    let keyArray = Utilities().convertKeyStringToKeyArray(with: fpObj.key)
                    fpObj.numberOfKeysAssigned = keyArray.count
                    fpObj.isGuestUser = fpObj.userId == "" ? true : false
                    
                    fpListArray.append(fpObj)
                }
                callback(fpListArray, error)
            } else {
                callback(nil, error)
            }
        }
    }
    
    func getExistingLockUserServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [AssignUserDetailsModel]?, _ error: NSError?) -> Void) {
        DataStoreManager().getExistingLockUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { (result, error) in
            if result != nil {
                print(result as Any)
                
                var usersListArray = [AssignUserDetailsModel]()
                for i in 0..<result!["data"].count {
                    
                    let userDetailsObj = AssignUserDetailsModel()
//                    userDetailsObj.id = result!["data"][i]["id"].rawValue as? String
                    userDetailsObj.id = result!["data"][i]["id"].rawString()
                    userDetailsObj.username = result!["data"][i]["username"].rawString()
                    userDetailsObj.email = result!["data"][i]["email"].rawString()
                    userDetailsObj.mobile = result!["data"][i]["mobile"].rawString()
                    userDetailsObj.address = result!["data"][i]["address"].rawString()
                    userDetailsObj.status = result!["data"][i]["status"].rawString()
                    
                    usersListArray.append(userDetailsObj)
                }
                callback(usersListArray, error)
            } else {
                callback(nil, error)
            }
        }
    }
    
    func createFingerPrintServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().createFingerPrintServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
    
    func updateFingerPrintServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().updateFingerPrintServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
    
    func updateUserNameServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().editUserNameServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
    
    func revokeFingerprintViaMqttServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().revokeRfidViaMqtt(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
        }
    }
    
    func manageFingerprintViaMqttServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().manageFingerprintViaMqtt(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
        }
    }
    
}
