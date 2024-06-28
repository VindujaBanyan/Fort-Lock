//
//  PinMainViewController.swift
//  SmartLockiOS
//
//  Created by Sathishkumar R S on 5/17/21.
//  Copyright © 2021 payoda. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift
import XLPagerTabStrip
import NetworkExtension



class PinMainViewController: BaseButtonBarPagerTabStripViewController<TabsCollectionViewCell>, SlideMenuControllerDelegate {
    @IBOutlet weak var viewManagePrivilege: UIView!
    @IBOutlet weak var switchManagePrivilege: UISwitch!
    var userLockID = String()
    var lockConnection:LockConnection = LockConnection()
    var scratchCode = String()
    var lockListDetailsObj = LockListModel(json: [:])
    let redColor = UIColor(red: 221/255.0, green: 0/255.0, blue: 19/255.0, alpha: 1.0)
    let unselectedIconColor = UIColor(red: 73/255.0, green: 8/255.0, blue: 10/255.0, alpha: 1.0)
    var isConnectedViaWIFI = Bool()
    
    private let notificationCenter = NotificationCenter.default

    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        buttonBarItemSpec = ButtonBarItemSpec.nibFile(nibName: "TabsCollectionViewCell", bundle: Bundle(for: TabsCollectionViewCell.self), width: { _ in
            return 70.0
        })
    }
    
    override func viewDidLoad() {
        self.title = "Manage PINS"
        
        notificationCenter
                          .addObserver(self,
                           selector:#selector(processBackgroundNotifiData(_:)),
                                       name: NSNotification.Name(BundleIdentifier),
                           object: nil)
        
        // change selected bar color
        
        settings.style.buttonBarBackgroundColor = UIColor.clear
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.selectedBarBackgroundColor = UIColor(red: 234/255.0, green: 234/255.0, blue: 234/255.0, alpha: 1.0)
        settings.style.selectedBarHeight = 4.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .white
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
        
        self.settings.style.selectedBarHeight = 0
        self.settings.style.selectedBarBackgroundColor = TABS_BGCOLOR //UIColor.orange
        
        changeCurrentIndexProgressive = { [weak self] (oldCell: TabsCollectionViewCell?, newCell: TabsCollectionViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.iconImage.tintColor = .white
            oldCell?.iconLabel.textColor = .white
            newCell?.iconImage.tintColor = TABS_BGCOLOR //.orange
            newCell?.iconLabel.textColor = TABS_BGCOLOR //.orange
            
        }
        super.viewDidLoad()
        self.updateUI()
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }
    
    @objc func processBackgroundNotifiData(_ notification: Notification) {
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        if let userInfo = notification.userInfo {
            
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            
            let title = userInfo["title"] as? String
            let body = userInfo["body"] as? String
            let command = userInfo["command"] as? String
            let status = userInfo["status"] as? String
            
            if (status == "success" && (command == LockNotificationCommand.PIN_ON.rawValue || command == LockNotificationCommand.PIN_OFF.rawValue)){
                
                // Save offline
                self.lockListDetailsObj.enable_pin = switchManagePrivilege.isOn ? "1" : "0"
                
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.popToViewController()
                }))
                self.present(alert, animated: true, completion: nil)
                
            }else if (status == "failure" && (command == LockNotificationCommand.PIN_ON.rawValue || command == LockNotificationCommand.PIN_OFF.rawValue)){
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
    
    func updateUI() {
        self.viewManagePrivilege.isHidden = self.lockListDetailsObj.enable_pin == "0" ? false : true
        self.switchManagePrivilege.isOn = self.lockListDetailsObj.enable_pin == "0" ? false : true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func popToViewController() {
        self.navigationController!.popViewController(animated: false)
    }
    
    // MARK: - PagerTabStripDataSource
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let DigiPinViewController = storyBoard.instantiateViewController(withIdentifier: "DigiPinViewController") as! DigiPinViewController
        DigiPinViewController.scratchCode = self.scratchCode
        DigiPinViewController.lockConnection.selectedLock =  lockConnection.selectedLock
        DigiPinViewController.scratchCode = self.lockListDetailsObj.scratch_code
        DigiPinViewController.lockConnection.serialNumber = self.lockConnection.serialNumber
        DigiPinViewController.lockListDetailsObj = self.lockListDetailsObj
        DigiPinViewController.userLockID = userLockID
        
        let OTPViewController = storyBoard.instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
        OTPViewController.scratchCode = self.scratchCode
        OTPViewController.lockConnection.selectedLock =  lockConnection.selectedLock
        OTPViewController.scratchCode = self.lockListDetailsObj.scratch_code
        OTPViewController.lockConnection.serialNumber = self.lockConnection.serialNumber
        OTPViewController.lockListDetailsObj = self.lockListDetailsObj
        OTPViewController.userLockID = userLockID
                
        return [DigiPinViewController, OTPViewController]
    }
    
    override func configure(cell: TabsCollectionViewCell, for indicatorInfo: IndicatorInfo) {
        cell.iconImage.image = indicatorInfo.image?.withRenderingMode(.alwaysTemplate)
        cell.iconLabel.text = indicatorInfo.title?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
        if indexWasChanged && toIndex > -1 && toIndex < viewControllers.count {
            let child = viewControllers[toIndex] as! IndicatorInfoProvider // swiftlint:disable:this force_cast
            UIView.performWithoutAnimation({ [weak self] () -> Void in
                guard let me = self else { return }
                me.navigationItem.leftBarButtonItem?.title =  child.indicatorInfo(for: me).title
            })
        }
    }

    func currentViewController() -> UIViewController {
        let viewController = self.viewControllers(for: PagerTabStripViewController())[currentIndex]
        return viewController
    }
    @IBAction func switchManagePrivilegeAction(_ sender: Any) {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if self.lockListDetailsObj.lockVersion == lockVersions.version4_0.rawValue {
            let urlString = ServiceUrl.BASE_URL + "locks/\(self.lockListDetailsObj.serial_number ?? "")/pin/manage"
            let pinManageStatus = "\(Int(truncating: NSNumber(value:switchManagePrivilege.isOn)))"
            let lockDetails = ["enable_pin": pinManageStatus]
            
            DigiPinViewModel().managePinViaMqttServiceViewModel(url: urlString, userDetails: lockDetails) { result, error in
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
        }else{
            self.updateManagePrivilegeWithWifi()
        }
    }
    
    @nonobjc func leftWillOpen() {
        //print("SlideMenuControllerDelegate: leftWillOpen")
    }
    
    @nonobjc func leftDidOpen() {
        //print("SlideMenuControllerDelegate: leftDidOpen")
    }
    
    @nonobjc func leftWillClose() {
        //print("SlideMenuControllerDelegate: leftWillClose")
    }
    
    @nonobjc func leftDidClose() {
        //print("SlideMenuControllerDelegate: leftDidClose")
    }
    
    @nonobjc func rightWillOpen() {
        //print("SlideMenuControllerDelegate: rightWillOpen")
    }
    
    @nonobjc func rightDidOpen() {
        //print("SlideMenuControllerDelegate: rightDidOpen")
    }
    
    @nonobjc func rightWillClose() {
        //print("SlideMenuControllerDelegate: rightWillClose")
    }
    
    @nonobjc func rightDidClose() {
        //print("SlideMenuControllerDelegate: rightDidClose")
    }
}

// MARK: Lock Connection
extension PinMainViewController{
    
    func updateManagePrivilegeWithWifi() {
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
    
    func updateManagePrivilegeViaWifi() {
        // Hardware add Digi Pin
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            var parameters = [String : Any]()
            parameters["owner-id"] = authorizationKey["owner-id"]
            parameters["slot-key"] = authorizationKey["slot-key"]
            parameters["en-dis"] = "\(Int(truncating: NSNumber(value:switchManagePrivilege.isOn)))"
            LockWifiManager.shared.updatePinManagePrivilege(userDetails: parameters, completion: {[unowned self] (isSuccess, jsonResponse, error) in
                LoaderView.sharedInstance.hideShadowView(selfObject: self)
                if isSuccess == true {
                    if let jsonDict = jsonResponse?.dictionary {
                        let dictResponse = jsonDict["response"]?.dictionaryObject!
                        let updatedKey = jsonDict["error-message"]?.rawString() ?? ""
                        let tempStr: LockWifiPINManagePrivilegeMessages = LockWifiPINManagePrivilegeMessages(rawValue: updatedKey) ?? .EMPTY
                        switch tempStr {
                        case .OK:
                            print(".OK")
                            // Save offline
                            self.lockListDetailsObj.enable_pin = switchManagePrivilege.isOn ? "1" : "0"
                            self.saveOfflineManagePrivilege()
                            self.localDataUpdate()
                            let alert = UIAlertController(title: ALERT_TITLE, message: switchManagePrivilege.isOn ? PIN_MANAGE_PRIVILEGE_ENABLE : PIN_MANAGE_PRIVILEGE_DISABLE, preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                self.popToViewController()
                            }))
                            self.present(alert, animated: true, completion: nil)
                            break
                        case .AUTHVIA_TP_DISABLED:
                            self.managePrivilegeActualState()
                            Utilities.showSuccessAlertView(message: TP_OTP_INVALID_FORMAT, presenter: self)
                            break
                        default:
                            self.managePrivilegeActualState()
                            break
                        }
                    }
                } else {
                    self.managePrivilegeActualState()
                    LoaderView.sharedInstance.hideShadowView(selfObject: self)
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

// MARK: - Wifi Settings
extension PinMainViewController {
    
    func configureWifiConnection(ssid: String, password: String) {
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            let config = NEHotspotConfiguration(ssid: newSSID, passphrase: password, isWEP: false)
            config.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(config) { (error) in
                if let error = error {
                    self.managePrivilegeActualState()
                    self.isConnectedViaWIFI = false
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            self.updateManagePrivilegeViaWifi()
                            self.isConnectedViaWIFI = true
                        } else {
                            self.managePrivilegeActualState()
                            self.isConnectedViaWIFI = false
                            Utilities.showErrorAlertView(message: "Lock disconnected. Failed to Manage Privilege.", presenter: self)
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

extension PinMainViewController{
    func saveOfflineManagePrivilege() {
        let userDetailsDict = [
            "enable_pin": "\(Int(truncating: NSNumber(value:switchManagePrivilege.isOn)))",
            "lock_id" : self.userLockID
        ] as [String : AnyObject]
        LockWifiManager.shared.localCache.setUpdatePinManagePrivilegeToBeUpdated(PinEnable: userDetailsDict)
    }
    func localDataUpdate(){
        let dbObj = CoreDataController()
        dbObj.updateLockList(id: userLockID, updateKey: "enable_pin", updateValue: "\(Int(truncating: NSNumber(value:switchManagePrivilege.isOn)))")
    }
}
