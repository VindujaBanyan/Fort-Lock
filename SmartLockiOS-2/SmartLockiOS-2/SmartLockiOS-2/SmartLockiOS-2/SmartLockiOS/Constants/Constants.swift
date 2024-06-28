//
//  Constants.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 05/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

let CONNECTIVITY_TIME = 13.0
var BLE_ACTIVE_TIME = 7.0

let ALERT_TITLE = Bundle.main.object(forInfoDictionaryKey: "AlertHeading") as! String
let AppCenterKey = Bundle.main.object(forInfoDictionaryKey: "AppCenterKey") as! String
let IsFromProduction = (Bundle.main.object(forInfoDictionaryKey: "IsFromProduction") as! NSString).boolValue
let ScratchCodeValidationCount = (Bundle.main.object(forInfoDictionaryKey: "ScratchCodeValidationCount") as! NSString).intValue
let ScratchCodeEnterCount = (Bundle.main.object(forInfoDictionaryKey: "ScratchCodeLength") as! NSString).intValue
let AppVersionVisibility = (Bundle.main.object(forInfoDictionaryKey: "AppVersionVisibility") as! NSString).boolValue
let BatteryLevelVisibility = (Bundle.main.object(forInfoDictionaryKey: "BatteryLevelVisibility") as! NSString).boolValue
let FactoryResetVisibility = (Bundle.main.object(forInfoDictionaryKey: "FactoryResetVisibility") as! NSString).boolValue
let EncryptionIv = Bundle.main.object(forInfoDictionaryKey: "EncryptionIv") as! String
let EncryptionKey = Bundle.main.object(forInfoDictionaryKey: "EncryptionKey") as! String
let EncryptionPassword = Bundle.main.object(forInfoDictionaryKey: "EncryptionPassword") as! String
let BuildTarget = Bundle.main.object(forInfoDictionaryKey: "BuildTarget") as! String

let BundleIdentifier = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String



let ScratchCodePrefix = Bundle.main.object(forInfoDictionaryKey: "ScratchCodePrefix") as! String
let AppLogo = Bundle.main.object(forInfoDictionaryKey: "AppLogo") as! String

let VERSION_2 = "v2.0"
let VERSION_3 = "v3.0"
let USER_PRIVILEGE = ""

// Error Messages

let EMAIL_VALIDATION_ERROR = "Please  enter a valid email id to create an account"
let MOBILE_VALIDATION_ERROR = "Please enter a valid mobile number."
let NAME_VALIDATION_ERROR = "Accepts 25 characters only"
let ADDRESS_VALIDATION_ERROR = "Please enter a valid address"//"Accepts 60 characters only"
let PASSWORD_VALIDATION_ERROR = "Please enter a valid password"

let EMAIL_MANDATORY_ERROR = "Email ID is mandatory"
let PASSWORD_MANDATORY_ERROR = "Password is mandatory"
let NAME_MANDATORY_ERROR = "Name is mandatory"
let CONFIRM_PASSWORD_MANDATORY_ERROR = "Confirm password is mandatory"
let MOBILE_MANDATORY_ERROR = "Mobile Number is mandatory"
let ADDRESS_MANDATORY_ERROR = "Address is mandatory"

let LOCKCODE_MANDATORY_ERROR = "Lock code is mandatory"
let LOCKCODE_VALID_ERROR = Bundle.main.object(forInfoDictionaryKey: "ScratchCodeError") as! String
let LOCKNAME_MANDATORY_ERROR = "Please set a lock name"
let INVALID_LOCK_CODE = "Invalid Lock code. Please enter a valid lock code."

let LOGIN_VALIDATION_ERROR = "Incorrect email or password"
let PASSWORD_MATCH_ERROR = "Password and Confirm password does not match"

let SETTINGS_NAVIGATION = "For security, the system prohibits any app from jumping to the Wi-Fi setting page. Please connect manually"

let TURN_ON_WIFI = "Please turn on Wi-Fi to access the lock"

let TURN_ON_BLUETOOTH = "Please ensure your phone Bluetooth is turned ON"
let TURN_ON_LOCK = "Please switch on the lock and try again"
let ADD_LOCK_SCCESS_MESSAGE = "Lock added Successfully"
let ENGAGE_LOCK_SUCCESS_MESSAGE = "Lock engaged successfully"
let INVALID_CONTACT_SELECTION = "Unable to choose the contact. Please make sure the number is correct and try again."

let ASSIGN_USER_SENT_MESSAGE = "Request sent successfully"
let ASSIGN_USER_WITHDRAW_MESSAGE = "Request withdrawn successfully"
let ASSIGN_USER_REVOKE_MESSAGE = "Access revoked successfully"

let FACTORY_RESET_MESSAGE = "Are you sure to reset the hardware? (Access to the lock will be removed for all the users and the lock needs to be added newly) Please confirm."

let INTERNET_CONNECTION_VALIDATION = "No Internet. Please check your network connection."
let LOGOUT_FAILED = "Oops something went wrong. Please try later"//"Failed to logout"
let LOGOUT_SUCCESS = "Logged out successfully"
let LOGOUT_CONFIRMATION = "Are you sure you want to logout?"
let EMPTY_LOCK_LIST = "You do not have any locks associated. Please add lock to proceed"

let FORCE_SYNC_FAILED = "Oops something went wrong. Please try later"//"Failed to logout"
let FORCE_SYNC_SUCCESS = "Data synced successfully"//"Failed to logout"

let SCHEDULED_ACCESS_SUCCESS_MESSAGE = "Scheduled access created successfully"
let SCHEDULED_ACCESS_UPDATE_MESSAGE = "Scheduled access updated successfully"

let START_DATE_MANDATORY = "Start date is mandatory"
let END_DATE_MANDATORY = "End date is mandatory"
let START_TIME_MANDATORY = "Start time is mandatory"
let END_TIME_MANDATORY = "End time is mandatory"
let VALID_END_DATE = "Please select valid end date"
let VALID_END_TIME = "Please select valid end time"

let WIFI_SSID_MANDATORY_ERROR = "Please enter wifi ssid"
let WIFI_PASSWORD_MANDATORY_ERROR = "Please enter wifi password"
let WIFI_PASSWORD_LENGTH_ERROR = "Wifi password length must be atleast 8 characters"

let UNABLE_TO_CONNECT_LOCK = Bundle.main.object(forInfoDictionaryKey: "UnableTo_connect") as! String

let ADD_RFID_INSTRUCTION = "Please place the RFID on lock. And follow the instructions."
let ADD_FP_INSTRUCTION = "Please place the finger on lock. And follow the instructions."
let RFID_ADDED_SUCCESS = "RFID added successfully"
let FP_ADDED_SUCCESS = "Finger print added successfully"

let DELETE_ACCOUNT_TITLE = "Delete Account"
let DELETE_ACCOUNT_MSG = "Are you sure you want to delete the account?"

// Colors

let BUTTON_BGCOLOR = UIColor(red: 254 / 255.0, green: 158 / 255.0, blue: 67 / 255.0, alpha: 1.0)
let TABS_BGCOLOR = UIColor(red: 252 / 255.0, green: 195 / 255.0, blue: 73 / 255.0, alpha: 1.0)

let ACCEPT_COLOR = UIColor(red: 89 / 255.0, green: 188 / 255.0, blue: 118 / 255.0, alpha: 1.0)
let REJECT_COLOR = UIColor(red: 238 / 255.0, green: 80 / 255.0, blue: 54 / 255.0, alpha: 1.0)
let WITHDRAW_COLOR = UIColor(red: 0 / 255.0, green: 60 / 255.0, blue: 118 / 255.0, alpha: 1.0)

// FINGER PRINT WIFI MESSAGES
let FP_NEXT_SAMPLE2 = "Please place the same finger again 2 of 3"
let FP_NEXT_SAMPLE3 = "Please place the same finger again 3 of 3" //  (Alert dialog Next button will show)"
let FP_NOT_PLACED = "Its seems the finger is not placed properly. Please try again"//  (Alert dialog Next button will show)"
let FP_MAX_TRIES_EXIT = "Please try after some time. The maximum number try exists"
let FP_TRY_OTHER_FINGER = "Please try with different side of finger"// (Alert dialog Next button will show)"
let FP_UID_ENROLLED = "Fingerprint added successfully"
let FP_USER_ID_NOT_EXISTS = "The Fingerprint doesn’t exists"
let FP_MAX_USR = "Maximum number of fingerprint per SDC device is 25. Maximum limit reached."
let FP_UID_REVOKED = "Fingerprint revoked successfully"
let FP_ID_ALREADY_EMPTY = "No fingerprint enrolled for the requested user ID"
let FP_NOT_CONNECTED = "Fingerprint module not connected"
let FP_BAD_FINGER = "Bad Finger detected. Please try again"

// RFID WIFI Messages
let RF_FOB_ENROLLED = "RFID Added Successfully"
let RF_NEXT2 = "Please place the RFID 2 of 3" //  (Alert dialog Next button will show)
let RF_NEXT3 = "Please place the RFID 3 of 3" //  (Alert dialog Next button will show)
let RF_NO_DETECT_OR_MATCH = "RF fob key is not detected or matched with previous swipe. Please try again" //  (Alert dialog Next button will show)"
let RF_NO_FREE_SLOTS = "No empty slots available to add new RF Fob key."
let RF_ALREADY_EXISTS = "RF fob key already exists or enrolled."
let RF_ID_NOT_EXISTS = "RF fob key does not exists."
let RF_MAX_TRIES_EXIT = "RF fob key maximum swipes exceeded."
let RF_REVOKED_OK = "RFID Deleted Successfully"
let RF_ID_ALREADY_EMPTY = "Delete the RF slot when its already empty."

// DIGIPIN WIFI Messages
let TP_PIN_INVALID_FORMAT = "Invalid PIN format."
let TP_PIN_INVALID_LEN = "Invalid PIN length."
let TP_PIN_ALREADY_EXISTS = "PIN already exists."
let TP_PIN_OK = "PIN added successfully"

// OTP WIFI Messages
let TP_OTP_INVALID_FORMAT = "Invalid OTP format."
let TP_OTP_INVALID_LEN = "Invalid OTP length."
let TP_OTP_ALREADY_EXISTS = "OTP already exists."
let TP_OTP_OK = "OTP added successfully"

// PIN MANAGE PRIVILEGE Messages
let PIN_MANAGE_PRIVILEGE_ENABLE = "PIN access enabled Successfully."
let PIN_MANAGE_PRIVILEGE_DISABLE = "PIN access disabled Successfully."
let PIN_MANAGE_PRIVILEGE_FAILED = "Authentication Failed."


// PIN MANAGE PRIVILEGE Messages
let FP_MANAGE_PRIVILEGE_ENABLE = "Finger Print access enabled Successfully."
let FP_MANAGE_PRIVILEGE_DISABLE = "Finger Print access disabled Successfully."
let FP_MANAGE_PRIVILEGE_FAILED = "Authentication Failed."

// Home Wifi and Mqtt Messages
let HOME_WIFI_MQTT_OK = "Wifi configuration updated Successfully."
let WIFI_NOT_CONNECTED = "WiFi is not connected. Please check your WiFi credentials."
let MQTT_NOT_CONNECTED = "Something went wrong. Please try again."


enum lockVersions : String {
    case version1 = ""
    case version2_0 = "v2.0"
    case version2_1 = "v2.1"
    case version3_0 = "v3.0"
    case version3_1 = "v3.1"
    case version4_0 = "v4.0"
}

extension UIViewController {
    
    func getActivityTime(lockVersion : lockVersions) -> Double{
        
        if let configurationValue = getJSON(UserdefaultsKeys.versionConfiguration.rawValue)
        {
            var strWifiTime = String()
            switch lockVersion {
            case .version1:
                strWifiTime = "\(String(describing: configurationValue["v1.0"]["wifi-time"]))"
                BLE_ACTIVE_TIME = Double("\(String(describing: configurationValue["v1.0"]["ble-time"]))") ?? 7.0
            case .version2_0:
                strWifiTime = "\(String(describing: configurationValue["v2.0"]["wifi-time"]))"
                BLE_ACTIVE_TIME = Double("\(String(describing: configurationValue["v2.0"]["ble-time"]))") ?? 7.0
            case .version2_1:
                strWifiTime = "\(String(describing: configurationValue["v2.1"]["wifi-time"]))"
                BLE_ACTIVE_TIME = Double("\(String(describing: configurationValue["v2.1"]["ble-time"]))") ?? 7.0
            case .version3_0:
                strWifiTime = "\(String(describing: configurationValue["v3.0"]["wifi-time"]))"
                BLE_ACTIVE_TIME = Double("\(String(describing: configurationValue["v3.0"]["ble-time"]))") ?? 7.0
            case .version3_1:
                strWifiTime = "\(String(describing: configurationValue["v3.1"]["wifi-time"]))"
                BLE_ACTIVE_TIME = Double("\(String(describing: configurationValue["v3.1"]["ble-time"]))") ?? 7.0
            case .version4_0:
                strWifiTime = "\(String(describing: configurationValue["v4.0"]["wifi-time"]))"
                BLE_ACTIVE_TIME = Double("\(String(describing: configurationValue["v4.0"]["ble-time"]))") ?? 7.0
            }
            return Double(strWifiTime) ?? 13.0
        }
        return 13.0
    }
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
}


