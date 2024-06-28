//
//  AssignUsersViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 15/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import Contacts
import ContactsUI
import UIKit
import NetworkExtension
import SKCountryPicker
import libPhoneNumber_iOS


class AssignUsersViewController: UIViewController, AssignUsersProtocol, BLELockAccessDisengageProtocol {
    
    @IBOutlet var usersTableView: UITableView!
//    @IBOutlet var usersTableView: CITreeView!
    
    @IBOutlet weak var phoneNumberConfirmView: MobileNumberConfirmView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerLabelView: UIView!
    @IBOutlet weak var headerLabelViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var shadowView: UIView!

    
    let refresher = UIRefreshControl()
    
    var masterListArray = [AssignUserModel]()
    var userListArray = [AssignUserModel]()
    var masterListArray1 = [AssignUserModel]()
    var masterListArray2 = [AssignUserModel]()
    var masterListArray3 = [AssignUserModel]()
    var fingerPrintUsersArray = [AssignUserModel]()
    var revokedKeyCountForUser: Int = 0
    var keyArray = [String]()
    var revokeFailedKeyArray = [String]()
    var selectedFingerPrintID = String()
    var selectedKeyValue = String()
    
    var contactPhoneArray: NSMutableArray = []
    var arrayForBool : NSMutableArray = NSMutableArray()
    
    var userRole = String()
    var userLockID = String()
    var selectedIndex = Int()
    var selectedSection = Int()
    var lockConnection:LockConnection = LockConnection()
    var availableListOfLock:[BluetoothAdvertismentData] = []
    var revokeUserObj = AssignUserModel()

    var data : [CITreeViewData] = []
    var isConnectedViaBLE = Bool()
    var scratchCode = String()
    var isConnectedViaWIFI = Bool()
    var isKeyListLoaded = Bool()
    var lockListDetailsObj = LockListModel(json: [:])
    var userPrivilegeUserID = String()
    lazy var country = Country(countryCode: "IN")
    
    private let notificationCenter = NotificationCenter.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.userRole = "Owner"
        title = "Assign Users"
//        usersTableView.backgroundColor = UIColor.white
        addBackBarButton()
        registerTableViewCell()
        addRefreshController()
        headerLabelView.backgroundColor = .lightGray
        userPrivilegeUserID = self.lockListDetailsObj.userPrivileges ?? ""
//        usersTableView.collapseNoneSelectedRows = false
//        usersTableView.expandAllRows()
        phoneNumberConfirmView.controller = self
        
        self.initialize()
        
        //Mqtt
        notificationCenter.addObserver(self,
                        selector:#selector(processBackgroundNotifiData(_:)),
                        name: NSNotification.Name(BundleIdentifier),
                        object: nil)
    }
    
    
    //MARK: - Receive User Details
    @objc func processBackgroundNotifiData(_ notification: Notification) {
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        if let userInfo = notification.userInfo {
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            let body = userInfo["body"] as? String
            let command = userInfo["command"] as? String
            let status = userInfo["status"] as? String
            
            if (status == "success" && (command == LockNotificationCommand.MASTER_REVOKE.rawValue || command == LockNotificationCommand.USER_REVOKE.rawValue)) {
                Utilities.showSuccessAlertViewWithHandler(message: body ?? "", presenter: self, completion:{ result in
                    self.getAssignUserKeyList()
                })
            }else if (status == "failure" && (command == LockNotificationCommand.MASTER_REVOKE.rawValue || command == LockNotificationCommand.USER_REVOKE.rawValue)) {
                Utilities.showErrorAlertView(message: body ?? "", presenter: self)
            }
        }
    }
    
    //MARK : - Remove Notification
    deinit {
           notificationCenter
                        .removeObserver(self,
                        name: NSNotification.Name(BundleIdentifier) ,
                        object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.initialize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize methods
    
    func initialize() {
        
        self.updateRevokeUserLocalData()
//        self.getAssignUserKeyList()
        if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
            BLELockAccessManager.shared.scanController.proactiveScanning(serialNumber: self.lockConnection.serialNumber, completionBlock: nil)
        }
        self.showMobileNumberConfirmView(hidden: true)
        phoneNumberConfirmView.btnCancelActionClosure = {
            self.showMobileNumberConfirmView(hidden: true)
        }
        phoneNumberConfirmView.btnConfirmActionClosure = {countryCode,phoneNumber in
            self.showMobileNumberConfirmView(hidden: true)
            print(countryCode)
            print(phoneNumber)
            self.createUserRequestServiceCall(selectedMobile: phoneNumber, countryCode: countryCode)
        }
        
    }
    
    // MARK: - Refresh controller
    
    func addRefreshController() {
        self.refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        //        refresher.tintColor = APP_THEME_COLOR
        self.refresher.addTarget(self, action: #selector(self.getAssignUserKeyList), for: .valueChanged)
        self.usersTableView!.addSubview(self.refresher)
    }
    
    // MARK: - Navigation Bar Buttons
    
    func addBackBarButton() {
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        backBtn.addTarget(self, action: #selector(self.popToViewController), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        
        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        let customBackBtnItem: UIBarButtonItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = customBackBtnItem
    }
    
    // MARK: - Register TableViewCell
    
    func registerTableViewCell() {
        self.usersTableView.register(UINib(nibName: "AssignUsersTableViewCell", bundle: nil), forCellReuseIdentifier: "AssignUsersTableViewCell")
        self.usersTableView.register(UINib(nibName: "AssignUserSubTableViewCell", bundle: nil), forCellReuseIdentifier: "AssignUserSubTableViewCell")

        self.usersTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

    }
    
    // MARK: - Button Actions
    
    @objc func popToViewController() {
        BLELockAccessManager.shared.stopPeripheralScan()
        self.navigationController!.popViewController(animated: false)
    }
    
    // MARK: - AssignUsersProtocol
    
    @objc func updateAssignUserStatus(_ sender: UIButton) {
        // service call
        
        //print("updateAssignUserStatus ==> ")
        //print("sender.tag ==> ")
        //print(sender.tag)
        
        var userObj = AssignUserModel()
        
        switch sender.tag {
        case 1, 2, 3:
            userObj = self.masterListArray[sender.tag - 1]
        case 4, 5, 6, 7, 8:
            userObj = self.userListArray[sender.tag - 4]
        case 9, 10, 11, 12, 13:
            userObj = self.masterListArray1[sender.tag - 9]
        case 14, 15, 16, 17, 18:
            userObj = self.masterListArray2[sender.tag - 14]
        case 19, 20, 21, 22, 23:
            userObj = self.masterListArray3[sender.tag - 19]

        default:
            break
        }
        
        //print("userObj ==>")
        //print(userObj.slotNumber)
        
        self.selectedIndex = sender.tag
        
        if userObj.userId == "" {
            if userObj.status == "0" {
                // Add
                self.openContactPickerViewController()
            }
        } else {
            if userObj.status == "0" {
                // "Withdraw"
                var requestId = userObj.requestDetails.id
                if requestId == nil {
                    requestId = ""
                }
                self.updateRequestUserServiceCall(status: "3", requestId: requestId!)
            } else {
                // Revoke via MQTT
                if (self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue) {
                    self.revokeUserObj = userObj
                    LoaderView.sharedInstance.showShadowView(title: "Loading", selfObject: self)
                    if self.revokeUserObj.userType.lowercased() == UserRoles.master.rawValue && self.userPrivilegeUserID == self.revokeUserObj.userId && (self.lockListDetailsObj.lockVersion == lockVersions.version2_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version2_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_1.rawValue) {
                        self.revokeMasterUserFingerPrintAccess()
                    } else {
                        self.revokeUserViaMQTT()
                    }
                }else {
                    let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self.revokeUserObj = userObj
                        LoaderView.sharedInstance.showShadowView(title: "Loading", selfObject: self)
                        if self.revokeUserObj.userType.lowercased() == UserRoles.master.rawValue && self.userPrivilegeUserID == self.revokeUserObj.userId && (self.lockListDetailsObj.lockVersion == lockVersions.version2_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version2_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_1.rawValue ) {
                            self.revokeMasterUserFingerPrintAccess()
                        } else {
                            self.revokeUserWithWIFI()
                        }
                        
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - Wifi Settings
    
    func configureWifiConnection(ssid: String, password: String, slotNumber: String, userObj: AssignUserModel, isRevokeUser: Bool) {
        
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            
            let config = NEHotspotConfiguration(ssid: newSSID, passphrase: password, isWEP: false)
            config.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(config) { (error) in
                if let error = error {
                    //print("error ==> \(error)")
                    self.isConnectedViaWIFI = false
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            if isRevokeUser {
                                self.revokeUserViaWIFI(slotNumber: slotNumber, userObj: userObj)
                            } else { // revoke finger print
                                self.revokeFingerPrintViaWIFI()
                            }
                            self.isConnectedViaWIFI = true
                        } else {
                            if (self.lockListDetailsObj.lockVersion == lockVersions.version2_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version2_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_1.rawValue) {
                                Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke user.", presenter: self)
                            }
                            self.isConnectedViaWIFI = false
                        }
                    })
                }
            }
        } else {
            // handle older versions
            let message = SETTINGS_NAVIGATION
            let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                self.navigateToDeviceSettings()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func disconnectWifi(ssid: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        if #available(iOS 11.0, *) {
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: newSSID)
        }
    }
    
    func navigateToDeviceSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                //print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    
    // MARK: - Revoke User
    func revokeUser(userObj: AssignUserModel) {
        
        var key = ""
        let slotNumber = userObj.slotNumber
        if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
            key = _key
        }
        else {
            Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
            return
        }
        
        
        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
            
            self.revokeUserViaWIFI(slotNumber: slotNumber!, userObj: userObj)
            
        } else {
            
            if lockConnection.selectedLock == nil {
                lockConnection.selectedLock  = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockConnection.serialNumber)
            }
            if lockConnection.selectedLock != nil {
                
                self.revokeUserViaBLE(slotNumber: slotNumber!, key: key, userObj: userObj) { (status) in
                    
                    LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.getActivityTime(lockVersion: lockVersions(rawValue: self.lockListDetailsObj.lockVersion) ?? .version1), execute: {
                        if !self.isConnectedViaBLE {
                            if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                                self.revokeUserViaWIFI(slotNumber: slotNumber!, userObj: userObj)
                            } else {
//                                if Connectivity().isConnectedToInternet() {
                                self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode, slotNumber: slotNumber!, userObj: userObj, isRevokeUser: true)
                                    
                               /* } else {
//                                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                                    
                                    let message = TURN_ON_WIFI
                                    let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                                    
                                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                    }))
                                    self.present(alert, animated: true, completion: nil)
                                }*/
                            }
                        }
                    })
                }
            } else {
                return
            }
        }
    }
    
    
    func revokeUserWithWIFI() {
        
        
        // Only for lock version 2.0 OWNERS
        if (self.lockListDetailsObj.lockVersion == lockVersions.version2_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version2_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_1.rawValue) {
            // For version 2 - Revoke user access can be done only via WIFI
        } else {
            // For version 1 - Revoke user access can be done via BLE & WIFI
            DispatchQueue.main.asyncAfter(deadline: .now() + getActivityTime(lockVersion: lockVersions(rawValue: self.lockListDetailsObj.lockVersion) ?? .version1), execute: {
                if !self.isConnectedViaWIFI {
                    if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                        self.initializeScan()
                    }  else {
                        Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
                    }
                }
            })
        }
        
        
        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
            self.revokeUserViaWIFI(slotNumber: revokeUserObj.slotNumber, userObj: self.revokeUserObj)
        } else {
            
//            if Connectivity().isConnectedToInternet() {
            self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode,  slotNumber: revokeUserObj.slotNumber, userObj: self.revokeUserObj, isRevokeUser: true)
                
           /* } else {
                
                let message = TURN_ON_WIFI
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
            }*/
        }
    }
    
    
    func revokeUserViaBLE(slotNumber: String, key: String, userObj: AssignUserModel, completion: @escaping (Bool) -> Void) {
        
        var isRevokeUserDone = true
        BLELockAccessManager.shared.userManagementDelegate = self
        BLELockAccessManager.shared.disengageDelegate = self

        BLELockAccessManager.shared.connectWithLock(lockData: lockConnection.selectedLock!, completion: { isSuccess in
            
            if isRevokeUserDone {
                isRevokeUserDone = false
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)

                if isSuccess {
                   
                    self.isConnectedViaBLE = true
                    BLELockAccessManager.shared.revokeUserKey(slotNumber: slotNumber, userKey: key, userId: userObj.id)
                } else {
                    self.isConnectedViaBLE = false
                }
                completion(isSuccess)
            }
        })
    }
    
    func revokeUserViaMQTT(){
        print(self.revokeUserObj)
        let userType = self.revokeUserObj.userType.lowercased()
        let urlString = ServiceUrl.BASE_URL + "locks/\(self.lockListDetailsObj.serial_number ?? "")/\(userType)/\(self.revokeUserObj.userId ?? "")/revoke"
        AssignUsersViewModel().revokeUserServiceViewModel(url: urlString, userDetails: [:]) { result, error in
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            if result != nil {
                print("Success.....\(result ?? "")")
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)

                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func revokeUserViaWIFI(slotNumber: String, userObj: AssignUserModel) {
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = authorizationKey
            // hack to ensure right slot number is passed
            var actualSlotNumber = slotNumber
            if actualSlotNumber.count == 1 {
                actualSlotNumber = "0\(actualSlotNumber)"
            }
            let data = Data([UInt8(actualSlotNumber)!])
            parameters["slot-id"] = data.hexEncodedStringNew(options: .upperCase)
           
            //parameters["slot-id"]  = String.stringToHexString(regularString: actualSlotNumber)
            LockWifiManager.shared.rewriteUserSlotKey(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        let updatedKey = dictResponse!["slot-key"] as! String
                        
                        // Encrypt newKey and then save to local
                        var isSecuredModified=false
                        if lockListDetailsObj.is_secured=="1" {
                            isSecuredModified=true
                        }
                        let encryptedNewKey = Utilities().convertStringToEncryptedString(plainString: updatedKey, isSecured: isSecuredModified)
                        self.updateRevokeUserToLocal(updateKey: encryptedNewKey, oldUserKey: userObj.id!, lockSerialNumber: self.lockConnection.serialNumber)
                    }
                } else {
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke user.", presenter: self)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke user.", presenter: self)
        }
    }
    
    
    func updateRevokeUserToLocal(updateKey: String, oldUserKey: String, lockSerialNumber: String) {
        LockWifiManager.shared.localCache.saveNewUserKey(newUserKey: updateKey, oldUserKey: oldUserKey, lockSerialNumber: self.lockConnection.serialNumber)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.disconnectWifi(ssid: self.lockConnection.serialNumber)
        }
        let alertController = UIAlertController(title: ALERT_TITLE, message: ASSIGN_USER_REVOKE_MESSAGE, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)

    }
    
    func updateRevokeUserLocalData() {
//        DispatchQueue.main.async {
        DispatchQueue.global(qos: .background).async {
            if Connectivity().isConnectedToInternet(){
                LockWifiManager.shared.localCache.checkAndUpdateUserKey(completion: { (status) in
//                    if status {
                        self.getAssignUserKeyList()
                        
//                    }
                })
            } else {
                
            }
        }
    }
    
    // MARK: - Revoke User old code
    
    func oldRevokeUser(userObj: AssignUserModel) {
        var key = ""
        let slotNumber = userObj.slotNumber
        if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
            key = _key
        }
        else {
            Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
            return
        }
        if lockConnection.isConnectedToLockWifi(ssidName: lockConnection.serialNumber){
            if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
                var parameters = authorizationKey
                // hack to ensure right slot number is passed
                var actualSlotNumber = slotNumber!
                if actualSlotNumber.count == 1 {
                    actualSlotNumber = "0\(actualSlotNumber)"
                }
                parameters["slot-id"] = actualSlotNumber
                LockWifiManager.shared.rewriteUserSlotKey(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    if isSuccess == true {
                        if let jsonDict = jsonResponse?.dictionary {
                            let dictResponse = jsonDict["response"]?.dictionaryObject!
                            let updatedKey = dictResponse!["slot-key"] as! String
                            var isSecuredModified=false
                            if self.lockListDetailsObj.is_secured=="1" {
                                isSecuredModified=true
                            }
                            // Encrypt newKey and then send to server
                            let encryptedNewKey = Utilities().convertStringToEncryptedString(plainString: updatedKey, isSecured: isSecuredModified)

                            self.updateRevokeUserToLocal(updateKey: encryptedNewKey, oldUserKey: userObj.id!, lockSerialNumber: self.lockConnection.serialNumber)
                        }
                    } else {
                        Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke user.", presenter: self)
                    }
                })
            }
        }
        else {
            if lockConnection.selectedLock == nil {
                lockConnection.selectedLock  = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockConnection.serialNumber)
            }
            guard  lockConnection.selectedLock  != nil else{
                if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                    BLELockAccessManager.shared.stopPeripheralScan()
                    Utilities.showErrorAlertView(message: TURN_ON_LOCK, presenter: self)
                    BLELockAccessManager.shared.scanForPeripherals()
                }
                else{
                    Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
                }
                return
            }
            LoaderView.sharedInstance.showShadowView(title: "Loading", selfObject: self)
            BLELockAccessManager.shared.userManagementDelegate = self
            BLELockAccessManager.shared.connectWithLock(lockData: lockConnection.selectedLock!, completion: { isSuccess in
                if isSuccess {
                    BLELockAccessManager.shared.revokeUserKey(slotNumber: slotNumber!, userKey: key, userId: userObj.id)
                } else {
                    Utilities.showErrorAlertView(message: "Lock is not connected", presenter: self)
                }
            })
            
        }
    }
    
    // MARK: - Service call
    
    @objc func getAssignUserKeyList() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let ownerStatus = "0"
        let type = self.userRole == "Owner" ? "Master,User" : "User"
        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(self.userLockID)&owner=\(ownerStatus)&type=\(type)"
//        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(self.userLockID)"
        
        AssignUsersViewModel().getAssignUserKeyListServiceViewModel(url: urlString, userDetails: [:]) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            LockWifiManager.shared.localCache.updateOfflineItems()
            
            if result != nil {
                /*
                if result?.count == 2 {
                    self.masterListArray = result![0] as! [AssignUserModel]
                    self.userListArray = result![1] as! [AssignUserModel]
                } else {
                    self.userListArray = result![0] as! [AssignUserModel]
                }
                */
                

                //print("result ==>  assign users ==> ")
                //print(result)
                
                
                var masterUserArray = [[AssignUserModel]]()


                self.masterListArray = result!["master"]!
                self.masterListArray1 = result!["master1User"]!
                self.masterListArray2 = result!["master2User"]!
                self.masterListArray3 = result!["master3User"]!
                self.userListArray = result!["ownerUser"]!
                self.fingerPrintUsersArray = result!["fingerPrintUsers"]!

                masterUserArray.append(self.masterListArray)
                masterUserArray.append(self.masterListArray1)
                masterUserArray.append(self.masterListArray2)
                masterUserArray.append(self.masterListArray3)
                masterUserArray.append(self.userListArray)
                
                self.data = CITreeViewData.getDefaultCITreeViewData(dataArray: masterUserArray)

                DispatchQueue.main.async {

//                    self.usersTableView.expandAllRows()
                }
                
                if !self.isKeyListLoaded {
                    self.arrayForBool .removeAllObjects()

                    if self.masterListArray.count > 0 {
                        self.arrayForBool.add(0) // Master 1
                        self.arrayForBool.add(0) // Master 2
                        self.arrayForBool.add(0) // Master 3
                    } else {
                    }
                    if self.masterListArray1.count > 0 || self.masterListArray2.count > 0 || self.masterListArray3.count > 0 {
                        self.arrayForBool.add(1)
                    }
                    if self.userListArray.count > 0 {
                        self.arrayForBool.add(1)
                    }
                    self.isKeyListLoaded = true
                }
                
                if self.masterListArray.count > 0 {
                    self.headerLabelViewHeightConstraint.constant = 60
                    self.headerLabelView.isHidden = false
                    self.headerLabel.isHidden = false
                } else {
                    self.headerLabelViewHeightConstraint.constant = 0
                    self.headerLabelView.isHidden = true
                    self.headerLabel.isHidden = true
                }
                
                self.usersTableView.reloadData()
                
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                }))
//                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func createUserRequestServiceCall(selectedMobile: String,countryCode: String) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "requests/createrequest"
        
        var keyID = ""
        /*
        if self.masterListArray.count > 0 {
            if self.selectedSection == 1 {
                let masterObj = masterListArray[self.selectedIndex]
                keyID = masterObj.id
            } else {
                let userObj = userListArray[self.selectedIndex]
                keyID = userObj.id
            }
        } else {
            let userObj = userListArray[self.selectedIndex]
            keyID = userObj.id
        }
        */
        
        //print("self.selectedIndex ==> ")
        //print(self.selectedIndex)
        var userObj = AssignUserModel()
        
        switch self.selectedIndex {
        case 1, 2, 3:
            userObj = self.masterListArray[self.selectedIndex - 1]
        case 4, 5, 6, 7, 8:
            userObj = self.userListArray[self.selectedIndex - 4]
        case 9, 10, 11, 12, 13:
            userObj = self.masterListArray1[self.selectedIndex - 9]
        case 14, 15, 16, 17, 18:
            userObj = self.masterListArray2[self.selectedIndex - 14]
        case 19, 20, 21, 22, 23:
            userObj = self.masterListArray3[self.selectedIndex - 19]
            
        default:
            break
        }

        keyID = userObj.id
        
        //print("keyID ==> ")
        //print(keyID)
        
        let mobNumber = selectedMobile.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        //print("mobNumber ==> \(mobNumber)")
        let userDetailsDict = ["key_id": keyID,
                               "mobile": mobNumber,
                               "status": "0",
                               "country_code":countryCode
        ]
        
        var userDetails = [String: String]()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let dictFromJSON = decoded as? [String: String] {
                userDetails = dictFromJSON
                //print("dictFromJSON ==> \(dictFromJSON)")
            }
        } catch {
            //print(error.localizedDescription)
        }
        
        AssignUsersViewModel().createRequestUserServiceViewModel(url: urlString, userDetails: userDetails as [String: String]) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {
                
                let message = result!["message"].rawValue as! String
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
                
                self.getAssignUserKeyList()
                
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                }))
//                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func updateRequestUserServiceCall(status: String, requestId: String) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "requests/updaterequest?id=\(requestId)"
        
        let userDetailsDict = [
            "status": status,
        ]
        
        var userDetails = [String: String]()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
            
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            if let dictFromJSON = decoded as? [String: String] {
                userDetails = dictFromJSON
                //print("dictFromJSON ==> \(dictFromJSON)")
            }
        } catch {
            //print(error.localizedDescription)
        }
        print(userDetails)
        AssignUsersViewModel().updateRequestUserServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {

                let message = result!["message"].rawValue as! String
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)

                
                
                self.getAssignUserKeyList()
                
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                }))
//                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func revokeRequestUserServiceCall(key: String, keyId: String) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "keys/updatekey?id=\(keyId)"
        
        let userDetailsDict = [
            "user_id": "",
            "key": key,
            "status": "0",
        ]
        
        var userDetails = [String: String]()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
            
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let dictFromJSON = decoded as? [String: String] {
                userDetails = dictFromJSON
                //print("dictFromJSON ==> \(dictFromJSON)")
            }
        } catch {
            //print(error.localizedDescription)
        }
        
        AssignUsersViewModel().revokeRequestUserServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            if result != nil {
                let message = result!["message"].rawValue as! String
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
                self.getAssignUserKeyList()

            } else {
                // Updated key is already encrypted while passed to revokeRequestUserServiceCall method
                self.updateRevokeUserToLocal(updateKey: key, oldUserKey: keyId, lockSerialNumber: self.lockConnection.serialNumber)
            }
        }
    }
    
    func updateUserPrivilegeServiceCallForMaster(sender: UIButton) {
            
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            
            let urlString = ServiceUrl.BASE_URL + "locks/adduserprivilege"
            
            var lockID = ""
            var userID : String?
            
            //print("self.selectedIndex ==> ")
            //print(self.selectedIndex)
            var userObj = AssignUserModel()
            
            let idx = sender.tag
            
            switch idx {
            case 1, 2, 3:
                userObj = self.masterListArray[idx - 1]
            case 4, 5, 6, 7, 8:
                userObj = self.userListArray[idx - 4]
            case 9, 10, 11, 12, 13:
                userObj = self.masterListArray1[idx - 9]
            case 14, 15, 16, 17, 18:
                userObj = self.masterListArray2[idx - 14]
            case 19, 20, 21, 22, 23:
                userObj = self.masterListArray3[idx - 19]
                
            default:
                break
            }

            lockID = userObj.lockId
            //print("keyID ==> ")
            //print(keyID)
            
            
            //print("mobNumber ==> \(mobNumber)")
            var userDetailsDict: [String: Any] = [
                "lock_id": lockID,
            ]
            
        if userPrivilegeUserID == "" {
                userDetailsDict["user_id"] = userObj.userId
            } else {
                userDetailsDict["user_id"] = ""
            }
            
            var userDetails = [String: String]()
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
                let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
                
                if let dictFromJSON = decoded as? [String: String] {
                    userDetails = dictFromJSON
//                    print("dictFromJSON ==> \(dictFromJSON)")
                }
            } catch {
//                print(error.localizedDescription)
            }
            
            AssignUsersViewModel().updateFingerPrintUserPrivilegeViewModel(url: urlString, userDetails: userDetails as [String: String]) { result, error in
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                
                if result != nil {
                    
//                    let resultResponse = result!["message"]
                    let locklistObj = result!["lockObj"] as! LockListModel
                    
                    let message = result!["message"] //result!["message"].rawValue as! String
                    let alert = UIAlertController(title: ALERT_TITLE, message: message as! String, preferredStyle: UIAlertController.Style.alert)
    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    }))
                    self.present(alert, animated: true, completion: nil)
    
                    self.userPrivilegeUserID = locklistObj.userPrivileges ?? ""
                    self.usersTableView.reloadData()
                    
                } else {
                    let message = error?.userInfo["ErrorMessage"] as! String
                    self.view.makeToast(message)
//                    let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                    }))
//                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    
    // MARK: - Show Contacts List
    
    @objc func showUserContactsListAlert(phoneListArray: NSMutableArray) {
        //  let topVC = topMostController()
        let getPersonName = phoneListArray[0] as! NSDictionary
        let alert = UIAlertController(title: getPersonName["PersonName"] as? String, message: "Select your phone number", preferredStyle: UIAlertController.Style.alert)
        for i in 0...(phoneListArray.count - 1) {
            let personNumber = phoneListArray[i] as! NSDictionary
            //print("person num ==> \(personNumber)")
            //print("person num ==> \(String(describing: personNumber["PersonNumber"]))")
            alert.addAction(UIAlertAction(title: personNumber["PersonNumber"] as? String, style: .default, handler: { action in
                let personNumberString = action.title
                //print(personNumberString as Any)
//                self.showConfirmDialog(choosenContactDetailArray: [])
//                self.showConfirmDialog(selectedMobile: personNumberString! as String)
                self.country = Country.init(countryCode: "\(personNumber["CountryCode"] ?? "US")".uppercased())
                self.phoneNumberConfirmView.country = self.country
                self.phoneNumberConfirmView.phoneNumber = "\(personNumber["PersonNumber"] ?? "")"
                self.phoneNumberConfirmView.setValues()
                self.showMobileNumberConfirmView(hidden: false)
//                self.createUserRequestServiceCall(selectedMobile: personNumberString! as String, countryCode: self.country.countryCode)
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Show confirm alert
    
    func showConfirmDialog(selectedMobile: String) {
//        //print(choosenContactDetailArray)
        let alertController = UIAlertController(title: "Transfer Owner", message: "Do you want to confirm to change the lock owner", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "OK", style: .default) { (_: UIAlertAction) in
            //print("You've pressed Ok")
            self.createUserRequestServiceCall(selectedMobile: selectedMobile, countryCode: self.country.countryCode)
        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (_: UIAlertAction) in
            //print("You've pressed cancel")
        }
        alertController.addAction(action1)
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Check ViewController Hierarchy
    
    func topMostController() -> UIViewController {
        var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
        while topController.presentedViewController != nil {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    @objc func onTapInfoButton(sender: UIButton) {
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let profileViewController = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        
        var userObj = AssignUserModel()
        
        switch sender.tag {
        case 1, 2, 3:
            userObj = self.masterListArray[(sender.tag) - 1]
        case 4, 5, 6, 7, 8:
            userObj = self.userListArray[(sender.tag) - 4]
        case 9, 10, 11, 12, 13:
            userObj = self.masterListArray1[(sender.tag) - 9]
        case 14, 15, 16, 17, 18:
            userObj = self.masterListArray2[(sender.tag) - 14]
        case 19, 20, 21, 22, 23:
            userObj = self.masterListArray3[(sender.tag) - 19]
        default:
            break
        }
        
        let profileObj = ProfileModel()
        profileObj.name = userObj.userDetails.username
        profileObj.email = userObj.userDetails.email
        profileObj.countryCode = userObj.userDetails.countryCode
        profileObj.mobile = userObj.userDetails.mobile
        profileObj.address = userObj.userDetails.address
        profileObj.accessGrantedTime = userObj.requestDetails.modified_date
        
        profileViewController.profileObj = profileObj
        profileViewController.isOtherProfile = true
        self.navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    @objc func onTapScheduledAccessButton(sender: UIButton) {
        
        var userObj = AssignUserModel()
        
        switch sender.tag {
        case 1, 2, 3:
            userObj = self.masterListArray[(sender.tag) - 1]
        case 4, 5, 6, 7, 8:
            userObj = self.userListArray[(sender.tag) - 4]
        case 9, 10, 11, 12, 13:
            userObj = self.masterListArray1[(sender.tag) - 9]
        case 14, 15, 16, 17, 18:
            userObj = self.masterListArray2[(sender.tag) - 14]
        case 19, 20, 21, 22, 23:
            userObj = self.masterListArray3[(sender.tag) - 19]
        default:
            break
        }
        
        if userRole.lowercased() == UserRoles.owner.rawValue {
            switch userObj.slotNumber! {
            case "01", "02", "03", "04", "05", "06", "07", "08":
                if userObj.is_schedule_access == "1" {
                    navigateToScheduledAccessViewController(userObj: userObj)
                } else {
                    navigateToEditScheduledAccessViewContorller(userObj: userObj)
                }
            case "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23":
                if userObj.is_schedule_access == "1" {
                    navigateToScheduledAccessViewController(userObj: userObj)
                }
            default:
                break
            }
            
        } else {
            if userObj.is_schedule_access == "1" {
                navigateToScheduledAccessViewController(userObj: userObj)
            } else {
                navigateToEditScheduledAccessViewContorller(userObj: userObj)
            }
        }
    }
    
    @objc func onTapFPAccessButton(sender: UIButton) {
        updateUserPrivilegeServiceCallForMaster(sender: sender)
    }
    
    func getUserPrivilegeStatus() -> Bool {
        
        for item in masterListArray {
            if (userPrivilegeUserID != "") && (item.userId == userPrivilegeUserID) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Navigation Methods
    
    func navigateToScheduledAccessViewController(userObj: AssignUserModel) {
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let scheduledAccessViewController = storyBoard.instantiateViewController(withIdentifier: "ScheduledAccessViewController") as! ScheduledAccessViewController
        
        let profileObj = ProfileModel()
        profileObj.name = userObj.userDetails.username
        profileObj.email = userObj.userDetails.email
        profileObj.mobile = userObj.userDetails.mobile
        profileObj.address = userObj.userDetails.address
        profileObj.accessGrantedTime = userObj.requestDetails.modified_date
        
        //        profileViewController.profileObj = profileObj
        //        profileViewController.isOtherProfile = true
        
        scheduledAccessViewController.userObj = userObj
        scheduledAccessViewController.userRole = self.userRole
        self.navigationController?.pushViewController(scheduledAccessViewController, animated: true)
    }
    
    func navigateToEditScheduledAccessViewContorller(userObj: AssignUserModel) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        //        let scheduledAccessViewController = storyBoard.instantiateViewController(withIdentifier: "ScheduledAccessViewController") as! ScheduledAccessViewController
        let scheduledAccessViewController = storyBoard.instantiateViewController(withIdentifier: "EditScheduleAccessViewController") as! EditScheduleAccessViewController
        
        let profileObj = ProfileModel()
        profileObj.name = userObj.userDetails.username
        profileObj.email = userObj.userDetails.email
        profileObj.mobile = userObj.userDetails.mobile
        profileObj.address = userObj.userDetails.address
        profileObj.accessGrantedTime = userObj.requestDetails.modified_date
        
        //        profileViewController.profileObj = profileObj
        //        profileViewController.isOtherProfile = true
        
        scheduledAccessViewController.isEditSchedule = false
        scheduledAccessViewController.keyID = userObj.id
        self.navigationController?.pushViewController(scheduledAccessViewController, animated: true)
    }

}

// MARK: - Contact Delegates

extension AssignUsersViewController: CNContactPickerDelegate {
    func openContactPickerViewController() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        self.present(contactPicker, animated: true, completion: nil)
    }
    
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        //print(contact)
        self.contactPhoneArray.removeAllObjects()
        for phoneNumber in contact.phoneNumbers {
            let dictParams: NSMutableDictionary? = ["PersonName": contact.givenName,
                                                    "PersonNumber": (phoneNumber.value).value(forKey: "stringValue") as Any,"CountryCode": (phoneNumber.value).value(forKey: "countryCode") as Any
            ]
            let phNumber = (phoneNumber.value).value(forKey: "stringValue")
            if !Utilities.isNilOrEmptyString(string: phNumber as? String) {
                self.contactPhoneArray.add(dictParams as Any)
            }
            
            //print("The \(String(describing: phoneNumber.label)) number of \(contact.givenName) is: \(phoneNumber.value)")
            //print(self.contactPhoneArray)
        }
        picker.dismiss(animated: true) {
            if self.contactPhoneArray.count > 1 {
                self.showUserContactsListAlert(phoneListArray: self.contactPhoneArray)
            } else {
                if self.contactPhoneArray.count > 0 {
                    let contactDetails = self.contactPhoneArray[0] as! NSDictionary
                    // self.showConfirmDialog(selectedMobile: contactDetails["PersonNumber"] as! String)
                    self.country = Country.init(countryCode: "\(contactDetails["CountryCode"] ?? "US")".uppercased())
                    self.phoneNumberConfirmView.country = self.country
                    self.phoneNumberConfirmView.phoneNumber = "\(contactDetails["PersonNumber"] ?? "9876543210")"
                    self.phoneNumberConfirmView.setValues()
                    self.showMobileNumberConfirmView(hidden: false)
//                    self.createUserRequestServiceCall(selectedMobile: contactDetails["PersonNumber"] as! String)
                } else {
                    let alert = UIAlertController(title: ALERT_TITLE, message: INVALID_CONTACT_SELECTION, preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

/*
// MARK: - CITreeViewDelegate
extension AssignUsersViewController : CITreeViewDelegate {
    func willExpandTreeViewNode(treeViewNode: CITreeViewNode, atIndexPath: IndexPath) {}
    
    func didExpandTreeViewNode(treeViewNode: CITreeViewNode, atIndexPath: IndexPath) {}
    
    func willCollapseTreeViewNode(treeViewNode: CITreeViewNode, atIndexPath: IndexPath) {}
    
    func didCollapseTreeViewNode(treeViewNode: CITreeViewNode, atIndexPath: IndexPath) {}
    
    
    func treeView(_ treeView: CITreeView, heightForRowAt indexPath: IndexPath, withTreeViewNode treeViewNode: CITreeViewNode) -> CGFloat {
        return 60
    }
    
    func treeView(_ treeView: CITreeView, didDeselectRowAt treeViewNode: CITreeViewNode, atIndexPath indexPath: IndexPath) {
        
    }
    
    func treeView(_ treeView: CITreeView, didSelectRowAt treeViewNode: CITreeViewNode, atIndexPath indexPath: IndexPath) {
        if let parentNode = treeViewNode.parentNode{
            //print(parentNode.item)
        }
    }
}


*/

/*
extension AssignUsersViewController : CITreeViewDataSource {
    func treeViewSelectedNodeChildren(for treeViewNodeItem: AnyObject) -> [AnyObject] {
        if let dataObj = treeViewNodeItem as? CITreeViewData {
            return dataObj.children
        }
        return []
    }
    
    func treeViewDataArray() -> [AnyObject] {
        return data
    }
    
    func treeView(_ treeView: CITreeView, atIndexPath indexPath: IndexPath, withTreeViewNode treeViewNode: CITreeViewNode) -> UITableViewCell {
        
        /*
        //print("treeViewNode ==> ")
        //print(treeViewNode)
        //print(treeViewNode.level)
        //print(treeViewNode.item)
        //print(treeViewNode.expand)
        //print(treeViewNode.parentNode)
        */
        
         switch treeViewNode.level {
         case 0:

            let cell:UITableViewCell = treeView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let dataObj = treeViewNode.item as! CITreeViewData

            cell.textLabel?.text = dataObj.name
            cell.backgroundColor = UIColor.lightGray
            cell.selectionStyle = .none
            return cell
            
        case 1: // Master 1, Master 2, Master 3 & Owner user
            let cell = treeView.dequeueReusableCell(withIdentifier: "AssignUsersTableViewCell") as? AssignUsersTableViewCell
            cell?.selectionStyle = .none
            cell?.delegate = self
            
            let dataObj = treeViewNode.item as! CITreeViewData
            cell?.userNameLabel.text = dataObj.name
            cell?.assignUserButton.tag = Int(dataObj.slotNumber)!

            //print("cell?.assignUserButton.tag ==> ")
            //print(cell?.assignUserButton.tag)
            
            cell?.infoButton?.tag = Int(dataObj.slotNumber)!
            cell?.infoButton?.addTarget(self, action: #selector(onTapInfoButton), for: .touchUpInside)
            cell?.infoButton?.isHidden = false
            var userObj = AssignUserModel()

            switch cell?.assignUserButton.tag {
            case 1, 2, 3:
                /*cell?.infoButtonWidthConstraint?.constant = 0
                cell?.infoButton?.isHidden = true */
                userObj = self.masterListArray[(cell?.assignUserButton.tag)!-1]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            case 4, 5, 6, 7, 8:
                userObj = self.userListArray[(cell?.assignUserButton.tag)! - 4]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            case 9, 10, 11, 12, 13:
                userObj = self.masterListArray1[(cell?.assignUserButton.tag)! - 9]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            case 14, 15, 16, 17, 18:
                userObj = self.masterListArray2[(cell?.assignUserButton.tag)! - 14]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            case 19, 20, 21, 22, 23:
                userObj = self.masterListArray3[(cell?.assignUserButton.tag)! - 19]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            default:
                break
            }
            
            cell?.scheduleAccessButton?.isHidden = true
            cell?.scheduleAccessButton?.tag = Int(dataObj.slotNumber)!
            cell?.scheduleAccessButton?.addTarget(self, action: #selector(onTapScheduledAccessButton), for: .touchUpInside)

            var buttonTitle = ""
            if userObj.userId == "" {
                if userObj.status == "0" {
                    buttonTitle = "Add"
                }
            } else {
                if userObj.status == "0" {
                    buttonTitle = "Withdraw"
                } else if userObj.status == "1" {
                    buttonTitle = "Revoke"
                    cell?.scheduleAccessButton?.isHidden = false
                    if userObj.is_schedule_access == "1" {
                        
                        let startDate = Utilities().toDate(dateString: userObj.schedule_date_from)
                        let startDateString = Utilities().toDateString(date: startDate)
                        
                        let endDate = Utilities().toDate(dateString: userObj.schedule_date_to)
                        let endDateString = Utilities().toDateString(date: endDate)
                        
                        let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                        let startTimeString = Utilities().to24HoursTimeString(date: startTime)
                        
                        let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                        let endTimeString = Utilities().to24HoursTimeString(date: endTime)
                        
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        let currentDate = NSDate()
                        let currentDateString = dateFormatter.string(from: currentDate as Date)
                        
                        let currentDateNew = Utilities().toDate(dateString: currentDateString)
                        let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
                        
                        
                        
                        let dateFormatter1 = DateFormatter()
                        dateFormatter1.dateFormat = "HH:mm"
                        let currentTimeString = dateFormatter1.string(from: currentDate as Date)
                        
                        
                        
                        
                        if currentDateNew > endDate {
                            // expired
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                            
                        } else if currentDateNew == endDate {
                            if currentTimeString > endTimeString {
                                // expired
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                            } else {
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                            }
                        } else if startDate < currentDateNew && currentDateNew < endDate {
                            
                            if startTimeString < currentTimeString && currentTimeString < endTimeString {
                                // expired
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                            } else {
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                            }
                        } else {
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                        }
                    } else {
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                    }
                } else {
                    buttonTitle = "Add"
                }
            }
            
            cell?.assignUserButton?.setTitle(buttonTitle, for: .normal)
            return cell!
            
         case 2:
            let cell = treeView.dequeueReusableCell(withIdentifier: "AssignUserSubTableViewCell") as? AssignUserSubTableViewCell
            cell?.selectionStyle = .none
            
            let dataObj = treeViewNode.item as! CITreeViewData
            
            cell?.userNameLabel?.text = dataObj.name
            cell?.viewButton?.tag = Int(dataObj.slotNumber)!
            
            var userObj = AssignUserModel()

            switch cell?.viewButton?.tag {
                
            case 9, 10, 11, 12, 13:
                userObj = self.masterListArray1[(cell?.viewButton?.tag)! - 9]
            case 14, 15, 16, 17, 18:
                userObj = self.masterListArray2[(cell?.viewButton?.tag)! - 14]
            case 19, 20, 21, 22, 23:
                userObj = self.masterListArray3[(cell?.viewButton?.tag)! - 19]
            default:
                break
            }
            
            cell?.viewButton?.isHidden = false
            cell?.viewButton?.addTarget(self, action: #selector(onTapInfoButton(sender:)), for: .touchUpInside)
            
            cell?.revokeButton?.isHidden = false
            cell?.revokeWidthConstraint?.constant = 80
            cell?.revokeButton?.tag = Int(dataObj.slotNumber)!
            cell?.revokeButton?.addTarget(self, action: #selector(self.updateAssignUserStatus(_:)), for: .touchUpInside)
            
            if (userObj.userId == nil) || userObj.userId == "" {
                cell?.viewButton?.isHidden = true
                cell?.revokeButton?.isHidden = true
                cell?.revokeWidthConstraint?.constant = 0
            }
            
            return cell!

         default:
               return UITableViewCell()
        }
        
    }
    
}
 */

extension AssignUsersViewController:BLELockUserManagementProtocol{
    func didFailedToConnect(error: String) {
        
    }

    func didFinishReadingAllCharacteristics() {

    }

    func didPeripheralDisconnect() {

    }
    
    func didFailAuthorization() {
        //BLELockAccessManager.shared.disEngageLock(key: self.userKey!)
        
        
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        
        //print("didFailAuthorization ==> ")
        //        self.isConnectedVisBLE = false
        Utilities.showErrorAlertView(message: "You are not an authorized user for this lock", presenter: self)
    }

    func didRevokeUser(isSuccess: Bool, newKey: String, userId slotNumber: String, error: String) {
        //print("didRevokeUser ==> called ==> ")
        BLELockAccessManager.shared.disconnectLock()
        if isSuccess == true {
            
            // Encrypt newKey and then send to server
            var isSecuredModified=false
            if self.lockListDetailsObj.is_secured=="1" {
                isSecuredModified=true
            }
            let encryptedNewKey = Utilities().convertStringToEncryptedString(plainString: newKey, isSecured: isSecuredModified)
            if Connectivity().isConnectedToInternet() {
                DispatchQueue.main.async {
                    self.revokeRequestUserServiceCall(key: encryptedNewKey, keyId: slotNumber)
                }
            } else {
                self.updateRevokeUserToLocal(updateKey: encryptedNewKey, oldUserKey: slotNumber, lockSerialNumber: self.lockConnection.serialNumber)
            }
        }
        else{
            Utilities.showErrorAlertView(message: "Failed to revoke user", presenter: self)
        }
    }
    
    func didDisengageLock(isSuccess: Bool, error: String) {
        
    }
    
    func didCompleteOwnerTransfer(isSuccess: Bool, newOwnerId: String, oldOwnerId: String, error: String) {
        
    }
    
    func didReadBatteryLevel(batteryPercentage: String) {
        
    }
    
    func didReadAccessLogs(logs: String) {
        
    }
    
    func didCompleteDisengageFlow() {
        
    }
    
    func didCompleteFactoryReset(isSuccess: Bool, error: String) {
        
    }

    func revokeUser(){
        
    }
}

extension AssignUsersViewController:BLELockScanControllerProtocol{
    func didEndScan() {
        //print("didEndScan ==> ==> ")
        
        if availableListOfLock.count > 0 {
            
        } else {
            Utilities.showErrorAlertView(message: UNABLE_TO_CONNECT_LOCK, presenter: self)
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        }
    }
    
    func didDiscoverNewLock(devices: [BluetoothAdvertismentData]) {
        //print("didDiscoverNewLock ==>")
        //print(devices)
        availableListOfLock = devices
        
        if devices.count > 0 {
            
            let advertisementData = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockConnection.serialNumber)
            self.lockConnection.selectedLock = advertisementData
            UserController.sharedController.loadDataOffline(forSerialNumber: self.lockConnection.serialNumber)
        }
        
        if !isConnectedViaWIFI {
            var key = ""
            if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
                key = _key
            }
            else {
                Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
                return
            }
            self.revokeUserViaBLE(slotNumber: self.revokeUserObj.slotNumber!, key: key, userObj: self.revokeUserObj) { (status) in
            }

        }
        
    }
    
    func initializeScan(){
        let scanController = BLELockAccessManager.shared.scanController
        scanController.scanDelegate = self
        scanController.prolongedScanForPeripherals()//scanForPeripherals()
        availableListOfLock.append(contentsOf: scanController.scannedDevicesList)
        
        //print(availableListOfLock)
    }
    
}


// MARK: - UITableview

extension AssignUsersViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK： UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // set delegate to tableviewcell
        
        
        if masterListArray.count > 0 {
            if indexPath.section == 0 {
                return masterUserCell(index: indexPath as NSIndexPath, listDataArray: masterListArray1)
            } else if indexPath.section == 1 {
                return masterUserCell(index: indexPath as NSIndexPath, listDataArray: masterListArray2)
            } else if indexPath.section == 2 {
                return masterUserCell(index: indexPath as NSIndexPath, listDataArray: masterListArray3)
            } else {
                return ownerMasterUserCell(index: indexPath as NSIndexPath, listDataArray: userListArray)
            }
        } else {
            var listArray = [AssignUserModel]()
            if masterListArray1.count > 0 {
                listArray = masterListArray1
            } else if masterListArray2.count > 0 {
                listArray = masterListArray2
            } else if masterListArray3.count > 0 {
                listArray = masterListArray3
            }
            return ownerMasterUserCell(index: indexPath as NSIndexPath, listDataArray: listArray)

        }
        

        
        /*
        
        if masterListArray.count > 0 {
            
        }
        
        switch indexPath.section {
        case 0, 1, 2:
            
        default:
            <#code#>
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssignUsersTableViewCell") as? AssignUsersTableViewCell
        cell?.selectionStyle = .none
        cell?.delegate = self
        
        
        return cell!
        */
    }
    
    func masterUserCell(index:NSIndexPath, listDataArray: [AssignUserModel]) -> UITableViewCell {

        let cell = usersTableView.dequeueReusableCell(withIdentifier: "AssignUserSubTableViewCell") as? AssignUserSubTableViewCell
        cell?.selectionStyle = .none
        
        let dataObj = listDataArray[index.row] as AssignUserModel

        cell?.viewButton?.tag = Int(dataObj.slotNumber)!
        
        var userObj = AssignUserModel()
        
        switch cell?.viewButton?.tag {
            
        case 9, 10, 11, 12, 13:
            userObj = self.masterListArray1[(cell?.viewButton?.tag)! - 9]
        case 14, 15, 16, 17, 18:
            userObj = self.masterListArray2[(cell?.viewButton?.tag)! - 14]
        case 19, 20, 21, 22, 23:
            userObj = self.masterListArray3[(cell?.viewButton?.tag)! - 19]
        default:
            break
        }
        
        cell?.viewButton?.isHidden = false
        cell?.viewButton?.addTarget(self, action: #selector(onTapInfoButton(sender:)), for: .touchUpInside)
        
        cell?.revokeButton?.isHidden = true
        cell?.revokeWidthConstraint?.constant = 0
        cell?.revokeButton?.tag = Int(dataObj.slotNumber)!
        cell?.revokeButton?.addTarget(self, action: #selector(self.updateAssignUserStatus(_:)), for: .touchUpInside)
        var prefix = ""
        if (userObj.userId == nil) || userObj.userId == "" {
            prefix = "Add "
            cell?.viewButton?.isHidden = true
        }
        
        cell?.userNameLabel?.text = prefix + dataObj.name
        
        cell?.scheduleAccessButton?.isHidden = true
        cell?.scheduleAccessButton?.tag = Int(listDataArray[index.row].slotNumber)!
        cell?.scheduleAccessButton?.addTarget(self, action: #selector(onTapScheduledAccessButton), for: .touchUpInside)

        if userObj.status == "1" { // revoke
            cell?.revokeButton?.isHidden = false
            cell?.revokeWidthConstraint?.constant = 80
            
            if userObj.is_schedule_access == "1" {
                
                cell?.scheduleAccessButton?.isHidden = false
                

                let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
                let startDateString = Utilities().toDateString(date: startDate)
                
                let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
                let endDateString = Utilities().toDateString(date: endDate)
                
                let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                let startTimeString = Utilities().to24HoursTimeString(date: startTime)
                
                let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                let endTimeString = Utilities().to24HoursTimeString(date: endTime)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let currentDate = NSDate()
                let currentDateString = dateFormatter.string(from: currentDate as Date)
                
                let currentDateNew = Utilities().toDate(dateString: currentDateString)
                let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
                
                let dateFormatter1 = DateFormatter()
                dateFormatter1.dateFormat = "HH:mm"
                let currentTimeString = dateFormatter1.string(from: currentDate as Date)
                
                
                if currentDateStringNew > endDateString {
                    // expired
                    cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                    
                } else if currentDateStringNew == endDateString {
                    if currentTimeString > endTimeString {
                        // expired
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                    } else {
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                    }
                } else if startDateString < currentDateStringNew && currentDateStringNew < endDateString {
                    
                    if startTimeString < currentTimeString && currentTimeString < endTimeString {
                        // expired
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                    } else {
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                    }
                } else if startDateString > currentDateStringNew {
                    cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                } else {
                    cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                }
            }
        }


        return cell!
    }
    
    
    func ownerMasterUserCell(index:NSIndexPath, listDataArray: [AssignUserModel]) -> UITableViewCell {

        let cell = usersTableView.dequeueReusableCell(withIdentifier: "AssignUsersTableViewCell") as? AssignUsersTableViewCell
        cell?.selectionStyle = .none
        cell?.delegate = self
        
        cell?.assignUserButton.tag = Int(listDataArray[index.row].slotNumber)!
        
        cell?.expandCollapseLabelWidthConstraint.constant = 0
        cell?.expandCollapseLabel.isHidden = true
        
        //print("cell?.assignUserButton.tag ==> ")
        //print(cell?.assignUserButton.tag)
        
        cell?.infoButton?.tag = Int(listDataArray[index.row].slotNumber)!
        cell?.infoButton?.addTarget(self, action: #selector(onTapInfoButton), for: .touchUpInside)
        cell?.infoButton?.isHidden = false
        
        cell?.fpPrivilegeButton.tag = Int(listDataArray[index.row].slotNumber)!
        cell?.fpPrivilegeButton.isHidden = true
        cell?.fpPrivilegeButtonWidthConstraint.constant = 0
        
        var userObj = AssignUserModel()
        
        switch cell?.assignUserButton.tag {
        case 1, 2, 3:
            /*cell?.infoButtonWidthConstraint?.constant = 0
             cell?.infoButton?.isHidden = true */
            userObj = self.masterListArray[(cell?.assignUserButton.tag)!-1]
            cell?.infoButton?.isHidden = false
            cell?.infoButtonWidthConstraint?.constant = 35
//            cell?.fpPrivilegeButton.addTarget(self, action: #selector(onTapFPAccessButton), for: .touchUpInside)

//            if isUserPrivilegeProvided {
//                if (userObj.userId == nil) || userObj.userId == "" {
//                    cell?.fpPrivilegeButton.isHidden = true
//                    cell?.fpPrivilegeButtonWidthConstraint.constant = 0
//                }
//            } else {
//                cell?.fpPrivilegeButton.isHidden = false
//                cell?.fpPrivilegeButtonWidthConstraint.constant = 30
//            }
            if (userObj.userId == nil) || userObj.userId == "" {
                cell?.infoButtonWidthConstraint?.constant = 0
                cell?.infoButton?.isHidden = true
            }
        case 4, 5, 6, 7, 8:
            userObj = self.userListArray[(cell?.assignUserButton.tag)! - 4]
            cell?.infoButton?.isHidden = false
            cell?.infoButtonWidthConstraint?.constant = 35
            if (userObj.userId == nil) || userObj.userId == "" {
                cell?.infoButtonWidthConstraint?.constant = 0
                cell?.infoButton?.isHidden = true
            }
        case 9, 10, 11, 12, 13:
            userObj = self.masterListArray1[(cell?.assignUserButton.tag)! - 9]
            cell?.infoButton?.isHidden = false
            cell?.infoButtonWidthConstraint?.constant = 35
            if (userObj.userId == nil) || userObj.userId == "" {
                cell?.infoButtonWidthConstraint?.constant = 0
                cell?.infoButton?.isHidden = true
            }
        case 14, 15, 16, 17, 18:
            userObj = self.masterListArray2[(cell?.assignUserButton.tag)! - 14]
            cell?.infoButton?.isHidden = false
            cell?.infoButtonWidthConstraint?.constant = 35
            if (userObj.userId == nil) || userObj.userId == "" {
                cell?.infoButtonWidthConstraint?.constant = 0
                cell?.infoButton?.isHidden = true
            }
        case 19, 20, 21, 22, 23:
            userObj = self.masterListArray3[(cell?.assignUserButton.tag)! - 19]
            cell?.infoButton?.isHidden = false
            cell?.infoButtonWidthConstraint?.constant = 35
            if (userObj.userId == nil) || userObj.userId == "" {
                cell?.infoButtonWidthConstraint?.constant = 0
                cell?.infoButton?.isHidden = true
            }
        default:
            break
        }
        
        cell?.scheduleAccessButton?.isHidden = true
        cell?.scheduleAccessButton?.tag = Int(listDataArray[index.row].slotNumber)!
        cell?.scheduleAccessButton?.addTarget(self, action: #selector(onTapScheduledAccessButton), for: .touchUpInside)
        
        var prefix = ""
        
        var buttonTitle = ""
        if userObj.userId == "" {
            if userObj.status == "0" {
                buttonTitle = "Add"
                prefix = "Add "
            }
        } else {
            if userObj.status == "0" {
                buttonTitle = "Withdraw"
            } else if userObj.status == "1" {
                buttonTitle = "Revoke"
                cell?.scheduleAccessButton?.isHidden = false
                if userObj.is_schedule_access == "1" {
                    
                    let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
                    let startDateString = Utilities().toDateString(date: startDate)
                    
                    let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
                    let endDateString = Utilities().toDateString(date: endDate)
                    
                    let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                    let startTimeString = Utilities().to24HoursTimeString(date: startTime)
                    
                    let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                    let endTimeString = Utilities().to24HoursTimeString(date: endTime)
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    let currentDate = NSDate()
                    let currentDateString = dateFormatter.string(from: currentDate as Date)
                    
                    let currentDateNew = Utilities().toDate(dateString: currentDateString)
                    let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
                    
                    let dateFormatter1 = DateFormatter()
                    dateFormatter1.dateFormat = "HH:mm"
                    let currentTimeString = dateFormatter1.string(from: currentDate as Date)
                    
                    if currentDateStringNew > endDateString {
                        // expired
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                        
                    } else if currentDateStringNew == endDateString {
                        if currentTimeString > endTimeString {
                            // expired
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                        } else {
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                        }
                    } else if startDateString < currentDateStringNew && currentDateStringNew < endDateString {
                        
                        if startTimeString < currentTimeString && currentTimeString < endTimeString {
                            // expired
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                        } else {
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                        }
                    } else if startDateString > currentDateStringNew {
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                    } else {
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                    }
                    
                    /*
                    if startDateString <= currentDateStringNew && currentDateStringNew <= endDateString {
                        
                        if startTimeString <= currentTimeString && currentTimeString <= endTimeString {
                            // expired
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                        } else {
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                        }
                    } else {
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                    }
                    */
/*
                    if startDateString <= currentDateStringNew && currentDateStringNew <= endDateString {
                        
                        if startDateString == currentDateStringNew {
                            if startTimeString >= currentTimeString || currentTimeString > endTimeString {
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal) // disable
                                
                            } else {
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal) // enable
                                
                            }
                        } else if currentDateStringNew == endDateString {
                            if currentTimeString > endTimeString {
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal) // disable
                            } else {
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal) // enable
                            }
                        } else if currentDateStringNew < endDateString {
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal) // enable
                        }
                        
                    } else {
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                    } */
                } else {
                    cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                }
 
                    
            } else {
                buttonTitle = "Add"
                prefix = "Add "
            }
        }
        
        cell?.userNameLabel.text = prefix + listDataArray[index.row].name
        cell?.assignUserButton?.setTitle(buttonTitle, for: .normal)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("arrayForBool   =>>>>>>>>>>>>> \(arrayForBool)")
        //print(arrayForBool.count)
        if arrayForBool.count > 0 {
            if ((arrayForBool .object(at: section) as AnyObject).boolValue == true) {
                if self.masterListArray.count > 0 { // Owner
                    if section == 0 { // Master 1
                        return self.masterListArray1.count
                    } else if section == 1 {  // Master 2
                        return self.masterListArray2.count
                    } else if section == 2 { // MAster 3
                        return self.masterListArray3.count
                    } else { // General users
                        return self.userListArray.count
                    }
                } else { // Master's User list
                    if self.masterListArray1.count > 0 || self.masterListArray2.count > 0 || self.masterListArray3.count > 0 {
                        
                        return 5
                    } else {
                        return 0
                    }
                }
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.masterListArray.count > 0 {
            return 4
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if arrayForBool.count > 0 {
            if((arrayForBool .object(at: indexPath.section) as AnyObject).boolValue == true){
                return 60
            } else {
                return 1
            }
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.usersTableView.frame.size.width, height: 50))
        
        
        var headerTitle = "GENERAL USER(S)"

        if self.masterListArray.count > 0 && section < self.masterListArray.count {
//                headerTitle = "MASTER USER(S)"
            headerView.backgroundColor = .red
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AssignUsersTableViewCell") as? AssignUsersTableViewCell
            cell?.selectionStyle = .none
            cell?.delegate = self
            
            cell?.assignUserButton.tag = Int(masterListArray[section].slotNumber)!
            
            //print("cell?.assignUserButton.tag ==> ")
            //print(cell?.assignUserButton.tag)
            
            cell?.infoButton?.tag = Int(masterListArray[section].slotNumber)!
            cell?.infoButton?.addTarget(self, action: #selector(onTapInfoButton), for: .touchUpInside)
            cell?.infoButton?.isHidden = false
            
            cell?.fpPrivilegeButton.tag = Int(masterListArray[section].slotNumber)!
            cell?.fpPrivilegeButton.isHidden = true
            cell?.fpPrivilegeButtonWidthConstraint.constant = 0
            cell?.fpPrivilegeButton.setImage(UIImage(named: "fp"), for: .normal)

            var userObj = AssignUserModel()
            
            switch cell?.assignUserButton.tag {
            case 1, 2, 3:
                /*cell?.infoButtonWidthConstraint?.constant = 0
                 cell?.infoButton?.isHidden = true */
                userObj = self.masterListArray[(cell?.assignUserButton.tag)!-1]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                
                if userObj.status == "1" {
                    
                    if self.lockListDetailsObj.lockVersion == lockVersions.version2_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version2_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
                        cell?.fpPrivilegeButton.addTarget(self, action: #selector(onTapFPAccessButton), for: .touchUpInside)
                        let isUserPrivilegeProvided = getUserPrivilegeStatus()
                        if isUserPrivilegeProvided {
                            if (userPrivilegeUserID != "") && (userObj.userId == userPrivilegeUserID) {
                                
                                cell?.fpPrivilegeButton.isHidden = false
                                cell?.fpPrivilegeButtonWidthConstraint.constant = 30
                                cell?.fpPrivilegeButton.setImage(UIImage(named: "ic_fp_access_granted"), for: .normal)
                                
                            } else {
                                cell?.fpPrivilegeButton.isHidden = true
                                cell?.fpPrivilegeButtonWidthConstraint.constant = 0
                            }
                        } else {
                            cell?.fpPrivilegeButton.isHidden = false
                            cell?.fpPrivilegeButtonWidthConstraint.constant = 30
                        }
                    }
                }
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                    cell?.fpPrivilegeButton.isHidden = true
                    cell?.fpPrivilegeButtonWidthConstraint.constant = 0
                }
            case 4, 5, 6, 7, 8:
                userObj = self.userListArray[(cell?.assignUserButton.tag)! - 4]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            case 9, 10, 11, 12, 13:
                userObj = self.masterListArray1[(cell?.assignUserButton.tag)! - 9]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            case 14, 15, 16, 17, 18:
                userObj = self.masterListArray2[(cell?.assignUserButton.tag)! - 14]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            case 19, 20, 21, 22, 23:
                userObj = self.masterListArray3[(cell?.assignUserButton.tag)! - 19]
                cell?.infoButton?.isHidden = false
                cell?.infoButtonWidthConstraint?.constant = 35
                if (userObj.userId == nil) || userObj.userId == "" {
                    cell?.infoButtonWidthConstraint?.constant = 0
                    cell?.infoButton?.isHidden = true
                }
            default:
                break
            }
            
            cell?.scheduleAccessButton?.isHidden = true
            cell?.scheduleAccessButton?.tag = Int(masterListArray[section].slotNumber)!
            cell?.scheduleAccessButton?.addTarget(self, action: #selector(onTapScheduledAccessButton), for: .touchUpInside)
            
            var buttonTitle = ""
            var prefix = ""
            if userObj.userId == "" {
                if userObj.status == "0" {
                    buttonTitle = "Add"
                    prefix = "Add "
                }
            } else {
                if userObj.status == "0" {
                    buttonTitle = "Withdraw"
                } else if userObj.status == "1" {
                    buttonTitle = "Revoke"
                    cell?.fpPrivilegeButton.isHidden = false
                    cell?.scheduleAccessButton?.isHidden = false
                    if userObj.is_schedule_access == "1" {
                        
                        let startDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_from)
                        let startDateString = Utilities().toDateString(date: startDate)
                        
                        let endDate = Utilities().toDate(withFormat: "dd-MM-yyyy", dateString: userObj.schedule_date_to)
                        let endDateString = Utilities().toDateString(date: endDate)
                        
                        let startTime = Utilities().toTime(dateString: userObj.schedule_time_from)
                        let startTimeString = Utilities().to24HoursTimeString(date: startTime)
                        
                        let endTime = Utilities().toTime(dateString: userObj.schedule_time_to)
                        let endTimeString = Utilities().to24HoursTimeString(date: endTime)
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        let currentDate = NSDate()
                        let currentDateString = dateFormatter.string(from: currentDate as Date)
                        
                        let currentDateNew = Utilities().toDate(dateString: currentDateString)
                        let currentDateStringNew = Utilities().toDateString(date: currentDateNew)
                        
                        let dateFormatter1 = DateFormatter()
                        dateFormatter1.dateFormat = "HH:mm"
                        let currentTimeString = dateFormatter1.string(from: currentDate as Date)
                        
                        /*
                            if startDateString <= currentDateStringNew && currentDateStringNew <= endDateString {

                                if startDateString == currentDateStringNew {
                                    if startTimeString >= currentTimeString || currentTimeString > endTimeString {
                                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal) // disable
                                        
                                    } else {
                                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal) // enable
                                        
                                    }
                                } else if currentDateStringNew == endDateString {
                                    if currentTimeString > endTimeString {
                                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal) // disable
                                    } else {
                                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal) // enable
                                    }
                                } else if currentDateStringNew < endDateString {
                                    cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal) // enable
                                }
                            
                        } else {
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                        }*/
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd-MM-yyyy"
                        let firstDate = formatter.date(from: startDateString)
                        let secondDate = formatter.date(from: currentDateStringNew)

                        if currentDateStringNew > endDateString {
                            // expired
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                            
                        } else if currentDateStringNew == endDateString {
                            if currentTimeString > endTimeString {
                                // expired
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                            } else {
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                            }
                        } else if startDateString < currentDateStringNew && currentDateStringNew < endDateString {
                            
                            if startTimeString < currentTimeString && currentTimeString < endTimeString {
                                // expired
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                            } else {
                                cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                            }
                        } else if firstDate?.compare(secondDate!) == .orderedDescending {
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                        } else {
                            cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderEnabled"), for: .normal)
                        }
                    } else {
                        cell?.scheduleAccessButton?.setImage(UIImage(named: "calenderDisabled"), for: .normal)
                    }
                } else {
                    buttonTitle = "Add"
                    prefix = "Add "
                }
            }
            cell?.userNameLabel.text = prefix + masterListArray[section].name
            cell?.assignUserButton?.setTitle(buttonTitle, for: .normal)
            cell?.assignUserButton?.isUserInteractionEnabled = true
            
            if arrayForBool[section] as! Bool == true {
                cell?.expandCollapseLabel.text = "-"
            } else {
                cell?.expandCollapseLabel.text = "+"
            }
            
            let headerTapped = UITapGestureRecognizer(target: self, action: #selector(self.sectionHeaderTapped(recognizer:)))
            
            cell?.contentView.addGestureRecognizer(headerTapped)
            cell?.contentView.tag = section

            /*
            var headerButton = UIButton(frame: CGRect(x: 0, y: 0, width: (cell?.userNameLabel.frame.size.width)!, height: 50))

            headerButton.addGestureRecognizer(headerTapped)
            headerButton.tag = section
            
            cell?.addSubview(headerButton)
            */
            
            cell?.expandCollapseLabelWidthConstraint.constant = 30
            cell?.expandCollapseLabel.isHidden = false
            
            return cell!
        } else {
            
            if self.masterListArray.count == 0 {
                headerTitle = "MASTER USER(S)"
            }
            let headerTitleLabel = UILabel(frame: CGRect(x: 10, y: 5, width: self.usersTableView.frame.size.width - 20, height: 40))
            
            headerView.backgroundColor = UIColor.lightGray

            headerTitleLabel.text = headerTitle
            headerView.addSubview(headerTitleLabel)
            /*
            let headerTapped = UITapGestureRecognizer(target: self, action: #selector(self.sectionHeaderTapped(recognizer:)))
            
            headerView .addGestureRecognizer(headerTapped)
            headerView.tag = section */
            return headerView
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.usersTableView.frame.size.width, height: 0))
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    @objc func sectionHeaderTapped(recognizer: UITapGestureRecognizer) {

        
        let indexPath : NSIndexPath = NSIndexPath(row: 0, section:(recognizer.view?.tag as Int?)!)
        if (indexPath.row == 0) {
            
            var collapsed = (arrayForBool .object(at: indexPath.section) as AnyObject).boolValue
            collapsed       = !collapsed!;
            
            arrayForBool .replaceObject(at: indexPath.section, with: collapsed)
            //reload specific section animated
            let range = NSMakeRange(indexPath.section, 1)
            let sectionToReload = NSIndexSet(indexesIn: range)
            self.usersTableView.reloadSectionIndexTitles()
            self.usersTableView.reloadData()
        }
        
    }
    
    @objc func sectionHeaderButtonTapped(sender: UIButton) {
        
        
        let indexPath : NSIndexPath = NSIndexPath(row: 0, section:(sender.tag as Int?)!)
        if (indexPath.row == 0) {
            
            var collapsed = (arrayForBool .object(at: indexPath.section) as AnyObject).boolValue
            collapsed       = !collapsed!;
            
            arrayForBool .replaceObject(at: indexPath.section, with: collapsed)
            //reload specific section animated
            let range = NSMakeRange(indexPath.section, 1)
            let sectionToReload = NSIndexSet(indexesIn: range)
            self.usersTableView .reloadSections(sectionToReload as IndexSet, with:UITableView.RowAnimation.fade)
        }
        
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

// MARK: - Revoke finger print

extension AssignUsersViewController {
    
    func revokeMasterUserFingerPrintAccess() {
        
        // revoke finger printaccess
        let userID = self.revokeUserObj.userId
        let filterArray = self.fingerPrintUsersArray.filter({ (fpUserModelObj) -> Bool in
            return fpUserModelObj.userId == userID
        })
        print("count ========>>>>>>>      \(filterArray.count)")
        print("filterArray ====> \(filterArray)")
        
        var keyString = ""
        if filterArray.count > 0 {
            keyString = filterArray[0].key
            self.keyArray = Utilities().convertKeyStringToKeyArray(with: keyString)
            self.revokeFailedKeyArray = self.keyArray
            self.selectedKeyValue = filterArray[0].key
            self.selectedFingerPrintID = filterArray[0].id
            // For testing
//            self.revokeFingerPrintViaWIFI()
            if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                self.revokeFingerPrintViaWIFI()
            } else {
                self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode,  slotNumber: revokeUserObj.slotNumber, userObj: self.revokeUserObj, isRevokeUser: false)
            }
        } else {
            self.revokeUserWithWIFI()
        }
    }
    
    func revokeFingerPrintViaWIFI() { // handle for each key
        
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        self.revokeCall()
    }
    
    func revokeCall() {
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = [String : Any]()
            parameters["owner-id"] = authorizationKey["owner-id"]
            parameters["slot-key"] = authorizationKey["slot-key"]
            // hack to ensure right slot number is passed
            
            //            Payload  {"owner-id":"12345678","slot-key":"ABCDEF01ABCDEF01ABCDEF01","fp-id":1}
            //            ["owner-id":self.ownerId,"slot-key":self.userKey]
            
            let keyValue = self.keyArray[self.revokedKeyCountForUser]
            
            parameters["fp-id"] = Int(keyValue) // should be integer
            LockWifiManager.shared.revokeFingerPrint(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        var updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        print("-----------------------")
                        print(updatedKey)
                        updatedKey = (updatedKey == "" || updatedKey == "none") ? "FP_NOT_PLACED" : updatedKey

                        let tempStr: LockWifiFPMessages = LockWifiFPMessages(rawValue: updatedKey)!
                        
                        switch tempStr {
                        case .OK:
                            // success
                            // next service call
                            // remove in array list
                            print(".OK")
                            
                            break
                            
                        case .FP_USER_ID_NOT_EXISTS: // for revoke finger print failure
                            
                            LoaderView.sharedInstance.hideShadowView(selfObject: self)
                            let alert = UIAlertController(title: ALERT_TITLE, message: FP_USER_ID_NOT_EXISTS, preferredStyle: UIAlertController.Style.alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            }))
                            self.present(alert, animated: true, completion: nil)
                            break
                        case .AUTHVIA_FP_DISABLED:
                            Utilities.showSuccessAlertView(message: FP_MANAGE_PRIVILEGE_FAILED, presenter: self)
                            break
                        case .EMPTY:
                            break
                        default:
                            break
                        }
                        
                        let value = self.keyArray[self.revokedKeyCountForUser]
                        
                        if let index = self.revokeFailedKeyArray.firstIndex(of: value) {
                            self.revokeFailedKeyArray.remove(at: index)
                        }
                        
                        self.revokedKeyCountForUser = self.revokedKeyCountForUser + 1
                        
                        if self.revokedKeyCountForUser == self.keyArray.count && self.revokeFailedKeyArray.count == 0 {
                            // all fp ids revoked
                            
                            self.saveRevokeFingerPrintOffline()
                            
                            // OKAy --> removed
                            
                            self.revokeUserViaWIFI(slotNumber: self.revokeUserObj.slotNumber, userObj: self.revokeUserObj)
                            
                        } else {
                            self.revokeCall()
                        }
                        // revoke user put here
                    } else {
                        LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    }
                } else {
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke user.", presenter: self)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke user.", presenter: self)
        }
    }
}

// MARK: - Handle Offline save

extension AssignUsersViewController {
    
    func saveRevokeFingerPrintOffline() {
        
        let userDetailsDict = [
            "user_id": "",
            "key": self.selectedKeyValue,
            "status": "0" // for revoke
        ]
        var userDetails = [String: String]()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userDetailsDict, options: .prettyPrinted)
            
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let dictFromJSON = decoded as? [String: String] {
                userDetails = dictFromJSON
                //print("dictFromJSON ==> \(dictFromJSON)")
            }
        } catch {
            //print(error.localizedDescription)
        }
        
        LockWifiManager.shared.localCache.saveRevokeFPKey(with: userDetails, keyID: self.selectedFingerPrintID)
        
    }
}

/*
 // MARK: - UITableview
 
 extension AssignUsersViewController: UITableViewDataSource, UITableViewDelegate {
 // MARK： UITableViewDataSource
 func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 // set delegate to tableviewcell
 
 let cell = tableView.dequeueReusableCell(withIdentifier: "AssignUsersTableViewCell") as? AssignUsersTableViewCell
 cell?.selectionStyle = .none
 cell?.delegate = self
 
 if self.masterListArray.count > 0 {
 if (indexPath as NSIndexPath).section == 0 {
 let masterObj = self.masterListArray[indexPath.row]
 cell?.userNameLabel.text = masterObj.name
 var buttonTitle = ""
 if masterObj.userId == "" {
 if masterObj.status == "0" {
 buttonTitle = "Add"
 }
 } else {
 if masterObj.status == "0" {
 buttonTitle = "Withdraw"
 } else {
 buttonTitle = "Revoke"
 }
 }
 //                cell?.assignUserButton.tag = Int(masterObj.slotNumber)!
 cell?.assignUserButton.tag = ((indexPath.section + 1) * 1000) + indexPath.row
 
 cell?.assignUserButton.setTitle(buttonTitle, for: .normal)
 cell?.delegate = self
 return cell!
 
 } else if (indexPath as NSIndexPath).section == 1 {
 let userObj = self.userListArray[indexPath.row]
 cell?.userNameLabel.text = userObj.name
 
 var buttonTitle = ""
 if userObj.userId == "" {
 if userObj.status == "0" {
 buttonTitle = "Add"
 }
 } else {
 if userObj.status == "0" {
 buttonTitle = "Withdraw"
 } else {
 buttonTitle = "Revoke"
 }
 }
 
 //                cell?.assignUserButton.tag = Int(userObj.slotNumber)!
 cell?.assignUserButton.tag = ((indexPath.section + 1) * 1000) + indexPath.row
 cell?.assignUserButton.setTitle(buttonTitle, for: .normal)
 cell?.delegate = self
 return cell!
 
 } else {
 return UITableViewCell()
 }
 } else { // Master
 if (indexPath as NSIndexPath).section == 0 {
 let userObj = self.userListArray[indexPath.row]
 cell?.userNameLabel.text = userObj.name
 
 var buttonTitle = ""
 if userObj.userId == "" {
 if userObj.status == "0" {
 buttonTitle = "Add"
 }
 } else {
 if userObj.status == "0" {
 buttonTitle = "Withdraw"
 } else {
 buttonTitle = "Revoke"
 }
 }
 //                cell?.assignUserButton.tag = Int(userObj.slotNumber)!
 cell?.assignUserButton.tag = ((indexPath.section + 1) * 1000) + indexPath.row
 
 cell?.assignUserButton.setTitle(buttonTitle, for: .normal)
 cell?.delegate = self
 return cell!
 
 } else {
 return UITableViewCell()
 }
 }
 }
 
 func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
 if self.masterListArray.count > 0 { // Owner
 if section == 0 {
 return self.masterListArray.count
 } else {
 return self.userListArray.count
 }
 } else { // Master
 return self.userListArray.count
 }
 }
 
 func numberOfSections(in tableView: UITableView) -> Int {
 if self.masterListArray.count > 0 {
 return 2
 } else {
 return 1
 }
 }
 
 func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
 return 60 // UITableViewAutomaticDimension
 }
 
 func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
 let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.usersTableView.frame.size.width, height: 50))
 
 let headerTitleLabel = UILabel(frame: CGRect(x: 10, y: 5, width: self.usersTableView.frame.size.width - 20, height: 40))
 
 var headerTitle = "GENERAL USER(S)"
 if self.masterListArray.count > 0 {
 if section == 0 {
 headerTitle = "MASTER USER(S)"
 }
 }
 
 headerTitleLabel.text = headerTitle
 headerView.addSubview(headerTitleLabel)
 headerView.backgroundColor = UIColor.lightGray
 return headerView
 }
 
 func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
 return 50
 }
 
 // MARK: - UITableViewDelegate
 
 func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
 }
 }
 
 */




/// Country code selection and validation
extension AssignUsersViewController {
    func showMobileNumberConfirmView(hidden : Bool){
        CountryManager.shared.resetLastSelectedCountry()
        self.shadowView.isHidden = hidden
        self.phoneNumberConfirmView.isHidden = hidden
    }
}
