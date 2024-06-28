//
//  NotificationViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 22/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class NotificationViewModel: NSObject {
    
    func getNotificationListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [NotificationListModel]?, _ error: NSError?) -> Void) {
        
        DataStoreManager().getNotificationListServiceDataStore(url: url, userDetails: userDetails as [String : AnyObject], callback: { (result, error) in
            if result != nil {
                //print("result getNotificationListServiceDataStore ==> \(result)")
                /*
                
                [
                    {
                        "created_date" : "2018-06-22 12:13:54",
                        "status" : 0,
                        "message" : "Hi Notification",
                        "id" : 1,
                        "notify_to" : 101,
                        "notify_id" : 1
                    },
                    {
                        "created_date" : "2018-06-22 12:31:57",
                        "status" : 1,
                        "message" : "Hello",
                        "id" : 2,
                        "notify_to" : 1,
                        "notify_id" : 3
                    }
                ]
                
                */
                
                
                var notificationListObjArray = [NotificationListModel]()
                
                if result!["data"].count > 0 {
                    for i in 0..<result!["data"].count {
                        
                        let notificationObj = NotificationListModel()
                        
                        notificationObj.id = result!["data"][i]["id"].rawValue as! String
                        notificationObj.notificationCreatedDateAndTime = result!["data"][i]["created_date"].rawValue as! String
                        notificationObj.status = result!["data"][i]["status"].rawValue as! String
                        notificationObj.notificationMessage = result!["data"][i]["message"].rawValue as! String
                        notificationObj.notifyID = ""
                        
                        notificationListObjArray.append(notificationObj)
                        
                    }
                }
                
                callback(notificationListObjArray, error)
                
                
            } else {
                callback(nil, error)
                
            }
            
        })
    }

    
}

