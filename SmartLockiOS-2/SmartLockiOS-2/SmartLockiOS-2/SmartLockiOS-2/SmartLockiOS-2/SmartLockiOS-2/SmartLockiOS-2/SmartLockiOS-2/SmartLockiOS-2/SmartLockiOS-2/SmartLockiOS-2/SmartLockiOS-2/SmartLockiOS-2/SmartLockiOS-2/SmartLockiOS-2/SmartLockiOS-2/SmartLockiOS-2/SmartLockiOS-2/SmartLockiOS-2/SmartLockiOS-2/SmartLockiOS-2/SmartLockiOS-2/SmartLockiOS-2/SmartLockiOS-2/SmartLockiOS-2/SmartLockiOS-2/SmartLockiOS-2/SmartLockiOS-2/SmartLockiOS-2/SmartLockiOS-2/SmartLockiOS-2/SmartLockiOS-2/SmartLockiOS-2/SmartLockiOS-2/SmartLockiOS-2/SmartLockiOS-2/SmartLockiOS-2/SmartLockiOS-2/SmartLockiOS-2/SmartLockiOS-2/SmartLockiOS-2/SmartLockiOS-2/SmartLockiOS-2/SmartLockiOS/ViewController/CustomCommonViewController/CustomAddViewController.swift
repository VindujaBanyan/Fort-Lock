//
//  CustomAddViewController.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/6/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit
import NetworkExtension

class CustomAddViewController: UIViewController {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var pressButton: UIButton!
    
    var isFromRFIDScreen = Bool()
    var isFromFingerPrintScreen = Bool()
    var isConnectedViaWIFI = Bool()
    var fingerPrintSuccessCount: Int = 0
    var isAlreadyFingerPrintAssigned = Bool()
    var guestUserName = String()
    var lockId = String()
    var userID = String()
    var assignedkeys = String()
    var fingerPrintID = String()
    
    var rfidSuccessCount: Int = 0
    var selectedRFID = String()
    var scratchCode = String()
    var lockConnection:LockConnection = LockConnection()
    var lockListDetailsObj = LockListModel(json: [:])
    
    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        initialize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Initialize Method
    func initialize() {
        addBackBarButton()
        updateMainViewUI()
        
        var pressButtonImage = ""
        
        if isFromRFIDScreen {
            updateOtherUI(titleString: "Add RFID", instructionString: ADD_RFID_INSTRUCTION)
            pressButtonImage = "managerfid"
        }
        
        if isFromFingerPrintScreen {
            updateOtherUI(titleString: "Add Finger Print", instructionString: ADD_FP_INSTRUCTION)
            pressButtonImage = "manageFP"
        }
        
        pressButton.setImage(UIImage(named: pressButtonImage), for: .normal)
    }
    
    func updateOtherUI(titleString: String, instructionString: String) {
        title = titleString
        instructionLabel.text = instructionString
    }
    
    func updateMainViewUI() {
        
        mainView.layer.cornerRadius = 15
        mainView.clipsToBounds = true
        mainView.layer.shadowColor = UIColor.gray.cgColor
        mainView.layer.shadowOpacity = 1
        mainView.layer.shadowOffset = CGSize(width: 3, height: 3)
        mainView.layer.shadowRadius = 10
        mainView.layer.shadowPath = UIBezierPath(rect: mainView.bounds).cgPath
        mainView.layer.shouldRasterize = true
        mainView.layer.masksToBounds = false
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
    
    // MARK: - IBActions
    
    @objc func popToViewController() {
        self.navigationController!.popViewController(animated: false)
    }
    
    @objc func popToLockDetailViewController() {
        for controller in self.navigationController!.viewControllers as Array {
            if controller.isKind(of: LockDetailsViewController.self) {
                _ =  self.navigationController!.popToViewController(controller, animated: true)
                break
            }
        }
    }
    
    @objc func popToFPListViewController() {
        for controller in self.navigationController!.viewControllers as Array {
            if controller.isKind(of: FPListViewController.self) {
                _ =  self.navigationController!.popToViewController(controller, animated: true)
                break
            }
        }
    }
    
    @objc func popToRFIDListViewController() {
        for controller in self.navigationController!.viewControllers as Array {
            if controller.isKind(of: RFIDListViewController.self) {
                _ =  self.navigationController!.popToViewController(controller, animated: true)
                break
            }
        }
    }
    
    @IBAction func onTapPressButton(_ sender: Any) {
        
        if isFromRFIDScreen {
            addRFID()
        }
        
        if isFromFingerPrintScreen {
            addFingerPrint()
        }
    }
    
    
    // MARK: - NAvigation methods
    
    func navigateToSuccessScreen() {
        let successViewController = storyBoard.instantiateViewController(withIdentifier: "CommonSuccessViewController") as! CommonSuccessViewController
        successViewController.isFromRFIDScreen = self.isFromRFIDScreen
        successViewController.isFromFingerPrintScreen = self.isFromFingerPrintScreen
        self.navigationController?.pushViewController(successViewController, animated: true)
    }
    
    // MARK: - Alert methods
    
    func showAlertWithNextButton(with message: String) {
        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "NEXT", style: .default, handler: { _ in
            if self.isFromRFIDScreen {
                self.addRFIDViaWIFI()
            }
            if self.isFromFingerPrintScreen {
                self.addFingerPrintViaWIFI()
            }
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showSuccessAlert(with message: String) {
        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            
            self.popToLockDetailViewController()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showSuccessAlertNavigation(with message: String) {
        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            
            self.navigateToSuccessScreen()
        }))
        self.present(alert, animated: true, completion: nil)
    }
        
    func showFailureAlert(with message: String) {
        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            
            if self.isFromRFIDScreen {
                self.popToRFIDListViewController()
            }
            if self.isFromFingerPrintScreen {
                self.popToFPListViewController() // ==> need to chenage
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - Add RFID

extension CustomAddViewController {
    func addRFID() {
        let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            self.addRFIDWithWIFI()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func addRFIDWithWIFI() {
                    
            // For testing
//            self.addRFIDViaWIFI()
            
            if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                self.addRFIDViaWIFI()
            } else {
                self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode)
            }
        }
    
    func addRFIDViaWIFI() {
        // Hardware add RFID
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            let parameters = authorizationKey
            
            //            Payload {"owner-id":"12345678","slot-key":"ABCDEF01ABCDEF01ABCDEF01"}
            LockWifiManager.shared.enrollRFID(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        let updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        print("-----------------------")
                        print(updatedKey)
                        
                        let tempStr: LockWifiRFIDMessages = LockWifiRFIDMessages(rawValue: updatedKey) ?? .EMPTY
                        
                        switch tempStr {
                        case .RF_NO_DETECT_OR_MATCH: //(Alert dialog Next button will show)
                            self.showAlertWithNextButton(with: RF_NO_DETECT_OR_MATCH)
                            break
                        case .RF_NO_FREE_SLOTS:
                            self.showSuccessAlert(with: RF_NO_FREE_SLOTS)
                            break
                        case .RF_ALREADY_EXISTS:
                            self.showSuccessAlert(with: RF_ALREADY_EXISTS)
                            break
                        case .RF_MAX_TRIES_EXIT:
                            self.showSuccessAlert(with: RF_MAX_TRIES_EXIT)
                            break
                        case .OK: // (Place 2nd or 3rd time Status Code : 200) // (Alert dialog Next button will show)
                            
                            self.rfidSuccessCount = self.rfidSuccessCount + 1
                            
                            if self.rfidSuccessCount == 1 {
                                self.showAlertWithNextButton(with: RF_NEXT2)
                            } else if self.rfidSuccessCount == 2 {
                                self.showAlertWithNextButton(with: RF_NEXT3)
                            } else {
                                
                            }
                            
                            break
                        case .RF_FOB_ENROLLED:
                            
                            // Save offline
                            // show alert n navigate to lock detail screen
                            
                            let rfid = dictResponse?["rf-id"] as! String
                            
                            self.saveUpdayeRFIDOffline(with: rfid)
                            
                            self.showSuccessAlertNavigation(with: RF_FOB_ENROLLED)
                            
                            break
                        default:
                            break
                        }
                    }
                } else {
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add RFID.", presenter: self)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add RFID.", presenter: self)
        }
        
        
    }
    
    
}

// MARK: - Add finger print
extension CustomAddViewController {
    func addFingerPrint() {
        let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            print("Loading.....")
            self.addFingerPrintWithWIFI()
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func addFingerPrintWithWIFI() {
                
        // For testing
//        self.addFingerPrintViaWIFI()
        
        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
            self.addFingerPrintViaWIFI()
        } else {
            self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode)
        }
    }
    
    func addFingerPrintViaWIFI() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = authorizationKey
            // hack to ensure right slot number is passed
            
//            Payload {"owner-id":"12345678","slot-key":"ABCDEF01ABCDEF01ABCDEF01"}
            
            LockWifiManager.shared.enrollFingerPrint(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        var updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        print("------------updatedKey-----------")
                        print(updatedKey)
//                        FP_NOT_PLACED
                        
//                        updatedKey == "INSUF_AUTHORIZATION"
                        
                        updatedKey = (updatedKey == "" || updatedKey == "none") ? "FP_NOT_PLACED" : updatedKey
                        
                        let tempStr: LockWifiFPMessages = LockWifiFPMessages(rawValue: updatedKey) ?? .EMPTY
                        
                        switch tempStr {
                        case .FP_NEXT_SAMPLE: // Next
                            // success count increment
                            print(".FP_NEXT_SAMPLE")
                            print("self.fingerPrintSuccessCount ==> \(self.fingerPrintSuccessCount)")
                            self.fingerPrintSuccessCount = self.fingerPrintSuccessCount + 1
                            
                            if self.fingerPrintSuccessCount == 3 {
                                // Save offline
                                // success -> navigate to lock list
                                self.fingerPrintSuccessCount = 0
                                self.showSuccessAlert(with: FP_UID_ENROLLED)
                            } else {
                                print("self.fingerPrintSuccessCount ==> \(self.fingerPrintSuccessCount)")
                                let message = self.fingerPrintSuccessCount == 1 ? FP_NEXT_SAMPLE2 : FP_NEXT_SAMPLE3
                                self.showAlertWithNextButton(with: message)
                            }
                            break
                        case .FP_NOT_PLACED: // Next
                            self.showAlertWithNextButton(with: FP_NOT_PLACED)
                            break
                        case .FP_MAX_TRIES_EXIT:
                            // failure case --> navigate to fp list screen
                            self.fingerPrintSuccessCount = 0
                            self.showSuccessAlert(with: FP_MAX_TRIES_EXIT)
                            break
                        case .FP_TRY_OTHER_FINGER: // Next
                            self.showAlertWithNextButton(with: FP_TRY_OTHER_FINGER)
                            break
                        case .FP_MAX_USR:
                            self.fingerPrintSuccessCount = 0
                            self.showSuccessAlert(with: FP_MAX_USR)
                            break
                        case .FP_BAD_FINGER:
                            self.showAlertWithNextButton(with: FP_BAD_FINGER)
                            break
                        case .FP_UID_ENROLLED:
                            // Save offline
                            // success -> navigate to lock list
                            
                            let fpID = dictResponse?["fp-id"] as! String
                            
                            // Enroll for first time
                            
                            //                            "[\"10\"]"
                            //                            "key" : "[\"04\", \"06\"]",
                            //                                    "[\"10\", \"03\"]"
                            //                            "[\"10\", \"03\"]"
                            var actualSlotNumber = fpID
                            
                            //                            "["04", "06", "
                            
                            if self.isAlreadyFingerPrintAssigned {
                                
                                let keyArray = Utilities().convertKeyStringToKeyArray(with: self.assignedkeys)
                                let keyString = Utilities().convertKeyArrayToString(with: keyArray)
                                
                                if actualSlotNumber.count == 1 {
                                    actualSlotNumber = keyString + "\"" + "0\(actualSlotNumber)" + "\"]"
                                } else {
                                    actualSlotNumber = keyString + "\"" + fpID + "\"]"
                                }
                                
                            } else {
                                
                                if actualSlotNumber.count == 1 {
                                    actualSlotNumber = "[\"" + "0\(actualSlotNumber)" + "\"]"
                                } else {
                                    actualSlotNumber = "[\"" + fpID + "\"]"
                                }
                            }
                            
                            self.saveAddFingerPrintOffline(with: actualSlotNumber)
                            
                            self.fingerPrintSuccessCount = 0
                            self.showSuccessAlertNavigation(with: FP_UID_ENROLLED)
                            break
                            //                        case .FP_USER_ID_NOT_EXISTS: // for revoke finger print
                            //                            break
                            
                        case .FP_NOT_CONNECTED: // for revoke finger print failure
                            
                            LoaderView.sharedInstance.hideShadowView(selfObject: self)
                            self.showSuccessAlert(with: FP_NOT_CONNECTED)

                        case .FP_ID_ALREADY_EMPTY: // for revoke finger print failure
                            
                            LoaderView.sharedInstance.hideShadowView(selfObject: self)
                            self.showSuccessAlert(with: FP_ID_ALREADY_EMPTY)
                            break
                        case .AUTHVIA_FP_DISABLED:
                            Utilities.showSuccessAlertView(message: FP_MANAGE_PRIVILEGE_FAILED, presenter: self)
                            break
                        case .EMPTY:
                            break
                        default:
                            break
                        }
                    }
                } else {
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add fingerprint.", presenter: self)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add fingerprint.", presenter: self)
        }
    }
}

// MARK: - Offline Handling

extension CustomAddViewController {
    
    func saveAddFingerPrintOffline(with key: String) {
                
        if isAlreadyFingerPrintAssigned {
            
            let userDetailsDict = [
                "user_id": "",
                "key": key,
                "status": "2"
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
            LockWifiManager.shared.localCache.saveUpdateFPKey(with: userDetails, keyID: fingerPrintID)
            
        } else {
            
            // For First time finger print enroll - Both Existing user and Guest user
            var userDetailsDict = [
                "name": self.guestUserName,
                "key": key,
                "lock_id": self.lockId
            ]
            if userID != "" {
                userDetailsDict["user_id"] = userID
            }
            
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
            
            LockWifiManager.shared.localCache.saveAddFPKey(with: userDetails)
        }
    }
    
    func saveUpdayeRFIDOffline(with key: String) {
        
        let userDetailsDict = [
            "user_id": "",
            "key": key,
            "status": "2" // for update rfid
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
        LockWifiManager.shared.localCache.saveUpdateRFIDKey(with: userDetails, keyID: self.selectedRFID)
    }
}

// MARK: - Wifi Settings

extension CustomAddViewController {
    
    func configureWifiConnection(ssid: String, password: String) {
        //print("configureWifiConnection ==> ")
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        print("=======> newSSID ==> \(newSSID)")
        print("=======> password ==> \(password)")
//        Utilities.showErrorAlertView(message: "Called", presenter: self)
        
        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            let config = NEHotspotConfiguration(ssid: newSSID, passphrase: password, isWEP: false)
            config.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(config) { (error) in
                //print("NEHotspotConfigurationManager.shared.apply =========")
                if let error = error {
                    self.isConnectedViaWIFI = false
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
//                    Utilities.showErrorAlertView(message: "Unable to connect the lock. Please try again.", presenter: self)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                      
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                            if self.isFromRFIDScreen {
                                self.addRFIDViaWIFI()
                            }
                            if self.isFromFingerPrintScreen {
                                self.addFingerPrintViaWIFI()
                            }
                            self.isConnectedViaWIFI = true
                        } else {
                            self.isConnectedViaWIFI = false
                            if self.isFromFingerPrintScreen {
                                Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add fingerprint.", presenter: self)
                            }
                            if self.isFromRFIDScreen {
                                Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add RFID.", presenter: self)
                            }
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
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
}
