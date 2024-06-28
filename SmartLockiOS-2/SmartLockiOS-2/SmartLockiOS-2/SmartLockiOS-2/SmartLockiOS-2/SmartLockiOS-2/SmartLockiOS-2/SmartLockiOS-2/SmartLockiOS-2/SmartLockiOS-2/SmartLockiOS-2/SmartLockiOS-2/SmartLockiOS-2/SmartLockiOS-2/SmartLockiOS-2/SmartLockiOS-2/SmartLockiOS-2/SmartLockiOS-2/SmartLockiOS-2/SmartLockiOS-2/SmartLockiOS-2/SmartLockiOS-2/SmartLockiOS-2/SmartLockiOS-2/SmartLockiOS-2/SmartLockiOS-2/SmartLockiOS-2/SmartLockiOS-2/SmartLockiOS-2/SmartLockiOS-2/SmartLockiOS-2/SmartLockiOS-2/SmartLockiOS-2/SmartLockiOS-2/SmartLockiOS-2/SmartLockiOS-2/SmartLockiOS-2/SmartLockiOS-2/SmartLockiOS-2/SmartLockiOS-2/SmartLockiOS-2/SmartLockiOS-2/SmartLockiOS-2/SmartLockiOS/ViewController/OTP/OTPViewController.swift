//
//  OTPViewController.swift
//  SmartLockiOS
//
//  Created by Sathishkumar R S on 5/17/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import NetworkExtension



class OTPViewController: UIViewController,IndicatorInfoProvider {

    @IBOutlet weak var stackViewButton: UIStackView!
    @IBOutlet weak var viewGenerateOtp: UIView!
    @IBOutlet weak var viewRewriteOtp: UIView!
    @IBOutlet weak var btnGenerateOtp: UIButton!
    @IBOutlet weak var btnRewriteOtp: UIButton!
    @IBOutlet weak var lblEmptyOTP: UILabel!
    var lockConnection:LockConnection = LockConnection()
    var isConnectedViaWIFI = Bool()
    var scratchCode = String()
    var lockListDetailsObj = LockListModel(json: [:])
    var userLockID = String()
    var itemInfo = IndicatorInfo(title: "OTP KEYS", image: UIImage(named: ""))
    lazy var arrOTP = [Any]()
    lazy var arrOtpValue = [DigiPin]()
    @IBOutlet var tblView: UITableView!
    
    private let notificationCenter = NotificationCenter.default
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "OTPTableViewCell", bundle: nil)
        self.tblView.register(nib, forCellReuseIdentifier: "OTPTableViewCell")
        self.tblView.delegate = self
        self.tblView.dataSource = self
        self.view.layoutIfNeeded()
        
        
//        LockWifiManager.shared.localCache.updateOfflineItems()
        self.uiUpdate()
        self.getOtpFromServer(isFromNext: false)
        
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
            
            if (status == "success" && command == LockNotificationCommand.OTP_REWRITE.rawValue){
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.popToViewController()
                }))
                self.present(alert, animated: true, completion: nil)
                
            }else if (status == "failure" && command == LockNotificationCommand.OTP_REWRITE.rawValue){
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
    
    func uiUpdate(){
        self.rewriteandGenerateOTPUI(isEnableGenerate: false)
    }
    func rewriteandGenerateOTPUI(isEnableGenerate : Bool){
        self.viewGenerateOtp.isHidden = !isEnableGenerate
//        self.stackViewOtpTextField.isHidden = isEnableGenerate ? false : true
        self.lblEmptyOTP.isHidden = self.arrOtpValue.count == 0 ? false : true
        self.lblEmptyOTP.text = isEnableGenerate ? "Please generate OTP to the lock to proceed" : "Please rewrite OTP to the lock to proceed"
//        if isEnableGenerate {
//            let arrString = self.arrOtpValue[0].pin.map { String($0) }
//            if(arrString.count == 5){
//            txtFieldFirstPin.text = arrString[0]
//            txtFieldSecondPin.text = arrString[1]
//            txtFieldThirdPin.text = arrString[2]
//            txtFieldFourthPin.text = arrString[3]
//            txtFieldFifthPin.text = arrString[4]
//            }
//        }
    }
    
    func popToViewController() {
        self.navigationController!.popViewController(animated: false)
    }
    @IBAction func btnGenerateOtpAction(_ sender: Any) {
        self.getOtpFromServer(isFromNext: true)
    }
    
    @IBAction func btnRewriteOtpAction(_ sender: Any) {
        self.generateOTP()
    }
    
}
extension OTPViewController{
    // MARK: - IndicatorInfoProvider
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return self.itemInfo
    }

}

// MARK: Generate OTP
extension OTPViewController{
    
    func generateOTP(){
        let setOtp = NSMutableSet()
        while setOtp.count < 5 {
            setOtp.add(randomNumberWith(digits:5))
        }
        self.arrOTP = Array(setOtp)
        self.updateOTPWithWifi()
    }
    
    func randomNumberWith(digits:Int) -> Int {
        let min = Int(pow(Double(10), Double(digits-1))) - 1
        let max = Int(pow(Double(10), Double(digits))) - 1
        return Int(Range(uncheckedBounds: (min, max)))
    }
}


// MARK: Server Connection
extension OTPViewController{
    func getOtpFromServer(isFromNext : Bool) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        let urlString = ServiceUrl.BASE_URL + "locks/getotp?lock_id=\(self.userLockID)&next=\(isFromNext == true ? 1 : 0)"
        DigiPinViewModel().getOTPListServiceViewModel(url: urlString, userDetails: [:]) { (result, error, recordExits) in
           
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            if result != nil {
                if result?.count == 0 {
                    self.rewriteandGenerateOTPUI(isEnableGenerate: recordExits ?? false)
                }else{
                    self.arrOtpValue = result ?? [DigiPin]()
                    self.rewriteandGenerateOTPUI(isEnableGenerate: recordExits ?? false)
                }
            } else {
                let message = error?.userInfo["ErrorMessage"] as! String
                self.view.makeToast(message)
            }
            LockWifiManager.shared.localCache.updateOfflineItems()
//            self.heightTableView.constant = CGFloat(self.arrOtpValue.count * self.tableViewHeight)
            self.tblView.reloadData()
        }
    }

}


// MARK: Lock Connection
extension OTPViewController{
    
    func updateOTPWithWifi() {
        if self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
            LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
            let urlString = ServiceUrl.BASE_URL + "locks/\(self.lockListDetailsObj.serial_number ?? "")/otp"
            var otpDetails:[String: String] = [:]
            for item in 0..<self.arrOTP.count{
                let otp = Utilities().convertStringToEncryptedString(plainString: "\(self.arrOTP[item])", isSecured: true)
                otpDetails["otp-\(item + 1)"] = "\(otp)"
            }
            print(otpDetails)
            DigiPinViewModel().updateOtpViaMqttServiceViewModel(url: urlString, userDetails: otpDetails) { result, error in
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
        }else{
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
    
    func updateOTPViaWifi() {
        // Hardware add Digi Pin
//        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = [String : Any]()
            parameters["owner-id"] = authorizationKey["owner-id"]
            parameters["slot-key"] = authorizationKey["slot-key"]
            for item in 0..<self.arrOTP.count{
                parameters["otp-\(item + 1)"] = "\(self.arrOTP[item])"
            }
            print("OTP Pins : \(parameters)")
            LockWifiManager.shared.addOTP(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        let updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        let tempStr: LockWifiDIGIPINMessages = LockWifiDIGIPINMessages(rawValue: updatedKey) ?? .EMPTY
                        switch tempStr {
                        case .OK:
                            print(".OK")
                            // Save offline
                            self.saveOtpOffline()
                            let alert = UIAlertController(title: ALERT_TITLE, message: TP_OTP_OK, preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                self.popToViewController()
                            }))
                            self.present(alert, animated: true, completion: nil)
                            break
                        case .TP_PIN_OTP_INVALID_FORMAT:
                            Utilities.showSuccessAlertView(message: TP_OTP_INVALID_FORMAT, presenter: self)
                            break
                        case .TP_PIN_OTP_INVALID_LEN:
                            Utilities.showSuccessAlertView(message: TP_OTP_INVALID_LEN, presenter: self)
                            break
                        case .TP_PIN_OTP_ALREADY_EXISTS:
                            Utilities.showSuccessAlertView(message: TP_OTP_ALREADY_EXISTS, presenter: self)
                            break
                        case .AUTHVIA_TP_DISABLED:
                            Utilities.showSuccessAlertView(message: PIN_MANAGE_PRIVILEGE_FAILED, presenter: self)
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
                    Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add OTP.", presenter: self)
                }
            })
        } else {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to add OTP.", presenter: self)
        }
        
    }
}

// MARK: - Wifi Settings
extension OTPViewController {
    
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
                            self.updateOTPViaWifi()
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

// MARK: Offline Storage
extension OTPViewController{
    func saveOtpOffline() {
        var arrTemp = [Any]()
        for item in 0..<self.arrOTP.count{
            let pin = Utilities().convertStringToEncryptedString(plainString: "\(self.arrOTP[item])", isSecured: true)
            let params : NSMutableDictionary = ["pin": pin, "slot_number" : item + 1]
            arrTemp.append(params)
        }
        let userDetailsDict = [
            "lock_otps": arrTemp,
            "lock_id": userLockID,
        ] as [String : AnyObject]
        LockWifiManager.shared.localCache.setUpdateOTPToBeUpdated(OtpList: userDetailsDict)
    }
}

extension OTPViewController: UITableViewDataSource,UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrOtpValue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "OTPTableViewCell") as? OTPTableViewCell{
            cell.selectionStyle = .none
            cell.lblOTP.text = self.arrOtpValue[indexPath.row].pin
            cell.status = self.arrOtpValue[indexPath.row].status
            cell.lblTime.text = self.arrOtpValue[indexPath.row].createdDate
            return cell
        }
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}


extension Int {
init(_ range: Range<Int> ) {
    let delta = range.lowerBound < 0 ? abs(range.lowerBound) : 0
    let min = UInt32(range.lowerBound + delta)
    let max = UInt32(range.upperBound   + delta)
    self.init(Int(min + arc4random_uniform(max - min)) - delta)
    }
}
