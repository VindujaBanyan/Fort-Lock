//
//  DigiPinViewController.swift
//  SmartLockiOS
//
//  Created by Sathishkumar R S on 5/17/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import UIKit
import NetworkExtension
import XLPagerTabStrip

struct DigiPin {
    var name : String = ""
    var pin : String = ""
    var slot_number : String = ""
    var status : String = ""
    var createdDate : String = ""
}


class DigiPinViewController: UIViewController,IndicatorInfoProvider {
    var itemInfo = IndicatorInfo(title: "DIGITAL KEYS", image: UIImage(named: ""))
    @IBOutlet var tblView: UITableView!
    lazy var arrDigiPins = [DigiPin]()
    @IBOutlet weak var btnUpdate: UIButton!
    var lockConnection:LockConnection = LockConnection()
    var isConnectedViaWIFI = Bool()
    var scratchCode = String()
    var lockListDetailsObj = LockListModel(json: [:])
    var userLockID = String()
    
    private let notificationCenter = NotificationCenter.default

    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter
                          .addObserver(self,
                           selector:#selector(processBackgroundNotifiData(_:)),
                                       name: NSNotification.Name(BundleIdentifier),
                           object: nil)
        
        getDigiPinList()
        registerTableViewCell()
    }
    
    @objc func processBackgroundNotifiData(_ notification: Notification) {
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        if let userInfo = notification.userInfo {
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            let title = userInfo["title"] as? String
            let body = userInfo["body"] as? String
            let command = userInfo["command"] as? String
            let status = userInfo["status"] as? String
            
            if (status == "success" && command == LockNotificationCommand.PIN_REWRITE.rawValue){
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.popToViewController()
                }))
                self.present(alert, animated: true, completion: nil)
                
            }else if (status == "failure" && command == LockNotificationCommand.PIN_REWRITE.rawValue){
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
    
    func registerTableViewCell() {
        let nib = UINib(nibName: "DigiPinTableViewCell", bundle: nil)
        self.tblView.register(nib, forCellReuseIdentifier: "DigiPinTableViewCell")
    }

    func createInitialDigiPins(){
        for item in 0...8 {
            var digiPin = DigiPin()
            digiPin.name = ""
            digiPin.pin = "    "
            digiPin.slot_number = "\(item + 1)"
            self.arrDigiPins.append(digiPin)
        }
        self.tblView.reloadData()
    }
    
    @IBAction func btnUpdateAction(_ sender: Any) {
        self.validatePins()
    }
    
    func popToViewController() {
        self.navigationController!.popViewController(animated: false)
    }
}
extension DigiPinViewController{
    
    func validatePins(){
        
        // Validate DigiPins
        let arrPins = self.arrDigiPins.filter { (number) -> Bool in
            return number.pin != "    " || number.name != ""
        }
        if arrPins.count == 0{
            self.updateDigiPinWithWifi()
            return
        }
        
        // Pin cannot be empty
        let arrTitlePinss = arrPins.filter { (number) -> Bool in
            return number.pin == "    " && number.name != ""
        }
        if arrTitlePinss.count > 0{
            let index = self.arrDigiPins.firstIndex(where: {$0.name == arrTitlePinss[0].name && $0.pin == arrTitlePinss[0].pin})
                Utilities.showSuccessAlertView(message: "PIN \((index ?? 0) + 1) can't be empty", presenter: self)
                return
        }
        
        
        // Pin validation - Pin count must be 4
        if arrPins.count > 0{
            let errorPins = arrPins.filter { (number) -> Bool in
                return (number.pin.rangeOfCharacter(from: .whitespacesAndNewlines) != nil)
            }
            if errorPins.count > 0{
                let index = self.arrDigiPins.firstIndex(where: {$0.pin == errorPins[0].pin})
                Utilities.showSuccessAlertView(message: "PIN (\((index ?? 0) + 1)) is invalid, Please type four digit PIN", presenter: self)
                return
            }
        }
        
        // Title not to be empty in valid pins
        let arrPinsTitle = arrPins.filter { (number) -> Bool in
            return number.name == ""
        }
        if arrPinsTitle.count > 0{
            let index = self.arrDigiPins.firstIndex(where: {$0.name == arrPinsTitle[0].name && $0.pin == arrPinsTitle[0].pin})
                Utilities.showSuccessAlertView(message: "Name (\((index ?? 0) + 1)) can't be empty", presenter: self)
                return
        }
        
        // Pin not to be empty in valid pins
        let arrTitlePins = arrPins.filter { (number) -> Bool in
            return number.pin == "    "
        }
        if arrTitlePins.count > 0{
            let index = self.arrDigiPins.firstIndex(where: {$0.name == arrTitlePins[0].name && $0.pin == arrTitlePins[0].pin})
                Utilities.showSuccessAlertView(message: "PIN \((index ?? 0) + 1) can't be empty", presenter: self)
                return
        }
        
        // Pin value should not be 0000
        let arrCheckZero = arrPins.filter { (number) -> Bool in
            return number.pin == "0000"
        }
        if arrCheckZero.count > 0{
            let index = self.arrDigiPins.firstIndex(where: {$0.pin == arrCheckZero[0].pin})
                Utilities.showSuccessAlertView(message: "PIN \((index ?? 0) + 1) can't be '0000'", presenter: self)
                return
        }
        
        // Pin duplicate validation
        let pinResult = self.duplicateCheck(value: "Pins", arrPins: arrPins)
        if pinResult == "TRUE"{
            return
        }
        
        //Title duplicate validation
        let titleResult = self.duplicateCheck(value: "Title", arrPins: arrPins)
        if titleResult == "TRUE"{
            return
        }
        self.updateDigiPinWithWifi()
    }
    
    func getIndex(arrPins: [DigiPin],index:Int,isFromFirst:Bool) -> Int{
        return isFromFirst ? self.arrDigiPins.firstIndex(where: {$0.name == arrPins[index].name && $0.pin == arrPins[index].pin})! : self.arrDigiPins.lastIndex(where: {$0.name == arrPins[index].name && $0.pin == arrPins[index].pin})!
    }

    func duplicateCheck(value : String,arrPins: [DigiPin]) -> String{
        for items in 0...arrPins.count - 1{
            let temp = value == "Pins" ? arrPins[items].pin : arrPins[items].name
            var itemCount = 0
            for item in 0...arrPins.count - 1{
                if temp == (value == "Pins" ? arrPins[item].pin : arrPins[item].name){
                    itemCount = itemCount + 1
                }
                if itemCount > 1{
                    let index = getIndex(arrPins: arrPins, index: items, isFromFirst: true)
                    let indexTwo = getIndex(arrPins: arrPins, index: item, isFromFirst: false)
                    let strName = value == "Pins" ? "Pin" : "Name"
                    Utilities.showSuccessAlertView(message: "\(strName) \((index ) + 1) and \(strName) \((indexTwo ) + 1) are Same", presenter: self)
                    return "TRUE"
                }
            }
        }
        return "FALSE"
    }
}

extension DigiPinViewController: UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrDigiPins.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DigiPinTableViewCell") as? DigiPinTableViewCell{
            cell.selectionStyle = .none
            cell.txtFieldTitle.text = arrDigiPins[indexPath.row].name
            cell.indexPathRow = indexPath.row
            cell.lblCount.text = "\(Int(arrDigiPins[indexPath.row].slot_number) ?? 1)"
            let arrString = arrDigiPins[indexPath.row].pin.map { String($0) }
            if(arrString.count == 4){
            cell.txtFieldFirstPin.text = arrString[0]
            cell.txtFieldSecondPin.text = arrString[1]
            cell.txtFieldThirdPin.text = arrString[2]
            cell.txtFieldFourthPin.text = arrString[3]
            }
            cell.valueChanged = { value, index, indexPathRow in
                if index == 5{
                    self.arrDigiPins[indexPathRow].name = value
                }else{
                   let strValue = value == "" ? " " : value
                    self.arrDigiPins[indexPathRow].pin.insert(contentsOf: strValue, at: self.arrDigiPins[indexPathRow].pin.index(self.arrDigiPins[indexPathRow].pin.startIndex, offsetBy: index))
                    self.arrDigiPins[indexPathRow].pin.remove(at: self.arrDigiPins[indexPathRow].pin.index(self.arrDigiPins[indexPathRow].pin.startIndex, offsetBy: index + 1))
                }
            }
            return cell
        }
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}

extension DigiPinViewController{
    // MARK: - IndicatorInfoProvider

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return self.itemInfo
    }

}


extension DigiPinViewController {
    // MARK: - Wifi Settings
    
    func configureWifiConnection(ssid: String, password: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            let config = NEHotspotConfiguration(ssid: newSSID, passphrase: password, isWEP: false)
            config.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(config) { (error) in
                if let error = error {
                    self.isConnectedViaWIFI = false
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            self.updateDigiPinViaWifi()
                            self.isConnectedViaWIFI = true
                        } else {
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                            self.isConnectedViaWIFI = false
                            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to Add Digi Pin.", presenter: self)
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
            })
        }
    }
}

// MARK: Lock Connection
extension DigiPinViewController{
    func updateDigiPinWithWifi() {
        if self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            let urlString = ServiceUrl.BASE_URL + "locks/\(self.lockListDetailsObj.serial_number ?? "")/pin"
            var pinDetails:[String: String] = [:]
            for item in 0..<self.arrDigiPins.count{
                pinDetails["name-\(Int(self.arrDigiPins[item].slot_number) ?? 0)"] = self.arrDigiPins[item].name == "    " ? "" : self.arrDigiPins[item].name
                pinDetails["pin-\(Int(self.arrDigiPins[item].slot_number) ?? 0)"] = self.arrDigiPins[item].pin == "    " ? "0000" : Utilities().convertStringToEncryptedString(plainString: self.arrDigiPins[item].pin, isSecured: true)
            }
            print(pinDetails)
            DigiPinViewModel().updatePinViaMqttServiceViewModel(url: urlString, userDetails: pinDetails) { result, error in
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
                if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
                } else {
    //                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                    self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.scratchCode)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func updateDigiPinViaWifi() {
        // Hardware add Digi Pin
//        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = [String : Any]()
            parameters["owner-id"] = authorizationKey["owner-id"]
            parameters["slot-key"] = authorizationKey["slot-key"]
            for item in 0..<self.arrDigiPins.count{
                parameters["pin-\(Int(self.arrDigiPins[item].slot_number) ?? 0)"] = self.arrDigiPins[item].pin == "    " ? "0000" : self.arrDigiPins[item].pin
            }
            print("Digi Pins : \(parameters)")
            LockWifiManager.shared.addDigiPin(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        let updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        let tempStr: LockWifiDIGIPINMessages = LockWifiDIGIPINMessages(rawValue: updatedKey) ?? .EMPTY
                        switch tempStr {
                        case .OK:
                            print(".OK")
                            // Save offline
                            self.saveDigiPinOffline()
                            let alert = UIAlertController(title: ALERT_TITLE, message: TP_PIN_OK, preferredStyle: UIAlertController.Style.alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                self.popToViewController()
                            }))
                            self.present(alert, animated: true, completion: nil)
                            break
                        case .TP_PIN_OTP_INVALID_FORMAT:
                            Utilities.showSuccessAlertView(message: TP_PIN_INVALID_FORMAT, presenter: self)
                            break
                        case .TP_PIN_OTP_INVALID_LEN:
                            Utilities.showSuccessAlertView(message: TP_PIN_INVALID_LEN, presenter: self)
                            break
                        case .TP_PIN_OTP_ALREADY_EXISTS:
                            Utilities.showSuccessAlertView(message: TP_PIN_ALREADY_EXISTS, presenter: self)
                            break
                        case .AUTHVIA_TP_DISABLED:
                            Utilities.showSuccessAlertView(message: PIN_MANAGE_PRIVILEGE_FAILED, presenter: self)
                            break
                        default:
                            break
                        }
                    }
                } else {
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add DigiPin.", presenter: self)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add DigiPin.", presenter: self)
        }
        
    }
}


// MARK: Server Connection
extension DigiPinViewController{
    
    // Get DigiPin list
    @objc func getDigiPinList() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        let ownerStatus = "0"
        let urlString = ServiceUrl.BASE_URL + "keys/keylist?id=\(self.userLockID)&owner=\(ownerStatus)&type=PIN"
        DigiPinViewModel().getDigiPinListServiceViewModel(url: urlString, userDetails: [:]) { (result, error) in
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            if result != nil {
                if result?.count == 0 {
                    self.createInitialDigiPins()
                }else{
                    self.createInitialDigiPins()
                    self.arrDigiPins = result ?? [DigiPin]()
                    self.tblView.reloadData()
                }
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
            }
            LockWifiManager.shared.localCache.updateOfflineItems()
        }
    }
    
    
    // Save DigiPins
    func saveDigiPinOffline() {
        var arrTemp = [Any]()
        for item in 0..<self.arrDigiPins.count{
            var pin = ""
            if self.arrDigiPins[item].pin != "    "{
                pin = Utilities().convertStringToEncryptedString(plainString: self.arrDigiPins[item].pin, isSecured: true)
            }else{
                pin = ""
            }
            let params : NSMutableDictionary = ["name" : self.arrDigiPins[item].name,"pin": pin, "slot_number" : self.arrDigiPins[item].slot_number]
            arrTemp.append(params)
        }
        let userDetailsDict = [
            "lock_pins": arrTemp,
            "lock_id": userLockID,
        ] as [String : AnyObject]
        LockWifiManager.shared.localCache.setUpdateDigiPinToBeUpdated(digiPinList: userDetailsDict)
    }
}


extension Array where Element: Equatable {
  func allIndices(of value: Element) -> [Index] {
    indices.filter { self[$0] == value }
  }
}
