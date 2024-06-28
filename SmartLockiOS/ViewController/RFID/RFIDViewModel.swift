//
//  RFIDViewModel.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/6/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit
import SwiftyJSON
import Foundation

class RFIDViewModel: NSObject {
    
    func getRFIDListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [RFIDModel]?, _ error: NSError?) -> Void) {
        
        DataStoreManager().getRFIDListServiceDataStore(url: url, userDetails: userDetails as [String : AnyObject]) { (result, error) in
            if result != nil {
                print("getRFIDListServiceViewModel")
                print(result as Any)
                
                var rfidListArray = [RFIDModel]()
                
                for i in 0..<result!["data"].count {
                    let rfidObj = RFIDModel()
                    let userDetailsObj = AssignUserDetailsModel()
                    let requestDetailsObj = AssignUsersRequestDetailsModel()
                    
                    if result!["data"][i]["userDetails"].rawValue is NSNull {
                        rfidObj.name = result!["data"][i]["name"].rawValue as? String
                    } else {
                        let userDetailsDict = result!["data"][i]["userDetails"].rawValue as! NSDictionary
                        rfidObj.name = userDetailsDict["username"] as? String
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
                    
                    rfidObj.status = result!["data"][i]["status"].rawValue as? String
                    rfidObj.slotNumber = result!["data"][i]["slot_number"].rawValue as? String
                    if result!["data"][i]["user_id"].rawValue is NSNull {
                        rfidObj.userId = ""
                        
                    } else {
                        rfidObj.userId = result!["data"][i]["user_id"].rawValue as? String
                    }
                    
                    // Start Date & Time
                    if result!["data"][i]["schedule_date_from"].rawValue is NSNull {
                        rfidObj.schedule_date_from = ""
                    } else {
                        rfidObj.schedule_date_from = result!["data"][i]["schedule_date_from"].rawValue as? String
                    }
                    
                    
                    if result!["data"][i]["schedule_time_from"].rawValue is NSNull {
                        rfidObj.schedule_time_from = ""
                    } else {
                        rfidObj.schedule_time_from = result!["data"][i]["schedule_time_from"].rawValue as? String
                    }
                    
                    if rfidObj.schedule_date_from != "" && rfidObj.schedule_time_from != ""
                    {
                        let startDateTime = Utilities().UTCToLocal(date: rfidObj.schedule_date_from + " " + rfidObj.schedule_time_from, true)
                        let arrStartDateTime = startDateTime.components(separatedBy: " ")
                        if arrStartDateTime.count>0
                        {
                            rfidObj.schedule_date_from = arrStartDateTime[0]
                            rfidObj.schedule_time_from = arrStartDateTime[1]
                        }
                    }
                    
                    // End Date & Time
                    if result!["data"][i]["schedule_date_to"].rawValue is NSNull {
                        rfidObj.schedule_date_to = ""
                    } else {
                        rfidObj.schedule_date_to = result!["data"][i]["schedule_date_to"].rawValue as? String
                    }
                    
                    if result!["data"][i]["schedule_time_to"].rawValue is NSNull {
                        rfidObj.schedule_time_to = ""
                    } else {
                        rfidObj.schedule_time_to = result!["data"][i]["schedule_time_to"].rawValue as? String
                    }
                    
                    if rfidObj.schedule_date_to != "" && rfidObj.schedule_time_to != ""
                    {
                        let endDateTime = Utilities().UTCToLocal(date: rfidObj.schedule_date_to + " " + rfidObj.schedule_time_to, true)
                        let arrEndDateTime = endDateTime.components(separatedBy: " ")
                        if arrEndDateTime.count>0
                        {
                            rfidObj.schedule_date_to = arrEndDateTime[0]
                            rfidObj.schedule_time_to = arrEndDateTime[1]
                        }
                    }
                    
                    rfidObj.is_schedule_access = result!["data"][i]["is_schedule_access"].rawValue as? String
                    rfidObj.userType = result!["data"][i]["user_type"].rawValue as? String
                    rfidObj.lockId = result!["data"][i]["lock_id"].rawValue as? String
                    rfidObj.id = result!["data"][i]["id"].rawValue as? String
                    rfidObj.key = result!["data"][i]["key"].rawValue as? String
                    rfidObj.userDetails = userDetailsObj
                    rfidObj.requestDetails = requestDetailsObj
                            
                    rfidListArray.append(rfidObj)
                }
                callback(rfidListArray, error)
            } else {
                callback(nil, error)
            }
        }
       
    }
    
    func revokeRfidViaMqttServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().revokeRfidViaMqtt(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
        }
    }

}
