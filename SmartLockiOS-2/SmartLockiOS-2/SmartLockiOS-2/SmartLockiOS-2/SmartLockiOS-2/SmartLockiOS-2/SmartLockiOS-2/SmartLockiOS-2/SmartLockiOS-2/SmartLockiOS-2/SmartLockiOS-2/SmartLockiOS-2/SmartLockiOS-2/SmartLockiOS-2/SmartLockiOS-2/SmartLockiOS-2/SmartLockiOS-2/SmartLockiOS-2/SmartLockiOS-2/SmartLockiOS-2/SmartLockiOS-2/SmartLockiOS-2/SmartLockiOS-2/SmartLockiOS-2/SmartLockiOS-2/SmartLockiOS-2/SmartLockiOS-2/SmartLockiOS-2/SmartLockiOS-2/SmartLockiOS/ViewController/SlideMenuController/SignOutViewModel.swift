//
//  SignOutViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 21/11/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class SignOutViewModel: NSObject {
    
    func logoutServiceViewModel(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON? , _ error : NSError?) -> Void) {
        
        DataStoreManager().logoutServiceDataStore(url: url, userDetails: userDetails) { (result, error) in
            
            callback(result, error)
        }
    }
    
    func deleteAccountServiceViewModel(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON? , _ error : NSError?) -> Void) {
        
        DataStoreManager().deleteAccountServiceDataStore(url: url, userDetails: userDetails) { (result, error) in
            
            callback(result, error)
        }
    }
}
