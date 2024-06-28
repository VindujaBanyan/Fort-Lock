//
//  HomeWifiConfigurationViewController.swift
//  SmartLockiOS
//
//  Created by mohamedshah on 17/05/22.
//  Copyright © 2022 payoda. All rights reserved.
//


import UIKit
import SwiftyJSON
import NetworkExtension

class HomeWifiConfigurationViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var lockNameTxtField: TweeAttributedTextField!
    @IBOutlet weak var wifiSsidTxtField: TweeAttributedTextField!
    @IBOutlet weak var wifiPasswordTxtField: TweeAttributedTextField!
    @IBOutlet weak var securityGroupTxtField: TweeAttributedTextField!
    @IBOutlet weak var passwordShowHideButton: UIButton!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    @IBOutlet weak var wifiPasswordTopConstraint: NSLayoutConstraint!
    
    var isPasswordHidden = true
    
    var securityGroupPickerView : UIPickerView!
    var securityGroupData = ["OPEN" , "WEP" , "WPA" , "WPA2", "WPA+WPA2"]
    
    var lockConnection:LockConnection = LockConnection()
    var isConnectedViaWIFI = Bool()
    var scratchCode = String()
    var lockListDetailsObj = LockListModel(json: [:])
    var userLockID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    // MARK: - Initialize Methods
    func initialize() {
        self.title = "Home WiFi Configuration"
        addBackBarButton()
        setButtonProperties()
        setLockName()
        
        // UIPickerView
        self.securityGroupPickerView = UIPickerView(frame:CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216))
        self.securityGroupPickerView.delegate = self
        self.securityGroupPickerView.dataSource = self
        self.securityGroupPickerView.backgroundColor = UIColor.white
        
        //Set the default value as WPA2
        securityGroupPickerView.selectRow(3, inComponent: 0, animated: true)
        
        self.wifiSsidTxtField.delegate = self
        self.wifiPasswordTxtField.delegate = self
        securityGroupTxtField.delegate = self
        securityGroupTxtField.text = securityGroupData[3]
        
        //Password visibility settings
        if isPasswordHidden {
            // eye strike img
            let image = UIImage(named: "hidePassword")?.withRenderingMode(.alwaysTemplate)
            passwordShowHideButton.setImage(image, for: .normal)
            wifiPasswordTxtField.isSecureTextEntry = true
        } else {
            // eye image
            let image = UIImage(named: "showPassword")?.withRenderingMode(.alwaysTemplate)
            passwordShowHideButton.setImage(image, for: .normal)
            wifiPasswordTxtField.isSecureTextEntry = false
        }
        passwordShowHideButton.tintColor = UIColor(red: 0.36, green: 0.36, blue: 0.36, alpha: 1.00)
    }
    
    func setLockName(){
       self.lockNameTxtField.text = lockListDetailsObj.lockname
    }
    
    func setButtonProperties() {
        self.cancelButton.layer.cornerRadius = 10.0
        self.cancelButton.layer.borderWidth = 1
        self.cancelButton.layer.borderColor = UIColor.darkGray.cgColor
        self.saveButton.layer.cornerRadius = 10.0
        self.disableSaveButton()
    }
    
    func disableSaveButton(){
        self.saveButton.isEnabled = false
        self.saveButton.isUserInteractionEnabled = false
        self.saveButton.backgroundColor = UIColor(red: 254 / 255, green: 158 / 255, blue: 67 / 255, alpha: 0.6)
    }
    func enableSaveButton() {
        self.saveButton.isEnabled = true
        self.saveButton.isUserInteractionEnabled = true
        self.saveButton.backgroundColor = UIColor(red: 254 / 255, green: 158 / 255, blue: 67 / 255, alpha: 1.0)
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
    
    @objc func popToViewController() {
        navigationController!.popViewController(animated: false)
    }
    
    @IBAction func onTapPasswordShowHideButton(_ sender: UIButton) {
        isPasswordHidden = !isPasswordHidden
        if isPasswordHidden {
            // change to hide password ==> eye strike
            let image = UIImage(named: "hidePassword")?.withRenderingMode(.alwaysTemplate)
            passwordShowHideButton.setImage(image, for: .normal)
            wifiPasswordTxtField.isSecureTextEntry = true
            
        } else {
            // change to show password ==> eye
            let image = UIImage(named: "showPassword")?.withRenderingMode(.alwaysTemplate)
            passwordShowHideButton.setImage(image, for: .normal)
            wifiPasswordTxtField.isSecureTextEntry = false
        }
        passwordShowHideButton.tintColor = UIColor(red: 0.36, green: 0.36, blue: 0.36, alpha: 1.00)
    }
    
    
    @IBAction func cancelBtnAction(_ sender: UIButton) {
        navigationController!.popViewController(animated: true)
    }
    
    @IBAction func saveBtnAction(_ sender: UIButton) {
        if self.lockListDetailsObj.lockVersion == lockVersions.version6_0.rawValue {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK_FOR_V6, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                    print("Works If part")
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    self.updateHomeWiFiConfiguration()
                    self.isConnectedViaWIFI = true
                    
                } else {
                    print("Works Else part")
                    //                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK_FOR_OTHERS, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                    print("Works If part")
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    self.updateHomeWiFiConfiguration()
                    self.isConnectedViaWIFI = true
                    
                } else {
                    print("Works Else part")
                    //                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func pickUp(_ textField : UITextField){
        textField.inputView = self.securityGroupPickerView
        
        // ToolBar
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(HomeWifiConfigurationViewController.doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(HomeWifiConfigurationViewController.cancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolBar
        
    }
    
    //MARK:- PickerView Delegate & DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return securityGroupData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return securityGroupData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.securityGroupTxtField.text = securityGroupData[row]
        if(securityGroupData[row] == "OPEN"){
            self.wifiPasswordTxtField.isHidden = true
            self.passwordShowHideButton.isHidden = true
            self.wifiPasswordTopConstraint.constant = -50
        }else {
            self.wifiPasswordTxtField.isHidden = false
            self.passwordShowHideButton.isHidden = false
            self.wifiPasswordTopConstraint.constant = 50
        }
        self.validation()
    }
    
    //MARK:- TextFiled Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.pickUp(securityGroupTxtField)
    }
    
    @IBAction func wifiSsidDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
        self.wifiSsidTxtField.hideInfo()
    }

    @IBAction func wifiSsidDidEndEditing(_ sender: TweeAttributedTextField) {
        if sender.text == "" {
            sender.showInfo(WIFI_SSID_MANDATORY_ERROR)
            self.disableSaveButton()
        } else {
            self.validation()
            return
        }
    }

    @IBAction func wifiPasswordDidBeginEditing(_ sender: TweeAttributedTextField) {
        self.validation()
        self.wifiPasswordTxtField.hideInfo()
    }

    @IBAction func wifiPasswordDidEndEditing(_ sender: TweeAttributedTextField) {
        if sender.text == "" {
            sender.showInfo(WIFI_PASSWORD_MANDATORY_ERROR)
            self.disableSaveButton()
        }else if(sender.text?.count)! < 8{
            sender.showInfo(WIFI_PASSWORD_LENGTH_ERROR)
            self.disableSaveButton()
        }else{
            self.validation()
            return
        }
    }
    
    // MARK: - Validation
    func validation() {
        self.disableSaveButton()
        if(self.wifiSsidTxtField.text?.isEmpty)!{
            
        }else if(self.securityGroupTxtField.text != securityGroupData[0] && (self.wifiPasswordTxtField.text?.isEmpty)!){
            
        }else if(self.securityGroupTxtField.text != securityGroupData[0] && (self.wifiPasswordTxtField.text?.count)! < 8){
            
        }else{
            self.enableSaveButton()
        }
    }
    
    //MARK:- Button
    @objc func doneClick() {
        securityGroupTxtField.resignFirstResponder()
    }
    @objc func cancelClick() {
        securityGroupTxtField.resignFirstResponder()
    }
    
    
}

extension HomeWifiConfigurationViewController {
    
    func configureWifiConnection(ssid: String, password: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            let config = NEHotspotConfiguration(ssid: newSSID, passphrase: password, isWEP: false)
            config.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(config) { (error) in
                if error != nil {
                    self.isConnectedViaWIFI = false
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            self.updateHomeWiFiConfiguration()
                            self.isConnectedViaWIFI = true
                            print("wifi connection = \(self.isConnectedViaWIFI)")
                        } else {
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                            print("wifi connection = \(self.isConnectedViaWIFI)")
                            self.isConnectedViaWIFI = false
                            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add Home WiFi details.", presenter: self)
                        }
                    })
                }
            }
        } else {
            // handle older versions
            let message = SETTINGS_NAVIGATION
            let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            }))
            self.present(alert, animated: true, completion: nil)
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        }
    }
    
    func updateHomeWiFiConfiguration() {
        // Hardware add Home WiFi 
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = [String : Any]()
            
            let securityGroupText = self.securityGroupTxtField.text
            let index = self.securityGroupData.firstIndex(where: {$0 == securityGroupText})
            
            parameters["owner-id"] = authorizationKey["owner-id"]
            parameters["slot-key"] = authorizationKey["slot-key"]
            parameters["wifi-ssid"] = self.wifiSsidTxtField.text
            parameters["wifi-pass"] = self.wifiPasswordTxtField.text
            parameters["wifi-sec"] = String(index!)
            
            let mqttServiceUrl = JsonUtils().getMqttServiceUrl()
            let lastColonIndex = mqttServiceUrl.lastIndex(of: ":")!

            let mqttIp = String(mqttServiceUrl[..<lastColonIndex])
            print("ip= \(mqttIp)")
            let mqttPort = String(mqttServiceUrl[mqttServiceUrl.index(after: lastColonIndex)...])
            print("port= \(mqttPort)")

            parameters["http-ip"] = mqttIp
            parameters["http-port"] = mqttPort

            print("Home WiFi Params: \(parameters)")
           // let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.configWiFiMqtt.rawValue
            //

            
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
          
            LockWifiManager.shared.configureHomeWiFiMqtt(wifiDetails: parameters) { [weak self] (isSuccess, jsonResponse, error) in
                guard let self = self else { return }
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                print("#######isSuccess = \(String(describing: isSuccess))")
                if isSuccess {
                    if let jsonDict = jsonResponse?.dictionary {
                        let status = jsonDict["status"]?.string ?? ""
                        let errorMessage = jsonDict["error-message"]?.string ?? ""
                        let tempStr: LockWiFiMqttConfigMessages = LockWiFiMqttConfigMessages(rawValue: errorMessage) ?? .EMPTY
                        switch tempStr {
                       // switch status {
                            //case "success":
                            case .OK :
                                print(".OK")
                                let alert = UIAlertController(title: ALERT_TITLE, message: HOME_WIFI_MQTT_OK, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                  // self.doPushWifiAddedServer(lock: self.lockListDetailsObj)
                                    self.disconnectWifi(ssid: self.lockConnection.serialNumber)
                                    self.popToViewController()
                                }))
                                self.present(alert, animated: true, completion: nil)
                                break
                            case .WIFI_NOT_CONNECTED:
                                Utilities.showSuccessAlertView(message: WIFI_NOT_CONNECTED, presenter: self)
                                break
                            case .MQTT_NOT_CONNECTED:
                                Utilities.showSuccessAlertView(message: MQTT_NOT_CONNECTED, presenter: self)
                                break
                            default:
                                // Handle other status codes if needed
                                Utilities.showErrorAlertView(message: errorMessage, presenter: self)
                        }
                    }
                } else {
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add Home WiFi details.", presenter: self)
                }
            }

        }
    }
    func doPushWifiAddedServer(lock:LockListModel) {
        var id: String?
        var key: String?
        if lockListDetailsObj.wasAddedOffline == true  {
            id =  self.lockListDetailsObj.lock_keys[1].lock_id!
            //key = mLock.getLockKeys()[0].getKey()
        } else {
            for lockKey in self.lockListDetailsObj.lock_keys {
                if lockKey.user_type!.lowercased() == UserRoles.owner.rawValue {
                    id = lockKey.lock_id
                } else {
                    
                }
            }
        }
        let oldOwnerId = self.lockListDetailsObj.lock_owner_id![0].id!
        var slotNumber = self.lockListDetailsObj.lock_owner_id![0].slot_number
        print("lockDisengageViaWIFI")
        LockDetailsViewController().transferOwnerViaWifi(oldOwnerId: oldOwnerId, slotNumber: slotNumber!)
    
            // Hardware add Home WiFi
            if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
                var parameters = [String : Any]()
                parameters["owner-id"] = authorizationKey["owner-id"]
                let encriptedOwnerId = Utilities().convertStringToEncryptedString(plainString: parameters["owner-id"] as! String, isSecured: true)
                parameters["ownerId"] = encriptedOwnerId
                parameters["serialNumber"] = self.lockListDetailsObj.serial_number
                parameters.removeValue(forKey: "owner-id")
                print("push lock Params: \(parameters)")
               // let url = LockWifiManager.wifiUrl + LockWifiRESTMethods.configWiFiMqtt.rawValue
                //

                
                LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
              
                LockWifiManager.shared.pushServerLock(LockDetails: parameters) { [weak self] (isSuccess, jsonResponse, error) in
                    guard let self = self else { return }
                   // LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    print("@@@@@isSuccess = \(String(describing: isSuccess))")
                    if isSuccess {
                        if let jsonDict = jsonResponse?.dictionary {
                            let status = jsonDict["status"]?.string ?? ""
                            let errorMessage = jsonDict["error-message"]?.string ?? ""
                            print("the lock details are pushed to the server")
                        }
                    } else {
                       print("lock details pushing is failed")
                    }
                }

            }
        }
        
  
    
    func disconnectWifi(ssid: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        if #available(iOS 11.0, *) {
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: newSSID)
        }
    }
}
