//
//  JsonUtils.swift
//  SmartLockiOS
//
//  Created by mohamedshah on 27/11/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import Foundation
import SwiftyJSON

class JsonUtils: NSObject {
    
    func getJSON(_ key: String)-> JSON? {
       var p = ""
       if let result = UserDefaults.standard.string(forKey: key) {
           p = result
       }
       if p != "" {
           if let json = p.data(using: String.Encoding.utf8, allowLossyConversion: false) {
               do {
                   return try JSON(data: json)
               } catch {
                   return nil
               }
           } else {
               return nil
           }
       } else {
           return nil
       }
    }
    
    func getValueByKey(key: String)-> Any? {
        if let brandingInfo = JsonUtils().getJSON(UserdefaultsKeys.brandingInformation.rawValue)
        {
            if(brandingInfo[key].exists()){
                return brandingInfo[key].rawValue
            }
        }
        return nil
    }
    
    func getManufacturerCode()->String {
        if let brandingInfo = JsonUtils().getJSON(UserdefaultsKeys.brandingInformation.rawValue)
        {
            if(brandingInfo["manufacturer_code"].exists()){
                return brandingInfo["manufacturer_code"].rawValue as! String
            }
        }
        return "ASTRIX_"
    }
    
    func getScratchCodePrefix()-> String {
        if let brandingInfo = JsonUtils().getJSON(UserdefaultsKeys.brandingInformation.rawValue)
        {
            if(brandingInfo["scratch_code_prefix"].exists()){
                if(brandingInfo["scratch_code_prefix"] != JSON.null ){
                    return brandingInfo["scratch_code_prefix"].rawValue as! String
                }
                
            }
        }
        return ScratchCodePrefix
    }
    
    func getMqttServiceUrl()-> String {
        if let brandingInfo = JsonUtils().getJSON(UserdefaultsKeys.brandingInformation.rawValue)
        {
            if(brandingInfo["mqtt_service_url"].exists()){
                if(brandingInfo["mqtt_service_url"] != JSON.null ){
                    return brandingInfo["mqtt_service_url"].rawValue as! String
                }
            }
        }
        return MqttInfo.MQTT_SERVICE_URL.rawValue
    }
    
    
    func getScratchCodeLength()-> Int {
        if let brandingInfo = JsonUtils().getJSON(UserdefaultsKeys.brandingInformation.rawValue)
        {
            if(brandingInfo["scratch_code_length"].exists()){
                return brandingInfo["scratch_code_length"].rawValue as! Int
            }
        }
        return Int(ScratchCodeEnterCount)
    }
    
}
