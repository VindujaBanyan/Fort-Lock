//
//  LockWifiManager.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/10/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import SystemConfiguration.CaptiveNetwork

enum LockWifiRESTMethods:String {
    case activate = "activate"
    case disengage = "disengage"
    case lockStatus = "lock-status"
    case dateTime = "date-time"
    case accessLogs = "access-logs"
    case rewriteSlot = "rewrite-slot"
    case readKeys = "read-keys"
    case deactivate = "deactivate"
    case batteryLevel = "battery-level"
    case factoryReset = "reset-device"
    case enrollFingerPrint = "enroll-fp"
    case revokeFingerPrint = "delete-fp"
    case enrollRFID = "enroll-rf"
    case revokeRFID = "delete-rf"
    case addDidiPins = "rewrite-pin"
    case addOTP = "rewrite-otp"
    case updatePinPrivilege = "authvia-pin"
    case updateFPPrivilege = "authvia-fp"
    case configWiFiMqtt = "config-wifi-http"
    case passageMode = "passage-mode"
    case pushWifiConfigStatus = "ddddd"
}

enum LockWifiFPMessages: String {
    case FP_NEXT_SAMPLE = "FP_NEXT_SAMPLE"
    case FP_NOT_PLACED = "FP_NOT_PLACED"
    case FP_MAX_TRIES_EXIT = "FP_MAX_TRIES_EXIT"
    case FP_TRY_OTHER_FINGER = "FP_TRY_OTHER_FINGER"
    case FP_UID_ENROLLED = "FP_UID_ENROLLED"
    case FP_USER_ID_NOT_EXISTS = "FP_USER_ID_NOT_EXISTS"
    case FP_ID_ALREADY_EMPTY = "FP_ID_ALREADY_EMPTY"
    case FP_NOT_CONNECTED = "FP_NOT_CONNECTED"
    case FP_MAX_USR = "FP_MAX_USR"
    case FP_BAD_FINGER = "FP_BAD_FINGER"
    case OK = "OK"
    case EMPTY = ""
    case AUTHVIA_FP_DISABLED = "AUTHVIA_FP_DISABLED"
}

enum LockWifiRFIDMessages: String {
    case RF_FOB_ENROLLED = "RF_FOB_ENROLLED"
    case RF_NO_DETECT_OR_MATCH = "RF_NO_DETECT_OR_MATCH"
    case RF_NO_FREE_SLOTS = "RF_NO_FREE_SLOTS"
    case RF_ALREADY_EXISTS = "RF_ALREADY_EXISTS"
    case RF_MAX_TRIES_EXIT = "RF_MAX_TRIES_EXIT"
    case OK = "OK" //(Place 2nd or 3rd time Status Code : 200)
    case RF_ID_ALREADY_EMPTY = "RF_ID_ALREADY_EMPTY"
    case RF_ID_NOT_EXISTS = "RF_ID_NOT_EXISTS"
    case EMPTY = ""
}

enum LockWifiDIGIPINMessages: String {
    case TP_PIN_OTP_INVALID_FORMAT = "TP_PIN_OTP_INVALID_FORMAT"
    case TP_PIN_OTP_INVALID_LEN = "TP_PIN_OTP_INVALID_LEN"
    case TP_PIN_OTP_ALREADY_EXISTS = "TP_PIN_OTP_ALREADY_EXISTS"
    case AUTHVIA_TP_DISABLED = "AUTHVIA_TP_DISABLED"
    case OK = "OK"
    case EMPTY = ""
}

enum LockWifiPINManagePrivilegeMessages: String {
    case AUTHVIA_TP_DISABLED = "AUTHVIA_TP_DISABLED"
    case OK = "OK"
    case EMPTY = ""
}
enum LockWifiPassageModeManagePrivilegeMessages: String {
  //  case AUTHVIA_TP_DISABLED = "AUTHVIA_TP_DISABLED"
    case OK = "OK"
    case EMPTY = ""
}

enum LockWifiFPManagePrivilegeMessages: String {
    case AUTHVIA_FP_DISABLED = "AUTHVIA_FP_DISABLED"
    case OK = "OK"
    case EMPTY = ""
}

enum ServerUrl : String {
    case versionConfiguration = "versions/configlist"
}

enum LockWiFiMqttConfigMessages: String {
    case WIFI_NOT_CONNECTED = "WIFI_NOT_CONNECTED"
    case MQTT_NOT_CONNECTED = "MQTT_NOT_CONNECTED"
    case OK = "OK"
    case EMPTY = ""
}

enum MqttInfo: String {
   case MQTT_SERVICE_URL = "http://fortlive.co.in/api/web/v1/activities:80"
   // case MQTT_SERVICE_URL = "http://fortstaging.co.in/api/web/v1/activities:80"//"smartlock.payoda.com:1883"
}

typealias LockWifiResponseCompletionBlock = (_ isSuccess:Bool,_ response:JSON?,_ error:String?) -> Void
typealias LockWifiReadBatteryCompletionBlock = (_ isSuccess:Bool,_ response:String?,_ error:String?) -> Void

class LockWifiManager {
    static let wifiUrl = "http://192.168.4.1/"
    static var shared:LockWifiManager = LockWifiManager()
    var localCache = LockWifiLocalCache()
    func verifyIfLockWifiServerIsReachable(completion:@escaping LockWifiResponseCompletionBlock) {
        let url = LockWifiManager.wifiUrl
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        AF.request(url, method: HTTPMethod.head, parameters: [:], encoding: JSONEncoding.default, headers: headers).response{ response in
            if response.response?.statusCode == 200 {
                completion(true,"","")
            }
            else{
                completion(false,"",response.error?.localizedDescription)
            }
        }
    }
    struct LockActivationResponse: Codable {
        // Define properties that match the structure of your JSON response
        // For example:
        // let success: Bool
        // let message: String?
    }
    struct AuthViaPinFp: Codable {
        var ownerId: String?
        var slotKey: String?
        var enDis: String?
    }
    
    struct LockActivationResponseForHomeWifi: Codable {
        var status: String?
        var errorCode: Int?
        var errorMessage: String?
        var response: LockActivationResponse?
        var ssid :String?
        // Assuming response can be any type of dictionary
        enum CodingKeys: String, CodingKey {
            case status
            case errorCode = "error-code"
            case errorMessage = "error-message"
            case response
        }
        init(from decoder: Decoder) throws {
            var container = try decoder.container(keyedBy: CodingKeys.self)
            self.status = try container.decode(String.self, forKey: .status)
            self.errorCode = try container.decode(Int.self, forKey: .errorCode)
            self.errorMessage = try container.decode(String.self, forKey: .errorMessage)
            self.response = try container.decode(LockActivationResponse.self, forKey: .response)
            
        }
    }
    
    func activateLock(activationCode: String, completion: @escaping LockWifiResponseCompletionBlock) {
        debugPrint("Activation Code \(activationCode)")
        let activationCodeAsHex = String.stringToHexString(regularString: activationCode)
        let activationCodeHeader = ["activation-code": activationCodeAsHex]
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.activate.rawValue
        debugPrint("URL \(url)")
        print("activateLock URL = \(url)")
        
        AF.request(url, method: .post, parameters: activationCodeHeader, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of:LockWifiManager.LockActivationResponse.self) { response in
                switch response.result {
                    case .success(let activationResponse):
                        let json = JSON(activationResponse)
                        // Handle successful decoding
                        self.deActivateLock(activationCode: activationCodeHeader, completion: nil)
                        completion(true, json, "")
                    case .failure(let error):
                        // Handle decoding failure
                        completion(false, nil, error.localizedDescription)
                }
            }
    }
    
    func deActivateLock(activationCode: [String:String], completion: LockWifiResponseCompletionBlock?) {
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.deactivate.rawValue
        AF.request(url, method: .post, parameters: activationCode, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    
                    //print("Deactivation completed")
                }
                else{
                    //print("Deactivation failed")
                }
            }
    }
    
    func transferOwnership(disengageCode: [String: String], slotNumber:String,oldOwnerId:String,completion:@escaping LockWifiResponseCompletionBlock) {
        setDateTime(userDetails: disengageCode)
        
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.disengage.rawValue
        AF.request(url, method: .post, parameters: disengageCode, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    self.readAllIds(userDetails: disengageCode, completion: completion)
                }
                else{
                    completion(false,"",response.error?.localizedDescription)
                }
            }
        
        //print("First engagement lock %%%%%%%%%%%%%%%")
        
        if let lockId = disengageCode["lockId"]{
            print("lock id ====> \(lockId)")
            //            readBatteryLevel(userDetails: disengageCode, lockId: lockId)
            readBatteryLevel(userDetails: disengageCode, lockId: lockId) { (isSuccess, result, error) in
                
            }
            readAccessLogs(userDetails: disengageCode, lockId: lockId) { (iSuccess, json, string) in
                
            }
        }
    }
    func disenegageLock(disengageCode: [String: String], completion:@escaping LockWifiResponseCompletionBlock) {
        setDateTime(userDetails: disengageCode)
        
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.disengage.rawValue
        AF.request(url, method: .post, parameters: disengageCode, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                //print("response ==> ")
                //print(response)
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,"","")
                }
                else{
                    completion(false,"",response.error?.localizedDescription)
                }
            }
        
        if let lockId = disengageCode["lockId"]{
            //            readBatteryLevel(userDetails: disengageCode, lockId: lockId)
            readBatteryLevel(userDetails: disengageCode, lockId: lockId) { (isSuccess, result, error) in
                
            }
            readAccessLogs(userDetails: disengageCode, lockId: lockId) { (iSuccess, json, string) in
                
            }
        }
    }
    
    func didFactoryReset(factoryReset: [String: String], completion:@escaping LockWifiResponseCompletionBlock) {
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.factoryReset.rawValue
        AF.request(url, method: .post, parameters: factoryReset, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,"","")
                }
                else{
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    func lockStatus(userDetails: [String: String], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters? = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.lockStatus.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                let json = self.handleResponse(responseObj: response).json
                //print("\(String(describing: json?.dictionary.debugDescription))")
                if response.response?.statusCode == 200 {
                    
                    self.readAllIds(userDetails: userDetails, completion: completion)
                }
                else{
                    completion(false,"",response.error?.localizedDescription)
                }
            }
        
    }
    func setDateTime(userDetails: [String: String]) {
        // assume owner id and key comes in
        var dateTimeDetails = userDetails as [String: Any]
        let DateTime = Date().currentDateTimeString()
        let dateD = "\(Utilities().localToUTCForHardware(date: Date().currentDateTimeString()).components(separatedBy: " ")[0])\0"
        //let timeD = "\(Utilities().localToUTCForHardware(date: Date().currentDateTimeString()).components(separatedBy: " ")[1])\0"
        
        print("time for disengage \(DateTime)")
        let components = DateTime.components(separatedBy: " ")
        let timeD = components.count > 1 ? components[1] : ""
        print("Time: \(timeD)")
        
        dateTimeDetails["date"] = dateD//Date().currentDateString()
        dateTimeDetails["time"] = timeD//Date().currentTimeString()
        let parameters: Parameters? = dateTimeDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        print("parameters for date and time \(parameters)")
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.dateTime.rawValue
        //print("setDateTime url ==> \(url)")
        //print("setDateTime parameters ==> \(parameters)")
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                let json = self.handleResponse(responseObj: response).json
                //print("\(String(describing: json?.dictionary.debugDescription))")
                if response.response?.statusCode == 200 {
                    
                }
                else{
                    //print("date and time changed failed")
                }
            }
    }
    
    func doFactoryReset(userDetails: [String: String]) {
        // assume owner id and key comes in
        var dateTimeDetails = userDetails
        dateTimeDetails["date"] = Date().currentDateString()
        dateTimeDetails["time"] = Date().currentTimeString()
        let parameters: Parameters? = dateTimeDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.dateTime.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                let json = self.handleResponse(responseObj: response).json
                //print("\(String(describing: json?.dictionary.debugDescription))")
                if response.response?.statusCode == 200 {
                    //print("Factory reset success")
                }
                else{
                    //print("Factory reset failed")
                }
            }
    }
    
    func readBatteryLevel(userDetails: [String: String], lockId:String, completion:@escaping LockWifiReadBatteryCompletionBlock) {
        let parameters: Parameters? = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.batteryLevel.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                let json = self.handleResponse(responseObj: response).json
                //print("\(String(describing: json?.dictionary.debugDescription))")
                
                //print("JSON ==> ")
                //print(json)
                if response.response?.statusCode == 200 {
                    //print("battery read")
                    //todelete
                    //                    let batteryLevel = json?.dictionary!["response"]!["Battery-Level"].string!
                    
                    let batteryLevel = json?.dictionary!["response"]!["Battery-Level"].stringValue
                    
                    
                    LockWifiManager.shared.localCache.updateBattery(lockId: lockId, batteryLevel: batteryLevel!)
                    
                    completion(true,batteryLevel!,"")
                    
                }
                else{
                    //print("battery read failed")
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    
    
    
    func readAccessLogs(userDetails: [String: String],lockId:String, completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.accessLogs.rawValue
        //print("readAccessLogs url ==> \(url)")
        //print("readAccessLogs parameters ==> \(parameters)")
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    let logsDict = json!["response"]
                    debugPrint("logs ------>>>>> \(logsDict)")
                    if logsDict.dictionary != nil {
                        let allKeys = logsDict.dictionaryObject?.keys
                        let logDict = logsDict.dictionaryObject
                        if allKeys != nil && allKeys!.count > 0 {
                            for key in allKeys!{
                                let actualLog = logDict![key]
                                LockWifiManager.shared.localCache.appendLogsFor(lockId: lockId, log: actualLog as! String)
                            }
                        }
                        
                    }
                    
                    //todelete
                    completion(true,"","")
                }
                else{
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    func rewriteUserSlotKey(userDetails: [String: String], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.rewriteSlot.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                }
                else{
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    func readAllIds(userDetails: [String: String], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.readKeys.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                }
                else{
                    completion(false,nil,response.error?.localizedDescription)
                }
            }
    }
    
    // Add/Enroll Finger print
    func enrollFingerPrint(userDetails: [String: String], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json; charset=utf-8"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.enrollFingerPrint.rawValue
        //        let url = "https://smartlock.free.beeceptor.com/enroll-fp"
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    // Success case - Response is 200 and no error in JSON
                    completion(true,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    
    // Revoke Finger print
    func revokeFingerPrint(userDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json; charset=utf-8"]
        //        let url = "https://smartlock.free.beeceptor.com/revoke-fp"
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.revokeFingerPrint.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(true,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    
    // Enroll/update RFID
    func enrollRFID(userDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        //        let url = "https://smartlock.free.beeceptor.com/enroll-rfid"
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.enrollRFID.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(true,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    
    // Revoke RFID
    func revokeRFID(userDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        //        let url = "https://smartlock.free.beeceptor.com/revoke-rfid"
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.revokeRFID.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(true,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    // Configure Home WiFi
    func configureHomeWiFiMqtt(wifiDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = wifiDetails
        print("home wifi parameters passing to api call are\(parameters)")
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        print("homewifi auth token = \(authToken)")
        let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        print("homewifi bundle id = \(bundleIdentifier)")
        let headers:HTTPHeaders = ["Content-Type": "application/json; charset=utf-8","bundle-id":bundleIdentifier,"Authorization":authToken]
        let url = "http://192.168.4.1/config-wifi-http"  //LockWifiManager.wifiUrl + LockWifiRESTMethods.configWiFiMqtt.rawValue
        print("home wifi mqtt url = \(url)")
        print("home wifi headers\(headers)")
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponseForHomeWifi.self) { response in
                debugPrint("Home wifi response: \(response)")
                let json = self.handleResponse(responseObj: response).json
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(false,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    func pushServerLock(LockDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        let parameters: Parameters = LockDetails
        print("push lock parameters passing to api call are\(parameters)")
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        print("push lock auth token = \(authToken)")
        let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        print("push lock bundle id = \(bundleIdentifier)")
        let headers:HTTPHeaders = ["Content-Type": "application/json; charset=utf-8","bundle-id":bundleIdentifier,"Authorization":authToken]
       let url = "https://fortlive.co.in/api/web/v1/ddddd"
       // let url = "https://fortstaging.co.in/api/web/v1/ddddd"
        print("push lock url = \(url)")
        print("push lock headers\(headers)")
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                debugPrint("push lock response: \(response)")
                
                let json = self.handleResponse(responseObj: response).json
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(false,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    
    
    func getWiFiSsid() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            
            debugPrint("interfaces ==> ")
            print(interfaces)
            
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    
                    
                    print(interfaceInfo)
                    
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    debugPrint("inside loop ==> interfaceInfo ==>\(String(describing: ssid)) ")
                    break
                }
            }
        }
        return ssid
    }
    
    //     func handleResponse<T>(responseObj: DataResponse<T, AFError>) -> (json: JSON?, error: NSError?) where T : Decodable {
    //            let jsonObject = JSON(responseObj.data as Any)
    //            // Success case - Response is 200 and no error in JSON
    //            guard responseObj.response?.statusCode != 200 else {
    //                return (json: jsonObject, nil)
    //            }
    //            if responseObj.data != nil{
    //                let errorString = String(data: responseObj.data!, encoding: .utf8)
    //                if errorString != nil{
    //                    //print("error \(String(describing: errorString))")
    //                }
    //            }
    //            return (json: nil, error:nil)//"JSON Parser error")
    //        }
    func handleResponse<T>(responseObj: DataResponse<T, AFError>) -> (json: JSON?, error: NSError?) where T : Decodable {
        let jsonObject = JSON(responseObj.data as Any)
        
        // Check if the response status code is 200
        if let statusCode = responseObj.response?.statusCode, statusCode != 200 {
            print("Lock wifi Status Code: \(statusCode)")
            let error = NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid status code \(statusCode)"])
            return (json: nil, error: error)
        }
        
        // Success case - Response is 200 and no error in JSON
        return (json: jsonObject, error: nil)
    }
    
}






extension LockWifiManager{
    // Add Digi Pin
    func addDigiPin(userDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        
        //        let parameters: Parameters = userDetails
        ////               let headers = ["Content-Type": "application/json"]
        //        var authToken = ""
        //        let authTokenValue = "H5X9Kq2smPsle78P53q6-S6b0v8FSjfR" //UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        //        authToken = "Bearer " + authTokenValue
        //        let headers = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        //               let url =  "https://smartlock.payoda.com/api/web/v1/hardwares/rewrite-pin"
        
        
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.addDidiPins.rawValue
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(false,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    
    func addOTP(userDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        
        //         Lock Connection
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url =  LockWifiManager.wifiUrl + LockWifiRESTMethods.addOTP.rawValue
        
        
        //        // Server Connection
        //        let parameters: Parameters = userDetails
        //        var authToken = ""
        //        let authTokenValue = "H5X9Kq2smPsle78P53q6-S6b0v8FSjfR" //UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        //        authToken = "Bearer " + authTokenValue
        //        let headers = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        //        let url = "https://smartlock.payoda.com/api/web/v1/hardwares/rewrite-otp"
        
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(true,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
}

// MARK: Update Pin Privilege
extension LockWifiManager{
    func updatePinManagePrivilege(userDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        
        // Lock Connection
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url =  LockWifiManager.wifiUrl + LockWifiRESTMethods.updatePinPrivilege.rawValue
        
        
        // Server Connection
        //        let parameters: Parameters = userDetails
        //        var authToken = ""
        //        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        //        authToken = "Bearer " + authTokenValue!
        //        let headers = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        //        let url = "https://smartlock.payoda.com/api/web/v1/hardwares/authvia-pin"
        
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(true,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
}


// MARK: Update FP Privilege

extension LockWifiManager{
    func updateFPManagePrivilege(userDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        
        // Lock Connection
        let parameters: Parameters = userDetails
        let headers:HTTPHeaders = ["Content-Type": "application/json"]
        let url =  LockWifiManager.wifiUrl + LockWifiRESTMethods.updateFPPrivilege.rawValue
        
        
        // Server Connection
        //        let parameters: Parameters = userDetails
        //        var authToken = ""
        //        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        //        authToken = "Bearer " + authTokenValue!
        //        let headers = ["Authorization": authToken, "Content-Type": "application/json", "bundle_id" : Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String]
        //        let url = "https://smartlock.payoda.com/api/web/v1/hardwares/authvia-fp"
        
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponse.self) { response in
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    //print("\(String(describing: json?.dictionary.debugDescription))")
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(true,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
    
    func setPassageMode(userDetails: [String: Any], completion:@escaping LockWifiResponseCompletionBlock) {
        
        let url =  LockWifiManager.wifiUrl + LockWifiRESTMethods.passageMode.rawValue
        let parameters: Parameters = userDetails
        print("passage mode parameters passing to api call are\(parameters)")
        var authToken = ""
        let authTokenValue = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
        authToken = "Bearer " + authTokenValue!
        print("passage mode auth token = \(authToken)")
        let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        print("passage mode bundle id = \(bundleIdentifier)")
        let headers:HTTPHeaders = ["Content-Type": "application/json; charset=utf-8","bundle-id":bundleIdentifier,"Authorization":authToken]
        print("passage mode url = \(url)")
        print("passage mode headers\(headers)")
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: LockWifiManager.LockActivationResponseForHomeWifi.self) { response in
                debugPrint("passage mode response: \(response)")
                let json = self.handleResponse(responseObj: response).json
                if response.response?.statusCode == 200 {
                    let json = self.handleResponse(responseObj: response).json
                    completion(true,json,"")
                } else if response.response?.statusCode == 400 {
                    let jsonObject = JSON(response.data as Any)
                    completion(false,jsonObject,"")
                } else {
                    completion(false,"",response.error?.localizedDescription)
                }
            }
    }
}
