//
//  FactoryResetListViewController.swift
//  SmartLockiOS
//
//  Created by Geethanjali Natarajan on 26/10/18.
//  Copyright © 2018 payoda. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift
import NetworkExtension

class FactoryResetListViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel?
    @IBOutlet weak var factoryResetListTableView: UITableView?
    
    var availableListOfLock:[BluetoothAdvertismentData] = []
    let refresher = UIRefreshControl()

    var lockConnection:LockConnection = LockConnection()
    var lockListDetailsObj = LockListModel(json: [:])
    var lockListArray = [LockListModel]()
    
    var isConnectedViaWIFI = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initialize method
    func initialize() {
        self.title = "Lock List"
        factoryResetListTableView?.separatorStyle = .none
//        factoryResetListTableView?.backgroundColor = UIColor.white
        addBackBarButton()
        registerTableViewCell()
        infoLabel?.text = EMPTY_LOCK_LIST
        
        handleSavedData()
    }
    
    
    func handleEnablePassageValue(_ enablePassage: String) {
            print("Received enable_passage value: \(enablePassage)")
         }
    /// Handle offline saved data
    func handleSavedData() {
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        DispatchQueue.global(qos: .background).async {
            LockWifiManager.shared.localCache.checkAndUpdateFactoryReset(completion: { (status) in
                self.getLockListServiceCall()
            })
        }
    }
    
    // MARK: - Register Cells
    func registerTableViewCell() {
        
        let nib = UINib(nibName: "LockListTableViewCell", bundle: nil)
        self.factoryResetListTableView?.register(nib, forCellReuseIdentifier: "LockListTableViewCell")
    }
    
    //MARK: - Add refresh controller
    
    func addRefreshController() {
        
        self.refresher.attributedTitle = NSAttributedString(string: "")
        self.refresher.addTarget(self, action: #selector(self.refreshCall), for: .valueChanged)
        self.factoryResetListTableView?.addSubview(self.refresher)
    }
    
    @objc func refreshCall() {
        
        if Connectivity().isConnectedToInternet() {
//            LockWifiManager.shared.localCache.updateOfflineItems()
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
//                self.getLockListServiceCall()
//            })
            DispatchQueue.global(qos: .background).async {
                LockWifiManager.shared.localCache.checkAndUpdateFactoryReset(completion: { (status) in
                    self.getLockListServiceCall()
                })
            }
        } else {
//            getListDataFromLocal()
            self.refresher.endRefreshing()
        }
    }


    // MARK: - Navigation Bar Button
    
    func addBackBarButton() {
        let backBtn: UIButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
        
        backBtn.addTarget(self, action: #selector(self.onTapBackButton), for: UIControl.Event.touchUpInside)
        backBtn.setImage(UIImage(named: "back"), for: UIControl.State.normal)
        
        backBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        backBtn.sizeToFit()
        backBtn.frame = CGRect(x: 0, y: 10, width: 36, height: 36)
        let customBackBtnItem: UIBarButtonItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = customBackBtnItem
    }
    
    @objc func onTapBackButton() {
        self.loadMainView()
    }
    
    @objc fileprivate func loadMainView() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController") as! LeftViewController
        
        let navigationController = UINavigationController(rootViewController: mainViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true
        leftViewController.mainViewController = navigationController
        
        let slider = SlideMenuController(mainViewController:navigationController, leftMenuViewController: leftViewController)
        
       slider.automaticallyAdjustsScrollViewInsets = true
        
        slider.delegate = mainViewController
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.window?.rootViewController = slider
        appDelegate.window?.makeKeyAndVisible()
    }

    // MARK: - Service Call
    
    @objc func getLockListServiceCall() {
      
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        
        let urlString = ServiceUrl.BASE_URL + "locks/locklist"
        
        LockDetailsViewModel().getLockListServiceViewModel(url: urlString, userDetails: [:]) { result, _ in
            
            LockWifiManager.shared.localCache.updateOfflineItems()
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.refresher.endRefreshing()
            
            if result != nil {
                // populate data from result and reload table
                
                self.lockListArray.removeAll()
                self.lockListArray = result as! [LockListModel]
                
                let filterArray = self.lockListArray.filter({ (lockListModel) -> Bool in
                    
                    return lockListModel.lock_keys[1].user_type!.lowercased() == UserRoles.owner.rawValue && lockListModel.lock_keys![0].status! == "1"
                })
                
                self.lockListArray = filterArray
                
                if self.lockListArray.count > 0 {
                    self.infoLabel?.isHidden = true
                    self.factoryResetListTableView?.isHidden = false
                } else {
                    self.infoLabel?.isHidden = false
                    self.factoryResetListTableView?.isHidden = true
                }
                DispatchQueue.main.async {
                    self.factoryResetListTableView?.reloadData()
                }
            } else {
                self.infoLabel?.isHidden = false
            }
        }
    }
    
    func updateFactoryResetLockDetails(){
        //        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if Connectivity().isConnectedToInternet() {
            let urlString = ServiceUrl.BASE_URL + "locks/updatelock?id=\(self.lockListDetailsObj.id!)"
            
            let userDetails = [
                "status": "2"
            ]
            LockDetailsViewModel().updateLockDetailsServiceViewModel(url: urlString, userDetails: userDetails) { result, error in
                
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                //print("Result ==> \(String(describing: result))")
                if result != nil {
                    
                    self.getLockListServiceCall()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.disconnectWifi(ssid: self.lockConnection.serialNumber)
                    }
                    let alert = UIAlertController(title: ALERT_TITLE, message: "Lock reset successfully. Please connect to the internet for the process to complete.", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    self.saveFactoryResetToLocal()
                    
                    //Error handling
                    let message = error?.userInfo["ErrorMessage"] as! String
                    self.view.makeToast(message)
//                    let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
//
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                    }))
//                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            saveFactoryResetToLocal()
        }
    }
    
    func saveFactoryResetToLocal() {
        LockWifiManager.shared.localCache.appendLocksForFactoryReset(lockId: self.lockListDetailsObj.id!)
        
        let localDB = CoreDataController()
        localDB.deleteLockList(id: self.lockListDetailsObj.id)
//        if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.usersLockList.rawValue) as? NSData {
        //    if let savedListObj = localDB.fetchLockList() as? [LockListModel] {
                
                

                //                    let newList = savedListObj.filter {$0.id == self.lockListDetailsObj.id}
                
                //print("savedListObj ==> ")
                //print(savedListObj)
                
                
//                if let i = savedListObj.index(where: { $0.id == self.lockListDetailsObj.id }) {
//
//                    var newList = savedListObj
//                    //print("Index ==> \(i)")
//
//                    //print(newList[i].lock_keys![0].status!)
//                    //print("------------------")
//                    let objectIndex = i
//                    newList.remove(at: objectIndex)
//
//                    //print("newList ==> ")
//                    //print(newList)
//
//
//
//                    let archivedObject = NSKeyedArchiver.archivedData(withRootObject: newList)
//                    let defaults = UserDefaults.standard
//                    defaults.set(archivedObject, forKey: UserdefaultsKeys.usersLockList.rawValue)
//                    defaults.synchronize()
//                }
                
                self.getListDataFromLocal()
                
        let alert = UIAlertController(title: ALERT_TITLE, message: "Lock reset successfully. Please connect to the internet for the process to complete.", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
          //  }
        //}
    }
    
    // MARK: - Get lock list from local
    
    func getListDataFromLocal() {
        
       // if let decodedNSData = UserDefaults.standard.object(forKey: UserdefaultsKeys.usersLockList.rawValue) as? NSData {
            
          var dbObj = CoreDataController()
        if let savedListObj = dbObj.fetchLockList() as? [LockListModel] {
                //                        user = savedUser
                //print("savedUser viewDidLoad ==> \(savedListObj)")
                
                self.lockListArray = savedListObj

                let filterArray = self.lockListArray.filter({ (lockListModel) -> Bool in
                    
                    return lockListModel.lock_keys[1].user_type!.lowercased() == UserRoles.owner.rawValue && lockListModel.lock_keys![0].status! == "1"
                })
                
                self.lockListArray = filterArray

                
                if self.lockListArray.count > 0 {
                    DispatchQueue.main.async {
                        self.factoryResetListTableView?.reloadData()
                        self.infoLabel?.isHidden = true
                    }
                } else {
                    self.factoryResetListTableView?.isHidden = true
                    self.infoLabel?.isHidden = false
                }
                //print("self.lockListArray ==> ")
                //print(self.lockListArray)
                DispatchQueue.main.async {
                    self.factoryResetListTableView?.reloadData()
                }
            }
       // }
    }
    
}

// MARK: - UITableViewDataSource
extension FactoryResetListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LockListTableViewCell") as? LockListTableViewCell
            cell?.selectionStyle = .none
//            cell?.backgroundColor = UIColor.white
            //            cell?.lockNameLabel.text = lockListArray[indexPath.row]
            let lockListObj = lockListArray[indexPath.row]
            cell?.lockNameLabel.text = lockListObj.lockname
            return cell!
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lockListArray.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 //UITableViewAutomaticDimension
    }
    
}

// MARK: - UITableViewDelegate

extension FactoryResetListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.lockListDetailsObj = lockListArray[indexPath.row]
        
        let advertisementData = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockListDetailsObj.serial_number)
        self.lockConnection.selectedLock = advertisementData
        self.lockConnection.serialNumber = self.lockListDetailsObj.serial_number
        UserController.sharedController.loadDataOffline(forSerialNumber: self.lockConnection.serialNumber)
        
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
        if self.lockListDetailsObj.lockVersion == lockVersions.version6_0.rawValue {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK_FOR_V6, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.factoryResetAlert()
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: ALERT_TITLE, message: TURN_ON_LOCK_FOR_OTHERS, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.factoryResetAlert()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - Wifi Settings

extension FactoryResetListViewController {
    func configureWifiConnection(ssid: String, password: String, isFactoryReset: Bool, isTransferredOwner: Bool) {
        
        let newSSID = JsonUtils().getManufacturerCode() + ssid
        
        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            
            let config = NEHotspotConfiguration(ssid: newSSID, passphrase: password, isWEP: false)
            config.joinOnce = false
            NEHotspotConfigurationManager.shared.apply(config) { (error) in
                if let error = error {
                    
                    self.isConnectedViaWIFI = false
                    
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: {
                        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
                            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

                            self.isConnectedViaWIFI = true
                            self.factoryResetViaWIFI()
                            
                        } else {
                            self.isConnectedViaWIFI = false
//                            Utilities.showErrorAlertView(message: "Unable to connect to lock. Please try again", presenter: self)
//                            return
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

// MARK: - Factory reset methods
extension FactoryResetListViewController {
    
    func factoryResetAlert() {
        let alert = UIAlertController(title: ALERT_TITLE, message: FACTORY_RESET_MESSAGE, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { _ in
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        }))
        alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { _ in
            self.factoryResetLockWithWIFI()
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func factoryReset() {
        
        var key = ""
        if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
            key = _key
        }
        else {
            Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
            return
        }
        
        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
            
            self.isConnectedViaWIFI = true
            self.factoryResetViaWIFI()
            
        } else {
            
            if lockConnection.selectedLock == nil {
                
                lockConnection.selectedLock = BLELockAccessManager.shared.scanController.matchingPeripheral("", self.lockConnection.serialNumber)
            }
            if lockConnection.selectedLock != nil {
                self.factoryResetViaBLE(key: key) { (status) in
                    
                    LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                }
            } else {
                return
            }
        }
        
    }
    
    func factoryResetViaBLE(key: String, completion: @escaping (Bool) -> Void) {
        var isFactoryResetDone = true
        BLELockAccessManager.shared.disengageDelegate = self
        if lockConnection.selectedLock! != nil {
            BLELockAccessManager.shared.connectWithLock(lockData:  lockConnection.selectedLock!, completion: { isSuccess in
                if isFactoryResetDone {
                    isFactoryResetDone = false
                    LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                    LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)
                    
                    if isSuccess {
                        BLELockAccessManager.shared.factoryReset(userKey: key)
                    } else {
                        //                Utilities.showErrorAlertView(message: "Lock is not connected", presenter: self)
                    }
                    completion(isSuccess)
                }
            })
        } else {
            Utilities.showErrorAlertView(message: "Unable to connect to lock. Please try again.", presenter: self)
        }
    }
    
    func factoryResetLockWithWIFI() {
        
        LoaderView.sharedInstance.showShadowView(title: "Loading...", selfObject: self, isFromNotifiation: false)

        var key = ""
        if let _key = UserController.sharedController.authorizationKey(isSecured: self.lockListDetailsObj.is_secured) {
            key = _key
        }
        else {
            Utilities.showErrorAlertView(message: "User info is missing", presenter: self)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + getActivityTime(lockVersion: lockVersions(rawValue: self.lockListDetailsObj.lockVersion) ?? .version1), execute: {
            if !self.isConnectedViaWIFI {
                if BLELockAccessManager.shared.checkForBluetoothAccess().canAccess == true {
                    self.initializeScan()

                }  else {
                   // Utilities.showErrorAlertView(message: TURN_ON_BLUETOOTH, presenter: self)
                }
            }
        })
        if self.lockConnection.isConnectedToLockWifi(ssidName: self.lockConnection.serialNumber) {
            
            self.isConnectedViaWIFI = true
            self.factoryResetViaWIFI()
        } else {
//            if Connectivity().isConnectedToInternet() {
                self.configureWifiConnection(ssid: self.lockConnection.serialNumber, password: self.lockListDetailsObj.scratch_code, isFactoryReset: true, isTransferredOwner: false)
                
            /*
            } else {
//                LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
                
                let message = TURN_ON_WIFI
                let alert = UIAlertController(title: ALERT_TITLE, message: message, preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                self.present(alert, animated: true, completion: nil)
            }
            */
        }
    }
    
    func factoryResetViaWIFI() {
        if  let authorizationKey = UserController.sharedController.authorizationKeyForWifi(isSecured: self.lockListDetailsObj.is_secured){
            let customHeaders = authorizationKey
            LockWifiManager.shared.didFactoryReset(factoryReset: customHeaders, completion: { (isSuccess, jsonResponse, error) in
                
                //print("loading hide view == > factory reset ViaWifi() ")
                
                if isSuccess == false {
                    self.isConnectedViaWIFI = false
//                    Utilities.showErrorAlertView(message: "Failed to set factory reset", presenter: self)
                } else {

                    self.isConnectedViaWIFI = true

                    //                    Utilities.showSuccessAlertView(message: "Factory reset done successfully", presenter: self)
                    self.updateFactoryResetLockDetails()
                    /*
                     let alertController = UIAlertController(title: ALERT_TITLE, message: "Factory reset done successfully", preferredStyle: .alert)
                     let action = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in
                     
                     self.updateFactoryResetLockDetails()
                     DispatchQueue.main.async {
                     self.navigationController?.popViewController(animated: true)
                     }
                     }
                     alertController.addAction(action)
                     self.present(alertController, animated: true, completion: nil) */
                }
            })
        } else {
//            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
            self.isConnectedViaWIFI = false
            Utilities.showSuccessAlertView(message: "Failed to set factory reset", presenter: self)
        }
    }
    
}


extension FactoryResetListViewController: BLELockScanControllerProtocol{
    
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
            self.factoryResetViaBLE(key: key, completion: { (status) in
                
            })
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

extension FactoryResetListViewController: BLELockAccessDisengageProtocol{
    func didReadAccessLogs(logs: String) {
    }
    
    func didCompleteOwnerTransfer(isSuccess: Bool, newOwnerId: String, oldOwnerId: String, error: String) {
    }
    
    func didDisengageLock(isSuccess: Bool, error: String) {
    }
    
    func didCompleteFactoryReset(isSuccess: Bool, error: String) {
        //        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        
        //print("loading hide view == > didcompletefactory reset() ")
        if isSuccess == false {
            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)

            Utilities.showErrorAlertView(message: error, presenter: self)
        }
        else{
            self.updateFactoryResetLockDetails()
            //            Utilities.showSuccessAlertView(message: "Factory reset done successfully", presenter: self)
            //
        }
    }
    func didFailedToConnect(error: String){
        //print("didFailedToConnect ==> ")
    }
    func didFinishReadingAllCharacteristics(){
        
    }
    func didPeripheralDisconnect(){
        
        //print("didFailedToConnect ==> ")
//        if isConnectedVisBLE {
//            Utilities.showErrorAlertView(message: "Lock disconnected", presenter: self)
//
//            LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
//            return
//        } else {
//
//        }
//
//        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
//
//
        
    }
    func didFailAuthorization() {
        //BLELockAccessManager.shared.disEngageLock(key: self.userKey!)
        
        
        LoaderView.sharedInstance.hideShadowView(selfObject: self, isFromNotifiation: false)
        
        //print("didFailAuthorization ==> ")
//        self.isConnectedVisBLE = false
        Utilities.showErrorAlertView(message: "You are not an authorized user for this lock", presenter: self)
    }
    
    func didReadBatteryLevel(batteryPercentage:String){
    }
    
    func didCompleteDisengageFlow() {
        //print("disconnted in flow")
        BLELockAccessManager.shared.disconnectLock()
    }
}
