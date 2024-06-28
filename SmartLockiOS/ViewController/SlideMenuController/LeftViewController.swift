//
//  LeftViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 04/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

enum LeftMenu: Int {
    case main = 0
    case profile
    case resetpin
    case transferowner
    case factoryreset
    case forceSync
    case deleteAccount
//    case logout
}

protocol LeftMenuProtocol : class {
    func changeViewController(_ menu: LeftMenu)
}

class LeftViewController : UIViewController, LeftMenuProtocol {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var welcomeTextLabel: UILabel!
    @IBOutlet weak var lblVersion: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var menus = ["Dashboard", "My Profile", "Reset PIN", "Transfer Owner", "Factory Reset", "Sync Data", "Delete Account"]//, "Logout"]
    

    var mainViewController: UIViewController!
    var profileViewController: UIViewController!
    var resetPinViewController: UIViewController!
    var transferOwnerViewController: UIViewController!
    var factoryResetViewController: UIViewController!

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblVersion.text = ""
        
        if FactoryResetVisibility {
            menus = ["Dashboard", "My Profile", "Reset PIN", "Transfer Owner", "Factory Reset", "Sync Data", "Delete Account"]//, "Logout"]
        } else{
            menus = ["Dashboard", "My Profile", "Reset PIN", "Transfer Owner", "Sync Data", "Delete Account"]//, "Logout"]
        }
        
        if AppVersionVisibility {
            lblVersion.text = "Version: \(Bundle.main.releaseVersionNumber ?? "1.0") Build: \(Bundle.main.buildVersionNumber ?? "1")"
        }
        
        getProfileDetails()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        let profileNav = UINavigationController(rootViewController: profileViewController)
        profileNav.navigationBar.setBackgroundImage(UIImage(), for: .default)
        profileNav.navigationBar.shadowImage = UIImage()
        profileNav.navigationBar.isTranslucent = true
        self.profileViewController = profileNav
        
        let resetPinViewController = storyboard.instantiateViewController(withIdentifier: "ValidatePinViewController") as! ValidatePinViewController
        let resetPinNav = UINavigationController(rootViewController: resetPinViewController)
        resetPinNav.navigationBar.setBackgroundImage(UIImage(), for: .default)
        resetPinNav.navigationBar.shadowImage = UIImage()
        resetPinNav.navigationBar.isTranslucent = true
        self.resetPinViewController = resetPinNav
        
        let transferOwnerVC = storyboard.instantiateViewController(withIdentifier: "TransferOwnerListViewController") as! TransferOwnerListViewController
        let transferOwnerNav = UINavigationController(rootViewController: transferOwnerVC)
        transferOwnerNav.navigationBar.setBackgroundImage(UIImage(), for: .default)
        transferOwnerNav.navigationBar.shadowImage = UIImage()
        transferOwnerNav.navigationBar.isTranslucent = true
        self.transferOwnerViewController = transferOwnerNav

        let factoryResetVC = storyboard.instantiateViewController(withIdentifier: "FactoryResetListViewController") as! FactoryResetListViewController
        let factoryResetNav = UINavigationController(rootViewController: factoryResetVC)
        factoryResetNav.navigationBar.setBackgroundImage(UIImage(), for: .default)
        factoryResetNav.navigationBar.shadowImage = UIImage()
        factoryResetNav.navigationBar.isTranslucent = true
        self.factoryResetViewController = factoryResetNav
        
      //  tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.registerTableViewCell()
    }
    
    func updateTextFont() {
        userNameLabel.font = UIFont.setRobotoRegular20FontForTitle
        welcomeTextLabel.font = UIFont.setRobotoRegular15FontForTitle
    }
    
    func registerTableViewCell() {
        let nib = UINib.init(nibName: "LeftViewTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "LeftViewTableViewCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let keychain = KeychainSwift()
        let password = "RNCryptorpassword"
        
        if let decryptValue = keychain.getData(KeychainKeys.userName.rawValue) {
            do {
                let decryptData = try RNCryptor.decrypt(data: decryptValue, withPassword: password)
                let decryptedString = String(decoding: decryptData, as: UTF8.self)
                self.userNameLabel.text = decryptedString
            } catch {
                // Handle decryption error
                print(error)
            }
        } else {
            // Handle case where decryptValue is nil
            print("Error: decryptValue is nil")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.layoutIfNeeded()
    }
    
    func changeViewController(_ menu: LeftMenu) {
        switch menu {
        case .main:
            self.slideMenuController()?.changeMainViewController(self.mainViewController, close: true)
        case .profile:
           
            if Connectivity().isConnectedToInternet() {
                self.slideMenuController()?.changeMainViewController(self.profileViewController, close: true)
                
            } else {
                
                self.showAlert(alertMessage: INTERNET_CONNECTION_VALIDATION)
            }
        case .resetpin:
            self.slideMenuController()?.changeMainViewController(self.resetPinViewController, close: true)
        case .transferowner:
           
            if Connectivity().isConnectedToInternet() {
                self.slideMenuController()?.changeMainViewController(self.transferOwnerViewController, close: true)
            } else {
                
                self.showAlert(alertMessage: INTERNET_CONNECTION_VALIDATION)
            }
            

        case .factoryreset:
                        if FactoryResetVisibility {
                            if Connectivity().isConnectedToInternet() {
                                self.slideMenuController()?.changeMainViewController(self.factoryResetViewController, close: true)
                            } else {
                                
                                self.showAlert(alertMessage: INTERNET_CONNECTION_VALIDATION)
                            }
                        } else {
                            self.forceSync()
                        }

            
            
//           if Connectivity().isConnectedToInternet() {
//                    self.slideMenuController()?.changeMainViewController(self.factoryResetViewController, close: true)
//                } else {
//                    
//                    self.showAlert(alertMessage: INTERNET_CONNECTION_VALIDATION)
//                }
//            
//        case .logout:
//            self.logoutAlert()
        case .forceSync:
            self.forceSync()
            
        case .deleteAccount:
            self.deleteAccount()
        }
    }
    
    // MARK: - Service Call
    func getProfileDetails() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "users/profile"
        
        /*
         "username":"spn",
         "password":"Payoda@123",
         "email":"spn@payoda.com",
         "mobile":"7788778877",
         "address":"kdfjvhiek",
         */
        
        
        ProfileViewModel().getProfileViewModel(url: urlString, userDetails: [:], callback: { (result, error) in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                // populate data from result and reload table
                
                let username = (result?.name)!
                let keychain = KeychainSwift()
                let password = "RNCryptorpassword"
                let userNameData = username.data(using: .utf8)
                let encryptedData = RNCryptor.encrypt(data: userNameData!, withPassword: password)
                keychain.set(encryptedData, forKey: KeychainKeys.userName.rawValue)
                
                let decryptValue = keychain.getData(KeychainKeys.userName.rawValue)
                do {
                    let decryptData = try RNCryptor.decrypt(data: decryptValue!, withPassword: password)
                    let decryptedString = String(decoding: decryptData, as: UTF8.self)
                    //print("securityPIN ==> \(String(describing: decryptedString))")
                    self.userNameLabel.text = decryptedString
                    // ...
                } catch {
                    //print(error)
                }
                
            } else {
//                let message = error?.userInfo["ErrorMessage"] as! String
//                self.showAlert(alertMessage: message)
            }
        })
    }
    
   
    func getLockListServiceCall(completion: @escaping (_ json: Array<Any>?, Bool) -> Void ) {
        
        let urlString = ServiceUrl.BASE_URL + "locks/locklist"
        LockDetailsViewModel().getLockListServiceViewModel(url: urlString, userDetails: [:]) { result, _ in
            
            if result != nil {
                completion(result as! [LockListModel], true)
            } else {
                completion(nil, false)
            }
        }
    }
    
    func updateLogs(completion: @escaping (Bool) -> Void ) {
        self.getLockListServiceCall(completion: { (result, success) in
            if (result?.count)! > 0 {
                
                let locklistArray = result as! [LockListModel]
                let logsDict = LockWifiManager.shared.localCache.logsToBeUpdated()
                let lockIds = logsDict.keys
                
                
                for lockListObj in locklistArray {
                    let lockID = lockListObj.lock_keys[1].lock_id!
                    let lockSerialNumber = lockListObj.serial_number!
                    if lockIds.contains(lockID) {
                        LockWifiManager.shared.localCache.checkAndUpdateLogsWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: false, completion: { (status) in
                            if !status {
                                completion(false)
                            }
                        })
                        
                    }
                }
                
                for lockListObj in locklistArray {
                    let lockID = lockListObj.lock_keys[1].lock_id!
                    let lockSerialNumber = lockListObj.serial_number!
                    if lockIds.contains(lockSerialNumber) {
                        
                        LockWifiManager.shared.localCache.checkAndUpdateLogsWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: true, completion: { (status) in
                            if !status {
                                completion(false)
                            }
                        })
                    }
                }
                
                completion(true)
            } else {
                completion(true)
            }
        })
    }
    

    func updateBatteryStatus(completion: @escaping (Bool) -> Void ) {
        self.getLockListServiceCall(completion: { (result, success) in
            if (result?.count)! > 0 {
                
                let locklistArray = result as! [LockListModel]
                let logsDict = LockWifiManager.shared.localCache.batteryToBeUpdated()
                let lockIds = logsDict.keys
                
                
                for lockListObj in locklistArray {
                    let lockID = lockListObj.lock_keys[1].lock_id!
                    let lockSerialNumber = lockListObj.serial_number!
                    if lockIds.contains(lockID) {
                        LockWifiManager.shared.localCache.checkAndUpdateBatteryStatusWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: false, completion: { (status) in
                            if !status {
                                completion(false)
                            }
                        })
                        
                    }
                }
                
                for lockListObj in locklistArray {
                    let lockID = lockListObj.lock_keys[1].lock_id!
                    let lockSerialNumber = lockListObj.serial_number!
                    if lockIds.contains(lockSerialNumber) {
                        
                        LockWifiManager.shared.localCache.checkAndUpdateBatteryStatusWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: true, completion: { (status) in
                            if !status {
                                completion(false)
                            }
                        })
                    }
                }
                completion(true)
            } else {
                completion(true)
            }
        })
    }
    
    /*func forceSynch() {
        
        LoaderView.sharedInstance.showShadowView(title: "Syncing data...", selfObject: self, isFromNotifiation: false)
        if Connectivity().isConnectedToInternet() {
            
            // addlock, updateowner, update keys, activity log, battery status, factory reset
            
            updateLocallyAddedLocks() // Add lock
            //            updateEditedLockList() // Edit lock
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                LockWifiManager.shared.localCache.checkAndUpdateOwnerId(completion: { (ownerIDStatus) in
                    NotificationCenter.default.post(name: Notification.Name("GetUpdatedLockList"), object: nil)
                    if ownerIDStatus {
                        LockWifiManager.shared.localCache.checkAndUpdateUserKey(completion: { (updateKeysStatus) in
                            
                            if updateKeysStatus {
                                //                            LockWifiManager.shared.localCache.checkAndUpdateLogs(completion: { (updateLogStatus) in
                                
                                self.updateLogs(completion: { (updateLogStatus) in
                                    if updateLogStatus {
                                        //                                    LockWifiManager.shared.localCache.checkAndUpdateBatteryStatus(completion: { (batteryStatus) in
                                        
                                        self.updateBatteryStatus(completion: { (batteryStatus) in
                                            if batteryStatus {
                                                
                                                    
                                                    LockWifiManager.shared.localCache.checkAndAddFPKey(completion: { (addFPStatus) in
                                                        if addFPStatus {
                                                            LockWifiManager.shared.localCache.checkAndUpdateFPKey(completion: { (updateFPStatus) in
                                                                if updateFPStatus {
                                                                    LockWifiManager.shared.localCache.checkAndUpdateRevokeFPKey(completion: { (revokeFPStatus) in
                                                                        if revokeFPStatus {
                                                                            LockWifiManager.shared.localCache.checkAndUpdateRFIDKey(completion: { (updateRFIDStatus) in
                                                                                if updateRFIDStatus {

                                                                                    LockWifiManager.shared.localCache.checkAndUpdateRevokeRFIDKey(completion: { (revokeRFIDStatus) in
                                                                                        if revokeRFIDStatus {
                                                                                            LockWifiManager.shared.localCache.checkAndUpdateFactoryReset(completion: { (FactoryResetStatus) in
                                                                                                if FactoryResetStatus {
                                                                                                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                                                                           
                                                                                                    NotificationCenter.default.post(name: Notification.Name("GetUpdatedLockList"), object: nil)

                                                                                                    self.forceSyncSuccessAlert(alertMessage: FORCE_SYNC_SUCCESS)
                                                                                                    
                                                                                                } else {
                                                                                                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                                                                                    print("5 failed")
                                                                                                    self.showErrorToast()
                                                                                                }
                                                                                            })
                                                                                        }
                                                                                    })
                                                                                }
                                                                            })
                                                                        }
                                                                    })
                                                                }
                                                            })
                                                        }
                                                    })
                                            } else {
                                                print("4 failed")
                                                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                                self.showErrorToast()
                                            }
                                        })
                                        //                                    })
                                    } else {
                                        print("3 failed")
                                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                        self.showErrorToast()
                                    }
                                })
                                
                                //                            })
                            } else {
                                print("2 failed")
                                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                self.showErrorToast()
                            }
                        })
                    } else {
                        print("1 failed")
                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                        self.showErrorToast()
                    }
                })
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            showAlert(alertMessage: INTERNET_CONNECTION_VALIDATION)
        }
    }*/
    
    func showErrorToast(){
        //self.view.makeToast(FORCE_SYNC_FAILED)
    }
    
    func logoutFuctionality() {
        
        if Connectivity().isConnectedToInternet() {
            
            // addlock, updateowner, update keys, activity log, battery status, factory reset
            
            updateLocallyAddedLocks() // Add lock
//            updateEditedLockList() // Edit lock
            
            LockWifiManager.shared.localCache.checkAndUpdateOwnerId(completion: { (ownerIDStatus) in
                
                if ownerIDStatus {
                    LockWifiManager.shared.localCache.checkAndUpdateUserKey(completion: { (updateKeysStatus) in
                        
                        if updateKeysStatus {
                            //                            LockWifiManager.shared.localCache.checkAndUpdateLogs(completion: { (updateLogStatus) in
                            
                            self.updateLogs(completion: { (updateLogStatus) in
                                if updateLogStatus {
                                    //                                    LockWifiManager.shared.localCache.checkAndUpdateBatteryStatus(completion: { (batteryStatus) in
                                    
                                    self.updateBatteryStatus(completion: { (batteryStatus) in
                                        if batteryStatus {
                                            LockWifiManager.shared.localCache.checkAndUpdateFactoryReset(completion: { (FactoryResetStatus) in
                                                
                                                if FactoryResetStatus {
                                                    self.logoutServiceCall(callback: { (status) in
                                                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                                        
                                                        if status == true {
                                                            
                                                            UserDefaults.standard.set(nil, forKey: UserdefaultsKeys.authenticationToken.rawValue)
                                                            self.closeLeft()
                                                            self.loadSignInVC()
                                                        } else {
                                                            self.showAlert(alertMessage: LOGOUT_FAILED)
                                                        }
                                                    })
                                                } else {
                                                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                                    self.showAlert(alertMessage: LOGOUT_FAILED)
                                                }
                                            })
                                        } else {
                                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                            self.showAlert(alertMessage: LOGOUT_FAILED)
                                        }
                                    })
                                    //                                    })
                                } else {
                                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                    self.showAlert(alertMessage: LOGOUT_FAILED)
                                }
                            })
                            
                            //                            })
                        } else {
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                            self.showAlert(alertMessage: LOGOUT_FAILED)
                        }
                    })
                } else {
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                    self.showAlert(alertMessage: LOGOUT_FAILED)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            showAlert(alertMessage: INTERNET_CONNECTION_VALIDATION)
        }
    }
    
    func logoutServiceCall(callback: @escaping (_ status : Bool?) -> Void) {
        let urlString = ServiceUrl.BASE_URL + "users/logout"
        SignOutViewModel().logoutServiceViewModel(url: urlString, userDetails: [:], callback: { (result, error) in

            if result != nil {
                callback(true)
            } else {
                callback(false)
            }
        })
    }
    
    //MARK: - Custom Alert
    
    func showAlert(alertMessage: String) {
        let alert = UIAlertController(title:ALERT_TITLE, message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func forceSyncSuccessAlert(alertMessage: String) {
        let alert = UIAlertController(title:ALERT_TITLE, message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.closeLeft()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func deleteAccountFailureAlert(alertMessage: String) {
        let alert = UIAlertController(title:ALERT_TITLE, message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.closeLeft()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func logoutAlert() {
        let alert = UIAlertController(title:ALERT_TITLE, message: LOGOUT_CONFIRMATION, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { action in
        }))
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { action in
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)

            self.logoutFuctionality()
        }))
        self.present(alert, animated: true, completion: nil)

    }
    // MARK: - Navigation methods
    func loadSignInVC() {
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let signInViewController = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        let navigationController = UINavigationController(rootViewController: signInViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = navigationController
        appDelegate.window?.makeKeyAndVisible()

    }
    
    // MARK: - Logout Service methods
    func updateLocallyAddedLocks() {
        // Update addLockList userdefaults
        
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.addLockList.rawValue) as? NSData {
            if let addLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [AddLockModel] {
                
                for i in 0..<addLockListArr.count {
                    // service call
                    self.addOfflineLockDetailsServiceCall(addLockObj: addLockListArr[i])
                }
            }
        }
    }
    
    func addOfflineLockDetailsServiceCall(addLockObj: AddLockModel) {
        
        let urlString = ServiceUrl.BASE_URL + "locks/addlock"
        
        let userDetails = [
            "name": addLockObj.lockListDetails.lockname! as String,
            "uuid": addLockObj.lockListDetails.uuid! as String, // BLE address ==> check rssi ?
            "ssid": addLockObj.lockListDetails.serial_number as String, // WIFI
            "serial_number": addLockObj.lockListDetails.serial_number! as String, // BLE serial number
            "scratch_code": addLockObj.lockListDetails.scratch_code! as String,
            "status": addLockObj.lockListDetails.status! as String,
            "lock_keys": addLockObj.lock_keys,
            "lock_ids": addLockObj.lock_ids,
            "is_secured":"1",
            "lock_version": addLockObj.lockListDetails.lockVersion
            ] as [String: Any]
        
        print("LeftVC ====>>  addOfflineLockDetailsServiceCall =======>> lock_version ====> \(String(describing: addLockObj.lockListDetails.lockVersion))")

        LockDetailsViewModel().addLockDetailsServiceViewModel(url: urlString, userDetails: userDetails) { result, _ in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                // remove this data obj in userdefaults
                
                self.updateAddLockList(addLockObj: addLockObj)
            } else {
                             //  self.saveLockInLocal(addLockObj: addLockObj)
                /*
                 let message = error?.userInfo["ErrorMessage"] as! String
                 let alert = UIAlertController(title:ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                 
                 alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                 }))
                 self.present(alert, animated: true, completion: nil)
                 */
            }
        }
    }
    
    func updateAddLockList(addLockObj: AddLockModel) {
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.addLockList.rawValue) as? NSData {
            if let addLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [AddLockModel] {
                //                        user = savedUser
                //print("savedUser ==> \(addLockListArr)")
                // check for serial_number
                
                _ = addLockListArr.filter { $0.lockListDetails.serial_number! == addLockObj.lockListDetails.serial_number! }
                
                var objectIndex = Int()
                
                var addLockListTempArray = addLockListArr
                
                if let i = addLockListTempArray.index(where: { $0.lockListDetails.serial_number! == addLockObj.lockListDetails.serial_number! }) {
                    //print("Index ==> \(i)")
                    objectIndex = i
                    
                    addLockListTempArray.remove(at: objectIndex)
                    
                    let archivedObject = NSKeyedArchiver.archivedData(withRootObject: addLockListTempArray)
                    let defaults = UserDefaults.standard
                    defaults.set(archivedObject, forKey: UserdefaultsKeys.addLockList.rawValue)
                    defaults.synchronize()
                }
            }
        }
    }
    
    func updateEditedLockList() {
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.editLockNameList.rawValue) as? NSData {
            if let editLockNameListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [LockListModel] {
                //print("updateLocallyAddedLocks savedUser ==> \(editLockNameListArr)")
                
                for i in 0..<editLockNameListArr.count {
                    // service call
                    self.updateEditLockDetailsServiceCall(editLockNameObj: editLockNameListArr[i])
                }
            }
        }
    }
    
    func updateEditLockDetailsServiceCall(editLockNameObj: LockListModel) {
        let urlString = ServiceUrl.BASE_URL + "locks/updatelock?id=\(editLockNameObj.id!)"
        
        let userDetails = [
            "name": editLockNameObj.lockname!
        ]
        
        LockDetailsViewModel().updateLockDetailsServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            //            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            //print("Result ==> \(result)")
            if result != nil {
                // remove obj from editlocknamelist
                // update lock list
                
                self.removeEditLockNameObj(editLockObj: editLockNameObj)
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                self.showAlert(alertMessage: message)
            }
        }
    }
    
    func removeEditLockNameObj(editLockObj: LockListModel) {
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.editLockNameList.rawValue) as? NSData {
            if let editLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [LockListModel] {
                //                        user = savedUser
                //print("savedUser ==> \(editLockListArr)")
                // check for serial_number
                
                let tmpArray = editLockListArr.filter { $0.serial_number! == editLockObj.serial_number! }
                
                var objectIndex = Int()
                
                var editLockListTempArray = editLockListArr
                
                if let i = editLockListTempArray.index(where: { $0.serial_number! == editLockObj.serial_number! }) {
                    //print("Index ==> \(i)")
                    objectIndex = i
                    
                    editLockListTempArray.remove(at: objectIndex)
                    
                    let archivedObject = NSKeyedArchiver.archivedData(withRootObject: editLockListTempArray)
                    let defaults = UserDefaults.standard
                    defaults.set(archivedObject, forKey: UserdefaultsKeys.editLockNameList.rawValue)
                    defaults.synchronize()
                }
            }
        }
    }
}

extension LeftViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let menu = LeftMenu(rawValue: indexPath.row) {
            switch menu {
            case .main, .profile, .resetpin, .transferowner, .factoryreset, .forceSync, .deleteAccount://, .logout :
                return 50
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let menu = LeftMenu(rawValue: indexPath.row) {
            self.changeViewController(menu)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.tableView == scrollView {
            
        }
    }
}

extension LeftViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let menu = LeftMenu(rawValue: indexPath.row) {
            switch menu {
            case .main, .profile, .resetpin, .transferowner, .factoryreset, .forceSync, .deleteAccount://, .logout :
//                let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell!
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeftViewTableViewCell") as? LeftViewTableViewCell
                cell?.selectionStyle = .none
                cell?.menuLabel.text = menus[indexPath.row]
                return cell!
            }
        }
        return UITableViewCell()
    }
    
}

extension LeftViewController{
    func forceSync() {
        if Connectivity().isConnectedToInternet() {
            LoaderView.sharedInstance.showShadowView(title: "Syncing data...", selfObject: self, isFromNotifiation: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                let group = DispatchGroup()
                self.syncData(group: group)
            
                group.notify(queue: .main) {
                    print("all finished.")
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
           
                    NotificationCenter.default.post(name: Notification.Name("GetUpdatedLockList"), object: nil)

                    self.forceSyncSuccessAlert(alertMessage: FORCE_SYNC_SUCCESS)
                }
            })
        }else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.showAlert(alertMessage: INTERNET_CONNECTION_VALIDATION)
        }
    }
    
    func syncData(group: DispatchGroup) {
        group.enter()
        LockWifiManager.shared.localCache.checkAndUpdateOwnerId(completion: { (ownerIDStatus) in
            group.leave()
            if !ownerIDStatus {
                print("1 failed")
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.showErrorToast()
            }
        })
        
        group.enter()
        LockWifiManager.shared.localCache.checkAndUpdateUserKey(completion: { (updateKeysStatus) in
            group.leave()
            if !updateKeysStatus {
                print("2 failed")
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.showErrorToast()

            }
        })

        group.enter()
        self.updateLogs(completion: { (updateLogStatus) in
            group.leave()
            if !updateLogStatus {
                print("3 failed")
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.showErrorToast()
            }
        })
        
        group.enter()
        self.updateBatteryStatus(completion: { (batteryStatus) in
            group.leave()
            if !batteryStatus {
                print("4 failed")
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.showErrorToast()
            }
        })
        
        group.enter()
        LockWifiManager.shared.localCache.checkAndAddFPKey(completion: { (addFPStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.checkAndUpdateFPKey(completion: { (updateFPStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.checkAndUpdateRevokeFPKey(completion: { (revokeFPStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.checkAndUpdateRFIDKey(completion: { (updateRFIDStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.checkAndUpdateRevokeRFIDKey(completion: { (revokeRFIDStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.updateDigiPins(completion: { (addDigiPinsStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.updateOTP(completion: { (otpStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.updatePinManagePrivilege(completion: { (pinManagePrivilegeStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.updatePassageMode(completion: { (passageModeStatus) in
            group.leave()
        })
        
        group.enter()
        LockWifiManager.shared.localCache.checkAndUpdateFactoryReset(completion: { (FactoryResetStatus) in
            group.leave()
            if !FactoryResetStatus {
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                print("5 failed")
                self.showErrorToast()
            }
        })
        
        group.enter()
        LockWifiManager.shared.localCache.updateFPManagePrivilege(completion: { (fpManagePrivilegeStatus) in
            group.leave()
        })

    }
    

    func deleteAccount(){
        if Connectivity().isConnectedToInternet() {
            let alert = UIAlertController(title: DELETE_ACCOUNT_TITLE, message: DELETE_ACCOUNT_MSG, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [self] in
                    let group = DispatchGroup()
                    self.syncData(group: group)
                    
                    group.notify(queue: .main) {
                        print("all finished.")
                        self.deleteAccountServiceCall(callback: { (status, error) in
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                            if status == true {
                                UserDefaults.standard.set(nil, forKey: UserdefaultsKeys.authenticationToken.rawValue)
                                self.closeLeft()
                                self.loadSignInVC()
                            } else {
                                let message = error?.userInfo["ErrorMessage"] as! String
                                self.deleteAccountFailureAlert(alertMessage: message)
                            }
                        })
                    }
                })
                
            }))
            alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { _ in
               
            }))
            self.present(alert, animated: true, completion: nil)
        }else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.showAlert(alertMessage: INTERNET_CONNECTION_VALIDATION)
        }
    }
    
    func deleteAccountServiceCall(callback: @escaping (_ status : Bool?, _ error : NSError?) -> Void) {
        let urlString = ServiceUrl.BASE_URL + "users/deleteaccount"
        SignOutViewModel().deleteAccountServiceViewModel(url: urlString, userDetails: [:], callback: { (result, error) in
            if result != nil {
                callback(true, error)
            } else {
                callback(false, error)
            }
        })
    }
}

