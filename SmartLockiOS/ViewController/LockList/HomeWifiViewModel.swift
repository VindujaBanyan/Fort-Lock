//
//  HomeWifiViewModel.swift
//  Fort
//
//  Created by The Banyan Infotech on 12/02/24.
//  Copyright © 2024 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class HomeWifiViewModel: NSObject {
    func homeWiFiServiceViewModel(url: String, wifiDetails: [String: Any], callback: @escaping (_ json: JSON? , _ error : NSError?) -> Void) {
        
        DataStoreManager().homeWifiServiceDataStore(url: url, parameters: wifiDetails) { (result, error) in
            
            callback(result, error)
        }
        
    }
}
