//
//  RequestViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 16/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class RequestViewModel: NSObject {
    func getRequestListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: NSMutableArray?, _ error: NSError?) -> Void) {
        DataStoreManager().getRequestListServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            if result != nil {
                //print(" result getRequestListServiceViewModel ==> \(result)")
                let requestListArray = NSMutableArray()
                for i in 0..<result!["data"].count {
                    let requestObj = RequestListModel()
                    
                    let lockDetailsObj = RequestLockDetailsModel()
                    let keyDetailsObj = RequestKeyDetailsModel()
                    let requestFromUserDetailsObj = AssignUserDetailsModel()
                    let requestToUserDetailsObj = AssignUserDetailsModel()
                    
                    requestObj.requestId = result!["data"][i]["id"].rawValue as? String
                    requestObj.lockId = result!["data"][i]["lock_id"].rawValue as? String
                    requestObj.status = (result!["data"][i]["status"].rawValue as! String)
                    requestObj.requestTo = result!["data"][i]["request_to"].rawValue as? String
                    requestObj.requestBy = result!["data"][i]["request_by"].rawValue as? String
                    requestObj.keyId = result!["data"][i]["key_id"].rawValue as? String
                    
                    // Lock details Obj
                    if result!["data"][i]["lock"].rawValue is NSNull {
                    } else {
                        let lockDetailsDict = result!["data"][i]["lock"].rawValue as! NSDictionary
                        lockDetailsObj.id = lockDetailsDict["id"] as? String
                        lockDetailsObj.name = lockDetailsDict["name"] as? String
                        
                        if lockDetailsDict["user_id"] is NSNull {
                            lockDetailsObj.userId = ""
                        } else {
                            lockDetailsObj.userId = lockDetailsDict["user_id"] as? String
                        }
                        
                        lockDetailsObj.status = lockDetailsDict["status"] as? String
                        
                        if let lockVersion = lockDetailsDict["lock_version"] {
                            lockDetailsObj.lockVersion = lockVersion as? String
                        }
                        
                        if let serialNumber = lockDetailsDict["serial_number"] {
                            lockDetailsObj.serialNumber = serialNumber as? String
                        }
                        
                    }
                    
                    // Key details Obj
                    if result!["data"][i]["key"].rawValue is NSNull {
                    } else {
                        let keyDetailsDict = result!["data"][i]["key"].rawValue as! NSDictionary
                        keyDetailsObj.id = keyDetailsDict["id"] as? String
                        keyDetailsObj.name = keyDetailsDict["name"] as? String
                        if keyDetailsDict["user_id"] is NSNull {
                            keyDetailsObj.userId = ""
                        } else {
                            keyDetailsObj.userId = keyDetailsDict["user_id"] as? String
                        }
                        keyDetailsObj.status = keyDetailsDict["status"] as? String
                        keyDetailsObj.userType = keyDetailsDict["user_type"] as? String
                        if keyDetailsDict["parent_user_id"] is NSNull {
                            keyDetailsObj.parentUserId = ""
                        } else {
                            keyDetailsObj.parentUserId = keyDetailsDict["parent_user_id"] as? String
                        }
                        keyDetailsObj.lockId = keyDetailsDict["lock_id"] as? String
                    }
                    
                    if result!["data"][i]["fromUser"].rawValue is NSNull {
                    } else {
                        let requestFromUserDetailsDict = result!["data"][i]["fromUser"].rawValue as! NSDictionary
                        requestFromUserDetailsObj.id = requestFromUserDetailsDict["id"] as? String
                        requestFromUserDetailsObj.username = requestFromUserDetailsDict["username"] as? String
                        requestFromUserDetailsObj.email = requestFromUserDetailsDict["email"] as? String
                        requestFromUserDetailsObj.status = requestFromUserDetailsDict["status"] as? String
                        requestFromUserDetailsObj.mobile = requestFromUserDetailsDict["mobile"] as? String
                        requestFromUserDetailsObj.address = requestFromUserDetailsDict["address"] as? String
                    }
                    
                    if result!["data"][i]["toUser"].rawValue is NSNull {
                    } else {
                        let requestToUserDetailsDict = result!["data"][i]["toUser"].rawValue as! NSDictionary
                        requestToUserDetailsObj.id = requestToUserDetailsDict["id"] as? String
                        requestToUserDetailsObj.username = requestToUserDetailsDict["username"] as? String
                        requestToUserDetailsObj.email = requestToUserDetailsDict["email"] as? String
                        requestToUserDetailsObj.status = requestToUserDetailsDict["status"] as? String
                        requestToUserDetailsObj.mobile = requestToUserDetailsDict["mobile"] as? String
                        requestToUserDetailsObj.address = requestToUserDetailsDict["address"] as? String
                    }
                    
                    requestObj.lockDetails = lockDetailsObj
                    requestObj.keyDetails = keyDetailsObj
                    requestObj.requestFromUserDetails = requestFromUserDetailsObj
                    requestObj.requestToUserDetails = requestToUserDetailsObj
                    
                    requestListArray.add(requestObj)
                }
                callback(requestListArray, error)
            } else {
                callback(nil, error)
            }
        }
    }
    
    func updateRequestUserServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().updateRequestUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
    
    func acceptTranserOwnerViaMqttServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().acceptTransferOwnerViaMqtt(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
}
