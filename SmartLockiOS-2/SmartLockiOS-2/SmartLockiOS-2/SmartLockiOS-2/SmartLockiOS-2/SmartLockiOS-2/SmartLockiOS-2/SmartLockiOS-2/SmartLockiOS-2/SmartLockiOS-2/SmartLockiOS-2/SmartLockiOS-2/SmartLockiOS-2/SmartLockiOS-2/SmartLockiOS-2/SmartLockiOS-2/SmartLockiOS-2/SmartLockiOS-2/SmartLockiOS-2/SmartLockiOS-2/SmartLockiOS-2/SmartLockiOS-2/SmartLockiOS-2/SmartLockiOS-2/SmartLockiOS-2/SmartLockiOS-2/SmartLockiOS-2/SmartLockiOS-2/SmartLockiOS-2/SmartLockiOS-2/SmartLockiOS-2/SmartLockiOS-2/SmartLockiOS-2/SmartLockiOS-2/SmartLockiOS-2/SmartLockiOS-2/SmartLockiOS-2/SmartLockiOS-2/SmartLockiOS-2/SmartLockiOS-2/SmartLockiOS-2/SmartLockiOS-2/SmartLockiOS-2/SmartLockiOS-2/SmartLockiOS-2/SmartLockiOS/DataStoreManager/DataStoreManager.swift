//
//  DataStoreManager.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 30/05/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON
import UIKit


class Connectivity {
    func isConnectedToInternet() -> Bool {
        //ssid check not working in iOS 14(Bug fix)
        
        let wifiSsid = LockWifiManager.shared.getWiFiSsid()
        let isConnectedToLock = wifiSsid?.lowercased().contains(JsonUtils().getManufacturerCode().lowercased())
        if isConnectedToLock == true {
            return false
        }
        return NetworkReachabilityManager()!.isReachable
    }

    func isConnectedToLock() -> Bool {
        //ssid check not working in iOS 14(Bug fix)
        
        let wifiSsid = LockWifiManager.shared.getWiFiSsid()
        let isConnectedToLock = wifiSsid?.lowercased().contains(JsonUtils().getManufacturerCode().lowercased())
        if isConnectedToLock == true {
            return true
        }
        return false
    }
}

class DataStoreManager: NSObject {
    // Fetch the branding information against bundle id
    func brandingServiceDataStore(url: String, callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().brandingServiceCall(url: url, callback: { result, error in
            callback(result, error as NSError?)
        })
    }
    
    func loginServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        //        if Connectivity().isConnectedToInternet() {
        
        NetworkManager().loginServiceCall(url: url, userDetails: userDetails) { result, error in
            
            callback(result, error)
        }
        //        } else {
        //            // send failure
        //            var result = [String : AnyObject]()
        //            callback(result)
        //        }
    }
    
    func updateDeviceTokenDataStore(url: String, tokenDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        //        if Connectivity().isConnectedToInternet() {
        
        NetworkManager().updateDeviceTokenServiceCall(url: url, tokenDetails: tokenDetails) { result, error in
            
            callback(result, error)
        }
        //        } else {
        //            // send failure
        //            var result = [String : AnyObject]()
        //            callback(result)
        //        }
    }
    
    func signUpServiceDataStore(url: String, userDetails: [String: String], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        //        if Connectivity().isConnectedToInternet() {
        
        NetworkManager().signUpServiceCall(url: url, userDetails: userDetails as [String: AnyObject]) { result, error in
            callback(result, error)
        }
        //        } else {
        //            // send failure
        //            var result = [String : AnyObject]()
        //            callback(result)
        //        }
    }
    
    func forgotPasswordServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        //        if Connectivity().isConnectedToInternet() {
        
        NetworkManager().forgotPasswordServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
        //        } else {
        //            // send failure
        //            var result = [String : AnyObject]()
        //            callback(result)
        //        }
    }
    
    // MARK: - Profile
    
    func getProfileServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getProfileDetailsServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func updateProfileServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().updateProfileDetailsServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    // MARK: - Lock
    
    func getLockListServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        //        if Connectivity().isConnectedToInternet() {
        NetworkManager().getLockListServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
        //        } else {
        //            // fetch from Db
        //            callback(nil, error)
        //        }
    }
    
    func addLockDetailsServiceDataStore(url: String, userDetails: [String: Any], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        //        if Connectivity().isConnectedToInternet() {
        NetworkManager().addLockDetailsServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
        //        } else {
        // update data in DB
        //
        //        }
    }
    
    func updateLockDetailsServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        //        if Connectivity().isConnectedToInternet() {
        NetworkManager().updateLockDetailsServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
        //        } else {
        // fetch from Db
        
        //        }
    }
    
    // MARK: - Request
    
    func getRequestListServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        //        if Connectivity().isConnectedToInternet() {
        NetworkManager().getRequestListServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
        //        } else {
        // fetch from Db
        
        //        }
    }
    
    // MARK: - Assign Users
    
    func getLockUsersListServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getLockUsersListServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func createRequestUserServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().createRequestUserServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func updateRequestUserServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().updateRequestUserServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func revokeRequestUserServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().revokeRequestUserServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    // MARK: - Schedule Access
    
    func createOrUpdateScheduleAccessServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().createRequestUserServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    // MARK: - Finger print Access
    
    func updateFingerPrintUserPrivilegeServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().updateFingerPrintUserPrivilegeServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    // MARK: - Update Transfer Owner request
    
    func updateTransferOwnerRequestUserServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().updateTransferOwnerRequestUserServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    // MARK: - Withdraw Transfer Owner
    
    func withdrawTransferOwnerRequestUserServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().withdrawTransferOwnerRequestUserServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    // MARK: - Notification list
    
    func getNotificationListServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getNotificatioListServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func getActivityListServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getActivityListServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func getActivityNotificationListServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getActivityNotificationListServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func postBatteryUpdate(batteryId: String,batteryLevel: String,callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void){
        let url = ServiceUrl.BASE_URL + "locks/updatelock?id=\(batteryId)"
        let userDetails = ["battery":batteryLevel]
        NetworkManager().postBatteryUpdate(url: url, userDetails: userDetails as [String : AnyObject], callback: { result, error in
            callback(result, error)
        })
    }
    
    func postLogsUpdate(logs: [String],lockId: String,callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void){
        let url = ServiceUrl.BASE_URL + "activities/addactivity?id=\(lockId)"
        let userDetails = ["data":logs]
        NetworkManager().postActivityLogs(url:url,userDetails: userDetails as [String : AnyObject]) { result, error in
            callback(result, error)
        }
    }
    
    // MARK: - Logout
    
    func logoutServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void){
        
        NetworkManager().logout(url: url, userDetails: userDetails, callback: { (result, error) in
            callback(result, error)
        })
    }
    
    // MARK: - DeleteAccount
    
    func deleteAccountServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void){
        
        NetworkManager().deleteAccount(url: url, userDetails: userDetails, callback: { (result, error) in
            callback(result, error)
        })
    }
    
    // MARK: - RFID list
    
    func getRFIDListServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getRFIDListServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    // MARK: - FP
    func getFPListServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getFPListServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func getExistingLockUserServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getExistingLockUserServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func createFingerPrintServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().createFingerPrintServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func updateFingerPrintServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().updateFingerPrintServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    
    func editUserNameServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().editUserNameServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func addDigiPinsServiceDataStore(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().addDigiPinsPrintServiceCall(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func getDigiPinListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ data : Data,_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getDigiPinListServiceCall(url: url, userDetails: userDetails) {data, result, error in
            callback(data, result, error)
        }
    }
    
    func getOTPListServiceCall(url: String, userDetails: [String: AnyObject], callback: @escaping (_ data : Data,_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().getOTPListServiceCall(url: url, userDetails: userDetails) {data, result, error in
            callback(data, result, error)
        }
    }
    
    // MQTT
    func addLockViaMqtt(url: String, lockDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().addLockViaMqtt(url: url, lockDetails: lockDetails) { result, error in
            callback(result, error)
        }
    }
    
    func engageLockViaMqtt(url: String, lockDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().engageLockViaMqtt(url: url, lockDetails: lockDetails) { result, error in
            callback(result, error)
        }
    }
    
    func revokeUserViaMqtt(url: String, lockDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().revokeUserViaMqtt(url: url, lockDetails: lockDetails) { result, error in
            callback(result, error)
        }
    }
    
    func revokeFingerprintViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().revokeFingerprintViaMqtt(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func revokeRfidViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().revokeRfidViaMqtt(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func manageFingerprintViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().manageFingerprintViaMqtt(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func managePinViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().managePinViaMqtt(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func updatePinViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().updatePinViaMqtt(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func updateOtpViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().updateOtpViaMqtt(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    func acceptTransferOwnerViaMqtt(url: String, userDetails: [String: AnyObject], callback: @escaping (_ json: JSON?, _ error: NSError?) -> Void) {
        NetworkManager().acceptTransferOwnerViaMqtt(url: url, userDetails: userDetails) { result, error in
            callback(result, error)
        }
    }
    
    
}

extension DataStoreManager{
   
}
