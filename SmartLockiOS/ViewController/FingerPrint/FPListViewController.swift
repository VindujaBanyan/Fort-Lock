//
//  FPListViewController.swift
//  SmartLockiOS
//
//  Created by PTPLM031 on 4/7/20.
//  Copyright © 2020 payoda. All rights reserved.
//

import UIKit
import NetworkExtension

class FPListViewController: UIViewController {
    
    @IBOutlet weak var fpTableView: UITableView!
    @IBOutlet weak var fpAddView: UIView!
    
    @IBOutlet weak var floatingAddButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var lblAddFinger: UILabel!
    @IBOutlet weak var switchManagePrivilege: UISwitch!
    @IBOutlet weak var lblManagePrivilege: UILabel!
    @IBOutlet weak var lblManagePrivilegeText: UILabel!
    var fpListArray = [FPModel]() {
        didSet {
            self.updateFPScreen()
            self.fpTableView.reloadData()
        }
    }
    @IBOutlet weak var fpTableViewTop: NSLayoutConstraint!
    var lockListDetailsObj = LockListModel(json: [:])
    var userLockID = String()
    var isConnectedViaWIFI = Bool()
    var scratchCode = String()
    var lockConnection:LockConnection = LockConnection()
    var revokedKeyCountForUser: Int = 0
    var keyArray = [String]()
    var revokeFailedKeyArray = [String]()
    var selectedFingerPrintID = String()
    var selectedKeyValue = String()
    var userID = String()
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
            
            if (status == "success"){
                if (command == LockNotificationCommand.FP_DELETE.rawValue) {
                    let value = self.keyArray[self.revokedKeyCountForUser]
                    if let index = self.revokeFailedKeyArray.firstIndex(of: value) {
                        self.revokeFailedKeyArray.remove(at: index)
                    }
                    
                    self.revokedKeyCountForUser = self.revokedKeyCountForUser + 1
                    
                    if self.revokedKeyCountForUser == self.keyArray.count && self.revokeFailedKeyArray.count == 0 {
                        self.saveRevokeFingerPrintOffline()
                        LoaderView.sharedInstance.hideShadowView(selfObject: self)
                        let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertController.Style.alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            self.popToViewController()
                        }))
                        self.present(alert, animated: true, completion: nil)
                        
                    }
                }else if(command == LockNotificationCommand.FP_ON.rawValue || command == LockNotificationCommand.FP_OFF.rawValue){
                    // Save offline
                    self.lockListDetailsObj.enable_fp = switchManagePrivilege.isOn ? "1" : "0"
                    
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self.popToViewController()
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }else if (status == "failure" && (command == LockNotificationCommand.FP_DELETE.rawValue || command == LockNotificationCommand.FP_ON.rawValue || command == LockNotificationCommand.FP_OFF.rawValue)){
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
        
        handleSavedData()
        self.updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateUI() {
        if self.lockListDetailsObj.lockVersion != lockVersions.version3_0.rawValue && self.lockListDetailsObj.lockVersion != lockVersions.version3_1.rawValue && self.lockListDetailsObj.lockVersion != lockVersions.version4_0.rawValue && self.lockListDetailsObj.lockVersion != lockVersions.version6_0.rawValue{
            self.switchManagePrivilege.isHidden = true
            self.lblManagePrivilege.isHidden = true
            self.lblManagePrivilegeText.isHidden = true
            self.fpTableViewTop.constant = 0
        } else{
            if self.lockListDetailsObj.lock_keys[1].user_type!.lowercased() == UserRoles.owner.rawValue {
                self.fpTableViewTop.constant = 50
                self.switchManagePrivilege.isHidden = false
                self.lblManagePrivilegeText.isHidden = false
                
                if self.lockListDetailsObj.enable_fp == "0"{
                    self.lblManagePrivilege.isHidden = false
                    self.switchManagePrivilege.isOn = false
                    self.fpTableView.isHidden = true
                    self.floatingAddButton.isHidden = true
                    self.fpAddView.isHidden = true
                    self.addButton.isHidden = true
                    self.lblAddFinger.isHidden = true
                }else{
                    self.lblManagePrivilege.isHidden = true
                    self.switchManagePrivilege.isOn = true
                    self.fpTableView.isHidden = false
                    self.floatingAddButton.isHidden = false
                    self.fpAddView.isHidden = false
                    self.lblAddFinger.isHidden = false
                }
            }else {
                self.switchManagePrivilege.isHidden = true
                self.lblManagePrivilege.isHidden = true
                self.lblManagePrivilegeText.isHidden = true
                self.fpTableViewTop.constant = 0
            }
        }
    }
    
    // MARK: - Initialize method
    
    func initialize() {
        title = "Finger Print"
        addBackBarButton()
        registerTableViewCell()
        fpTableView.tableFooterView = UIView()
    }
    
    /// Handle offline saved data
    func handleSavedData() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        DispatchQueue.global(qos: .background).async {
            LockWifiManager.shared.localCache.checkAndAddFPKey(completion: { (status) in
                LockWifiManager.shared.localCache.checkAndUpdateFPKey(completion: { (status) in
                    LockWifiManager.shared.localCache.checkAndUpdateRevokeFPKey(completion: { (status) in
                        self.getFPList()
                    })
                })
            })
        }
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
        self.fpTableView.register(UINib(nibName: "FPListTableViewCell", bundle: nil), forCellReuseIdentifier: "FPListTableViewCell")
    }
    
    // MARK: - UI update methods
    
    /// Update fingerprint list screen
    func updateFPScreen() {
        let status = fpListArray.count == 0 || self.lockListDetailsObj.enable_fp == "0" ? false : true // hide fpAddView
        updateViewVisibility(with: status)
    }
    
    /// Update view visibility
    /// - Parameter status: Bool value
    func updateViewVisibility(with status: Bool) {
        self.fpAddView.isHidden = status
        self.fpTableView.isHidden = !status
        self.floatingAddButton.isHidden = !status
    }
    
    // MARK: - Button Actions
    
    /// Pop to UIViewController
    @objc func popToViewController() {
//        self.navigationController!.popViewController(animated: false)
        guard let navigationController = self.navigationController else {
                   print("Navigation controller is nil, cannot pop view controller.")
                   return
               }
               navigationController.popViewController(animated: false)
    }
    
    /// Initial add fingerprint Button action
    /// - Parameter sender: Button instance
    @IBAction func onTapAddButton(_ sender: Any) {
        showActionsheetToSelectUserType()
    }
    
    /// Common add fingerprint Button action
    /// - Parameter sender: Button instance
    @IBAction func onTapFloatingAddButton(_ sender: Any) {
        showActionsheetToSelectUserType()
    }
    
    /// Edit guest user name Button action
    /// - Parameter sender: Button instance
    @objc func onTapEditGuestUserButton(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FPNewUserViewController") as! FPNewUserViewController
        vc.isAddUser = false
        vc.isEditUser = true
        
        let tag = sender.tag
        let obj = fpListArray[tag]
        if let registrationObj = obj.registrationDetails {
            vc.userRegistrationObj = registrationObj
        }
        vc.lockConnection.selectedLock =  lockConnection.selectedLock
        vc.lockConnection.serialNumber = self.lockConnection.serialNumber
        vc.scratchCode = scratchCode

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Add fingerprint Button action in tableviewcell
    /// - Parameter sender: Button instance
    @objc func onTapAddFPButton(_ sender: UIButton) {
        
        let tag = sender.tag
        
        let obj = fpListArray[tag] as FPModel
        let customAddViewController = storyBoard.instantiateViewController(withIdentifier: "CustomAddViewController") as! CustomAddViewController
        customAddViewController.isFromRFIDScreen = false
        customAddViewController.isFromFingerPrintScreen = true
        customAddViewController.isAlreadyFingerPrintAssigned = true
        customAddViewController.userID =  obj.registrationDetails.id
        customAddViewController.assignedkeys = obj.key
        customAddViewController.fingerPrintID = obj.id
        customAddViewController.lockConnection.selectedLock =  lockConnection.selectedLock
        customAddViewController.lockConnection.serialNumber = lockConnection.serialNumber
        customAddViewController.scratchCode = scratchCode
        customAddViewController.lockListDetailsObj = self.lockListDetailsObj
        self.navigationController?.pushViewController(customAddViewController, animated: true)
        
    }
    
    /// Revoke fingerprint Button action in tableviewcell
    /// - Parameter sender: Button instance
    @objc func onTapRevokeFPButton(_ sender: UIButton) {
        
        let tag = sender.tag
        let obj = fpListArray[tag] as FPModel
        self.keyArray = Utilities().convertKeyStringToKeyArray(with: obj.key)
        self.revokeFailedKeyArray = self.keyArray
        self.selectedFingerPrintID = obj.id
        self.selectedKeyValue = obj.key
        self.userID = obj.userId
        revokeFingerPrint()
    }
    
    //MARK: - Finger print add functions
    
    /// Display action sheet to select user type
    func showActionsheetToSelectUserType() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: "Select user type", preferredStyle: .actionSheet)
            let newUserAction = UIAlertAction(title: "New user", style: .default) { (action) in
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "FPNewUserViewController") as! FPNewUserViewController
                vc.isAddUser = true
                vc.isEditUser = false
                vc.lockId = self.userLockID
                vc.lockConnection.selectedLock = self.lockConnection.selectedLock
                vc.lockConnection.serialNumber = self.lockConnection.serialNumber
                vc.scratchCode = self.scratchCode
                vc.lockListDetailsObj = self.lockListDetailsObj
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            let existingUserAction = UIAlertAction(title: "Existing User", style: .default) { (action) in
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "FPExistingUserListViewController") as! FPExistingUserListViewController
                vc.lockId = self.userLockID
                vc.fpListArray = self.fpListArray
                vc.lockConnection.selectedLock = self.lockConnection.selectedLock
                vc.lockConnection.serialNumber = self.lockConnection.serialNumber
                vc.scratchCode = self.scratchCode
                vc.lockListDetailsObj = self.lockListDetailsObj
                self.navigationController?.pushViewController(vc, animated: true)
            }

            let cancelAction1 = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            }

            alert.addAction(newUserAction)
            alert.addAction(existingUserAction)
            alert.addAction(cancelAction1)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func switchManagePrivilegeAction(_ sender: Any) {
//        self.fpManagePrivilegeViaWIFI()
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
            let urlString = ServiceUrl.BASE_URL + "locks/\(self.lockListDetailsObj.serial_number ?? "")/fp/manage"
            let fpManageStatus = "\(Int(truncating: NSNumber(value:switchManagePrivilege.isOn)))"
            let lockDetails = ["enable_fp": fpManageStatus]
            
            FPViewModel().manageFingerprintViaMqttServiceViewModel(url: urlString, userDetails: lockDetails) { result, error in
                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                
                if result != nil {
                    print("Success.....\(result ?? "")")
                } else {
                    self.managePrivilegeActualState()
                    let message = error?.userInfo["ErrorMessage"] as! String
                    let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)

                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }else {
            self.updateFPWithWifi()
        }
    }
    
}

// MARK: - UITableview

extension FPListViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK： UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPListTableViewCell") as? FPListTableViewCell
        cell?.backgroundColor = .clear
        cell?.selectionStyle = .none
        
        let fpObj = fpListArray[indexPath.row]
        
        cell?.titleLabel.text = fpObj.isGuestUser ? fpObj.registrationDetails.name : fpObj.userDetails.username
        cell?.keyCountLabel.text = "(\(String(describing: fpObj.numberOfKeysAssigned!)))"
        
        cell?.editButton.isHidden = fpObj.isGuestUser ? false : true
        cell?.editButtonWidthConstraint.constant = fpObj.isGuestUser ? 35.0 : 0.0
        cell?.editButtonLeadingConstraint.constant = fpObj.isGuestUser ? 5.0 : 0.0
        
        cell?.editButton?.addTarget(self, action: #selector(self.onTapEditGuestUserButton(_:)), for: .touchUpInside)
        cell?.addButton?.addTarget(self, action: #selector(self.onTapAddFPButton(_:)), for: .touchUpInside)
        cell?.revokeButton?.addTarget(self, action: #selector(self.onTapRevokeFPButton), for: .touchUpInside)

        cell?.editButton.tag = indexPath.row // Check with API integration
        cell?.addButton.tag = indexPath.row
        cell?.revokeButton.tag = indexPath.row
        
        return cell!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fpListArray.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 //UITableViewAutomaticDimension
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

// MARK: - Service call
extension FPListViewController {
        
    // Get RFID list
    @objc func getFPList() {
        
        let ownerStatus = "0"
        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(self.userLockID)&owner=\(ownerStatus)&type=Fingerprint"
        //        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(self.userLockID)"
        
        FPViewModel().getFPListServiceViewModel(url: urlString, userDetails: [:]) { (result, error) in
           
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            if result != nil {
                self.fpListArray = result!
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
//                self.showCustomAlert(with: message)
            }
            LockWifiManager.shared.localCache.updateOfflineItems()
        }
    }
        
    /// Add fingerprint with
    /// - Parameter isExistingUser: Already fingerprint added user - status
    func addFingerPrint(isExistingUser: Bool) {
        
        let urlString = ServiceUrl.BASE_URL + "addfingerprint"
            
            var userDetailsDict = [
                "lock_id": "",
                "key": "",
                "name": "0",
                ]

        if isExistingUser {
            userDetailsDict["user_id"] = ""
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
        
//        {"lock_id":"449","name":"David Albert","key":"[6]","user_id":"355"}

//            ["04"]
                
        FPViewModel().getFPListServiceViewModel(url: urlString, userDetails: [:]) { (result, error) in
           
            if result != nil {
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
}

// MARK: - Add finger print
extension FPListViewController {
    
    /// Revoke fingerprint
    func revokeFingerPrint() {
        if self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
            var isFirstCall = true
            for fpId in self.keyArray {
                DispatchQueue.main.asyncAfter(deadline: .now() + (isFirstCall ? 0 : 1)) {
                    isFirstCall = false
                    let urlString = ServiceUrl.BASE_URL + "locks/\(self.lockListDetailsObj.serial_number ?? "")/key/\(self.selectedFingerPrintID)/fp/\(fpId)"
                    LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                    FPViewModel().revokeFingerprintViaMqttServiceViewModel(url: urlString, userDetails: [:]) { result, error in
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
            }
        }else if self.lockListDetailsObj.lockVersion == lockVersions.version6_0.rawValue {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK_FOR_V6, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)

                self.revokeFingerPrintWithWIFI()
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK_FOR_OTHERS, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)

                self.revokeFingerPrintWithWIFI()
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /// Revoke fingerprint via WIFI
    func revokeFingerPrintWithWIFI() {
                
        // For testing
//        self.revokeFingerPrintViaWIFI()
        
        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
            self.revokeFingerPrintViaWIFI()
        } else {
            self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode, isFromManagePrivilege: false)
        }
    }
    
    /// Revoke fingerprint via WIFI
    func revokeFingerPrintViaWIFI() { // handle for each key
        
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        self.revokeCall()
    }
    
    /// Revoke fingerprint WIFI service call
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
            print("revoke finherprint parameters are \(parameters)")
            LockWifiManager.shared.revokeFingerPrint(userDetails: parameters, completion: {[weak self] (isSuccess, jsonResponse, error) in
                guard let self = self else { return }
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        var updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        print("-----------------------")
                        print(updatedKey)
                        updatedKey = (updatedKey == "" || updatedKey == "none") ? "FP_NOT_PLACED" : updatedKey

                        let tempStr: LockWifiFPMessages = LockWifiFPMessages(rawValue: updatedKey) ?? .EMPTY
                        
                        switch tempStr {
                        case .OK:
                            // success
                            // next service call
                            // remove in array list
                            print(".OK")
                            
                            let value = self.keyArray[self.revokedKeyCountForUser]

                            if let index = self.revokeFailedKeyArray.firstIndex(of: value) {
                                self.revokeFailedKeyArray.remove(at: index)
                            }
                            
                            self.revokedKeyCountForUser = self.revokedKeyCountForUser + 1
                            
                            if self.revokedKeyCountForUser == self.keyArray.count && self.revokeFailedKeyArray.count == 0 {
                                // all fp ids revoked
                                // Save to local
                                // navigate to lock detail
                                //
                                
                                self.saveRevokeFingerPrintOffline()
                                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                                let alert = UIAlertController(title: ALERT_TITLE, message: FP_UID_REVOKED, preferredStyle: UIAlertController.Style.alert)
                                
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                    self.popToViewController()
                                }))
                                self.present(alert, animated: true, completion: nil)
                                
                            } else {
                                self.revokeCall()
                            }
                            break
                            
                        case .FP_USER_ID_NOT_EXISTS: // for revoke finger print failure
                            
                            LoaderView.sharedInstance.hideShadowView(selfObject: self)
                            let alert = UIAlertController(title: ALERT_TITLE, message: FP_USER_ID_NOT_EXISTS, preferredStyle: UIAlertController.Style.alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            }))
                            self.present(alert, animated: true, completion: nil)
                            break
                            
                        case .FP_NOT_CONNECTED: // for revoke finger print failure
                            
                            LoaderView.sharedInstance.hideShadowView(selfObject: self)
                            let alert = UIAlertController(title: ALERT_TITLE, message: FP_NOT_CONNECTED, preferredStyle: UIAlertController.Style.alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            }))
                            self.present(alert, animated: true, completion: nil)
                            break
                        case .FP_ID_ALREADY_EMPTY: // for revoke finger print failure
                            
                            LoaderView.sharedInstance.hideShadowView(selfObject: self)
                            let alert = UIAlertController(title: ALERT_TITLE, message: FP_ID_ALREADY_EMPTY, preferredStyle: UIAlertController.Style.alert)
                            
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
                    } else {
                        LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    }
                } else {
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke fingerprint access.", presenter: self)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to revoke fingerprint access.", presenter: self)
        }
    }
}

// MARK: - Handle Offline save

extension FPListViewController {
    
    /// Handling revoke fingerprint offline
    func saveRevokeFingerPrintOffline() {
        
        let userDetailsDict = [
            "user_id": self.userID,
            "key":"[]",//self.selectedKeyValue,
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

// MARK: - Wifi Settings

extension FPListViewController {
    
    /// Configure WIFI connection
    /// - Parameters:
    ///   - ssid: Hardware id
    ///   - password: Hardware WIFI password
    func configureWifiConnection(ssid: String, password: String, isFromManagePrivilege: Bool) {
        //print("configureWifiConnection ==> ")
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            
            let config = NEHotspotConfiguration(ssid: newSSID, passphrase: password, isWEP: false)
            config.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(config) { (error) in
                //print("NEHotspotConfigurationManager.shared.apply =========")
                if error != nil {
                    self.isConnectedViaWIFI = false
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                    if isFromManagePrivilege{
                        self.managePrivilegeActualState()
                    }
//                    Utilities.showErrorAlertView(message: "Unable to connect the lock. Please try again.", presenter: self)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                      
                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            if isFromManagePrivilege{
                                self.fpManagePrivilegeViaWIFI()
                            }else{
                                self.revokeFingerPrintViaWIFI()
                            }
                            self.isConnectedViaWIFI = true
                        } else {
                            self.isConnectedViaWIFI = false
                            if isFromManagePrivilege{
                                self.managePrivilegeActualState()
                            }
                            Utilities.showErrorAlertView(message:isFromManagePrivilege ? "Lock disconnected. Failed to Manage Privilege." : "Lock disconnected. Failed to revoke fingerprint access.", presenter: self)
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
    
    /// Manually disconnecting WIFI connection
    /// - Parameter ssid: Hardware id
    func disconnectWifi(ssid: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        if #available(iOS 11.0, *) {
            //print("disconnectWifi(ssid: String) ==> \(ssid)")
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: newSSID)
        }
    }
    
    /// Navigate to Device settings screen
    func navigateToDeviceSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString/*UIApplicationOpenSettingsURLString*/) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                //print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
}

extension FPListViewController{
    func updateFPWithWifi() {
        if self.lockListDetailsObj.lockVersion == lockVersions.version6_0.rawValue {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK_FOR_V6, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                } else {
                    //                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode, isFromManagePrivilege: true)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else  {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK_FOR_OTHERS, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                } else {
                    //                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode, isFromManagePrivilege: true)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func fpManagePrivilegeViaWIFI() {
        // Hardware Manage FP Privilege
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = [String : Any]()
            parameters["owner-id"] = authorizationKey["owner-id"]
            parameters["slot-key"] = authorizationKey["slot-key"]
            parameters["en-dis"] = "\(Int(truncating: NSNumber(value:switchManagePrivilege.isOn)))"
            LockWifiManager.shared.updateFPManagePrivilege(userDetails: parameters, completion: {[weak self] (isSuccess, jsonResponse, error) in
                guard let self = self else { return }
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        let updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        let tempStr: LockWifiFPManagePrivilegeMessages = LockWifiFPManagePrivilegeMessages(rawValue: updatedKey) ?? .EMPTY
                        switch tempStr {
                        case .OK:
                            print(".OK")
                            // Save offline
                            self.lockListDetailsObj.enable_fp = switchManagePrivilege.isOn ? "1" : "0"
                            self.saveOfflineManagePrivilege()
                            self.localDataUpdate()
                            let alert = UIAlertController(title: ALERT_TITLE, message: switchManagePrivilege.isOn ? FP_MANAGE_PRIVILEGE_ENABLE : FP_MANAGE_PRIVILEGE_DISABLE, preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                self.popToViewController()
                            }))
                            self.present(alert, animated: true, completion: nil)
                            break
                        case .AUTHVIA_FP_DISABLED:
                            self.managePrivilegeActualState()
                            Utilities.showSuccessAlertView(message: FP_MANAGE_PRIVILEGE_FAILED, presenter: self)
                        case.EMPTY:
                            self.managePrivilegeActualState()
                        break
                        }
                    }
                } else {
                    self.managePrivilegeActualState()
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to Manage Privilege.", presenter: self)
                }
            })
        } else {
            self.managePrivilegeActualState()
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to Manage Privilege.", presenter: self)
        }
        
    }
    func managePrivilegeActualState(){
        switchManagePrivilege.isOn = !switchManagePrivilege.isOn
    }
}

extension FPListViewController{
    func saveOfflineManagePrivilege() {
        let userDetailsDict = [
            "enable_fp": "\(Int(truncating: NSNumber(value:switchManagePrivilege.isOn)))",
            "lock_id" : self.userLockID
        ] as [String : AnyObject]
        LockWifiManager.shared.localCache.setUpdateFpManagePrivilegeToBeUpdated(FPEnable: userDetailsDict)
    }
    func localDataUpdate(){
        let dbObj = CoreDataController()
        dbObj.updateLockList(id: userLockID, updateKey: "enable_fp", updateValue: "\(Int(truncating: NSNumber(value:switchManagePrivilege.isOn)))")
    }
}
