//
//  SignInViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 31/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SwiftyJSON

class SignInViewModel: NSObject {
    /*
    func loginServiceViewModel(url: String, userDetails: [String: AnyObject], callback: @escaping (_ result: [String: AnyObject]) -> Void) {
        
        DataStoreManager().loginServiceDataStore(url: url, userDetails: userDetails) { (result) in
            
            callback(result)
        }
        
    }*/
    func loginServiceViewModel(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().loginServiceDataStore(url: url, userDetails: userDetails) { (result, error) in
            callback(result, error)
        }
    }

//    func loginServiceViewModel(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON? , _ error : NSError?) -> Void) {
//        
//        DataStoreManager().loginServiceDataStore(url: url, userDetails: userDetails) { (result, error) in
//            
//            callback(result, error)
//        }
//        
//    }

    
}
