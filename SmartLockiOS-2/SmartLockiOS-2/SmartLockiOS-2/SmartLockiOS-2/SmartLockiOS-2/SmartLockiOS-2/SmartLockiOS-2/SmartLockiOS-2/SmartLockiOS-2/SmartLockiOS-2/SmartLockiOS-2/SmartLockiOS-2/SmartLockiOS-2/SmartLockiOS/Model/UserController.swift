//
//  UserController.swift
//  SmartLockiOS
//
//  Created by Dhilip on 7/6/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Foundation
class UserController {
    static var sharedController:UserController = UserController()
    var userRole:UserRoles = .user
    var ownerId:String = ""
    var userKey:String = ""
    var serialNumber:String = ""
    init() {

    }

    func lockKey(){

    }

    func save(ownerId:String,userKey:String,userRole:UserRoles,serialNumber:String) {
        let key = generateCustomKey(serialNumber: serialNumber)
        var dictionary:[String:String] = [:]
        dictionary["Owner_id"] = ownerId
        dictionary["User_key"] = userKey
        dictionary["userRole"] = userRole.rawValue
        UserDefaults.standard.set(dictionary, forKey: key)
        //print("Saving lock data for \(serialNumber)")
        loadDataOffline(forSerialNumber: serialNumber)
    }

    func loadDataOffline(forSerialNumber:String){
        //print("loading data for \(forSerialNumber)")
        let key = generateCustomKey(serialNumber: forSerialNumber)
        if let dictionary = UserDefaults.standard.object(forKey: key) as? [String:String] {
            self.ownerId = dictionary["Owner_id"] ?? ""
                self.userKey = dictionary["User_key"] ?? ""
                let role =  dictionary["userRole"] ?? ""
                self.userRole = UserRoles(rawValue: role)!
        }
        else{
            //print("loading failed for \(forSerialNumber)")
            self.userRole = .user
            self.ownerId = ""
            self.userKey = ""
            self.serialNumber = ""

            //print("lock data not present offline")
        }
    }

    func authorizationKey(isSecured: String) -> String? {
        if self.ownerId.isEmpty || self.userKey.isEmpty {
            return ""
        }
//        return "\(self.ownerId)\(self.userKey)" // Before implementing Encryption and decryption
        // Decrypt both owner id & slot key
        var isSecuredModified=false
        if isSecured=="1" {
            isSecuredModified=true
        }
        let decryptedOwnerID = Utilities().decryptStringToPlainString(plainString: self.ownerId, isSecured: isSecuredModified)
        let decryptedSlotKey = Utilities().decryptStringToPlainString(plainString: self.userKey, isSecured: isSecuredModified)
        print("Owner Id \(decryptedOwnerID)")
        print("Slot Key \(decryptedSlotKey)")
        return "\(decryptedOwnerID)\(decryptedSlotKey)"
    }

    func authorizationKeyForWifi(isSecured: String) -> [String:String]? {
        if self.ownerId.isEmpty || self.userKey.isEmpty {
            //print("authorization key was empty")
            return nil
        }
//        return ["owner-id":self.ownerId,"slot-key":self.userKey] // Before implementing Encryption and decryption
        // Decrypt both owner id & slot key
        var isSecuredModified=false
        if isSecured=="1" {
            isSecuredModified=true
        }
        let decryptedOwnerID = Utilities().decryptStringToPlainString(plainString: self.ownerId, isSecured: isSecuredModified)
        let decryptedSlotKey = Utilities().decryptStringToPlainString(plainString: self.userKey, isSecured: isSecuredModified)
        print("Owner ID:   "+decryptedOwnerID)
        print("Slot Key :  "+decryptedSlotKey)
        print("isSecured002 = \(isSecured)")
        return ["owner-id":decryptedOwnerID,"slot-key":decryptedSlotKey]
        

    }

    func generateCustomKey(serialNumber:String) -> String {
        return "\(serialNumber)-data"
    }
}
