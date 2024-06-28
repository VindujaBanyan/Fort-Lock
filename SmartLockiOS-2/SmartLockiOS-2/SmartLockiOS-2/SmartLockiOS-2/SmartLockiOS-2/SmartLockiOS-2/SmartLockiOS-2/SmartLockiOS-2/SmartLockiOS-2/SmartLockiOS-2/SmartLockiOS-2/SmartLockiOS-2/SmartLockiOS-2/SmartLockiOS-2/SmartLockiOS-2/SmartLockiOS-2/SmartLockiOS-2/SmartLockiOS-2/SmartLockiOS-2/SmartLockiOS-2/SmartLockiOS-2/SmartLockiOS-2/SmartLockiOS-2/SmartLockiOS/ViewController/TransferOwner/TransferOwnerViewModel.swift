//
//  TransferOwnerViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 19/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class TransferOwnerViewModel: NSObject {
    func getAssignUserKeyListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: NSMutableArray?, _ error: NSError?) -> Void) {
        DataStoreManager().getLockUsersListServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            if result != nil {
                let resultArray = NSMutableArray()
                for i in 0..<result!["data"].count {
                    let auObj = AssignUserModel()
                    let userDetailsObj = AssignUserDetailsModel()
                    let requestDetailsObj = AssignUsersRequestDetailsModel()
                    
                    if result!["data"][i]["userDetails"].rawValue is NSNull {
                        auObj.name = result!["data"][i]["name"].rawValue as! String
                    } else {
                        let userDetailsDict = result!["data"][i]["userDetails"].rawValue as! NSDictionary
                        auObj.name = userDetailsDict["username"] as! String
                        userDetailsObj.id = userDetailsDict["id"] as! String
                        userDetailsObj.username = userDetailsDict["username"] as! String
                        userDetailsObj.email = userDetailsDict["email"] as! String
                        userDetailsObj.mobile = userDetailsDict["mobile"] as! String
                        userDetailsObj.address = userDetailsDict["address"] as! String
                        userDetailsObj.status = userDetailsDict["status"] as! String
                    }
                    
                    if result!["data"][i]["requestDetails"].rawValue is NSNull {
                    } else {
                        let requestDetailsDict = result!["data"][i]["requestDetails"].rawValue as! NSDictionary
                        requestDetailsObj.id = requestDetailsDict["id"] as! String
                        requestDetailsObj.lockId = requestDetailsDict["lock_id"] as! String
                        requestDetailsObj.keyId = requestDetailsDict["key_id"] as! String
                        requestDetailsObj.requestTo = requestDetailsDict["request_to"] as! String
                        requestDetailsObj.status = requestDetailsDict["status"] as! String
                    }
                    
                    auObj.status = result!["data"][i]["status"].rawValue as! String
                    auObj.slotNumber = result!["data"][i]["slot_number"].rawValue as! String
                    if result!["data"][i]["user_id"].rawValue is NSNull {
                        auObj.userId = ""
                        
                    } else {
                        auObj.userId = result!["data"][i]["user_id"].rawValue as! String
                    }
                    
                    auObj.userType = result!["data"][i]["user_type"].rawValue as! String
                    auObj.lockId = result!["data"][i]["lock_id"].rawValue as! String
                    auObj.id = result!["data"][i]["id"].rawValue as! String
//                    auObj.key = result!["data"][i]["key"].rawValue as! String
                    auObj.userDetails = userDetailsObj
                    auObj.requestDetails = requestDetailsObj
                    
                    resultArray.add(auObj)
                }
                
                callback(resultArray, error)
            } else {
                callback(nil, error)
            }
        }
    }
    
    func createTransferOwnerRequestUserServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: NSMutableArray?, _ error: NSError?) -> Void) {
        print("----------- Transfer owner -------")
        print("url ----------- \(url)")
        print("userDetails ----------- \(userDetails)")
        
        DataStoreManager().createRequestUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            if result != nil {
                
                //print("result ==> \(result)")
                
                let resultArray = NSMutableArray()
                let userDetailsObj = AssignUserDetailsModel()
                
                if result!["data"]["user_details"].rawValue is NSNull {
                } else {
                    let userDetailsDict = result!["data"]["user_details"].rawValue as! NSDictionary
                    userDetailsObj.username = userDetailsDict["username"] as! String
                    userDetailsObj.mobile = userDetailsDict["mobile"] as! String
                    userDetailsObj.email = userDetailsDict["email"] as! String
                }
                resultArray.add(userDetailsObj)
                callback(resultArray, error)
                
            } else {
                callback(nil, error)
            }
        }
    }
    
    func updateTransferOwnerRequestUserServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().updateTransferOwnerRequestUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
    
    func withdrawTransferOwnerRequestUserServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().withdrawTransferOwnerRequestUserServiceDataStore(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            
            callback(result, error)
        }
    }
}
