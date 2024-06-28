//
//  DigiPinViewModel.swift
//  SmartLockiOS
//
//  Created by Sathishkumar R S on 26/05/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import UIKit
//import SwiftyJSON
import Foundation
import SwiftyJSON


class DigiPinViewModel: NSObject {

func addDigiPinsServiceViewModel(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
    DataStoreManager().addDigiPinsServiceDataStore(url: url, userDetails: userDetails) { result, error in
        
        callback(result, error)
    }
}
    
    func getDigiPinListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [DigiPin]?, _ error: NSError?) -> Void) {
        DataStoreManager().getDigiPinListServiceCall(url: url, userDetails: userDetails as [String : AnyObject]) { (data, result, error) in
            if result != nil {
                var arrDigiPins = [DigiPin]()
                for i in 0..<result!["data"].count {
                    var arrDigiPin = DigiPin()
                    if result!["data"][i]["registrationDetails"].rawValue is NSNull{
                        arrDigiPin.name = ""
                    }else{
                        let registrationDetailsDict = result!["data"][i]["registrationDetails"].rawValue as! NSDictionary
                        arrDigiPin.name = registrationDetailsDict["name"] as? String ?? ""
                    }
                    if result!["data"][i]["key"] == "" || result!["data"][i]["key"] == "0"{
                        arrDigiPin.pin = "    "
                    }else{
                        arrDigiPin.pin = Utilities().decryptStringToPlainString(plainString: result!["data"][i]["key"].rawValue as? String ?? "", isSecured: true)
                    }
                    arrDigiPin.slot_number = result!["data"][i]["slot_number"].rawValue as? String ?? ""
                    arrDigiPins.append(arrDigiPin)
                }
                callback(arrDigiPins, error)
            } else {
                callback(nil, error)
            }
        }
    }
    
    func getOTPListServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: [DigiPin]?, _ error: NSError?, _ recordExits: Bool?) -> Void) {
        DataStoreManager().getDigiPinListServiceCall(url: url, userDetails: userDetails as [String : AnyObject]) { (data, result, error) in
            if result != nil {
                
                var arrDigiPins = [DigiPin]()
                
                print(result)
                for i in 0..<result!["data"]["keys"].count {
                    var arrDigiPin = DigiPin()
                        arrDigiPin.pin = Utilities().decryptStringToPlainString(plainString: result!["data"]["keys"][i]["key"].rawValue as? String ?? "", isSecured: true)
                    arrDigiPin.slot_number = result!["data"]["keys"][i]["slot_number"].rawValue as? String ?? ""
                    arrDigiPin.status = result!["data"]["keys"][i]["status"].rawValue as? String ?? ""
                    arrDigiPin.createdDate = Utilities().UTCToLocal(date: result!["data"]["keys"][i]["assigned_datetime"].rawValue as? String ?? "", false)
                    arrDigiPins.append(arrDigiPin)
                }
                callback(arrDigiPins, error, result?["data"]["get_otp"].boolValue)
            } else {
                callback(nil, error, false)
            }
        }
    }
    
    func managePinViaMqttServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().managePinViaMqtt(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
        }
    }
    
    
    func updatePinViaMqttServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().updatePinViaMqtt(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
        }
    }
    
    func updateOtpViaMqttServiceViewModel(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        DataStoreManager().updateOtpViaMqtt(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
        }
    }
    
    
}
