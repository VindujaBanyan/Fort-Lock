//
//  LockDetailsViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 11/06/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import NetworkExtension

class LockDetailsViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var textFieldView: UIView!
    
    @IBOutlet var lockNameTextField: TweeAttributedTextField!
    
    @IBOutlet var nameDetailsView: UIView!
    
    @IBOutlet var lockNameLabel: UILabel!
    @IBOutlet var firstTimeEngageLockLabel: UILabel!
    @IBOutlet var buttonStackView: UIStackView!
    
    @IBOutlet weak var disengageButton: UIButton!
    @IBOutlet var usersView: UIView!
    @IBOutlet var historyView: UIView!
    
    @IBOutlet var rfidView: UIView!
    @IBOutlet var fingerPrintView: UIView!
    //@IBOutlet var transferOwnerView: UIView! // this option moved to left menu
    
    @IBOutlet var usersButton: UIButton!
    @IBOutlet var historyButton: UIButton!
    @IBOutlet var rfidButton: UIButton!
    @IBOutlet var fingerPrintButton: UIButton!
    //@IBOutlet var transferOwnerButton: UIButton!
    @IBOutlet var factoryResetButton: UIButton!
    var customBackBtnItem = UIBarButtonItem()
    var customEditBtnItem = UIBarButtonItem()
    var customDoneBtnItem = UIBarButtonItem()
    var customSettingsBtnItem = UIBarButtonItem()
    
    @IBOutlet weak var lockBatteryLabel: UILabel!
    @IBOutlet var batteryLevel: UILabel!
    @IBOutlet var batteryImageView:UIImageView!
    @IBOutlet var factoryResetIcon:UIImageView!
    
    var isConnectedVisBLE = Bool()
    var isConnectedViaWIFI = Bool()
    var availableListOfLock:[BluetoothAdvertismentData] = []
    
    var isDisEngageTapped = Bool()
    
    var userKey:String?
    //    var lockDetailsObj = LockDetailsModel()
    var lockConnection:LockConnection = LockConnection()
    var lockListDetailsObj = LockListModel(json: [:])
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    /// Version 3 fields
    @IBOutlet var buttonStackViewWithDigiPin: UIStackView!
    @IBOutlet weak var userViewDigiPin: UIView!
    @IBOutlet weak var fingerPrintDigiPin: UIView!
    @IBOutlet weak var rfidDigiPin: UIView!
    @IBOutlet weak var pinDigiPin: UIView!
    @IBOutlet var historyViewDigiPin: UIView!
    
    
    @IBOutlet weak var engageLockLabel: UILabel!
    
    private let notificationCenter = NotificationCenter.default
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initialize()
        
        notificationCenter
                          .addObserver(self,
                           selector:#selector(processBackgroundNotifiData(_:)),
                                       name: NSNotification.Name(BundleIdentifier),
                           object: nil)
    }
    
    @objc func processBackgroundNotifiData(_ notification: Notification) {
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        if let userInfo = notification.userInfo {
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            let body = userInfo["body"] as? String
            let command = userInfo["command"] as? String
            let status = userInfo["status"] as? String
            
            if (status == "success" && command == LockNotificationCommand.ENGAGE.rawValue) {
                Utilities.showSuccessAlertView(message: body ?? "", presenter: self)
            }else if (status == "failure") && command == LockNotificationCommand.ENGAGE.rawValue {
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
        
//        NotificationCenter.default.addObserver(self, selector:#selector(self.checkForReachability), name: NSNotification.Name.reachabilityChanged, object: nil)

        self.nameDetailsView.isHidden = false
        self.textFieldView.isHidden = true
        
        if self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
            engageLockLabel.text = "Please Tap here to Lock/Unlock"
        }else {
            engageLockLabel.text = "Please switch ON the Lock and Tap here to Lock/Unlock"
        }
//        self.factoryResetIcon.isHidden = true
//        self.factoryResetButton.isHidden = true
        updateBatteryPercentage(battery: self.lockListDetailsObj.battery)
        LockWifiManager.shared.localCache.updateOfflineItems()
        
        /* //Removed Transfer owner view - Moved to left menu
        if self.transferOwnerView != nil {
            self.buttonStackView.removeArrangedSubview(self.transferOwnerView)
            self.transferOwnerView.removeFromSuperview()
        }
 */

        if self.lockListDetailsObj.lock_keys[1].user_type!.lowercased() == UserRoles.owner.rawValue {
            // Lock Owner settings
//            self.factoryResetIcon.isHidden = false
//            self.factoryResetButton.isHidden = false
            print("If Part")
            addRightBarButtonItems()
            //self.navigationItem.rightBarButtonItem = self.customEditBtnItem
            
            // Only for lock version 2.0 OWNERS
            if (self.lockListDetailsObj.lockVersion == lockVersions.version2_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version2_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue) {
                // show FP & RFID
                handleTransferOwnerUI()
                print("Version "+self.lockListDetailsObj.lockVersion);
            } else {
                removeRIFDViewFromButtonStack()
                removeFingerPrintViewFromButtonStack()
            }
            
        } else if self.lockListDetailsObj.lock_keys[1].user_type!.lowercased() == UserRoles.master.rawValue {
            //Lock Master settings
            print("Else if Part")
            // show finger print based on user privilege options - only for lock version 2.0 MASTERS
            
            if (self.lockListDetailsObj.userPrivileges != nil) && (self.lockListDetailsObj.userPrivileges == self.lockListDetailsObj.lock_keys[1].userID) && (self.lockListDetailsObj.lockVersion == lockVersions.version2_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version2_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue){
                // show FP & RFID
                
            } else {
                removeRIFDViewFromButtonStack()
                removeFingerPrintViewFromButtonStack()
            }
        } else {
            // Lock User settings
            print("Else Part")
            removeUserViewFromButtonStack()
            removeRIFDViewFromButtonStack()
            removeFingerPrintViewFromButtonStack()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        BLELockAccessManager.shared.disengageDelegate = nil
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.reachabilityChanged, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize Methods
    
    func initialize() {
        self.title = "Lock Details"
        self.nameDetailsView.isHidden = false
        self.textFieldView.isHidden = true
        
        self.lockNameLabel.text = self.lockListDetailsObj.lockname
        lockNameTextField.delegate = self

        self.addBackBarButton()
        self.handleTransferOwnerUI()
        if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
            self.userKey = _key
            if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                BLELockAccessManager.shared.scanController.proactiveScanning(serialNumber: self.lockConnection.serialNumber, completionBlock: nil)
            }
        }
    }
    
    func initializeFirstTimeOwnerUI(){
        self.firstTimeEngageLockLabel.isHidden = false
        self.firstTimeEngageLockLabel.text = "You may now operate the lock"
        self.batteryImageView.isHidden = true
        self.lockBatteryLabel.isHidden = true
        self.batteryLevel.isHidden = true
//        self.factoryResetIcon.isHidden = true
//        self.factoryResetButton.isHidden = true
    }
    
    //checking app is production state
    func checkFactoryApp()
    {
        if  BatteryLevelVisibility // UAT, QA, DEV, FActory
        {
            self.lockBatteryLabel.isHidden = false
            self.batteryImageView.isHidden = false
            self.batteryLevel.isHidden = false
        }
        else  // production
        {
//            self.lockBatteryLabel.isHidden = true
//            self.batteryImageView.isHidden = true
            self.batteryLevel.isHidden = true
        }
    }
    
    func hideFirstTimeOwnerUI(){
        self.firstTimeEngageLockLabel.isHidden = true
        self.firstTimeEngageLockLabel.text = ""
        self.lockBatteryLabel.isHidden = false
        self.batteryImageView.isHidden = false
        self.batteryLevel.isHidden = false
        self.checkFactoryApp()
        if self.lockListDetailsObj.lock_keys[1].user_type!.lowercased() == UserRoles.owner.rawValue {
            //print("Owner")
//            self.factoryResetIcon.isHidden = false
//            self.factoryResetButton.isHidden = false
            addRightBarButtonItems()
            //self.navigationItem.rightBarButtonItem = self.customEditBtnItem
            
        } else {
//            self.factoryResetIcon.isHidden = true
//            self.factoryResetButton.isHidden = true
        }
    }
    
    // MARK: - Navigation Bar Button
    
    func addBackBarButton() {
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        backBtn.addTarget(self, action: #selector(self.popToRoot), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        self.customBackBtnItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = self.customBackBtnItem
    }
    
    func addRightBarButtonItems() {
        let editBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        editBtn.addTarget(self, action: #selector(self.onTapEditButton), for: UIControl.Event.touchUpInside)
        if let image = UIImage(named: "edit_icon.png") {
            editBtn.setImage(image, for: .normal)
        }
//        editBtn.setTitle("Edit", for: .normal)
//
//        editBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
        editBtn.sizeToFit()
        self.customEditBtnItem = UIBarButtonItem(customView: editBtn)
        
        let doneBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        doneBtn.addTarget(self, action: #selector(self.onTapDoneButton), for: UIControl.Event.touchUpInside)
        if let image = UIImage(named: "done_icon.png") {
            doneBtn.setImage(image, for: .normal)
        }
//        doneBtn.setTitle("Done", for: .normal)
//
//        doneBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
        doneBtn.sizeToFit()
        self.customDoneBtnItem = UIBarButtonItem(customView: doneBtn)
        
        var rightBarButtonItemsTemp:[UIBarButtonItem] = []
        
        if (self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue){
            let homeWiFiSettingsBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
            homeWiFiSettingsBtn.addTarget(self, action: #selector(self.onTapHomeWiFiSettingsButton), for: UIControl.Event.touchUpInside)
            if let image = UIImage(named: "settings_icon.png") {
                homeWiFiSettingsBtn.setImage(image, for: .normal)
            }
            
            self.customSettingsBtnItem = UIBarButtonItem(customView: homeWiFiSettingsBtn)
            rightBarButtonItemsTemp.append(self.customSettingsBtnItem)
        }
        rightBarButtonItemsTemp.append(self.customEditBtnItem)
        
        self.navigationItem.rightBarButtonItems = rightBarButtonItemsTemp
    }
    
    func handleTransferOwnerUI(){
        DispatchQueue.main.async { [unowned self] in
            let userObj = self.lockListDetailsObj.lock_keys![0] as UserLockRoleDetails
            if userObj.status! == "2" || self.lockListDetailsObj.wasAddedOffline {
                self.buttonStackView.isHidden = true
                self.buttonStackViewWithDigiPin.isHidden = true
                self.historyViewDigiPin.isHidden = true
                self.initializeFirstTimeOwnerUI()
            }
            else{
                if self.lockListDetailsObj.lockVersion == lockVersions.version2_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version2_1.rawValue{
                    self.buttonStackView.isHidden = false
                    self.buttonStackViewWithDigiPin.isHidden = true
                    self.historyViewDigiPin.isHidden = true
                }else if self.lockListDetailsObj.lockVersion == lockVersions.version3_0.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version3_1.rawValue || self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue{
                    if self.lockListDetailsObj.lock_keys[1].user_type!.lowercased() == UserRoles.owner.rawValue {
                        self.historyViewDigiPin.isHidden = false
                        self.buttonStackView.isHidden = true
                        self.buttonStackViewWithDigiPin.isHidden = false
                    } else if self.lockListDetailsObj.lock_keys[1].user_type!.lowercased() == UserRoles.master.rawValue {
                        self.historyViewDigiPin.isHidden = true
                        self.buttonStackView.isHidden = false
                        self.buttonStackViewWithDigiPin.isHidden = true
                    } else {
                        self.historyViewDigiPin.isHidden = true
                        self.buttonStackView.isHidden = false
                        self.buttonStackViewWithDigiPin.isHidden = true
                    }
                }
                self.hideFirstTimeOwnerUI()
            }
        }
        
    }
    
    // MARK: - Button stack UI update methods
    
    func removeUserViewFromButtonStack() {
        if self.usersView != nil {
            self.buttonStackView.removeArrangedSubview(self.usersView)
            self.usersView.removeFromSuperview()
        }
    }
    
    func removeRIFDViewFromButtonStack() {
        if self.rfidView != nil {
            self.buttonStackView.removeArrangedSubview(self.rfidView)
            self.rfidView.removeFromSuperview()
        }
    }
    
    func removeFingerPrintViewFromButtonStack() {
        if self.fingerPrintView != nil {
            self.buttonStackView.removeArrangedSubview(self.fingerPrintView)
            self.fingerPrintView.removeFromSuperview()
        }
    }
    
    // MARK: - Button Actions
    
    @objc func popToRoot() {
        BLELockAccessManager.shared.disconnectLock()
        BLELockAccessManager.shared.scanController.stopPeripheralScan()
        self.navigationController?.popViewController(animated: true)
    }
    

    
    // MARK: - Factory Reset Methods

    
    @IBAction func onTapFactoryResetBtn(_ sender: Any) {}
    
    @IBAction func onTapDisengageButton(_ sender: UIButton) {
//        previousImplementation() -> wifi and then ble connection checked
        if self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
            self.engageLockViaMqttServiceCall()
        }else {
            if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                    self.disEngageWithWIFI()
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
            }
        }
    }
    
    func engageLockViaMqttServiceCall() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "locks/\(self.lockListDetailsObj.serial_number ?? "")/engage"
        
        self.customEditBtnItem.isEnabled = false
        self.customSettingsBtnItem.isEnabled = false
        LockDetailsViewModel().engageLockViaMqttViewModel(url: urlString, lockDetails: [:]) { result, error in
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.customEditBtnItem.isEnabled = true
            self.customSettingsBtnItem.isEnabled = true
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
    
    // MARK: - Wifi Settings
    
    func configureWifiConnection(ssid: String, password: String, isFactoryReset: Bool, isTransferredOwner: Bool) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            
            let config = NEHotspotConfiguration(ssid: newSSID, passphrase: password, isWEP: false)
            config.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(config) { (error) in
                //print("NEHotspotConfigurationManager.shared.apply =========")
                if let error = error {
                    self.isConnectedViaWIFI = false
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {

                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                            self.isConnectedViaWIFI = true

                            if isTransferredOwner {
                                let oldOwnerId = self.lockListDetailsObj.lock_owner_id![0].id!
//                                let userObj = self.lockListDetailsObj.lock_keys![0] as UserLockRoleDetails
//                                var slotNumber = userObj.slot_number
//                                if slotNumber == "1"{
//                                    slotNumber = "01"
//                                }
                                var slotNumber = self.lockListDetailsObj.lock_owner_id![0].slot_number
                                print("lockDisengageViaWIFI")
                                self.transferOwnerViaWifi(oldOwnerId: oldOwnerId, slotNumber: slotNumber!)
                            } else {
                                //print("configureWifiConnection ==> self.disengageViaWifi()")
                                self.disengageViaWifi()
                            }
                            
                        } else {
                            self.isConnectedViaWIFI = false
//                            Utilities.showErrorAlertView(message: "Unable to connect to lock. Please try again", presenter: self)
                        }
                        
                    })
                }
            }
        } else {
            // handle older versions
            let message = SETTINGS_NAVIGATION
            let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
            /*
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                
            })) */
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                self.navigateToDeviceSettings()
            }))
            self.present(alert, animated: true, completion: nil)
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

        }
    }
    
    func disconnectWifi(ssid: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        if #available(iOS 11.0, *) {
            //print("disconnectWifi(ssid: String) ==> \(ssid)")
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
    
    @objc func checkForReachability(notification:NSNotification)
    {
        // Remove the next two lines of code. You cannot instantiate the object
        // you want to receive notifications from inside of the notification
        // handler that is meant for the notifications it emits.
        
        //var networkReachability = Reachability.reachabilityForInternetConnection()
        //networkReachability.startNotifier()
        
        //print("Notification =====> checkForReachability lock details")
        //print(notification)
        
        let networkReachability = notification.object as! Reachability;
        var remoteHostStatus = networkReachability.connection
        
        //print("remoteHostStatus.description ==> \(remoteHostStatus.description)")
        if remoteHostStatus.description == "No Connection" {
            
        } else { // Cellular, WiFi
            
            let authToken = UserDefaults.standard.string(forKey: UserdefaultsKeys.authenticationToken.rawValue)
            if authToken != nil {
                let keychain = KeychainSwift()
                let decryptValue = keychain.getData(KeychainKeys.securityPin.rawValue)
                if decryptValue != nil {
//                    LockWifiManager.shared.localCache.updateOfflineItems()
                    if !isDisEngageTapped {
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                            self.isConnectedViaWIFI = true
                            let userObj = self.lockListDetailsObj.lock_keys![0] as UserLockRoleDetails
                            var isTransferredOwner = Bool()
                            if userObj.status! == "2" || lockListDetailsObj.wasAddedOffline == true {
                                isTransferredOwner = true
                            }
                            if isTransferredOwner {
                                let oldOwnerId = self.lockListDetailsObj.lock_owner_id![0].id!
                                var slotNumber = userObj.slot_number
                                if slotNumber == "1"{
                                    slotNumber = "01"
                                }
                                print("checkForReachability")
                                self.transferOwnerViaWifi(oldOwnerId: oldOwnerId, slotNumber: slotNumber!)
                            } else {
                                //print("check for reachability ==> self.disengageViaWifi()")
                                
                                
                                self.disengageViaWifi()
                            }
                            
                        } else {
                            self.isConnectedViaWIFI = false
                            //                            Utilities.showErrorAlertView(message: "Unable to connect to lock. Please try again", presenter: self)
                        }
                    }
                }
            }
        }
        /*
         let networkReachability = notification.object as! Reachability;
         var remoteHostStatus = networkReachability.currentReachabilityStatus()
         
         if (remoteHostStatus.value == NotReachable.value)
         {
         println("Not Reachable")
         }
         else if (remoteHostStatus.value == ReachableViaWiFi.value)
         {
         println("Reachable via Wifi")
         }
         else
         {
         println("Reachable")
         }*/
    }
    
    // MARK: - Engage Lock Methods
    
    func engageLock() {
        
        var key = ""
        if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
            key = _key
        } else {
            Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
            return
        }
        let userObj = lockListDetailsObj.lock_keys![0] as UserLockRoleDetails

        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
            

            self.lockDisengageViaWIFI(userObj: userObj)
            
        } else {
            
            if lockConnection.selectedLock == nil {
                lockConnection.selectedLock  = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockConnection.serialNumber)
            }
            
            if lockConnection.selectedLock != nil {
                
                if userObj.status! == "2" || lockListDetailsObj.wasAddedOffline == true {
                    // After transferring ownership first time disengage
                    // communicate with hardware and reset previous ownerid
                    // call revoke service call
                    var slotNumber = userObj.slot_number
                    if slotNumber == "1"{
                        slotNumber = "01"
                    }
                    
                    //print("userObj.status! == 2 @@@@@@@@@@@@@@@@ ==> lock already exist")

                    
                    self.transferOwnerUpdateViaBLE(slotNumber: slotNumber!, key: key) { (status) in
                        
                        /*
                        DispatchQueue.main.asyncAfter(deadline: .now() + CONNECTIVITY_TIME, execute: {
                            if !self.isConnectedVisBLE {
                                let oldOwnerId = self.lockListDetailsObj.lock_owner_id![0].id!
                                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                                    self.transferOwnerViaWifi(oldOwnerId: oldOwnerId, slotNumber: slotNumber!)
                                } else {
                                    
                                    if Connectivity().isConnectedToInternet() {
                                        self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.lockListDetailsObj.scratch_code, isFactoryReset: false, isTransferredOwner: true)

                                    } else {
                                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

                                        let message = TURN_ON_WIFI
                                        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                                        
                                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                        }))
                                        self.present(alert, animated: true, completion: nil)
                                    }

                                }
                            }
                        }) */
                    }
                    
                } else {
                    self.disengageLockViaBLE(key: key) { (status) in
                        
                        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                       /*
                        DispatchQueue.main.asyncAfter(deadline: .now() + CONNECTIVITY_TIME, execute: {
                            if !self.isConnectedVisBLE {
                                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                                    self.disengageViaWifi()
                                } else {

                                    
                                    if Connectivity().isConnectedToInternet() {
                                        self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.lockListDetailsObj.scratch_code, isFactoryReset: false, isTransferredOwner: false)
                                    } else {
                                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

                                        let message = TURN_ON_WIFI
                                        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                                        
                                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                        }))
                                        self.present(alert, animated: true, completion: nil)
                                    }
                                    
                                }
                            }
                        }) */
                    }
                }
                
            } else {
                /*
                
                BLELockAccessManager.shared.stopPeripheralScan()
                BLELockAccessManager.shared.prolongedScanForPeripherals()
                
                //print("userObj.status! == 2 @@@@@@@@@@@@@@@@ ==> ======&&&&&&&&&&& ")

                
                if userObj.status! == "2" || lockListDetailsObj.wasAddedOffline == true {
                    // After transferring ownership first time disengage
                    // communicate with hardware and reset previous ownerid
                    // call revoke service call
                    var slotNumber = userObj.slot_number
                    if slotNumber == "1"{
                        slotNumber = "01"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + CONNECTIVITY_TIME, execute: {
                        self.firstTimeDisenageWithWIFI(slotNumber: slotNumber!)
                    })
                    
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + CONNECTIVITY_TIME, execute: {
                        self.disEngageWithWIFI()
                    })
                }
 */
            }
        }
    }
    
    func disEngageWithWIFI() {
        
        var lockVersion = lockVersions.version1
        if let version = self.lockListDetailsObj.lockVersion{
            lockVersion = lockVersions(rawValue: version)!
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + getActivityTime(lockVersion: lockVersion), execute: {
            if !self.isConnectedViaWIFI {
                if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                    print("Initialize Scan")
                    self.initializeScan()
                    
                }  else {
                    Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
                }
            }
        })
        let userObj = lockListDetailsObj.lock_keys![0] as UserLockRoleDetails

        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
//            self.disengageViaWifi()
            self.lockDisengageViaWIFI(userObj: userObj)
        } else {
            
//            if Connectivity().isConnectedToInternet() {
            
                var transferOwnerStatus = false
                if userObj.status! == "2" || lockListDetailsObj.wasAddedOffline == true {
                    transferOwnerStatus = true
                }
            print()
print("disEngageWithWIFI config")
                self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.lockListDetailsObj.scratch_code, isFactoryReset: false, isTransferredOwner: transferOwnerStatus)
          
            /*} else {
//                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                let message = TURN_ON_WIFI
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
            } */
        }
        
    }
    
    func firstTimeDisenageWithWIFI(slotNumber: String) {
        if !self.isConnectedVisBLE {
            let oldOwnerId = self.lockListDetailsObj.lock_owner_id![0].id!
            if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                print("firstTimeDisenageWithWIFI")
                self.transferOwnerViaWifi(oldOwnerId: oldOwnerId, slotNumber: slotNumber)
            } else {
                
//                if Connectivity().isConnectedToInternet() {
                print("firstTimeDisenageWithWIFI config")
                    self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.lockListDetailsObj.scratch_code, isFactoryReset: false, isTransferredOwner: true)
              /*  } else {
//                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                    
                    let message = TURN_ON_WIFI
                    let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    }))
                    self.present(alert, animated: true, completion: nil)
                }*/
            }
        }
    }
    
    func engageLockWorking() {
        /*
        if lockConnection.isConnectedToLockWifi(ssidName: lockConnection.serialNumber) == false {
            
            if lockConnection.selectedLock == nil {
                
                lockConnection.selectedLock  = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockConnection.serialNumber)
            }
            guard   lockConnection.selectedLock  != nil else {
                
                 if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                 BLELockAccessManager.shared.stopPeripheralScan()
                 Utilities.showErrorAlertView(message: "Unable to connect the lock", presenter: self)
                 BLELockAccessManager.shared.prolongedScanForPeripherals()
                 
                 }
                 else{
                 Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
                 }
//                Utilities.showErrorAlertView(message: "Unable to connect the lock", presenter: self)
                
                return
            }
        }
        
        let userObj = lockListDetailsObj.lock_keys![0] as UserLockRoleDetails
        //let userObj1 = lockListDetailsObj.lock_keys![1] as UserLockRoleDetails
        var key = ""
        if let _key = UserController.sharedController.authorizationKey() {
            key = _key
        } else {
            Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
            return
        }
        
        if userObj.status! == "2" || lockListDetailsObj.wasAddedOffline == true {
            // After transferring ownership first time disengage
            // communicate with hardware and reset previous ownerid
            // call revoke service call
            var slotNumber = userObj.slot_number
            if slotNumber == "1"{
                slotNumber = "01"
            }
            
            self.transferOwnerUpdateViaBLE(slotNumber: slotNumber!, key: key)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0, execute: {
                let oldOwnerId = self.lockListDetailsObj.lock_owner_id![0].id!
                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                    self.transferOwnerViaWifi(oldOwnerId: oldOwnerId, slotNumber: slotNumber!)
                } else {
                    // ios 11 - Auto connection
                    self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.lockListDetailsObj.scratch_code)
                }
                
            })
            
        } else {
            
            self.disengageLockViaBLE(key: key)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0, execute: {
                
                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                    
                    self.disengageViaWifi()
                } else {
                    // ios 11 - Auto connection
                    self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.lockListDetailsObj.scratch_code)
                }
            })
        }
        */
    }
    
    func lockDisengageViaWIFI(userObj: UserLockRoleDetails) {
        if userObj.status! == "2" || lockListDetailsObj.wasAddedOffline == true {
            
            var slotNumber = userObj.slot_number
            if slotNumber == "1"{
                slotNumber = "01"
            }
            let oldOwnerId = self.lockListDetailsObj.lock_owner_id![0].id!
            print("lockDisengageViaWIFI")
            self.transferOwnerViaWifi(oldOwnerId: oldOwnerId, slotNumber: slotNumber!)
            
        } else {
            self.disengageViaWifi()
        }
    }
    
    
    func disengageViaWifi() {
        
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var customHeaders = authorizationKey
            customHeaders["lockId"] = self.lockListDetailsObj.lock_keys[1].lock_id!
            LockWifiManager.shared.disenegageLock(disengageCode: customHeaders, completion: { (isSuccess, jsonResponse, error) in
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
//                if self.isDisEngageTapped {
//
//                }
                
                self.isConnectedViaWIFI = true
                if isSuccess == false {
                    Utilities.showErrorAlertView(message: "Failed to engage lock", presenter: self)
                } else {
                    /*
                    readBatteryLevel(userDetails: didDisengageLock, lockId: lockId)
                    readAccessLogs(userDetails: didDisengageLock, lockId: lockId) { (iSuccess, json, string) in
                     
                    }
*/
                    

                    
                    
                    LockWifiManager.shared.readBatteryLevel(userDetails: customHeaders, lockId: self.lockListDetailsObj.lock_keys[1].lock_id!, completion: { (isSuccess, result, error) in

                        if isSuccess {
                            self.batteryLevel.text = "\(result!) %"
                            self.updateBatteryPercentage(battery: result!)

                            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
                                if Connectivity().isConnectedToInternet(){
                                    LockWifiManager.shared.localCache.checkAndUpdateBatteryStatus(completion: { (status) in
                                        
                                    })
                                }
                            }
                        } else {
                            
                        }
                        
                    })
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.disconnectWifi(ssid: self.lockConnection.serialNumber)
                    }
//                    self.isDisEngageTapped = true
                    Utilities.showSuccessAlertView(message: ENGAGE_LOCK_SUCCESS_MESSAGE, presenter: self)
                }
            })
        } else {
            self.isConnectedViaWIFI = false
        }
    }
    
    func transferOwnerViaWifi(oldOwnerId: String, slotNumber: String) {
        debugPrint("WIFI ====>> transferOwnerViaWifi")
        debugPrint("WIFI ====>> \(oldOwnerId) --- \(slotNumber)")
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured) {
            LockWifiManager.shared.transferOwnership(disengageCode: authorizationKey, slotNumber: slotNumber , oldOwnerId: oldOwnerId, completion: { (isSuccess, jsonResponse, error) in
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.isConnectedViaWIFI = true
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        debugPrint("WIFI ====>> \(dictResponse)")
                        var newOwnerId = ""
                        if slotNumber == "01"{
                            newOwnerId = dictResponse!["owner-id-1"] as! String
                        }
                        else{
                            newOwnerId = dictResponse!["owner-id-0"] as! String
                        }

                        //  Our changes
                        var isSecuredModified=false
                        if self.lockListDetailsObj.is_secured=="1" {
                            isSecuredModified=true
                        }
                        let encryptedResponse0 = Utilities().convertStringToEncryptedString(plainString: dictResponse!["owner-id-0"] as! String, isSecured: isSecuredModified)
                        let encryptedResponse1 = Utilities().convertStringToEncryptedString(plainString: dictResponse!["owner-id-1"] as! String, isSecured: isSecuredModified)
                        if let lockKeysArray = self.lockListDetailsObj.lock_keys {
                            for lockKeys in lockKeysArray {
                                if let userType = lockKeys.user_type, userType.uppercased() == "OWNERID" {
                                    if encryptedResponse0 == lockKeys.key {
                                        newOwnerId = dictResponse!["owner-id-1"] as! String
                                    } else if encryptedResponse1 == lockKeys.key {
                                        newOwnerId = dictResponse!["owner-id-0"] as! String
                                    }
                                    break
                                }
                            }
                        }
                        
                        print("lockListDetailsObj ======> : \(self.lockListDetailsObj)");

                        if oldOwnerId != "" {
                            debugPrint("1st engage saved WIFI")
                            debugPrint("newOwnerId ====> \(newOwnerId)")
                            // Encrypt newOwner ID and save to local
                            // Encrypt newKey and then send to server
                            var isSecuredModified=false
                            if self.lockListDetailsObj.is_secured=="1" {
                                isSecuredModified=true
                            }
                            newOwnerId = Utilities().convertStringToEncryptedString(plainString: newOwnerId, isSecured: isSecuredModified)
                            LockWifiManager.shared.localCache.saveNewOwnerId(newOwnerId: newOwnerId, oldOwnerId: oldOwnerId,lockSerialNumber: self.lockConnection.serialNumber)
                        }
                    }
                    
                    var customHeaders = authorizationKey
                
                    var lockIDString = self.lockListDetailsObj.lock_keys[1].lock_id!
                    if lockIDString == "" {
                        lockIDString = self.lockListDetailsObj.serial_number
                    }
                    customHeaders["lockId"] = lockIDString

                    LockWifiManager.shared.readAccessLogs(userDetails: customHeaders, lockId: lockIDString, completion: { (success, result, error) in
                    })
                    
                    LockWifiManager.shared.readBatteryLevel(userDetails: customHeaders, lockId: lockIDString, completion: { (isSuccess, result, error) in
                    })

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.disconnectWifi(ssid: self.lockConnection.serialNumber)
                    }
                    Utilities.showSuccessAlertView(message: ENGAGE_LOCK_SUCCESS_MESSAGE, presenter: self)
                } else {
                    Utilities.showErrorAlertView(message: "Lock is disconnected. Please try again", presenter: self)
                }
            })
        }  else {
            self.isConnectedViaWIFI = false
        }
    }
    
    func disengageLockViaBLE(key: String, completion: @escaping (Bool) -> Void){

        var isDisEngageLock = true
        BLELockAccessManager.shared.disengageDelegate = self
        BLELockAccessManager.shared.connectWithLock(lockData:  lockConnection.selectedLock!, completion: { isSuccess in
            if isDisEngageLock {
                isDisEngageLock = false
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                if isSuccess {
                    BLELockAccessManager.shared.disEngageLock(key: key)
                    self.isConnectedVisBLE = true
                    
                } else {
                    self.isConnectedVisBLE = false
                    //                Utilities.showErrorAlertView(message: "Lock is not connected", presenter: self)
                }
                completion(isSuccess)
            }
        })
    }
    
    func transferOwnerUpdateViaBLE(slotNumber: String, key: String, completion: @escaping (Bool) -> Void) {
        
        var isTransferOwnerEngaged = true
        BLELockAccessManager.shared.disengageDelegate = self
        BLELockAccessManager.shared.connectWithLock(lockData:  lockConnection.selectedLock!, completion: {[unowned self] isSuccess in
            
            if isTransferOwnerEngaged {
                isTransferOwnerEngaged = false
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)

                if isSuccess {
                    BLELockAccessManager.shared.transferOwnership(slotNumber: slotNumber, key: key, oldOwnerId: self.lockListDetailsObj.lock_owner_id![0].id!)
                    self.isConnectedVisBLE = true
                    //BLELockAccessManager.shared.transferOwnership(slotNumber: "01", key: "9abcdef0abcdef01abcdef01abcdef01")
                } else {
                    self.isConnectedVisBLE = false
//                    Utilities.showErrorAlertView(message: "Lock is not connected", presenter: self)
                }
                completion(isSuccess)
            }
            completion(isSuccess)
        })
    }
    
    
    
    // MARK: - Previous Engage implementation
    func previousImplementation() {
        
        if lockConnection.isConnectedToLockWifi(ssidName: lockConnection.serialNumber) == false {
            if lockConnection.selectedLock == nil {
                
                lockConnection.selectedLock  = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockConnection.serialNumber)
            }
            guard   lockConnection.selectedLock  != nil else{
                if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                    BLELockAccessManager.shared.stopPeripheralScan()
                    Utilities.showErrorAlertView(message: TURN_ON_LOCK, presenter: self)
                    BLELockAccessManager.shared.prolongedScanForPeripherals()
                    
                }
                else{
                    Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
                }
                return
            }
        }
        
        
        let userObj = lockListDetailsObj.lock_keys![0] as UserLockRoleDetails
        //let userObj1 = lockListDetailsObj.lock_keys![1] as UserLockRoleDetails
        var key = ""
        if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
            key = _key
        }
        else {
            Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
            return
        }
        
        
        if userObj.status! == "2" || lockListDetailsObj.wasAddedOffline == true {
            // After transferring ownership first time disengage
            // communicate with hardware and reset previous ownerid
            // call revoke service call
            var slotNumber = userObj.slot_number
            if slotNumber == "1"{
                slotNumber = "01"
            }
            
            let oldOwnerId = lockListDetailsObj.lock_owner_id![0].id!
            if lockConnection.isConnectedToLockWifi(ssidName: lockConnection.serialNumber) {
                if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured) {
                    LockWifiManager.shared.transferOwnership(disengageCode: authorizationKey, slotNumber: slotNumber! , oldOwnerId: oldOwnerId, completion: { (isSuccess, jsonResponse, error) in
                        if isSuccess == true {
                            if let jsonDict = jsonResponse?.dictionary {
                                let dictResponse = jsonDict["response"]?.dictionaryObject!
                                var newOwnerId = ""
                                if slotNumber == "0"{
                                    newOwnerId = dictResponse!["owner-id-1"] as! String
                                }
                                else{
                                    newOwnerId = dictResponse!["owner-id-0"] as! String
                                }
                                print("1st engage saved ==> Prev implement")
                                LockWifiManager.shared.localCache.saveNewOwnerId(newOwnerId: newOwnerId, oldOwnerId: oldOwnerId,lockSerialNumber: self.lockConnection.serialNumber)
                            }
                        }
                        else {
                            Utilities.showErrorAlertView(message: "Lock is disconnected. Please try again", presenter: self)
                        }
                    })
                }
            }
            else {
                
                BLELockAccessManager.shared.disengageDelegate = self
                BLELockAccessManager.shared.connectWithLock(lockData:  lockConnection.selectedLock!, completion: {[unowned self] isSuccess in
                    if isSuccess {
                        BLELockAccessManager.shared.transferOwnership(slotNumber: slotNumber!, key: key, oldOwnerId: self.lockListDetailsObj.lock_owner_id![0].id!)
                        //BLELockAccessManager.shared.transferOwnership(slotNumber: "01", key: "9abcdef0abcdef01abcdef01abcdef01")
                    } else {
                        Utilities.showErrorAlertView(message: "Lock is not connected", presenter: self)
                    }
                })
            }
            
        } else {
            if lockConnection.isConnectedToLockWifi(ssidName: lockConnection.serialNumber) {
                if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
                    var customHeaders = authorizationKey
                    customHeaders["lockId"] = lockListDetailsObj.lock_keys[1].lock_id!
                    LockWifiManager.shared.disenegageLock(disengageCode: customHeaders, completion: { (isSuccess, jsonResponse, error) in
                        if isSuccess == false {
                            Utilities.showErrorAlertView(message: "Failed to engage lock", presenter: self)
                        }
                        else{
                            Utilities.showSuccessAlertView(message: ENGAGE_LOCK_SUCCESS_MESSAGE, presenter: self)
                            //BLELockAccessManager.shared.disconnectLock()
                        }
                    })
                }
            }
            else{
                BLELockAccessManager.shared.disengageDelegate = self
                BLELockAccessManager.shared.connectWithLock(lockData:  lockConnection.selectedLock!, completion: { isSuccess in
                    if isSuccess {
                        BLELockAccessManager.shared.disEngageLock(key: key)
                    } else {
                        Utilities.showErrorAlertView(message: "Lock is not connected", presenter: self)
                    }
                })
            }
        }
    }
    
    // MARK: - Factory reset Old code
    
    func factoryResetOldCode() {
        if lockConnection.isConnectedToLockWifi(ssidName: lockConnection.serialNumber) == false {
            if lockConnection.selectedLock == nil {
                
                lockConnection.selectedLock  = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockConnection.serialNumber)
            }
            guard   lockConnection.selectedLock  != nil else{
                if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                    BLELockAccessManager.shared.stopPeripheralScan()
                    Utilities.showErrorAlertView(message: TURN_ON_LOCK, presenter: self)
                    BLELockAccessManager.shared.prolongedScanForPeripherals()
                    
                }
                else{
                    Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
                }
                return
            }
        }
        
        var key = ""
        if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
            key = _key
        }
        else {
            Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
            return
        }
        
        if lockConnection.isConnectedToLockWifi(ssidName: lockConnection.serialNumber) {
            
            if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
                let customHeaders = authorizationKey
                LockWifiManager.shared.didFactoryReset(factoryReset: customHeaders, completion: { (isSuccess, jsonResponse, error) in
                    
                    if isSuccess == false {
                        Utilities.showErrorAlertView(message: "Failed to set factory reset", presenter: self)
                    } else {
                        Utilities.showSuccessAlertView(message: "Factory reset done successfully", presenter: self)
                        
                    }
                })
            }
        } else {
            BLELockAccessManager.shared.disengageDelegate = self
            BLELockAccessManager.shared.connectWithLock(lockData:  lockConnection.selectedLock!, completion: { isSuccess in
                if isSuccess {
                    BLELockAccessManager.shared.factoryReset(userKey: key)
                } else {
                    Utilities.showErrorAlertView(message: "Lock is not connected", presenter: self)
                }
            })
        }
    }
    
    // MARK: - Alert
    
    func showInternetConnectionValidationAlert() {
        let alert = UIAlertController(title: ALERT_TITLE, message: INTERNET_CONNECTION_VALIDATION, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Button Actions
    
    @objc func onTapEditButton() {
        
        if Connectivity().isConnectedToInternet() {
            //self.navigationItem.rightBarButtonItem = customDoneBtnItem
            var rightBarButtonItemsTemp:[UIBarButtonItem] = []
            if (self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue){
                let homeWiFiSettingsBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
                homeWiFiSettingsBtn.addTarget(self, action: #selector(self.onTapHomeWiFiSettingsButton), for: UIControl.Event.touchUpInside)
                if let image = UIImage(named: "settings_icon.png") {
                    homeWiFiSettingsBtn.setImage(image, for: .normal)
                }
                
                self.customSettingsBtnItem = UIBarButtonItem(customView: homeWiFiSettingsBtn)
                rightBarButtonItemsTemp.append(self.customSettingsBtnItem)
            }
            rightBarButtonItemsTemp.append(self.customDoneBtnItem)
            self.navigationItem.rightBarButtonItems = rightBarButtonItemsTemp
            
            self.nameDetailsView.isHidden = true
            self.textFieldView.isHidden = false
            lockNameTextField.becomeFirstResponder()
            
            self.lockNameTextField.text = self.lockListDetailsObj.lockname

        } else {
            showInternetConnectionValidationAlert()
        }
        
    }
    
    @objc func onTapDoneButton() {
        
        if lockNameTextField.text == "" {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            lockNameTextField.showInfo(LOCKNAME_MANDATORY_ERROR)
            return
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        lockNameTextField.resignFirstResponder()
        var editedLockObj = LockListModel(json: [:])
        var dbObj = CoreDataController()
        
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.usersLockList.rawValue) as? NSData {
            if let savedUser = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [LockListModel] {
                //                        user = savedUser
                //print("savedUser ==> \(savedUser)")
                //print("savedUser lock key dedtails ==> \(savedUser[0].lock_keys)")
                
                _ = savedUser.filter { $0.serial_number! == self.lockListDetailsObj.serial_number! }
                var objectIndex = Int()
                var lockListTempArray = savedUser
                if let i = lockListTempArray.index(where: { $0.serial_number! == self.lockListDetailsObj.serial_number! }) {
                    //print("Index ==> \(i)")
                    objectIndex = i
                }
                
                let listObject = lockListTempArray[objectIndex] as LockListModel
                listObject.lockname = self.lockNameTextField.text!
                editedLockObj = listObject
                
                lockListTempArray[objectIndex] = listObject
                
                // update in local
                
                let archivedObject = NSKeyedArchiver.archivedData(withRootObject: lockListTempArray)
                let defaults = UserDefaults.standard
                defaults.set(archivedObject, forKey: UserdefaultsKeys.usersLockList.rawValue)
                defaults.synchronize()
            }
        }
        
        // Update addLockList userdefaults
        
        var addLockObject = AddLockModel(json: [:])
        var addLockListArray = [AddLockModel]()
        var objArrayToBeupdated = [AddLockModel]()
        
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.addLockList.rawValue) as? NSData {
            if let addLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [AddLockModel] {
                //print("savedUser ==> \(addLockListArr)")
                
                if addLockListArr.count > 0 {
                    addLockListArray = addLockListArr
                    
                    objArrayToBeupdated = addLockListArr.filter { $0.lockListDetails.serial_number! == self.lockListDetailsObj.serial_number! }
                    
                    var objectIndex = Int()
                    
                    var addLockListTempArray = addLockListArr
                    
                    if let i = addLockListTempArray.index(where: { $0.lockListDetails.serial_number! == self.lockListDetailsObj.serial_number! }) {
                        //print("Index ==> \(i)")
                        objectIndex = i
                    }
                    
                    let listObject = addLockListTempArray[objectIndex] as AddLockModel
                    listObject.lockListDetails.lockname = self.lockNameTextField.text!
                    
                    //print("listObject.lockname ==> \(listObject.lockListDetails.lockname!)")
                    
                    addLockObject = listObject
                    addLockListTempArray[objectIndex] = listObject
                    
                    let archivedObject = NSKeyedArchiver.archivedData(withRootObject: addLockListTempArray)
                    let defaults = UserDefaults.standard
                    defaults.set(archivedObject, forKey: UserdefaultsKeys.addLockList.rawValue)
                    defaults.synchronize()
                    
                } else { // newly added locks updated to list, so addlocklist is empty ==> save edit locks in editlocknamelist
                }
            }
        }
        
//        if addLockListArray.count > 0 {
//        } else {
//            if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.editLockNameList.rawValue) as? NSData {
//                if let editLockNameListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [LockListModel] {
//                    _ = editLockNameListArr.filter { $0.serial_number! == self.lockListDetailsObj.serial_number! }
//                    var objectIndex = Int()
//                    var lockListTempArray = editLockNameListArr
//
//                    if lockListTempArray.count > 0 {
//                        if let i = lockListTempArray.index(where: { $0.serial_number! == self.lockListDetailsObj.serial_number! }) {
//                            // if already exists
//                            //print("Index ==> \(i)")
//                            objectIndex = i
//                            let listObject = lockListTempArray[objectIndex] as LockListModel
//                            listObject.lockname = self.lockNameTextField.text!
//                            editedLockObj = listObject
//
//                            lockListTempArray[objectIndex] = listObject
//
//                            let archivedObject = NSKeyedArchiver.archivedData(withRootObject: lockListTempArray)
//                            let defaults = UserDefaults.standard
//                            defaults.set(archivedObject, forKey: UserdefaultsKeys.editLockNameList.rawValue)
//                            defaults.synchronize()
//                        }
//                    } else {
//                        // add in
//                        if(editedLockObj.id != nil){
//                        var tempArr = [LockListModel]()
//                        tempArr.append(editedLockObj)
//                        let archivedObject = NSKeyedArchiver.archivedData(withRootObject: tempArr)
//                        let defaults = UserDefaults.standard
//                        defaults.set(archivedObject, forKey: UserdefaultsKeys.editLockNameList.rawValue)
//                        defaults.synchronize()
//                        }
//                    }
//                }
//
//            } else {
//                var tempArr = [LockListModel]()
//                tempArr.append(editedLockObj)
//
//                let archivedObject = NSKeyedArchiver.archivedData(withRootObject: tempArr)
//                let defaults = UserDefaults.standard
//                defaults.set(archivedObject, forKey: UserdefaultsKeys.editLockNameList.rawValue)
//                defaults.synchronize()
//            }
//        }
        
        if lockNameTextField.text != "" {
            if Connectivity().isConnectedToInternet() {
                if objArrayToBeupdated.count > 0 {
                    // add lock service
                    self.addOfflineLockDetailsServiceCall(addLockObj: addLockObject, editedObj: editedLockObj)
                    
                } else {
                    self.updateLockDetailsServiceCall()
                }
                
            } else {
                // Update UI
                self.navigationItem.rightBarButtonItem?.isEnabled = true
//                self.updateUIAfterEditLockName()
                
            }
        }
    }
    
    @objc func onTapHomeWiFiSettingsButton() {
        self.view.endEditing(true)
        if Connectivity().isConnectedToInternet() {
            let homeWifiConfigurationViewController = storyBoard.instantiateViewController(withIdentifier: "HomeWifiConfigurationViewController") as! HomeWifiConfigurationViewController
            homeWifiConfigurationViewController.userLockID = lockListDetailsObj.lock_keys[1].lock_id!
            homeWifiConfigurationViewController.scratchCode = self.lockListDetailsObj.scratch_code
            homeWifiConfigurationViewController.lockConnection.selectedLock =  lockConnection.selectedLock
            homeWifiConfigurationViewController.lockConnection.serialNumber = self.lockConnection.serialNumber
            homeWifiConfigurationViewController.lockListDetailsObj = self.lockListDetailsObj
            self.navigationController?.pushViewController(homeWifiConfigurationViewController, animated: true)
        } else {
            showInternetConnectionValidationAlert()
        }
        
    }
    
    func updateUIAfterEditLockName() {
        self.lockListDetailsObj.lockname = self.lockNameTextField.text!
        self.lockNameLabel.text = self.lockNameTextField.text! // self.lockListDetailsObj.lockname
        //self.navigationItem.rightBarButtonItem = self.customEditBtnItem
        var rightBarButtonItemsTemp:[UIBarButtonItem] = []
        if (self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue){
            let homeWiFiSettingsBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
            homeWiFiSettingsBtn.addTarget(self, action: #selector(self.onTapHomeWiFiSettingsButton), for: UIControl.Event.touchUpInside)
            if let image = UIImage(named: "settings_icon.png") {
                homeWiFiSettingsBtn.setImage(image, for: .normal)
            }
            
            self.customSettingsBtnItem = UIBarButtonItem(customView: homeWiFiSettingsBtn)
            rightBarButtonItemsTemp.append(self.customSettingsBtnItem)
        }
        rightBarButtonItemsTemp.append(self.customEditBtnItem)
        self.navigationItem.rightBarButtonItems = rightBarButtonItemsTemp
        
        self.nameDetailsView.isHidden = false
        self.textFieldView.isHidden = true
    }
    
    @IBAction func onTapUsersButton(_ sender: UIButton) {
        
        if Connectivity().isConnectedToInternet() {
            let assignUsersViewController = storyBoard.instantiateViewController(withIdentifier: "AssignUsersViewController") as! AssignUsersViewController
            assignUsersViewController.lockConnection.serialNumber = self.lockConnection.serialNumber
            assignUsersViewController.userLockID = lockListDetailsObj.lock_keys[1].lock_id!
            assignUsersViewController.lockConnection.selectedLock =  lockConnection.selectedLock
            assignUsersViewController.scratchCode = self.lockListDetailsObj.scratch_code
            assignUsersViewController.userRole = self.lockListDetailsObj.lock_keys[1].user_type!
            assignUsersViewController.lockListDetailsObj = self.lockListDetailsObj
            self.navigationController?.pushViewController(assignUsersViewController, animated: true)
        } else {
            showInternetConnectionValidationAlert()
        }
    }
    
    @IBAction func onTapHistoryButton(_ sender: UIButton) {
        
        // Disconnect or forgot WIFI sample
//        if #available(iOS 11.0, *) {
//            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: "ASTRIX_0000000000003003")
//        } else {
//            // Fallback on earlier versions
//        }

        if Connectivity().isConnectedToInternet() {
//            LockWifiManager.shared.localCache.updateOfflineItems()
//            LockWifiManager.shared.localCache.checkAndUpdateLogs { (status) in
//            }

            let lockHistoryViewController = storyBoard.instantiateViewController(withIdentifier: "LockHistoryViewController") as! LockHistoryViewController
            lockHistoryViewController.lockId = lockListDetailsObj.lock_keys[1].lock_id!
            self.navigationController?.pushViewController(lockHistoryViewController, animated: true)
            
        } else {
            showInternetConnectionValidationAlert()
        }
    }
    
    @IBAction func onTapRFIDButton(_ sender: UIButton) {
        
        if Connectivity().isConnectedToInternet() {
//            LockWifiManager.shared.localCache.updateOfflineItems()

            // Navigate to RFID list
            let rfidListViewController = storyBoard.instantiateViewController(withIdentifier: "RFIDListViewController") as! RFIDListViewController
            rfidListViewController.userLockID = lockListDetailsObj.lock_keys[1].lock_id!
            rfidListViewController.lockConnection.selectedLock =  lockConnection.selectedLock
            rfidListViewController.scratchCode = self.lockListDetailsObj.scratch_code
            rfidListViewController.lockConnection.serialNumber = self.lockConnection.serialNumber
            rfidListViewController.lockListDetailsObj = self.lockListDetailsObj
            
            self.navigationController?.pushViewController(rfidListViewController, animated: true)
        } else {
            showInternetConnectionValidationAlert()
        }
    }
    
    @IBAction func onTapFingerPrintButton(_ sender: UIButton) {
        
        if Connectivity().isConnectedToInternet() {
//            LockWifiManager.shared.localCache.updateOfflineItems()
            
            // Navigate to FP list
            let fpListViewController = storyBoard.instantiateViewController(withIdentifier: "FPListViewController") as! FPListViewController
            fpListViewController.userLockID = lockListDetailsObj.lock_keys[1].lock_id!
            fpListViewController.lockConnection.selectedLock =  lockConnection.selectedLock
            fpListViewController.scratchCode = self.lockListDetailsObj.scratch_code
            fpListViewController.lockConnection.serialNumber = self.lockConnection.serialNumber
            fpListViewController.lockListDetailsObj = self.lockListDetailsObj
            
            self.navigationController?.pushViewController(fpListViewController, animated: true)
            
        } else {
            showInternetConnectionValidationAlert()
        }
    }
    
    @IBAction func onTapTransferButton(_ sender: UIButton) {
        if Connectivity().isConnectedToInternet() {
            LockWifiManager.shared.localCache.updateOfflineItems()
            self.navigationItem.rightBarButtonItem = self.customEditBtnItem
            self.nameDetailsView.isHidden = false
            self.textFieldView.isHidden = true
            let transferOwnerViewController = storyBoard.instantiateViewController(withIdentifier: "TransferOwnerViewController") as! TransferOwnerViewController
            transferOwnerViewController.transferKeyId = lockListDetailsObj.lock_owner_id![0].id!
            transferOwnerViewController.isAddScreen = true
            transferOwnerViewController.userLockID = lockListDetailsObj.lock_keys[1].lock_id!
            self.navigationController?.pushViewController(transferOwnerViewController, animated: true)
        } else {
            showInternetConnectionValidationAlert()
        }
    }
    
    
    // MARK: - Remove Added lock in userdefaults
    
    func updateAddLockList(addLockObj: AddLockModel) {
        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.addLockList.rawValue) as? NSData {
            if let addLockListArr = NSKeyedUnarchiver.unarchiveObject(with: decodedNSData as Data) as? [AddLockModel] {
                //                        user = savedUser
                //print("savedUser ==> \(addLockListArr)")
                // check for serial_number
                
                let tmpArray = addLockListArr.filter { $0.lockListDetails.serial_number! == addLockObj.lockListDetails.serial_number! }
                
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
    
    // MARK: - TextField Delegate Methods
    
    @IBAction func lockNameTextFieldDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.lockNameTextField.hideInfo()
    }
    
    @IBAction func lockNameTextFieldDidEndEditing(_ sender: TweeAttributedTextField) {
        if sender.text != "" {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            return
        }
        
        if sender.text == "" {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            sender.showInfo(LOCKNAME_MANDATORY_ERROR)
        } else {
            return
        }
    }
    
    @IBAction func factoryResetTapped(_ sender: UIButton){}
    
    // MARK: - Service Call
    
    func addOfflineLockDetailsServiceCall(addLockObj: AddLockModel, editedObj: LockListModel) {
        
        let urlString = ServiceUrl.BASE_URL + "locks/addlock"
        
        let userDetails = [
            "name": addLockObj.lockListDetails.lockname! as AnyObject,
            "uuid": addLockObj.lockListDetails.uuid! as AnyObject, // BLE address ==> check rssi ?
            "ssid": "Payoda WIfi" as AnyObject, // WIFI
            "serial_number": addLockObj.lockListDetails.serial_number! as AnyObject, // BLE serial number
            "scratch_code": addLockObj.lockListDetails.scratch_code! as AnyObject, //
            "status": addLockObj.lockListDetails.status! as AnyObject,
            "lock_keys": addLockObj.lock_keys,
            "lock_ids": addLockObj.lock_ids,
            "is_secured":"1",
            "lock_version": addLockObj.lockListDetails.lockVersion
            ] as [String: AnyObject]
        
        print("LockDetailsViewController ====>>  addOfflineLockDetailsServiceCall =======>> lock_version ====> \(addLockObj.lockListDetails.lockVersion)")

        LockDetailsViewModel().addLockDetailsServiceViewModel(url: urlString, userDetails: userDetails ) { result, _ in
            
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            if result != nil {
                self.updateAddLockList(addLockObj: addLockObj)
                self.removeEditLockNameObj(editLockObj: editedObj)
                self.updateUIAfterEditLockName()
            } else {
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
    
    func updateLockDetailsServiceCall() {
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "locks/updatelock?id=\(self.lockListDetailsObj.id!)"
        
        let userDetails = [
            "name": self.lockNameTextField.text!,
            ]
        
        LockDetailsViewModel().updateLockDetailsServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
            
                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            if result != nil {
                let localDB = CoreDataController()
                localDB.updateLockList(id: self.lockListDetailsObj.id, updateKey: "lockname", updateValue: self.lockNameTextField.text!)

                self.updateUIAfterEditLockName()
                Utilities.showSuccessAlertView(message: "Lock name updated successfully", presenter: self)
                
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

    //key - new owner id, keyid = lock_owner_id's id
    func revokeRequestUserServiceCall(key: String, keyId: String) {
        print("update key ==>> revokeRequestUserServiceCall")
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
            //print("loading hide view == > revoke user() ")

            
            if result != nil {
                DispatchQueue.main.async {
                    self.buttonStackView.isHidden = false
                    self.hideFirstTimeOwnerUI()
                }
                
                
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
    
    // MARK: - UITextField Delegate
    
    /*
     func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
     if string.rangeOfCharacter(from: NSCharacterSet.letters) != nil {
     return true
     } else {
     return false
     }
     }
     */
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.lockNameTextField {
            if (string.rangeOfCharacter(from: NSCharacterSet.letters) != nil || string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil) ||  (string.rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil) && (textField.text?.count)! < 50    {
                if range.location == 0 && string.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil {
                    return false
                }
                return true
            } else if string == "" {
                //print("Backspace pressed")
                return true
                
            } else {
                return false
            }
        }
        return true
    }
}
extension LockDetailsViewController: BLELockAccessDisengageProtocol{
    func didReadAccessLogs(logs: String) {
        
        //print("didReadAccessLogs ==> ")
        
        //print(logs)
        
        //print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        
        //print("self.lockListDetailsObj.lock_keys[1].lock_id! ==> \(self.lockListDetailsObj.lock_keys[1].lock_id!)")
        var isSerialNumber = Bool()
        var lockID = self.lockListDetailsObj.lock_keys[1].lock_id!
        
        if lockID == "" {
            isSerialNumber = true
            lockID = self.lockListDetailsObj.serial_number
        }
        
        print("lockID =============@@@@@@@@@@@@@@@ ===> \(lockID)")
        
        LockWifiManager.shared.localCache.appendLogsFor(lockId: lockID, log: logs)
        if Connectivity().isConnectedToInternet() {
            
            LockWifiManager.shared.localCache.updateOfflineItems()
            
//            self.getLockListServiceCall(completion: { (result, success) in
//                if (result?.count)! > 0 {
//
//                    let locklistArray = result as! [LockListModel]
//                    let logsDict = LockWifiManager.shared.localCache.logsToBeUpdated()
//                    let lockIds = logsDict.keys
//
//
//                    for lockListObj in locklistArray {
//                        let lockID = lockListObj.lock_keys[1].lock_id!
//                        let lockSerialNumber = lockListObj.serial_number!
//                        if lockIds.contains(lockID) {
//
//                            LockWifiManager.shared.localCache.checkAndUpdateLogsWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: false, completion: { (status) in
//
//                            })
//
//                        } else if lockIds.contains(lockSerialNumber) {
//
//                            LockWifiManager.shared.localCache.checkAndUpdateLogsWithLockID(lockID: lockID, lockSerialNumber: lockSerialNumber, isSerialNumber: true, completion: { (status) in
//                            })
//                        }
//                    }
//                } else {
//
//                }
//            })
            
//            LockWifiManager.shared.localCache.checkAndUpdateLogs { (status) in
//            }
        }
    }
    
    func didCompleteOwnerTransfer(isSuccess: Bool, newOwnerId: String, oldOwnerId: String, error: String) {
        
        //print("======   didCompleteOwnerTransfer =======")
        //print(isSuccess)
        //print(newOwnerId)
        //print(oldOwnerId)
        //print(error)
        //print("=======   didCompleteOwnerTransfer ======")
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

        if isSuccess == false {
            Utilities.showErrorAlertView(message: error, presenter: self)
        }
        else{
            Utilities.showSuccessAlertView(message: ENGAGE_LOCK_SUCCESS_MESSAGE, presenter: self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                // your code here
                BLELockAccessManager.shared.disconnectLock()
            }
            
            // Encrpt new oenwer id
            var isSecuredModified=false
            if self.lockListDetailsObj.is_secured=="1" {
                isSecuredModified=true
            }
            let encryptedNewOwnerID = Utilities().convertStringToEncryptedString(plainString: newOwnerId, isSecured: isSecuredModified)
            
            if Connectivity().isConnectedToInternet() {
                self.revokeRequestUserServiceCall(key: encryptedNewOwnerID, keyId: oldOwnerId)

            } else {
                if oldOwnerId != "" {
                    print("1st engage saved BLE")
                    LockWifiManager.shared.localCache.saveNewOwnerId(newOwnerId: newOwnerId, oldOwnerId: oldOwnerId,lockSerialNumber: self.lockConnection.serialNumber)
                }
            }
        }
    }
    func didDisengageLock(isSuccess: Bool, error: String) {
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        
        //print("loading hide view == > disengage lock call back() ")
        if isSuccess == false {
            Utilities.showErrorAlertView(message: error, presenter: self)
        } else{
            Utilities.showSuccessAlertView(message: ENGAGE_LOCK_SUCCESS_MESSAGE, presenter: self)
            //BLELockAccessManager.shared.disconnectLock()
        }
        // Handling worst case scenario
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // your code here
            BLELockAccessManager.shared.disconnectLock()
        }
    }
    func didCompleteFactoryReset(isSuccess: Bool, error: String) {
    }
    func didFailedToConnect(error: String){
        //print("didFailedToConnect ==> ")
    }
    func didFinishReadingAllCharacteristics(){
        
    }
    func didPeripheralDisconnect(){
        
        //print("didFailedToConnect ==> ")
        if isConnectedVisBLE {
            Utilities.showErrorAlertView(message: "Lock disconnected", presenter: self)

            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            return
        } else {
            
        }
        
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
    }
    
    func didFailAuthorization() {
        //BLELockAccessManager.shared.disEngageLock(key: self.userKey!)

        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

        //print("didFailAuthorization ==> ")
        self.isConnectedVisBLE = false
        Utilities.showErrorAlertView(message: "Unable to connect the lock. Your access may be revoked. Please contact support team.", presenter: self)
    }
    
    func didReadBatteryLevel(batteryPercentage:String){
        
        //print("batteryPercentage => ")
        //print(batteryPercentage)
        //print("=================")
        
        updateBatteryPercentage(battery: batteryPercentage)
        
        if Connectivity().isConnectedToInternet() {
            DataStoreManager().postBatteryUpdate(batteryId: self.lockListDetailsObj.lock_keys[1].lock_id!, batteryLevel: batteryPercentage, callback: { (json,error) in
                if error != nil {
                    //print("error in posting battery response")
                }
                else{
                    //print("posting battery response")
                }
            })
        } else {
            
            var lockID = self.lockListDetailsObj.lock_keys[1].lock_id!
            if lockID == "" {
                lockID = self.lockListDetailsObj.serial_number
            }
            LockWifiManager.shared.localCache.updateBattery(lockId: lockID, batteryLevel: batteryPercentage)
        }
    }
    
    func didCompleteDisengageFlow() {
        //print("disconnted in flow")
        BLELockAccessManager.shared.disconnectLock()
    }
}
extension LockDetailsViewController{
    func updateBatteryPercentage(battery:String) {
        if battery == "null"{
            //print("*** battery printing null")
            return
        }
        self.lockListDetailsObj.battery = battery
        DispatchQueue.main.async{[unowned self] in
            var _batteryInInteger = Int(battery)
            if let batteryInInteger = _batteryInInteger{
                if batteryInInteger < 30  && batteryInInteger > 9{
                    self.batteryImageView.image = UIImage(named: "battery_half")
                }
                else if batteryInInteger < 10 {
                    self.batteryImageView.image = UIImage(named: "battery_less")
                }
                else{
                    self.batteryImageView.image = UIImage(named: "battery_full")
                }
            }
            
            if _batteryInInteger! > 100 {
                _batteryInInteger! = 100
            }
            
            self.batteryLevel.text = "\(_batteryInInteger!) %"
        }
    }
}

extension LockDetailsViewController: BLELockScanControllerProtocol{
    func didEndScan() {
        //print("didEndScan ==> ==> ")

        if !isConnectedViaWIFI {
            if availableListOfLock.count > 0 {
                
            } else {
                Utilities.showErrorAlertView(message: UNABLE_TO_CONNECT_LOCK, presenter: self)
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            }
        }
    }
    
    func didDiscoverNewLock(devices: [BluetoothAdvertismentData]) {
        //print("didDiscoverNewLock ==>")
        //print(devices)
        availableListOfLock = devices
        
        if devices.count > 0 {
            
            let advertisementData = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockListDetailsObj.serial_number)
            self.lockConnection.selectedLock = advertisementData
            self.lockConnection.serialNumber = self.lockListDetailsObj.serial_number
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
            let userObj = lockListDetailsObj.lock_keys![0] as UserLockRoleDetails
            if userObj.status! == "2" || lockListDetailsObj.wasAddedOffline == true {
                // After transferring ownership first time disengage
                // communicate with hardware and reset previous ownerid
                // call revoke service call
                var slotNumber = userObj.slot_number
                if slotNumber == "1"{
                    slotNumber = "01"
                }
                
                //print("userObj.status! == 2 @@@@@@@@@@@@@@@@ ==> lock already exist")
                print("didDiscoverNewLock called")
                self.transferOwnerUpdateViaBLE(slotNumber: slotNumber!, key: key) { (status) in
                    print("didDiscoverNewLock success ==> \(status)")
                }
            } else {
                if lockConnection.selectedLock != nil {
                    self.disengageLockViaBLE(key: key) { (status) in
                        
                    }
                }
            }
        }
    }
    
    func initializeScan(){
        let scanController = BLELockAccessManager.shared.scanController
        scanController.scanDelegate = self
        scanController.prolongedScanForPeripherals()//scanForPeripherals()
//        availableListOfLock.append(contentsOf: scanController.scannedDevicesList)
        
//        //print(availableListOfLock)
    }
    
}

extension LockDetailsViewController {
    func forTesting() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.initializeScan()
        }
    }
}


extension LockDetailsViewController{
    @IBAction func onTapPinButton(_ sender: UIButton) {
        

        if Connectivity().isConnectedToInternet() {
            LockWifiManager.shared.localCache.updateOfflineItems()
            let PinMainViewController = storyBoard.instantiateViewController(withIdentifier: "PinMainViewController") as! PinMainViewController
            PinMainViewController.userLockID = lockListDetailsObj.lock_keys[1].lock_id!
            PinMainViewController.scratchCode = self.lockListDetailsObj.scratch_code
            PinMainViewController.lockConnection.selectedLock =  lockConnection.selectedLock
            PinMainViewController.lockConnection.serialNumber = self.lockConnection.serialNumber
            PinMainViewController.lockListDetailsObj = self.lockListDetailsObj
            self.navigationController?.pushViewController(PinMainViewController, animated: true)
            
        } else {
            showInternetConnectionValidationAlert()
        }
    }
    
}
