//
//  ForgotPasswordViewModel.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 06/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SwiftyJSON

class ForgotPasswordViewModel: NSObject {
    func forgotPasswordServiceViewModel(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        
        DataStoreManager().forgotPasswordServiceDataStore(url: url, userDetails: userDetails, callback: { (result, error) in
            callback(result, error)
        })
    }
}
