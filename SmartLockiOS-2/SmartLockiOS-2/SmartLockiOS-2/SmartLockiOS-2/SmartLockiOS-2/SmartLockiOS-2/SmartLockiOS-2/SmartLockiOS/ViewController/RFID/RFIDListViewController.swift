//
//  RFIDListViewController.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/3/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit
import NetworkExtension

class RFIDListViewController: UIViewController {
    
    @IBOutlet weak var rfidTableView: UITableView!
    
    var rfidListArray = [RFIDModel]() {
        didSet {
            self.rfidTableView.reloadData()
        }
    }
    var lockListDetailsObj = LockListModel(json: [:])
    var userLockID = String()
    var isConnectedViaWIFI = Bool()
    var scratchCode = String()
    var lockConnection:LockConnection = LockConnection()
    var selectedRFID = String()
    var selectedKeyValue = String()

    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
    
    private let notificationCenter = NotificationCenter.default
    
    // MARK: - View life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
        
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
            
            let title = userInfo["title"] as? String
            let body = userInfo["body"] as? String
            let command = userInfo["command"] as? String
            let status = userInfo["status"] as? String
            
            if (status == "success" && command == LockNotificationCommand.RFID_DELETE.rawValue) {
                
                let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.popToViewController()
                }))
                self.present(alert, animated: true, completion: nil)
                
            }
            else if (status == "failure") && command == LockNotificationCommand.RFID_DELETE.rawValue {
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
        
        if Connectivity().isConnectedToInternet(){
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            DispatchQueue.global(qos: .background).async {
                LockWifiManager.shared.localCache.checkAndUpdateRFIDKey(completion: { (status) in
                    LockWifiManager.shared.localCache.checkAndUpdateRevokeRFIDKey(completion: { (status) in
                        self.getRFIDList()
                    })
                })
            }
        } else {
            Utilities.showErrorAlertView(message: INTERNET_CONNECTION_VALIDATION, presenter: self)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize method
    func initialize() {
        title = "RFID"
        addBackBarButton()
        registerTableViewCell()
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
        self.rfidTableView.register(UINib(nibName: "RFIDListTableViewCell", bundle: nil), forCellReuseIdentifier: "RFIDListTableViewCell")
    }
    
    // MARK: - Button Actions
    
    @objc func popToViewController() {
        BLELockAccessManager.shared.stopPeripheralScan()
        self.navigationController!.popViewController(animated: false)
    }
    
    @objc func updateRFIDStatus(_ sender: UIButton) {
        print(sender.tag)
        let rfidObj = rfidListArray[sender.tag]
        
        if rfidObj.key == "00000000" { // Perform Add RFID
            
            let customAddViewController = storyBoard.instantiateViewController(withIdentifier: "CustomAddViewController") as! CustomAddViewController
            customAddViewController.isFromRFIDScreen = true
            customAddViewController.isFromFingerPrintScreen = false
            customAddViewController.lockConnection.selectedLock =  lockConnection.selectedLock
            customAddViewController.lockConnection.serialNumber = lockConnection.serialNumber
            customAddViewController.scratchCode = scratchCode
            customAddViewController.selectedRFID = rfidObj.id
            customAddViewController.lockListDetailsObj = self.lockListDetailsObj
            self.navigationController?.pushViewController(customAddViewController, animated: true)
        } else { // Perform revoke RFID
            self.selectedRFID = rfidObj.id
            self.selectedKeyValue = rfidObj.key
            self.revokeRFID()
        }
    }
}

// MARK: - UITableview

extension RFIDListViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK： UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RFIDListTableViewCell") as? RFIDListTableViewCell
        cell?.backgroundColor = .clear
        cell?.selectionStyle = .none
        
        let rfidObj = rfidListArray[indexPath.row]
        
        cell?.titleLabel.text = rfidObj.name
        cell?.addOrRevokeButton.setTitle(rfidObj.key == "00000000" ? "Add" : "Revoke", for: .normal)
        cell?.addOrRevokeButton?.addTarget(self, action: #selector(self.updateRFIDStatus(_:)), for: .touchUpInside)
        
        cell?.addOrRevokeButton.tag = indexPath.row // Check with API integration
        
        return cell!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rfidListArray.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 //UITableViewAutomaticDimension
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

// MARK: - Service call
extension RFIDListViewController {
        
    // Get RFID list
    @objc func getRFIDList() {
        
        
        let ownerStatus = "0"
        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(self.userLockID)&owner=\(ownerStatus)&type=RFID"
        //        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(self.userLockID)"
        
        RFIDViewModel().getRFIDListServiceViewModel(url: urlString, userDetails: [:]) { (result, error) in
           
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            LockWifiManager.shared.localCache.updateOfflineItems()
            if result != nil {
                self.rfidListArray = result!
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                self.showCustomAlert(with: message)
            }
        }
    }
    
    // Show custom alert with string
    func showCustomAlert(with message: String) {
        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showBackNavigationCustomAlert(with message: String) {
        let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.popToViewController()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Revoke RFID via WIFI
extension RFIDListViewController {
    func revokeRFID() {
        if self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
            let urlString = ServiceUrl.BASE_URL + "locks/\(self.lockListDetailsObj.serial_number ?? "")/rfid/\(self.selectedKeyValue)"
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            RFIDViewModel().revokeRfidViaMqttServiceViewModel(url: urlString, userDetails: [:]) { result, error in
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
        }else {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                self.revokeRFIDWithWIFI()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func revokeRFIDWithWIFI() {
        
        // For testing
        //            self.revokeRFIDViaWIFI()
        
        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
            self.revokeRFIDViaWIFI()
        } else {
            self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode)
        }
    }
    
    func revokeRFIDViaWIFI() {
        
        // Hardware revoke RFID
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = [String : Any]()
            parameters["owner-id"] = authorizationKey["owner-id"]
            parameters["slot-key"] = authorizationKey["slot-key"]
            // hack to ensure right slot number is passed
            
//{"owner-id":"12345678","slot-key":"ABCDEF01ABCDEF01ABCDEF01","rf-id":2}
                        
            parameters["rf-id"] = Int(self.selectedKeyValue) // should be integer
            LockWifiManager.shared.revokeRFID(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        let updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        print("-----------------------")
                        print(updatedKey ?? "")
                        
                        let tempStr: LockWifiRFIDMessages = LockWifiRFIDMessages(rawValue: updatedKey) ?? .EMPTY
                        
                        switch tempStr {
                        case .OK:
                            // success
                            // next service call
                            // remove in array list
                            print(".OK")
                            
                            // Save offline
                            
                            self.saveRevokeRFIDOffline()
                            let alert = UIAlertController(title: ALERT_TITLE, message: RF_REVOKED_OK, preferredStyle: UIAlertController.Style.alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                self.popToViewController()
                            }))
                            self.present(alert, animated: true, completion: nil)
                            
                            break
                            
                        case .RF_ID_ALREADY_EMPTY:
                            
                            self.saveRevokeRFIDOffline()
                            self.showBackNavigationCustomAlert(with: RF_ID_ALREADY_EMPTY) // --> no error revoke the id
                            break
                        case .RF_ID_NOT_EXISTS:
                            self.showBackNavigationCustomAlert(with: RF_ID_NOT_EXISTS)
                            break
                        default:
                            break
                        }
                        LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    } else {
                        LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    }
                } else {
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke RFID access.", presenter: self)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke RFID access.", presenter: self)
        }
        
    }
}

// MARK: - Handle Offline save

extension RFIDListViewController {
    
    func saveRevokeRFIDOffline() {
        
        let userDetailsDict = [
            "user_id": "",
            "key": "00000000",
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
        LockWifiManager.shared.localCache.saveRevokeRFIDKey(with: userDetails, keyID: self.selectedRFID)
    }
}

extension RFIDListViewController {
    // MARK: - Wifi Settings
    
    func configureWifiConnection(ssid: String, password: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
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
                      
                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            
                            
                            self.revokeRFIDViaWIFI()
                            self.isConnectedViaWIFI = true
                        } else {
                            self.isConnectedViaWIFI = false
                            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke RFID access.", presenter: self)
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
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString /*.UIApplicationOpenSettingsURLString*/) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                //print("Settings opened: \(success)") // Prints true
            })
        }
    }
}
