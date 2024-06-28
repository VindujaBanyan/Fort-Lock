//
//  ProfileViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 12/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class ProfileViewModel: NSObject {
    func getProfileViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: ProfileModel?, _ error: NSError?) -> Void) {
        
        DataStoreManager().getProfileServiceDataStore(url: url, userDetails: userDetails as [String : AnyObject], callback: { (result, error) in
            
            if result != nil {
                let profileObj = ProfileModel()
                let a = result!.rawValue
                //print("A ==> \(a)")
                profileObj.name = result!["name"].rawValue as! String
                profileObj.email = result!["email"].rawValue as! String
                profileObj.mobile = result!["mobile"].rawValue as! String
                profileObj.address = result!["address"].rawValue as! String
                profileObj.countryCode = result!["country_code"].rawValue as? String
                /*
                profileObj.name = docsDict.objectForKey("file_name") as! String
                docsObj.documentsID = docsDict.objectForKey("document") as! String
                docsObj.documentsExtension = docsDict.objectForKey("extension") as! String
                docsObj.documentsURL = docsDict.objectForKey("url") as! String
                docsObj.uploadedBy = docsDict.objectForKey("shared_by") as! String
 */
                callback(profileObj, error)
                
//                                callback(result, error)
            } else {
                callback(nil, error)
            }
        
        })
    }
    
    func updateProfileViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        
        DataStoreManager().updateProfileServiceDataStore(url: url, userDetails: userDetails as [String : AnyObject], callback: { (result, error) in
            
            if result != nil {
                let profileObj = ProfileModel()
                profileObj.name = ""
                profileObj.email = ""
                profileObj.mobile = ""
                profileObj.address = ""
                /*
                 profileObj.name = docsDict.objectForKey("file_name") as! String
                 docsObj.documentsID = docsDict.objectForKey("document") as! String
                 docsObj.documentsExtension = docsDict.objectForKey("extension") as! String
                 docsObj.documentsURL = docsDict.objectForKey("url") as! String
                 docsObj.uploadedBy = docsDict.objectForKey("shared_by") as! String
                 */
                callback(result, error)
            } else {
                callback(result, error)
            }
        })
    }
    
}
